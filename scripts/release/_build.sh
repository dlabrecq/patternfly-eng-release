#!/bin/sh

default()
{
  SCRIPT=`basename $0`
  SCRIPT_DIR=`dirname $0`
  SCRIPT_DIR=`cd $SCRIPT_DIR; pwd`

  . $SCRIPT_DIR/../_env.sh
  . $SCRIPT_DIR/../_common.sh
  . $SCRIPT_DIR/_common.sh

  BUILD_DIR=$TRAVIS_BUILD_DIR
}

# Add tag to kick off version bump
#
# $1: Remote repo
# $2: Remote branch
# $3: Local branch
add_bump_tag()
{
  echo "*** Adding version bump tag"
  cd $BUILD_DIR

  # Add tag to kick off version bump
  git fetch $1 $2:$3 # <remote-branch>:<local-branch>
  check $? "git fetch failure"
  git checkout $3
  git tag $BUMP_TAG_PREFIX$VERSION -f
  git push $1 tag $BUMP_TAG_PREFIX$VERSION
  check $? "git push tag failure"
}

# Add release tag
#
add_release_tag()
{
  echo "*** Adding release tag"
  cd $BUILD_DIR

  # Add release tag
  git tag $RELEASE_TAG_PREFIX$VERSION
  check $? "add tag failure"
  git push upstream tag $RELEASE_TAG_PREFIX$VERSION
  check $? "git push tag failure"
}

# Delete tag used to kick off version bump
#
delete_bump_tag()
{
  echo "*** Deleting bump tag"
  cd $BUILD_DIR

  # Remove bump tag
  git tag -d $BUMP_TAG_PREFIX$VERSION
  git push upstream :refs/tags/$BUMP_TAG_PREFIX$VERSION
  check $? "delete tag failure"
}

# Check prerequisites before continuing
#
prereqs()
{
  echo "This build is running against $TRAVIS_REPO_SLUG"

  if [ -n "$TRAVIS_TAG" ]; then
    echo "This build is running against $TRAVIS_TAG"

    # Get version from tag
    case "$TRAVIS_TAG" in
      $BUMP_TAG_PREFIX* ) VERSION=`echo "$TRAVIS_TAG" | cut -c $BUMP_TAG_PREFIX_COUNT-`;;
      *) check 1 "$TRAVIS_TAG is not a recognized format. Do not release!";;
    esac
  fi

  delete_bump_tag # Wait until we have the version

  # Ensure release runs for main repo only
  if [ "$TRAVIS_REPO_SLUG" != "$REPO_SLUG" ]; then
    check 1 echo "Release must be performed on $REPO_SLUG only!"
  fi

  git tag | grep "^$RELEASE_TAG_PREFIX$VERSION"
  if [ $? -eq 0 ]; then
    check 1 "Tag $RELEASE_TAG_PREFIX$VERSION exists. Do not release!"
  fi
}

usage()
{
cat <<- EEOOFF

    This script will build, publish, and release the repo.

    If a custom Git tag has been created to publish a release, the Git tag will be deleted first. Then, the appropriate
    scripts will be called to bump version numbers and publish the repo. Finally, a custom tag will be created to kick
    off the release for the Angular Patternfly, Patternfly Org and RCUE repos.

    Note: Intended for use with Travis only.

    AUTH_TOKEN must be set via Travis CI.

    sh [-x] $SCRIPT [-h] -a|e|j|o|p|r|w

    Example: sh $SCRIPT -p

    OPTIONS:
    h       Display this message (default)
    a       Angular PatternFly
    e       Patternfly Eng Release
    j       Patternfly jQuery
    o       PatternFly Org
    p       PatternFly
    r       PatternFly RCUE
    w       Patternfly Web Components

EEOOFF
}

# main()
{
  default

  if [ "$#" -eq 0 ]; then
    usage
    exit 1
  fi

  while getopts haejoprw c; do
    case $c in
      h) usage; exit 0;;
      a) PTNFLY_ANGULAR=1;
         REPO_SLUG=$REPO_SLUG_PTNFLY_ANGULAR;
         SWITCH=a;;
      e) PTNFLY_ENG_RELEASE=1;
         REPO_SLUG=$REPO_SLUG_PTNFLY_ENG_RELEASE;
         SWITCH=e;;
      j) PTNFLY_JQUERY=1;
         REPO_SLUG=$REPO_SLUG_PTNFLY_JQUERY;
         SWITCH=j;;
      o) PTNFLY_ORG=1;
         REPO_SLUG=$REPO_SLUG_PTNFLY_ORG;
         SWITCH=o;;
      p) PTNFLY=1;
         REPO_SLUG=$REPO_SLUG_PTNFLY;
         SWITCH=p;;
      r) PTNFLY_RCUE=1;
         REPO_SLUG=$REPO_SLUG_RCUE;
         SWITCH=r;;
      w) PTNFLY_WC=1;
         SWITCH=w;;
      \?) usage; exit 1;;
    esac
  done

  prereqs # Check for existing tag before fetching remotes
  git_setup

  # Bump version numbers, build, and test
  sh -x $SCRIPT_DIR/release.sh -s -v $VERSION -$SWITCH
  check $? "bump version failure"

  # Push version bump and generated files to master and dist branches
  if [ -n "$PTNFLY" -o -n "$PTNFLY_JQUERY" -o -n "$PTNFLY_ANGULAR" ]; then
    sh -x $SCRIPT_DIR/_publish.sh -m -d
  else
    sh -x $SCRIPT_DIR/_publish.sh -m
  fi
  check $? "Publish failure"

  # NPM publish
  if [ -n "$PTNFLY" -o -n "$PTNFLY_ANGULAR" -o -n "$PTNFLY_ENG_RELEASE" ]; then
    if [ -z "$SKIP_NPM_PUBLISH" ]; then
      sh -x $SCRIPT_DIR/publish-npm.sh -s -$SWITCH
      check $? "npm publish failure"
    fi
  fi

  add_release_tag # Add release tag

  # Kick off next version bump in chained release
  if [ -n "$PTNFLY" ]; then
    # Todo: Enable patternfly-jquery when repo is ready
    #add_bump_tag $REPO_NAME_PTNFLY_JQUERY $RELEASE_BRANCH $RELEASE_BRANCH-$REPO_NAME_PTNFLY_JQUERY
    add_bump_tag $REPO_NAME_PTNFLY_ANGULAR $RELEASE_BRANCH $RELEASE_BRANCH-$REPO_NAME_PTNFLY_ANGULAR
    add_bump_tag $REPO_NAME_RCUE $RELEASE_BRANCH $RELEASE_BRANCH-$REPO_NAME_RCUE
  elif [ -n "$PTNFLY_JQUERY" ]; then
    add_bump_tag $REPO_NAME_PTNFLY_ANGULAR $RELEASE_BRANCH $RELEASE_BRANCH-$REPO_NAME_PTNFLY_ANGULAR
    add_bump_tag $REPO_NAME_RCUE $RELEASE_BRANCH $RELEASE_BRANCH-$REPO_NAME_RCUE
  elif [ -n "$PTNFLY_ANGULAR" ]; then
    add_bump_tag $REPO_NAME_PTNFLY_ORG $RELEASE_BRANCH $RELEASE_BRANCH-$REPO_NAME_PTNFLY_ORG
  elif [ -n "$PTNFLY_ENG_RELEASE" ]; then
    add_bump_tag $REPO_NAME_PTNFLY $RELEASE_BRANCH $RELEASE_BRANCH-$REPO_NAME_PTNFLY
  fi
}
