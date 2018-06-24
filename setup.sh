#!/bin/bash
# Demo Red Hat Single Sign On
# @author Rodrigo Ramalho - rramalho@redhat.com
#                           github.com/hodrigohamalho
# This script shouldn't be updated
# all settings is on setup.env.sh file
# Install EAP 7 and SSO.
# Install EAP 7 SSO adapters: SAML and OpenID

. setup-env.sh

function validateRequirements(){
	command -v mvn -q >/dev/null 2>&1 || { echo >&2 "Maven is required but not installed or not present in thet system PATH yet... aborting."; exit 1; }
	command -v git --version >/dev/null 2>&1 || { echo >&2 "Git is required but not installed or not present in thet system PATH yet... aborting."; exit 1; }

	# make some checks first before proceeding.
	if [ -r $EAP_INSTALLER ] || [ -L $EAP_INSTALLER ]; then
		printf "\n JBoss EAP installer is present..."
	else
		printf "\n Need to download Fuse package from the Customer Portal"
		printf "\n\t and place it in the $BINARIES_DIR directory to proceed... \n"
		exit
	fi

	if [ -r $SSO_INSTALLER ] || [ -L $SSO_INSTALLER ]; then
			printf "\n JBoss SSO installer is present... \n"
	else
			printf "\n Need to download JDV installer from the Customer Portal"
			printf "\n\t and place it in the $BINARIES_DIR directory to proceed... \n"
			exit
	fi
}

function installEAP(){
	echo
	echo " Installing EAP, please wait..."

	unzip -q $EAP_INSTALLER -d $TARGET_DIR
	rm $EAP_HOME/bin/*.bat

	if [ $? -ne 0 ]; then
		printf "\n Error occurred during JBoss EAP installation!"
		exit
	fi

	printf "\n Installing RH SSO EAP 7 Adapter"
	unzip -oq $EAP_SSO_ADAPTER -d $EAP_HOME
	printf "\n Installing RH SSO EAP 7 SAML Adapter \n\n"
	unzip -oq $EAP_SSO_SAML_ADAPTER -d $EAP_HOME

	printf "\n Starting EAP to install modules \n\n"
	$EAP_HOME/bin/standalone.sh > /dev/null &
	sleep JBOSS_STARTUP_TIME
	
	$EAP_HOME/bin/jboss-cli.sh -c --file=$EAP_HOME/bin/adapter-install.cli > /dev/null
	$EAP_HOME/bin/jboss-cli.sh -c --file=$EAP_HOME/bin/adapter-install-saml.cli > /dev/null
	
	EAP_PROC_ID=$(ps -ef | awk '/jbos[s]/ {print $2}')
	kill -9 $EAP_PROC_ID
}

function installSSO(){
	echo
	echo "Installing SSO, please wait..."

	unzip -q $SSO_INSTALLER -d $TARGET_DIR
	rm $SSO_HOME/bin/*.bat
	$SSO_HOME/bin/add-user-keycloak.sh -u admin -p redhat@123

	if [ $? -ne 0 ]; then
		printf "\n Error occurred during JBoss SSO installation!"
		exit
	fi
}

function usersInfo(){
	echo "############### CREDENTIALS ##################"
	echo "USER: admin"
	echo "PASSWORD: redhat@123"
	echo "##############################################"
}

function start(){
	echo "Starting EAP default port"
	$EAP_HOME/bin/standalone.sh > /dev/null &
	echo "Starting SSO port-offset 100"
	$SSO_HOME/bin/standalone.sh -Djboss.socket.binding.port-offset=100 > /dev/null &
}

case "$1" in
        install)
			validateRequirements
			rm -rf $TARGET_DIR/*
			installEAP
			installSSO
            ;;

        uninstall)
            uninstall
            ;;

		start)
			start
			;; 

        credentials)
            usersInfo
            ;;

        *)
			echo $"Usage: $0  install | uninstall | start | credentials"
            exit 1

esac

