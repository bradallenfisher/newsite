#!/bin/bash

# Directories
##########################################################
httpDir="/var/www/html/"
rootDir="drupal/" #leave blank to set http directory as root directory.
libraries="sites/all/libraries/"
modules="sites/all/modules/"
files="sites/default/files/"
themes="sites/all/themes/"
##########################################################

# Site
##########################################################
siteName="SITENAME"
siteSlogan="SLOGAN"
##########################################################

# Database
##########################################################
dbHost="localhost"
dbName="drupal"
dbUser="drupal"
dbPassword=""
dbsu="root" # root user
dbsupw="" # using no
##########################################################


# Admin
##########################################################
AdminUsername="ADMIN"
AdminPassword="ADMINPASSWORD"
adminEmail="email@email.com"
##########################################################

# Paths
##########################################################
WGET_PATH="$(which wget)"
UNZIP="$(which unzip)"
TAR="$(which tar)"
##########################################################

# Download Core
##########################################################
cd $httpDir

echo "Starting Clean... deleting $httpDir$rootDir if it exists"
if [[ -d "$httpDir$rootDir" ]]
  then
  sudo rm $rootDir -rf
fi

drush dl -y --destination=$httpDir --drupal-project-rename=$rootDir

echo "cleaning up ...... removing text files"
cd $httpDir$rootDir

echo "$PWD"

# Install core
##########################################################
drush site-install -y standard --account-mail=$adminEmail --account-name=$AdminUsername --db-su=$dbsu --db-su-pw=$dbsupw --account-pass=$AdminPassword --site-name=$siteName --site-mail=$adminEmail --db-url=mysql://$dbUser:$dbPassword@$dbHost/$dbName
drush cleanup
echo "creating module directories"
mkdir $httpDir$rootDir$modules\contrib
mkdir $httpDir$rootDir$modules\custom
mkdir $httpDir$rootDir$modules\features

# Download modules and themes
##########################################################
drush -y dl omega
cd $httpDir$rootDir$theme
git clone https://github.com/bradallenfisher/kelly.git
cd kelly
rm .git -rf
drush en kelly -y
drush vset theme_default kelly -y

# Disable some core modules
##########################################################
drush -y dis color toolbar shortcut dashboard overlay help
cd $httpDir$rootDir

# Features
###########################################################################
###########################################################################

# Enable modules
###########################################################################
drush dl -y admin_menu context google_analytics
drush dl wysiwyg --dev
drush -y en features fontawesome imce_wysiwyg empty_front_page wysiwyg admin_menu admin_menu_toolbar context_ui field_group redirect googleanalytics libraries link metatag module_filter page_title pathauto globalredirect search404 token transliteration xmlsitemap entitycache

# Ckeditor
##############################
cd $httpDir$rootDir$libraries
wget http://download.cksource.com/CKEditor/CKEditor/CKEditor%204.6.0/ckeditor_4.6.0_full.zip
unzip ckeditor_4.6.0_full.zip

cd $httpDir$rootDir$modules
cd features
git clone https://github.com/bradallenfisher/kelly_wysiwyg.git
drush en kelly_wysiwyg -y


# Pre configure settings
###########################################################################
# Set Site Slogan
drush vset -y site_slogan "$siteSlogan"

# Disable user pictures
drush vset -y user_pictures 0

# Allow only admins to register users
drush vset -y user_register 0

# Remove require user email verification
drush vset -y user_email_verification 0

# Create file locations
cd $httpDir$rootDir
mkdir $files\private
mkdir $files\tmp
cd $httpDir$rootDir$files
sudo chown apache:apache tmp
sudo chmod 775 tmp

# Change file destinations
drush vset -y file_private_path "sites/default/files/private"
drush vset -y file_temporary_path "sites/default/files/tmp"

# Change ownership of new files locations.
sudo chown -R apache:apache $httpDir$rootDir$files
sudo chmod -R 775 $httpDir$rootDir$files

# Set the site name using the variable in top of script
drush vset -y site_name "$siteName"

###########################################################################

echo -e "////////////////////////////////////////////////////"
echo -e "Install Completed"
echo -e "////////////////////////////////////////////////////"

echo "$PWD"

drush -y pm-disable bartik
drush -y pm-uninstall color
drush -y pm-uninstall dashboard
drush -y pm-uninstall help
drush -y pm-uninstall overlay
drush -y pm-uninstall shortcut
drush -y pm-uninstall toolbar
drush -y pm-disable block
drush -y pm-uninstall block
drush -y pm-enable block


cd $httpDir$rootDir
echo "$PWD"
drush cc all
drush uli
