#!/bin/sh

default()
{
  SCRIPT=`basename $0`
  SCRIPT_DIR=`dirname $0`
  SCRIPT_DIR=`cd $SCRIPT_DIR; pwd`

  . $SCRIPT_DIR/_env.sh
  . $SCRIPT_DIR/_common.sh

  BUILD_DIR=$TRAVIS_BUILD_DIR
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

# Check prerequisites before continuing
#
prereqs()
{
  echo "This build is running against $TRAVIS_REPO_SLUG"

  if [ -n "$TRAVIS_TAG" ]; then
    echo "This build is running against $TRAVIS_TAG"

    # Get version from package
    VERSION=`npm info $REPO_NAME | grep latest | awk -F':' '{print $3}' | awk -F"'" '{print $2}'`
  fi

  # Ensure release runs for main repo only
  if [ "$TRAVIS_REPO_SLUG" != "$REPO_SLUG" ]; then
    check 1 echo "Release must be performed on $REPO_SLUG only!"
  fi

  git tag | grep "^$RELEASE_TAG_PREFIX$VERSION$"
  if [ $? -eq 0 ]; then
    check 1 "Tag $RELEASE_TAG_PREFIX$VERSION exists. Do not release!"
  fi
}

usage()
{
cat <<- EEOOFF

    This script will publish webjar and tag the repo.

    Note: Intended for use with Travis only.

    AUTH_TOKEN must be set via Travis CI.

    sh [-x] $SCRIPT [-h] -a|e|o|p|r|w|x

    Example: sh $SCRIPT -p

    OPTIONS:
    h       Display this message (default)
    a       Angular PatternFly
    e       PatternFly Eng Release
    o       PatternFly Org
    p       PatternFly
    r       RCUE
    w       PatternFly Web Components
    x       Patternfly NG

EEOOFF
}

# main()
{
  default

  if [ "$#" -eq 0 ]; then
    usage
    exit 1
  fi

  while getopts haeoprwx c; do
    case $c in
      h) usage; exit 0;;
      a) PTNFLY_ANGULAR=1;
         REPO_NAME=$REPO_NAME_PTNFLY_ANGULAR;
         REPO_SLUG=$REPO_SLUG_PTNFLY_ANGULAR;;
      e) PTNFLY_ENG_RELEASE=1;
         REPO_NAME=$REPO_NAME_PTNFLY_ENG_RELEASE;
         REPO_SLUG=$REPO_SLUG_PTNFLY_ENG_RELEASE;;
      o) PTNFLY_ORG=1;
         REPO_NAME=$REPO_NAME_PTNFLY_ORG;
         REPO_SLUG=$REPO_SLUG_PTNFLY_ORG;;
      p) PTNFLY=1;
         REPO_NAME=$REPO_NAME_PTNFLY;
         REPO_SLUG=$REPO_SLUG_PTNFLY;;
      r) RCUE=1;
         REPO_NAME=$REPO_NAME_RCUE;
         REPO_SLUG=$REPO_SLUG_RCUE;;
      w) PTNFLY_WC=1;
         REPO_NAME=$REPO_NAME_PTNFLY_WC;
         REPO_SLUG=$REPO_SLUG_PTNFLY_WC;;
      x) PTNFLY_NG=1;
         REPO_NAME=$REPO_NAME_PTNFLY_NG;
         REPO_SLUG=$REPO_SLUG_PTNFLY_NG;;
      \?) usage; exit 1;;
    esac
  done

  prereqs # Check for existing tag before fetching remotes
  git_setup

  # Webjar publish
  if [ -z "$SKIP_WEBJAR_PUBLISH" ]; then
    if [ -n "$PTNFLY" -o -n "$PTNFLY_ANGULAR" ]; then
      sh -x $SCRIPT_DIR/release/publish-webjar.sh -v $VERSION -$SWITCH
      check $? "webjar publish failure"
    fi
  fi

  add_release_tag # Add release tag
}
