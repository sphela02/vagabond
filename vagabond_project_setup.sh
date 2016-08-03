#!/bin/bash

export whoami=`/usr/bin/whoami`

echo dbg ... whoami = $whoami

# Setup github repos
if [ ! -d "$HOME/github/hc" ]; then
    cd $HOME/github
    git clone git@github.com:$whoami/hc.git -b develop
    cd $HOME/github/hc
    git remote add upstream git@github.com:harris-corp-it/hc.git
fi

# Setup vagrant to load
chmod -R 777 $HOME/github/hc/box
cd $HOME/github/hc/box
#dbg ... Tweak Vagrantfile to make it distinct, or use the local override file to do it
vagrant up

vagrant ssh -c "cd /var/www/harris/ ; composer install"
echo $LINENO ... RC = $?

vagrant ssh -c "cd /var/www/harris/ ; ./task.sh setup:git-hooks"

vagrant ssh -c "cd /var/www/harris/sites/all/themes/custom/harris ; ./install-node.sh 0.12.9"

vagrant ssh -c 'export NVM_DIR=/home/vagrant/.nvm; . $NVM_DIR/nvm.sh ; cd /var/www/harris/sites/all/themes/custom/harris ; nvm use --delete-prefix 0.12.9 ; npm install -g gulp ; npm install -g browser-sync'

vagrant ssh -c 'export NVM_DIR=/home/vagrant/.nvm; . $NVM_DIR/nvm.sh ; cd /var/www/harris ; ./task.sh frontend:build'

# DBG ... Hack the local.yml here if you're messing the drupal DB settings

vagrant ssh -c 'export NVM_DIR=/home/vagrant/.nvm; . $NVM_DIR/nvm.sh ; cd /var/www/harris ; ./task.sh setup:build:all'

vagrant ssh -c 'export NVM_DIR=/home/vagrant/.nvm; . $NVM_DIR/nvm.sh ; cd /var/www/harris ; ./task.sh setup:drupal:settings'

cp $HOME/.ssh/id_rsa* $HOME/github/hc/box/

vagrant ssh -c 'mv /vagrant/id_rsa* ~/.ssh/ ; chmod 600 ~/.ssh/id_rsa*'

# dbg - not working?? Maybe the drupaldb hack made trouble
vagrant ssh -c 'export NVM_DIR=/home/vagrant/.nvm; . $NVM_DIR/nvm.sh ; cd /var/www/harris/docroot ; drush sql-sync -y --create-db @harris.dev @harris.loc'


exit; #dbg


# Frontend build

echo $LINENO ... RC = $?

# dbg ... change local.yml later to use different db userid and host?
# dbg perl -pi.orig -e 's/DATE/localtime/e'

echo $LINENO ... RC = $?

echo $LINENO ... RC = $?

cd /var/www/harris/docroot
drush sql-sync --create-db @harris.dev @harris.loc
echo $LINENO ... RC = $?

drush cc all
echo $LINENO ... RC = $?

ENDSSH
