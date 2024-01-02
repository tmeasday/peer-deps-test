#!/bin/bash
bold=$(tput bold)
normal=$(tput sgr0)

header () {
  echo
  echo
  echo "${bold}## ${1} ##${normal}"
}

TMPDIR=$(mktemp -d)
cd $TMPDIR

if [ "${CMD}" = "yarn" ]; then
  ADD="add --dev"
  VERSION=${VERSION:-4.0.2}
elif [ "${CMD}" = "pnpm" ]; then
  ADD="add -D"
  VERSION=${VERSION:-8.12.1}
elif [ "${CMD}" = "npm" ]; then
  ADD="add -D"
  VERSION=${VERSION:-10.2.3}
fi

if [ "${WS}" = "1" ]; then
  echo '{ "name": "test-project", "private": true, "workspaces": ["package"] }' > package.json
  echo 'packages:' > pnpm-workspace.yaml
  echo "  - 'package'" >> pnpm-workspace.yaml
else
  echo '{ "name": "test-package", "scripts": { "start": "node index.js" } }' > package.json
fi

header "Setup package manager"

echo 'hoist=false' > .npmrc

if [ "${CMD}" = "yarn" ]; then
  yarn set version $VERSION
else
  echo corepack use "${CMD}@${VERSION}"
  corepack use "${CMD}@${VERSION}"
fi

if [ "x${NO_PNP}" == "x1" ]; then
  yarn config set nodeLinker node-modules
fi


if [ "${WS}" = "1" ]; then
  mkdir package
  cd package
  echo '{ "name": "test-package", "version": "1.0.0", "scripts": { "start": "node index.js" } }' > package.json
  $CMD install
fi

header "Package manager version"
$CMD --version

if [ x$DEP1 != "x" ]; then
  header "Install ${DEP1}"
  $CMD $ADD tmeasday-test-package-${DEP1}
fi

if [ x$DEP2 != "x" ]; then
  header "Install ${DEP2}"
  $CMD $ADD tmeasday-test-package-${DEP2}
fi

header "Install ${PKG}"
$CMD $ADD tmeasday-test-package-$PKG

echo "require('tmeasday-test-package-${PKG}'); console.log('Done!');" > index.js

header "No use a"
$CMD run start

header "Use a"
USE_A=1 $CMD run start