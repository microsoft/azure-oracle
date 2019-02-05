#!/bin/bash


export JDK_INSTALL_BINARY_NAME=$1
export WLS_INSTALL_BINARY_NAME=$2
export PSWD=$3
export MOUNT_FS=$4
export TEMPLATE=$MOUNT_FS/jde_tf/wlsinstall/templates
export LOGFILE=/tmp/wlsprovisioning.log


. $MOUNT_FS/jde_tf/wlsinstall/jde_util.sh




#Edit response files
WLS_INSTALL_PATH="$MOUNT_FS/app/oracle/Middleware"
var=$(echo "$WLS_INSTALL_PATH" | sed 's/\//\\\//g')
cp $TEMPLATE/domain_orig.py $TEMPLATE/domain.py
cp $TEMPLATE/nodemgr_orig.py $TEMPLATE/nodemgr.py
sed -i "s/wlshome/$var/g" $TEMPLATE/domain.py

### Trim leading whitespaces ###
WLS_ADMIN_PSWD="${PSWD##*( )}"
### trim trailing whitespaces  ##
WLS_ADMIN_PSWD="${PSWD%%*( )}"
export WLS_ADMIN_PSWD

sed -i "s/wlspwd/$WLS_ADMIN_PSWD/g" $TEMPLATE/domain.py
sed -i "s/wlshome/$var/g" $TEMPLATE/nodemgr.py
sed -i "s/wlspwd/$WLS_ADMIN_PSWD/g" $TEMPLATE/nodemgr.py




#Removing previous existence of domain.py and nodemanager.py
sudo rm -rf ../webtier/templates/domain.py
sudo rm -rf ../webtier/templates/nodemgr.py  
sudo rm -rf $LOGFILE 
sudo rm -rf $MOUNT_FS/jde_tf/jdk
sudo rm -rf $MOUNT_FS/app


echo "--Creating Remote directory--" | tee -a $LOGFILE
create_remote_directory $MOUNT_FS/app $LOGFILE


echo "------------------Unzip JDK Installer-----------------------" | tee -a $LOGFILE
 create_remote_directory $MOUNT_FS/jde_tf/jdk $LOGFILE
 change_file_permission $MOUNT_FS/jde_tf/jdk $LOGFILE
 extract_tar $MOUNT_FS/jde_tf/wlsbinary $JDK_INSTALL_BINARY_NAME $MOUNT_FS/jde_tf/jdk $LOGFILE
 sudo chown -R oracle:oracle $MOUNT_FS/jde_tf/jdk
    
echo "------------------------Installing Weblogic Server-------------------------------" | tee -a $LOGFILE
  create_remote_directory $MOUNT_FS/app/oraInventory $LOGFILE
  change_owner_oracle $MOUNT_FS/app $LOGFILE
  sudo su -c "rm -rf /etc/oraInst.loc" | tee -a $LOGFILE
  echo "Status is  ${PIPESTATUS[0]}"
  if [[ ${PIPESTATUS[0]} -eq 0 ]] 
  then
  	sudo su -c "echo \"inventory_loc=$MOUNT_FS/app/oraInventory\" >> /etc/oraInst.loc" | tee -a $LOGFILE
	sudo su -c "echo \"inst_group=oracle\" >> /etc/oraInst.loc" | tee -a $LOGFILE
  fi

   sudo su - oracle -c "$MOUNT_FS/jde_tf/jdk/bin/java -jar $MOUNT_FS/jde_tf/wlsbinary/$WLS_INSTALL_BINARY_NAME -silent -responseFile $TEMPLATE/wls.rsp" | tee -a $LOGFILE
   if [[ ${PIPESTATUS[0]} -ne 0 ]]
   then
	echo "ERROR!!!!!!Weblogic  Installation failed. Check $LOGFILE" | tee -a $LOGFILE
	exit
   fi
    

##Creating Domain and Machine

echo "-----------------------Creating Domain and Machines-------------------------------------------------------------------"
sudo su - oracle -c "cd $WLS_INSTALL_PATH/oracle_common/common/bin;./commEnv.sh;./wlst.sh $TEMPLATE/domain.py" | tee -a $LOGFILE
if [[ ${PIPESTATUS[0]} -ne 0 ]]
then
    echo "Domain Creation Failed.Check $LOGFILE  for more details"
    exit
fi

sudo sed -i "s/.*SecureListener.*/SecureListener=false/" $WLS_INSTALL_PATH/user_projects/domains/jdee1/nodemanager/nodemanager.properties | tee -a $LOGFILE
sudo su - oracle -c "cd $WLS_INSTALL_PATH/oracle_common/common/bin;./commEnv.sh;./wlst.sh $TEMPLATE/nodemgr.py" | tee -a $LOGFILE
if [[ ${PIPESTATUS[0]} -ne 0 ]]
then
    echo "Machine Creation Failed.Check $LOGFILE for more details" | tee -a $LOGFILE
    exit
fi


exit 
