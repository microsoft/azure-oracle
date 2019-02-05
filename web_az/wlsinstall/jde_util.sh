#!/bin/bash



remove_dir()
{
ssh -i $key -o "StrictHostKeyChecking no" -tt opc@$1 "sudo rm -rf $2" | tee -a $3
if [[ $? -ne 0 ]]
then
echo "ERROR!! Unable to delete directory" | tee -a $3
exit
fi

}

transfer_binaries()
{
ssh -i $key -o "StrictHostKeyChecking no" -tt opc@$1 "sudo mkdir -p $2;sudo chown -R opc:opc $2" | tee -a $5

if [[ $? -ne 0 ]]
then
echo "ERROR!! Unable to create REMOTE BINARY PATH" | tee -a $5
exit
fi

scp -i $key -o "StrictHostKeyChecking no" $3/$4 opc@$1:$2 | tee -a $5

if [[ $? -ne 0 ]]
then
echo "ERROR!! Unable to move JDE payload to REMOTE BINARY PATH" | tee -a $5
exit
fi

}



extract_zip()
{
ssh -i $key -o "StrictHostKeyChecking no" -tt opc@$1 "cd $2;unzip -o $3" | tee -a $4

if [[ $? -ne 0 ]]
then
echo "ERROR!! Unzip of artifact failed"
exit
fi

}

extract_tar()
{
cd $1;tar -zxf $2 -C $3 --strip-components=1 | tee -a $4

if [[ ${PIPESTATUS[0]} -ne 0 ]]
then
echo "ERROR!! Unzip of artifact failed" | tee -a $4
exit
fi

}

change_owner_oracle()
{
sudo chown -R oracle:oracle $1 | tee -a $2
if [[ ${PIPESTATUS[0]} -ne 0 ]]
then
echo "Failed to change oracle ownership of $1" | tee -a $2
exit
fi

}

change_file_permission()
{
sudo chmod -R 777 $1 | tee -a $2
if [[ ${PIPESTATUS[0]} -ne 0 ]]
then
echo "Error while changing permission" | tee -a $2
exit
fi
}

create_remote_directory()
{
sudo mkdir -p $1 | tee -a $2
if [[ ${PIPESTATUS[0]} -ne 0 ]]
then
echo "Error while creating directory $1" | tee -a $3
exit
fi
}


create_domain_nodemanager_wls()
{
ssh -i $key -o "StrictHostKeyChecking no" -tt opc@$1 "sudo su - oracle -c 'cd $2/oracle_common/common/bin;./commEnv.sh;./wlst.sh /u01/jde_tf/domain.py'" >> /tmp/create_domain.log | tee -a $3

if [[ $? -ne 0 ]]
then
echo "Domain Creation Failed.Check /tmp/create_domain.log on local machine and /tmp/wlst_createdomain.log on $1 for more details" | tee -a $3
exit
fi

ssh -i $key -o "StrictHostKeyChecking no" -tt opc@$1 "sudo su - oracle -c 'cd $2/oracle_common/common/bin;./commEnv.sh;./wlst.sh /u01/jde_tf/nodemgr.py'" >> /tmp/create_machine_domain.log | tee -a $3

if [[ $? -ne 0 ]]
then
echo "Machine Creation Failed.Check /tmp/create_machine_domain.log on local machine and /tmp/wlst_create_machine.log on $1 for more details" | tee -a $3
exit
fi


}


find_oracle_group()
{
oracle_grp=$(ssh -i $key -o "StrictHostKeyChecking no" -tt opc@$1 "sudo id -Gn oracle") | tee -a $2
if [[ $? -ne 0 ]]
then
echo "oracle user doesn't exist" | tee -a $2
exit
fi
echo "$oracle_grp"
}

install_smc()
{


inventory_loc=$(ssh -i $key -o "StrictHostKeyChecking no" -tt opc@$1 "grep "inventory_loc" /etc/oraInst.loc | sed "s/inventory_loc=//g"")
oracle_group=$(ssh -i $key -o "StrictHostKeyChecking no" -tt opc@$1 "grep "inst_group" /etc/oraInst.loc | sed "s/inst_group=//g"")


echo "Invemtory Location is : $inventory_loc"
echo "Oracle Group Name : $oracle_group"

var=$(echo "$inventory_loc" | sed -e 's/[\r\n]//g')

if [ $oracle_group == $3 ]
then
echo "Inventory group matches oracle user group"

else
echo "Error!!!!! Make sure Oracle inventory group is same as oracle user group"
exit
fi


ssh -i $key -o "StrictHostKeyChecking no" -tt opc@$1 "sudo su - oracle -c 'export TMP=/tmp;export TEMP=/tmp;$2/sminstall/Disk1/install/runInstaller -silent -waitforcompletion -responseFile $2/templates/SM_WLS.rsp'" >> /tmp/sm_install.log



if grep "The installation of JD Edwards Server Manager Management Console was successful" /tmp/sm_install.log
then
   echo "The installation of JD Edwards Server Manager Management Console was successful"
   ssh -i $key -o "StrictHostKeyChecking no" -tt opc@$1 "sudo $var/orainstRoot.sh"
else
   echo "The installation of JD Edwards Server Manager Management Console was unsuccessful"
   exit
fi

}


