#!/bin/bash
helpFunction()
{
   echo ""
   echo "Example Usage: $0 -action install -beats filebeat,metricbeat -url https://logstash-url.sade-edap.prv"
   echo -e "\t-action Determines what the script is doing. \n           Values: install, uninstall"
   echo -e "\t-beats Determines which beats the action is targeting. \n           Values: metricbeat,filebeat,auditbeat,packetbeat,heartbeat,functionbeat,journalbeat"
   echo -e "\t-url Set the logstash endpoint for the beat configuration files."
   exit 1 # Exit script after printing help
}

install ()
{
    echo "Installing the following beats: ${beats[*]}"  
    for beat in "${beats[@]}"
    do
    : 
        # Convert string to array
        IFS=',' read -r -a beats <<< "$beats"
        # Validate valid values
        for beat in "${beats[@]}"
        do
        : 
            case "$beat" in
            metricbeat|filebeat|packetbeat|auditbeat|heartbeat|journalbeat ) 
                echo "Installing $beat via yum" 
                filename=$beat".rpm"
                configFile=$beat".yml"
                #install package
                yum -y install ./packages/$filename
                #enable as system daemon
                systemctl enable $beat
                #Copy base yaml
                yes | cp -rf ../configs/$configFile /etc/$beat/$configFile
                #Modify token
                sed -i "s/%LOGSTASH_HOST%/$url/g" /etc/$beat/$configFile
                ;;
            functionbeat ) 
                # Functionbeat is a tar not an rpm
                # TODO: Requires AWS Credentials
                ;;
            * ) 
                echo "Unrecognized beat name: $beat"
                helpFunction
                exit 1 
                ;;
            esac
        done
    done
}

uninstall() 
{
    echo "Uninstalling the following beats: ${beats[*]}"  
    for beat in "${beats[@]}"
    do
    : 
        # Convert string to array
        IFS=',' read -r -a beats <<< "$beats"
        # Validate valid values
        for beat in "${beats[@]}"
        do
        : 
            case "$beat" in
            metricbeat|filebeat|packetbeat|auditbeat|heartbeat|journalbeat ) 
                echo "Uninstalling $beat via yum" 
                #Remove package
                yum -y remove $beat
                #disable as system daemon
                systemctl disable $beat
                ;;
            functionbeat ) 
                # Functionbeat is a tar not an rpm
                # TODO: Requires AWS Credentials
                ;;
            * ) 
                echo "Unrecognized beat name: $beat"
                helpFunction
                exit 1 
                ;;
            esac
        done
    done
    
}

while getopts "a:b:u:" opt
do
    case "$opt" in
        a ) action="$OPTARG" ;;
        b ) beats="$OPTARG" ;;
        u ) url="$OPTARG" ;;
        ? ) helpFunction ;; # Print helpFunction in case parameter is non-existent
    esac
done

# Print helpFunction in case parameters are empty
if [ -z "$action" ] || [ -z "$beats" ] || [ -z "$url" ]
then
   echo "Some or all of the parameters are empty";
   helpFunction
fi


if [ "$action" == "install" ]
then
    install 
fi
if [ "$action" == "uninstall" ]
then
    uninstall
fi
