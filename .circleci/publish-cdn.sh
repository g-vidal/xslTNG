#!/bin/bash

if [[ -v CIRCLE_TAG ]]; then
    echo "Deploying CDN updates for $CIRCLE_TAG"
else
    echo "CDN updates are not published for untagged builds"
    exit
fi

if [ `git branch -r | grep "origin/gh-pages" | wc -l` = 0 ]; then
    echo "No gh-pages branch for publication"
    exit
fi

if [ `set | grep GIT_EMAIL | wc -l` = 0 -o `set | grep GIT_USER | wc -l` = 0 ]; then
    echo "No identity configured with GIT_USER/GIT_EMAIL"
    exit
fi

git config --global user.email $GIT_EMAIL
git config --global user.name $GIT_USER

# Remember the SHA of the current build.
SHA=$(git rev-parse --verify HEAD)

# Checkout and update cdn.docbook.org; note we need to explicitly
# specify the deployment key because it's a different repo.
IDRSA="/home/circleci/.ssh/id_rsa_7e53fb003499b878e63a06d77ddd01b3"

cd ../
mkdir cdn
cd cdn
git clone --depth 1 -c core.sshCommand="/usr/bin/ssh -i $IDRSA" git@github.com:docbook/cdn.git .

# We should never be republishing to the same tag, but just in case...
rm -rf release/xsltng/$CIRCLE_TAG
mkdir -p release/xsltng/$CIRCLE_TAG
rsync -ar ../repo/build/docbook-xslTNG-$CIRCLE_TAG/ release/xsltng/$CIRCLE_TAG/

# Make this the current release too
rm -rf release/xsltng/current
mkdir -p release/xsltng/current
rsync -ar ../repo/build/docbook-xslTNG-$CIRCLE_TAG/ release/xsltng/current/

# generate indexes
perl bin/make-indexes.pl release/xsltng

git add .
git commit -m "Deploy xsltng CDN for ${CIRCLE_PROJECT_USERNAME}: ${SHA}"
git push -q origin HEAD
