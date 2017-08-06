#!/bin/sh

# Build PatternFly templates using Jekyll
export PF_PAGE_BUILDER=jekyll

# Email used to notify users release is available
EMAIL_PTNFLY=patternfly@redhat.com
EMAIL_PTNFLY_ANGULAR=patternfly-angular@redhat.com
EMAIL_RCUE=patternfly@redhat.com

# Git properties
GIT_USER_NAME=patternfly-build
GIT_USER_EMAIL=patternfly-build@redhat.com

# Official release branches
RELEASE_BRANCH=master
RELEASE_DIST_BRANCH=master-dist

# PF 'next' branches (i.e., PF4 alpha, beta, etc.)
NEXT_BRANCH=branch-4.0-dev
NEXT_DIST_BRANCH=branch-4.0-dev-dist
NEXT_TAG=next

# Tag prefix for bumping version of a single repo (e.g., _bump-v3.15.0)
BUMP_TAG_PREFIX=_bump-v
BUMP_TAG_PREFIX_COUNT=`echo $BUMP_TAG_PREFIX | wc -c`

# Tag prefix for chaining version bumps with multiple repos (e.g., _bump_chain-v3.15.0)
BUMP_CHAIN_TAG_PREFIX=_bump_chain-v
BUMP_CHAIN_TAG_PREFIX_COUNT=`echo $BUMP_CHAIN_TAG_PREFIX | wc -c`

# Tag prefix for PF 'next' version bump (e.g., _bump_next-v4.0.0)
BUMP_NEXT_TAG_PREFIX=_bump_next-v
BUMP_NEXT_TAG_PREFIX_COUNT=`echo $BUMP_NEXT_TAG_PREFIX | wc -c`

# Tag prefix for chaining PF 'next' version bumps with multiple repos (e.g., _bump_next-v4.0.0)
BUMP_NEXT_CHAIN_TAG_PREFIX=_bump_next_chain-v
BUMP_NEXT_CHAIN_TAG_PREFIX_COUNT=`echo $BUMP_NEXT_CHAIN_TAG_PREFIX | wc -c`

# Prefix used for tagging release (e.g., v3.15.0)
RELEASE_TAG_PREFIX=v

# Repo names
REPO_NAME_PTNFLY=patternfly
REPO_NAME_PTNFLY_ANGULAR=angular-patternfly
REPO_NAME_PTNFLY_NG=patternfly-ng
REPO_NAME_PTNFLY_ORG=patternfly-org
REPO_NAME_PTNFLY_ENG_RELEASE=patternfly-eng-release
REPO_NAME_PTNFLY_WC=patternfly-webcomponents
REPO_NAME_RCUE=rcue

# Repo owners
REPO_OWNER_PTNFLY=patternfly
REPO_OWNER_PTNFLY_WC=patternfly-webcomponents
REPO_OWNER_RCUE=redhat-rcue

# Set flag indicating scripts are running against a fork to prevent accidental merging, npm publish, etc.
if [ -n "$TRAVIS" ]; then
  REPO_OWNER=`dirname $TRAVIS_REPO_SLUG`
  if ! [ "$REPO_OWNER" = "$REPO_OWNER_PTNFLY" -o \
         "$REPO_OWNER" = "$REPO_OWNER_PTNFLY_WC" -o \
         "$REPO_OWNER" = "$REPO_OWNER_RCUE" ]; then
    REPO_FORK=1
  fi
fi

# Run against fork instead of main repo(s) -- set REPO_FORK=1 via local env when testing scripts
if [ -n "$REPO_FORK" ]; then
  if [ -z "$REPO_OWNER" ]; then
    REPO_OWNER=`whoami`
  fi

  # Set fork owner for repo slugs (i.e., owner_name/repo_name)
  REPO_OWNER_PTNFLY=$REPO_OWNER
  REPO_OWNER_PTNFLY_WC=$REPO_OWNER
  REPO_OWNER_RCUE=$REPO_OWNER

  # Email used to notify users release is available
  EMAIL_PTNFLY=$REPO_OWNER@redhat.com
  EMAIL_PTNFLY_ANGULAR=$REPO_OWNER@redhat.com

  # Git properties
  GIT_USER_NAME=$REPO_OWNER
  GIT_USER_EMAIL=$REPO_OWNER@redhat.com

  # Skip npm publish
  SKIP_NPM_PUBLISH=1

  # Skip webjar publish
  SKIP_WEBJAR_PUBLISH=1
fi

# Repo slugs
REPO_SLUG_PTNFLY=$REPO_OWNER_PTNFLY/patternfly
REPO_SLUG_PTNFLY_ANGULAR=$REPO_OWNER_PTNFLY/angular-patternfly
REPO_SLUG_PTNFLY_ENG_RELEASE=$REPO_OWNER_PTNFLY/patternfly-eng-release
REPO_SLUG_PTNFLY_NG=$REPO_OWNER_PTNFLY/patternfly-ng
REPO_SLUG_PTNFLY_ORG=$REPO_OWNER_PTNFLY/patternfly-org
REPO_SLUG_PTNFLY_WC=$REPO_OWNER_PTNFLY_WC/patternfly-webcomponents
REPO_SLUG_RCUE=$REPO_OWNER_RCUE/rcue

# Repo URLs
REPO_URL_PTNFLY="github.com/$REPO_SLUG_PTNFLY.git"
REPO_URL_PTNFLY_ANGULAR="github.com/$REPO_SLUG_PTNFLY_ANGULAR.git"
REPO_URL_PTNFLY_ENG_RELEASE="github.com/$REPO_SLUG_PTNFLY_ENG_RELEASE.git"
REPO_URL_PTNFLY_NG="github.com/$REPO_SLUG_PTNFLY_NG.git"

# Common files
BOWER_JSON=bower.json
GEM_FILE=Gemfile
GRUNT_FILE_JS=Gruntfile.js
GRUNT_NGDOCS_TMPL=grunt-ngdocs-index.tmpl
GULP_FILE_JS=gulpfile.js
HOME_HTML=source/index.html
JSDOC_CONF_JSON=jsdocConfig.json
KARMA_CONF_JS=karma.conf.js
NSP=node_modules/nsp/bin/nsp
PACKAGE_JSON=package.json
PTNFLY_SETTINGS_JS=src/js/patternfly-settings-base.js
SHRINKWRAP_JSON=npm-shrinkwrap.json
