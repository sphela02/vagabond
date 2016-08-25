#!/bin/bash

export gitHubUser=sphela02
export projectInstanceNumber=8 #dbg

########################################
if [ "$gitHubUser" == "" ]; then
    export whoami=`/usr/bin/whoami`
    export gitHubUser=$whoami
fi

echo dbg ... gitHubUser = $gitHubUser

export gitHubBaseDir=$HOME/github

if [ $projectInstanceNumber -gt 0 ]; then
   export projectDir=$gitHubBaseDir/hc$projectInstanceNumber.dev

   # Setup IP address to use for VM
   tmpNum=`expr 87 + $projectInstanceNumber` 
   vmInstanceIPAddress=192.168.88.$tmpNum

else
   export projectDir=$gitHubBaseDir/hc.dev

   # Setup IP address to use for VM
   vmInstanceIPAddress=192.168.88.88

fi

echo DBG vmInstanceIPAddress = $vmInstanceIPAddress

# Setup github repos
if [ ! -d "$projectDir" ]; then
    git clone git@github.com:$gitHubUser/hc.git $projectDir -b develop

    cd $projectDir
    git remote add upstream git@github.com:harris-corp-it/hc.git

# DBG .. For now, exit after git repo setup, to allow for VM config tooling before launching the vagrant process
exit #dbg
fi

# Setup vagrant overrides for specific machine instance
if [ $projectInstanceNumber -gt 0 -a ! -e "$projectDir/box/local.config.yml" ]; then
    > $projectDir/box/local.config.yml cat <<EOF
vagrant_hostname: hc$projectInstanceNumber.dev
vagrant_machine_name: drupalvm$projectInstanceNumber
vagrant_ip: 192.168.88.$vmInstanceIPAddress

drupal_domain: "hc$projectInstanceNumber.dev"
EOF
fi

# exit #dbg

# Setup vagrant to load
chmod -R 777 $projectDir/box
cd $projectDir/box
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

cp $HOME/.ssh/id_rsa* $projectDir/box/

vagrant ssh -c 'mv /vagrant/id_rsa* ~/.ssh/ ; chmod 600 ~/.ssh/id_rsa*'

# dbg - not working?? Maybe the drupaldb hack made trouble
vagrant ssh -c 'export NVM_DIR=/home/vagrant/.nvm; . $NVM_DIR/nvm.sh ; cd /var/www/harris/docroot ; drush sql-sync -y --create-db @harris.dev @harris.loc'

echo $LINENO ... RC = $?

# Setup aliases
grep vagrant ~/.aliases.bash > $projectDir/box/.aliases
vagrant ssh -c 'mv /vagrant/.aliases ~/ ; echo "source ~/.aliases" >> ~/.bashrc '

vagrant ssh -c 'rsync --archive -e ssh harris.dev@staging-15049.prod.hosting.acquia.com:/mnt/gfs/harris.dev/sites/default/files /var/www/harris/sites/default/' 

exit; #dbg


# Frontend build

# dbg ... change local.yml later to use different db userid and host?
# dbg perl -pi.orig -e 's/DATE/localtime/e'


echo $LINENO ... RC = $?

cd /var/www/harris/docroot
drush sql-sync --create-db @harris.dev @harris.loc
echo $LINENO ... RC = $?

drush cc all
echo $LINENO ... RC = $?

ENDSSH
