#!/bin/bash

export gitHubUser=sphela02
export projectInstanceNumber=5 #dbg

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
    git remote add cloris   git@github.com:cloris-harris/hc.git
    git remote add jculve01  git@github.com:jculve01/hc.git
    git remote add kramming git@github.com:kramming/hc.git
    git remote add sphela02  git@github.com:sphela02/hc.git

# DBG .. For now, exit after git repo setup, to allow for VM config tooling before launching the vagrant process
exit #dbg
fi

# Setup vagrant overrides for specific machine instance
if [ $projectInstanceNumber -gt 0 -a ! -e "$projectDir/box/local.config.yml" ]; then
    > $projectDir/box/local.config.yml cat <<EOF
vagrant_hostname: hc$projectInstanceNumber.dev
vagrant_machine_name: drupalvm$projectInstanceNumber
vagrant_ip: $vmInstanceIPAddress

drupal_domain: "hc$projectInstanceNumber.dev"
EOF
echo COMPLETED - box/local.config.yml updated for this machine
exit #dbg
fi

# exit #dbg

# Setup vagrant to load
chmod -R 777 $projectDir/box
cd $projectDir/box
#dbg ... Tweak Vagrantfile to make it distinct, or use the local override file to do it
vagrant up

echo VAGRANT BOX NOW UP ... CONFIGURATION NEXT

# Set up SSH Keys for later
cp $HOME/.ssh/id_rsa* $projectDir/box/
vagrant ssh -c 'mv /vagrant/id_rsa* ~/.ssh/ ; chmod 600 ~/.ssh/id_rsa*'

# Start configuring the box internally
vagrant ssh -c "/vagrant/configure_vm.sh"

#You should now see a local.yml in the root directory. Update the values in local.yml with local database credentials:
#
# local_url: 'http://hc.dev'
#    db:
#      username: drupal
#      name: drupal
#      host: localhost
#      port: 3306
#      password: drupal

exit

# DBG ... Hack the local.yml here if you're messing the drupal DB settings

#If so try this:
#
#cd /home/vagrant/.drush/cache/download/
#
#cp https---storage.googleapis.com-google-code-archive-downloads-v2-code.google.com-jsonpath-jsonpath-0.8.1.php https---jsonpath.googlecode.com-files-jsonpath-0.8.1.php
# OR ... just download it from here to the cache?
#  https://storage.googleapis.com/google-code-archive-downloads/v2/code.google.com/jsonpath/jsonpath-0.8.1.php

vagrant ssh -c 'echo DBG: 82; ls -l /var/www/harris/docroot/sites/default/files/js/'

vagrant ssh -c 'export NVM_DIR=/home/vagrant/.nvm; . $NVM_DIR/nvm.sh ; cd /var/www/harris ; ./task.sh setup:drupal:settings'

vagrant ssh -c 'echo DBG: 86; ls -l /var/www/harris/docroot/sites/default/files/js/'

# Open up permissions on the JS files directory.
vagrant ssh -c 'chmod -R 777 /var/www/harris/docroot/sites/default/files/js/'

cp $HOME/.ssh/id_rsa* $projectDir/box/

vagrant ssh -c 'mv /vagrant/id_rsa* ~/.ssh/ ; chmod 600 ~/.ssh/id_rsa*'

# dbg - not working?? Maybe the drupaldb hack made trouble
vagrant ssh -c 'export NVM_DIR=/home/vagrant/.nvm; . $NVM_DIR/nvm.sh ; cd /var/www/harris/docroot ; drush sql-sync -y --create-db @harris.dev @harris.loc'

echo DBG $LINENO ... RC = $?

# Setup aliases
echo DBG ... hardcoded vagabond directory at line 102, we should use \$0 to derive this
grep vagrant ~/github/vagabond/aliases.vagrant.bash > $projectDir/box/.aliases
vagrant ssh -c 'mv /vagrant/.aliases ~/ ; echo "source ~/.aliases" >> ~/.bashrc '

#If your local site appears unstyled or if the css and javascript are not working, you may need to create a files directory. The files directory is used to serve css, javascript, and uploaded image files but has been ommited from the repository in /var/www/harris/.gitignore
#
## Ignore paths that contain user-generated content.
#sites/*/files
#sites/*/private
#
#To create the files directory and attach the css and javascript to the site:
#
#    change to the project root directory cd /var/www/harris/
#    create a files directory mkdir sites/default/files/
#    change to the harris directory cd sites/all/themes/custom/harris/
#    run gulp
#    return to the docroot directory cd ../../../../../docroot/
#    and clear the cache drush cc all
#    refresh the site

vagrant ssh -c 'rsync --archive -v -e ssh harris.dev@staging-15049.prod.hosting.acquia.com:/mnt/gfs/harris.dev/sites/default/files /var/www/harris/sites/default/'
echo DBG ... RSYNC-RC $?

vagrant ssh -c 'echo DBG: 107; ls -l /var/www/harris/docroot/sites/default/files/js/'

# Open up permissions on the JS files directory.
vagrant ssh -c 'chmod 777 /var/www/harris/docroot/sites/default/files/js/'

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
