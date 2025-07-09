#!/bin/sh
#
WORKING_DIRECTORY_FOLDER=/home/ebanking/scb-registry-service
GROUP_EXCUTE_SERVICE=ebanking
USER_EXCUTE_SERVICE=ebanking
USER_PASSWORD_EXCUTE_SERVICE=Admin@123

#
SERVICE_NAME_SYSTEMD=scb-registry-service
SERVICE_TITLE_SYSTEMD='registry-service'
#
RUNTIME_PATH_LOG=tmp
RUNTIME_FILE_PATH_LOG=$RUNTIME_PATH_LOG/$SERVICE_NAME_SYSTEMD.log




# redirect stdout/stderr to a file
# exec >./setup.log 2>&1
# ======================================================================================================================
echo # =================================================================================================================
if [ ! -d "$WORKING_DIRECTORY_FOLDER" ]; then
    echo $SERVICE_NAME_SYSTEMD create folder working space $WORKING_DIRECTORY_FOLDER
    mkdir -p $WORKING_DIRECTORY_FOLDER
fi

setfacl -R -d -m g::rwx -m o::rx $WORKING_DIRECTORY_FOLDER
chmod -R 2770 $WORKING_DIRECTORY_FOLDER

useradd -d $WORKING_DIRECTORY_FOLDER $USER_EXCUTE_SERVICE
echo "$USER_PASSWORD_EXCUTE_SERVICE" | passwd --stdin "$USER_EXCUTE_SERVICE"
echo; echo "User $USER_EXCUTE_SERVICE password changed!"


usermod -aG $GROUP_EXCUTE_SERVICE $USER_EXCUTE_SERVICE

chown $USER_EXCUTE_SERVICE:$GROUP_EXCUTE_SERVICE -R $WORKING_DIRECTORY_FOLDER
chmod 755 -R $WORKING_DIRECTORY_FOLDER

touch /usr/lib/systemd/system/$SERVICE_NAME_SYSTEMD.service
echo '# '$SERVICE_TITLE_SYSTEMD' location: /usr/lib/systemd/system/'$SERVICE_NAME_SYSTEMD'.service
[Unit]
Description='$SERVICE_TITLE_SYSTEMD'
After=network.target
# After=syslog.target network.target

[Service]
SuccessExitStatus=143
# allow bind to 80 and 443
AmbientCapabilities=CAP_NET_BIND_SERVICE

User='$USER_EXCUTE_SERVICE'
Group='$GROUP_EXCUTE_SERVICE'
#EnvironmentFile=./config/startup.conf
Environment=LOGFILE='$RUNTIME_FILE_PATH_LOG'
WorkingDirectory='$WORKING_DIRECTORY_FOLDER'
RuntimeDirectory='$WORKING_DIRECTORY_FOLDER/$RUNTIME_PATH_LOG'
RuntimeDirectoryMode=0750
PIDFile='$WORKING_DIRECTORY_FOLDER/$RUNTIME_PATH_LOG/$SERVICE_NAME_SYSTEMD.pid'

# more threads for this process
#TasksMax=65000
# allow more open files for this process
LimitNPROC=65000
LimitNOFILE=65000
#
#LimitNOFILE=infinity
#LimitNPROC=infinity
LimitCORE=infinity
LimitMEMLOCK=infinity
#
# filesystem access
# TemporaryFileSystem=/:ro
# PrivateTmp=true
#
# deprecated PermissionsStartOnly=true
# ExecStartPre=+/bin/mkdir '$RUNTIME_PATH_LOG'
ExecStart=/bin/bash -c "exec ./scripts/launch.sh < /dev/null >> ${LOGFILE} 2>&1"
ExecStartPost=/bin/bash -c "echo $MAINPID > '$RUNTIME_PATH_LOG/$SERVICE_NAME_SYSTEMD.pid'"

Restart=on-failure
#Restart=always
RestartPreventExitStatus=255
RestartSec=10s
StartLimitBurst=8
StartLimitInterval=600
#ExecStop=..graceful_shutdown.sh
#ExecReload=..reload.sh
Type=simple

[Install]
WantedBy=multi-user.target' > /usr/lib/systemd/system/$SERVICE_NAME_SYSTEMD.service

echo
echo "Created file service manager /usr/lib/systemd/system/$SERVICE_NAME_SYSTEMD.service"

systemctl enable $SERVICE_NAME_SYSTEMD.service
systemctl daemon-reload


if [ ! -d "$WORKING_DIRECTORY_FOLDER/tmp" ]; then
    echo $SERVICE_NAME_SYSTEMD create folder working runtime $WORKING_DIRECTORY_FOLDER/tmp
    mkdir -p $WORKING_DIRECTORY_FOLDER/$RUNTIME_PATH_LOG/
fi


echo Make sure existed file $WORKING_DIRECTORY_FOLDER/scripts/launch.sh copy-ed
chown $GROUP_EXCUTE_SERVICE:$USER_EXCUTE_SERVICE -R $WORKING_DIRECTORY_FOLDER
# chmod 750 $WORKING_DIRECTORY_FOLDER/scripts/launch.sh
chmod +x -R $WORKING_DIRECTORY_FOLDER/scripts



isInFile=$(grep '^'$SERVICE_NAME_SYSTEMD' ALL=(root) NOPASSWD: /bin/systemctl status '$SERVICE_NAME_SYSTEMD'' /etc/sudoers)
if [ -z "$isInFile" ]
then
	chmod 640 /etc/sudoers

	echo "Set permission start/stop/restart/status service systemctl";
	echo "
	$USER_EXCUTE_SERVICE ALL=(root) NOPASSWD: /bin/systemctl status $SERVICE_NAME_SYSTEMD
	$USER_EXCUTE_SERVICE ALL=(root) NOPASSWD: /bin/systemctl start $SERVICE_NAME_SYSTEMD
	$USER_EXCUTE_SERVICE ALL=(root) NOPASSWD: /bin/systemctl stop $SERVICE_NAME_SYSTEMD
	$USER_EXCUTE_SERVICE ALL=(root) NOPASSWD: /bin/systemctl restart $SERVICE_NAME_SYSTEMD" >> /etc/sudoers
fi

echo Starting serverice.............................
systemctl start $SERVICE_NAME_SYSTEMD

echo Check status bidc-cam-job-export or no
systemctl status $SERVICE_NAME_SYSTEMD
echo ===================================================================================================================
echo IF NOT START RUN:  sudo systemctl start $SERVICE_NAME_SYSTEMD
echo OR RESTART RUN:  sudo systemctl restart $SERVICE_NAME_SYSTEMD  /  sudo systemctl status $SERVICE_NAME_SYSTEMD
