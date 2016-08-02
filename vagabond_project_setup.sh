#!/bin/sh

export whoami=`/usr/bin/whoami`

echo dbg ... whoami = $whoami

# Setup github repos
if [ ! -d "~/github/hc" ]; then
    cd ~/github
    git clone git@github.com:$whoami/hc.git -b develop
    cd ~/github/hc
    git remote add upstream git@github.com:harris-corp-it/hc.git
fi

# Setup vagrant to load
chmod -R 777 ~/github/hc/box
cd ~/github/hc/box
vagrant up

vagrant ssh <<END_SSH
cd /var/www/harris
compser install
echo COMPOSER INSTALL ... RC = $?

./task.sh setup:git-hooks
echo SETUP_HOOKS ... RC = $?

# Install Node
cd /var/www/harris/sites/all/themes/custom/harris
./install-node.sh 0.12.9
source ~/.bashrc
nvm use --delete-prefix 0.12.9

#Install gulp and globals
npm install -g gulp
npm install -g browser-sync

# Frontend build
cd /var/www/harris
./task.sh frontend:build
echo $LINENO ... RC = $?

# dbg ... change local.yml later to use different db userid and host?

./task.sh setup:build:all
echo $LINENO ... RC = $?

./task.sh setup:drupal:settings
echo $LINENO ... RC = $?

cd /var/www/harris/docroot
drush sql-sync --create-db @harris.dev @harris.loc
echo $LINENO ... RC = $?

drush cc all
echo $LINENO ... RC = $?

END_SSH


