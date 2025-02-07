#!/bin/bash

# The MIT License (MIT)
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
# 
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

set -ex

{
    lamp_on_azure_configs_json_path=${1}
    number=$(ls /var/lib/waagent/custom-script/download/)
    cd /var/lib/waagent/custom-script/download/$number/
    . ./helper_functions.sh

    get_setup_params_from_configs_json $lamp_on_azure_configs_json_path || exit 99

    echo $glusterNode          >> /tmp/vars.txt
    echo $glusterVolume        >> /tmp/vars.txt
    echo $siteFQDN             >> /tmp/vars.txt
    echo $httpsTermination     >> /tmp/vars.txt
    echo $dbIP                 >> /tmp/vars.txt
    echo $adminpass            >> /tmp/vars.txt
    echo $dbadminlogin         >> /tmp/vars.txt
    echo $dbadminloginazure    >> /tmp/vars.txt
    echo $dbadminpass          >> /tmp/vars.txt
    echo $storageAccountName   >> /tmp/vars.txt
    echo $storageAccountKey    >> /tmp/vars.txt
    echo $redisDeploySwitch    >> /tmp/vars.txt
    echo $redisDns             >> /tmp/vars.txt
    echo $redisAuth            >> /tmp/vars.txt
    echo $dbServerType                >> /tmp/vars.txt
    echo $fileServerType              >> /tmp/vars.txt
    echo $mssqlDbServiceObjectiveName >> /tmp/vars.txt
    echo $mssqlDbEdition	>> /tmp/vars.txt
    echo $mssqlDbSize	>> /tmp/vars.txt
    echo $thumbprintSslCert >> /tmp/vars.txt
    echo $thumbprintCaCert >> /tmp/vars.txt
    echo $nfsByoIpExportPath >> /tmp/vars.txt
    echo $phpVersion >> /tmp/vars.txt
    echo $cmsApplication    >>/tmp/vars.txt
    echo $lbDns             >>/tmp/vars.txt
    echo $applicationDbName >>/tmp/vars.txt
    echo $wpAdminPass       >>/tmp/vars.txt
    echo $wpDbUserPass      >>/tmp/vars.txt
    echo $wpVersion         >>/tmp/vars.txt
    echo $sshUsername       >>/tmp/vars.txt
    echo $storageAccountType >>/tmp/vars.txt
    echo $fileServerDiskSize >>/tmp/vars.txt
    echo $frontDoorFQDN >> /tmp/vars.txt

    check_fileServerType_param $fileServerType
    wpPath=/azlamp/html/$siteFQDN
        cat > /home/$sshUsername/.profile << EOF
        # ~/.profile: executed by the command interpreter for login shells.
# This file is not read by bash(1), if ~/.bash_profile or ~/.bash_login
# exists.
# see /usr/share/doc/bash/examples/startup-files for examples.
# the files are located in the bash-doc package.
# the default umask is set in /etc/profile; for setting the umask
# for ssh logins, install and configure the libpam-umask package.
#umask 022
# if running bash
if [ -n "$BASH_VERSION" ]; then
    # include .bashrc if it exists
    if [ -f "\$HOME/.bashrc" ]; then
        . "\$HOME/.bashrc"
    fi
fi
# set PATH so it includes user's private bin if it exists
if [ -d "\$HOME/bin" ] ; then
    PATH="\$HOME/bin:\$PATH"
fi
# set PATH so it includes user's private bin if it exists
if [ -d "\$HOME/.local/bin" ] ; then
    PATH="\$HOME/.local/bin:\$PATH"
fi
echo "----------------------------------------------------------------------
 Welcome to the Wordpress Controller VM

Important Guidelines:

1) Please delete the primary Wordpress directory, identified as $wpPath.

2) Wordpress Plugins install: It is more effictant to use the command 'wp' to update or install a plugins and core Wordpress installation.

3) NOTE: It is important to execute the 'wp' command as the root user, AND you must include the flags --allow-root and --path=$wpPath. For example:
\$ sudo su
\$ wp plugin install akismet --activate --path=$wpPath --allow-root

4) NOTE: After the installation or updating of any plugins, execute the following command to ensure the correct ownership of the Wordpress directory by the web server:
sudo chown -R www-data:www-data /azlamp/

for the time been, You can use this command. [ \$ sudo bash /home/$sshUsername/install-new-wordpress.sh] 

5.1) to install a certificate for the website $siteFQDN you must add the certificate into the following folder [/azlamp/certs/$siteFQDN/] AND the certificate should be in the following name nginx.crt , nginx.kry
5.2) SSL/TLS Certificate Considerations: Instead of installing a certificate directly on this VM and replicating it to the VM Scale Set (VMSS), it is recommended to leverage the 'Azure Front Door' resource, which should be deployed in conjunction with this VM. Within the Azure Front Door resource:

. Navigate to the 'Front Door designer'.
. Add your Custom Domain.
. Ensure that the 'CUSTOM DOMAIN HTTPS' option is enabled.
. Adjust the Routing Rules to encompass your custom domain.
. Save your modifications to effectuate these changes.
----------------------------------------------------------------------
NOW run this command 'cat wordpress.txt' to get the credentials for the main wordpress installation, if that command fails then wait for 5 minutes and try again.
"
EOF
cat > /home/$sshUsername/install-new-wordpress.sh << EOF
OLDPWD=\$(pwd)
lamp_on_azure_configs_json_path=/var/lib/cloud/instance/lamp_on_azure_configs.json
number=\$(ls /var/lib/waagent/custom-script/download/)
cd /var/lib/waagent/custom-script/download/\$number/
. ./helper_functions.sh
get_setup_params_from_configs_json \$lamp_on_azure_configs_json_path || exit 99
function install_wordpress_application2 {
        local dnsSite=\$siteFQDN
        local wpTitle=LAMP-WordPress
        local wpAdminUser=admin
        local wpAdminPassword=\$wpAdminPass
        local wpAdminEmail=admin@\$dnsSite
	
        clear
        echo "-------------------------------------"
        read -p "Enter FQDN of the new website: " dnsSite
        local wpPath=/azlamp/html/\$dnsSite
        local wpDbUserId=admin
        local wpDbUserPass=\$wpDbUserPass
        local frontDoorFQDN=\$frontDoorFQDN
        local httpProtocol="http://"
        local wpHome="\$httpProtocol\$frontDoorFQDN"
        wpHome="\$httpProtocol\$dnsSite"
        read -p "Title/name of the new website: " wpTitle
        read -p "Email address of the admin of the new website: " wpAdminEmail
	char=_
        table_prefix=\$(cat /dev/urandom | tr -dc 'A-Z' | fold -w 4 | head -n 1)
	table_prefix=\$table_prefix\$char
        # Creates a Database for CMS application
        #create_database \$dbIP \$dbadminloginazure \$dbadminpass \$applicationDbName \$wpDbUserId \$wpDbUserPass
        # One off create for flexible server which doesn't use dbuser@host for connection, just uses dbuser instead 
        create_database \$dbIP \$dbadminlogin \$dbadminpass \$applicationDbName \$wpDbUserId \$wpDbUserPass 
        # Download the WordPress application compressed file
        download_wordpress \$dnsSite \$wpVersion
        # Links the data content folder to shared folder.. /azlamp/data
        linking_data_location \$dnsSite
        # Creates a wp-config file for WordPress
        #create_wpconfig \$dbIP \$applicationDbName \$dbadminloginazure \$dbadminpass \$dnsSite
        create_wpconfig \$dbIP \$applicationDbName \$dbadminlogin \$dbadminpass \$dnsSite  \$wpHome \$table_prefix
        # Installs WP-CLI tool
        install_wp_cli
        # Install WordPress by using wp-cli commands
        install_wordpress \$dnsSite \$wpTitle \$wpAdminUser \$wpAdminPassword \$wpAdminEmail \$wpPath
        # Install W3 Total Cache plug-in
        install_plugins \$wpPath
        # Generates the openSSL certificates
        generate_sslcerts \$dnsSite
        # Generate the text file
        #generate_text_file \$dnsSite \$wpAdminUser \$wpAdminPassword \$dbIP \$wpDbUserId \$wpDbUserPass \$sshUsername
        generate_text_file \$wpPath \$wpAdminUser \$wpAdminPassword \$dbIP \$wpDbUserId \$wpDbUserPass \$sshUsername
        update_script
    }
    install_wordpress_application2
    /usr/local/bin/update_last_modified_time.azlamp.sh
    sync
cd \$OLDPWD
EOF
    #Updating php sources
    check_apt_locks
    sudo add-apt-repository ppa:ondrej/php -y
    check_apt_locks
    sudo apt-get update -y
mkdir -p /etc/nginx/sites-enabled2/

  PhpVer=$(get_php_version)
  if [ "$PhpVer" = "" ]; then
    PhpVer=8.2
  fi
cat > /etc/nginx/sites-enabled2/default << EOF
upstream backend {
        server unix:/run/php/php${PhpVer}-fpm.sock fail_timeout=1s;
        server unix:/run/php/php${PhpVer}-fpm-backup.sock backup;
} 
EOF
    # make sure system does automatic updates and fail2ban
    export DEBIAN_FRONTEND=noninteractive
    check_apt_locks
    apt-get -y update
    # TODO: ENSURE THIS IS CONFIGURED CORRECTLY
    check_apt_locks
    apt-get -y install unattended-upgrades fail2ban

    config_fail2ban

    # create gluster, nfs or Azure Files mount point
    mkdir -p /azlamp

    if [ $fileServerType = "gluster" ]; then
        # configure gluster repository & install gluster client
        check_apt_locks
        add-apt-repository ppa:gluster/glusterfs-3.10 -y                 >> /tmp/apt1.log
    elif [ $fileServerType = "nfs" ]; then
        # configure NFS server and export
        setup_raid_disk_and_filesystem /azlamp /dev/md1 /dev/md1p1
        configure_nfs_server_and_export /azlamp
    fi
    check_apt_locks
    apt-get -y update                                                   >> /tmp/apt2.log
    check_apt_locks
    apt-get -y --force-yes install rsyslog git                          >> /tmp/apt3.log

    if [ $fileServerType = "gluster" ]; then
        check_apt_locks
        apt-get -y --force-yes install glusterfs-client                 >> /tmp/apt3.log
    elif [ "$fileServerType" = "azurefiles" ]; then
        # install azure cli & setup container
        AZ_REPO=$(lsb_release -cs)
        echo "deb [arch=amd64] https://packages.microsoft.com/repos/azure-cli/ $AZ_REPO main" |  tee /etc/apt/sources.list.d/azure-cli.list
        curl -L https://packages.microsoft.com/keys/microsoft.asc | sudo apt-key add - >> /tmp/apt3.log
        check_apt_locks
        sudo apt-get -y install apt-transport-https >> /tmp/apt3.log
        check_apt_locks
        sudo apt-get -y update > /dev/null
        check_apt_locks
        sudo apt-get -y install azure-cli >> /tmp/apt3.log
        check_apt_locks
        apt-get -y --force-yes install cifs-utils >> /tmp/apt3.log
    fi

    if [ $dbServerType = "mysql" ]; then
        check_apt_locks
        apt-get -y --force-yes install mysql-client >> /tmp/apt3.log
    elif [ "$dbServerType" = "postgres" ]; then
        #apt-get -y --force-yes install postgresql-client >> /tmp/apt3.log
        # Get a new version of Postgres to match Azure version (default Xenial postgresql-client version--previous line--is 9.5)
        # Note that this was done after create_db, but before pg_dump cron job setup (no idea why). If this change
        # causes any pgres install issue, consider reverting this ordering change...
        check_apt_locks
        add-apt-repository -y "deb http://apt.postgresql.org/pub/repos/apt/ xenial-pgdg main"
        wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | apt-key add -
        check_apt_locks
        apt-get update -y
        check_apt_locks
        apt-get install -y postgresql-client-9.6
    fi

    if [ $fileServerType = "gluster" ]; then
        # mount gluster files system
        echo -e '\n\rInstalling GlusterFS on '$glusterNode':/'$glusterVolume '/azlamp\n\r' 
        setup_and_mount_gluster_share $glusterNode $glusterVolume /azlamp
    elif [ $fileServerType = "nfs-ha" ]; then
        # mount NFS-HA export
        echo -e '\n\rMounting NFS export from '$nfsHaLbIP' on /azlamp\n\r'
        configure_nfs_client_and_mount $nfsHaLbIP $nfsHaExportPath /azlamp
    elif [ $fileServerType = "nfs-byo" ]; then
        # mount NFS-BYO export
        echo -e '\n\rMounting NFS export from '$nfsByoIpExportPath' on /azlamp\n\r'
        configure_nfs_client_and_mount0 $nfsByoIpExportPath /azlamp
    fi
    
    # install pre-requisites
    # apt-get install -y --fix-missing python-software-properties unzip
    check_apt_locks
    sudo add-apt-repository -y ppa:ubuntu-toolchain-r/ppa
    check_apt_locks
    sudo apt-get -y update > /dev/null 2>&1
    check_apt_locks
     sudo apt-get -y install software-properties-common
     check_apt_locks
    sudo apt-get -y install unzip


    # install the entire stack
    # passing php versions $phpVersion
    check_apt_locks
    apt-get -y --force-yes install nginx php$phpVersion-fpm php$phpVersion php$phpVersion-cli php$phpVersion-curl php$phpVersion-zip >> /tmp/apt5.log

    # LAMP requirements
    check_apt_locks
    apt-get -y update > /dev/null
    # passing php versions $phpVersion
    check_apt_locks
    apt-get install -y --force-yes php$phpVersion-common php$phpVersion-soap php7.4-json php$phpVersion-redis php$phpVersion-bcmath php$phpVersion-gd php$phpVersion-xmlrpc php$phpVersion-intl php$phpVersion-xml php$phpVersion-bz2 php-pear php$phpVersion-mbstring php$phpVersion-dev mcrypt >> /tmp/apt6.log
    PhpVer=$(get_php_version)
    if [ $dbServerType = "mysql" ]; then
        check_apt_locks
        apt-get install -y --force-yes php$phpVersion-mysql
    elif [ $dbServerType = "mssql" ]; then
        check_apt_locks
        apt-get install -y libapache2-mod-php$phpVersion  # Need this because install_php_mssql_driver tries to update apache2-mod-php settings always (which will fail without this)
        install_php_mssql_driver
    else
        check_apt_locks
        apt-get install -y --force-yes php$phpVersion-pgsql
    fi

    # Set up initial LAMP dirs
    mkdir -p /azlamp/html
    mkdir -p /azlamp/certs
    mkdir -p /azlamp/data

    # Build nginx config
    create_main_nginx_conf_on_controller $httpsTermination

    update_php_config_on_controller

    # Remove the default site
    rm -f /etc/nginx/sites-enabled/default

    # restart Nginx
    systemctl restart nginx

    # Master config for syslog
    config_syslog_on_controller
    systemctl restart rsyslog

    # Turning off services we don't need the controller running
    systemctl stop nginx
    systemctl stop php${PhpVer}-fpm

    if [ $fileServerType = "azurefiles" ]; then
        # Delayed copy of azlamp installation to the Azure Files share

        # First rename azlamp directory to something else
        mv /azlamp /azlamp_old_delete_me
        # Then create the azlamp share
        echo -e '\n\rCreating an Azure Files share for azlamp'
        create_azure_files_share azlamp $storageAccountName $storageAccountKey /tmp/wabs.log $fileServerDiskSize
        # Set up and mount Azure Files share. Must be done after nginx is installed because of www-data user/group
        echo -e '\n\rSetting up and mounting Azure Files share on //'$storageAccountName'.file.core.windows.net/azlamp on /azlamp\n\r'
        setup_and_mount_azure_files_share azlamp $storageAccountName $storageAccountKey
        # Move the local installation over to the Azure Files
        echo -e '\n\rMoving locally installed azlamp over to Azure Files'
        #cp -a /azlamp_old_delete_me/* /azlamp || true # Ignore case sensitive directory copy failure
        # install azcopy
      wget -q -O azcopy_v10.tar.gz https://aka.ms/downloadazcopy-v10-linux && tar -xf azcopy_v10.tar.gz --strip-components=1 && mv ./azcopy /usr/bin/

      ACCOUNT_KEY="$storageAccountKey"
      NAME="$storageAccountName"
      END=`date -u -d "60 minutes" '+%Y-%m-%dT%H:%M:00Z'`

      sas=$(az storage share generate-sas \
        -n azlamp \
        --account-key $ACCOUNT_KEY \
        --account-name $NAME \
        --https-only \
        --permissions lrw \
        --expiry $END -o tsv)

      export AZCOPY_CONCURRENCY_VALUE='48'
      export AZCOPY_BUFFER_GB='4'

      # cp -a /azlamp_old_delete_me/* /azlamp || true # Ignore case sensitive directory copy failure
      azcopy --log-level ERROR copy "/azlamp_old_delete_me/*" "https://$NAME.file.core.windows.net/azlamp?$sas" --recursive || true # Ignore case sensitive directory copy failure
      rm -rf /azlamp_old_delete_me || true # Keep the files just in case
    fi

    # chmod /azlamp for Azure NetApp Files (its default is 770!)
    if [ $fileServerType = "nfs-byo" ]; then
        chmod +rx /azlamp
    fi

    create_last_modified_time_update_script
    run_once_last_modified_time_update_script

    # Install scripts for LAMP
    mkdir -p /azlamp/bin
    cp helper_functions.sh /azlamp/bin/utils.sh
    chmod +x /azlamp/bin/utils.sh
    cat <<EOF > /azlamp/bin/update-vmss-config
#!/bin/bash

# Lookup the version number corresponding to the next process to be run on the machine
VERSION=1
VERSION_FILE=/root/vmss_config_version
[ -f \${VERSION_FILE} ] && VERSION=\$(<\${VERSION_FILE})

# iterate over processes that haven't yet been run on this machine, executing them one by one
while true
do
    case \$VERSION in
        # Uncomment the following block when adding/removing sites. Change the parameters if needed (default should work for most cases).
        # true (or anything else): htmlLocalCopySwitch, VMSS (or anything else): https termination
        # Add another block with the next version number for any further site addition/removal.

        #1)
        #    . /azlamp/bin/utils.sh
        #    reset_all_sites_on_vmss true VMSS
        #;;

        *)
            # nothing more to do so exit
            exit 0
        ;;
    esac

    # increment the version number and store it away to mark the successful end of the process
    VERSION=\$(( \$VERSION + 1 ))
    echo \$VERSION > \${VERSION_FILE}

done
EOF
    function install_wordpress_application {
        local dnsSite=$siteFQDN
        local wpTitle=LAMP-WordPress
        local wpAdminUser=admin
        local wpAdminPassword=$wpAdminPass
        local wpAdminEmail=admin@$dnsSite
        local wpPath=/azlamp/html/$dnsSite
        local wpDbUserId=admin
        local wpDbUserPass=$wpDbUserPass
        local frontDoorFQDN=$frontDoorFQDN
        local httpProtocol="http://"
        local wpHome="$httpProtocol$frontDoorFQDN"

        # Creates a Database for CMS application
        #create_database $dbIP $dbadminloginazure $dbadminpass $applicationDbName $wpDbUserId $wpDbUserPass
        # One off create for flexible server which doesn't use dbuser@host for connection, just uses dbuser instead 
        create_database $dbIP $dbadminlogin $dbadminpass $applicationDbName $wpDbUserId $wpDbUserPass 
        # Download the WordPress application compressed file
        download_wordpress $dnsSite $wpVersion
        # Links the data content folder to shared folder.. /azlamp/data
        linking_data_location $dnsSite
        # Creates a wp-config file for WordPress
        #create_wpconfig $dbIP $applicationDbName $dbadminloginazure $dbadminpass $dnsSite
        create_wpconfig $dbIP $applicationDbName $dbadminlogin $dbadminpass $dnsSite  $wpHome $table_prefix
        # Installs WP-CLI tool
        install_wp_cli
        # Install WordPress by using wp-cli commands
        install_wordpress $dnsSite $wpTitle $wpAdminUser $wpAdminPassword $wpAdminEmail $wpPath
        # Install W3 Total Cache plug-in
        install_plugins $wpPath
        # Generates the openSSL certificates
        generate_sslcerts $dnsSite
        # Generate the text file
        #generate_text_file $dnsSite $wpAdminUser $wpAdminPassword $dbIP $wpDbUserId $wpDbUserPass $sshUsername
        generate_text_file $wpPath $wpAdminUser $wpAdminPassword $dbIP $wpDbUserId $wpDbUserPass $sshUsername
    }

    if [ "$cmsApplication" = "WordPress" ]; then
        install_wordpress_application
    fi

  echo "### Script End `date`###"

} 2>&1 | tee /tmp/install.log
