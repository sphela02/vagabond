cd /var/www/harris ; ./task.sh setup:build:make ; cd /var/www/harris/docroot/ ; drush sql-sync --create-db @harris.dev @harris.loc -y ; drush updb -y ; drush vset preprocess_css 0 ; drush vset preprocess_js 0 ; drush vset cache 0 ; cd /var/www/harris/sites/all/themes/custom/harris ; gulp ; cd - ; drush uli
cd /var/www/harris ; ./task.sh setup:build:make
cd /var/www/harris/docroot/ ; drush sql-sync --create-db @harris.dev @harris.loc -y 
cd /var/www/harris/sites/all/themes/custom/harris ; gulp ; cd -
