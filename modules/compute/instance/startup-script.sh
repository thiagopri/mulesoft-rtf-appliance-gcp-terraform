#!/bin/bash
set -eo pipefail

# Constants
SCRIPT_VERSION='20211210_01'
REDIRECT_LOG=/var/log/rtf-startupscript.log
CURL_WITH_PROXY="curl  --noproxy"
CURL_OPTS="-L -k -sS --fail --connect-timeout 10 --retry 5 --retry-delay 15"
CURRENT_STEP=init
#Anypoint connectedApp cliente_id
CONNECTED_APP_CLIENT_ID=""
#Anypoint connectedApp cliente_secret
CONNECTED_APP_CLIENT_SECRET=""
#OrgId or BGID where the RTF cluster will be registered
ORGANIZATION_ID=""
RTF_NAME="${rtf_name}"
RTF_VERSION="${rtf_version}"
RTF_APPLIANCE_VERSION="${rtf_appliance_version}"
RTF_ACTIVATION_DATA="${rtf_activation_data}"
RTF_AWS_S3_URL="https://runtime-fabric.s3.amazonaws.com/installer"
OAUTH_ACCESS_TOKEN=""
RTF_RESPONSE_JSON_FILE=rtf-response.json
LINE="\n================================================"

# ADDITIONAL_ENV_VARS_PLACEHOLDER_DO_NOT_REMOVE

function on_exit {
  local trap_code=$?
  if [ $trap_code -ne 0 ] ; then
    local ANCHOR=$(echo $CURRENT_STEP | tr "_" "-")
    echo
    echo "***********************************************************"
    echo "** Your installation has stopped due to an error. *********"
    echo "***********************************************************"
    echo
    echo "Additional information: Error code: $trap_code; Step: $CURRENT_STEP; Line: $TRAP_LINE;"
    echo

  fi
}

function on_error {
    TRAP_LINE=$1
}

trap 'on_error $LINENO' ERR
trap on_exit EXIT

function run_step() {
    CURRENT_STEP=$1
    local DESCRIPTION=$2
    (( CURRENT_STEP_NBR++ )) || true
    echo
    echo -e "$CURRENT_STEP_NBR / $STEP_COUNT: $DESCRIPTION$LINE"
    echo -e "Started - $(date)"
    eval $CURRENT_STEP
    echo -e "Done    - $(date).\n"
}

function install_required_packages() {
    CURRENT_STEP=$FUNCNAME
    echo "Installing Required Packages ..."

    if command -v apt >/dev/null; then
        sudo apt update
        sudo apt install jq zip unzip -y
    elif command -v apt-get >/dev/null; then
        sudo apt-get update
        sudo apt-get install jq zip unzip -y
    elif command -v yum >/dev/null; then
        sudo yum install jq zip unzip -y
    else
        echo "Could not identify the OS Distribution. Exiting ..."
        exit 1
    fi
    
}

function fetch_runtime_access_token() {
    CURRENT_STEP=$FUNCNAME
    echo "Fetching Runtime Acess Token..."

    OAUTH_ENDPOINT="https://anypoint.mulesoft.com/accounts/api/v2/oauth2/token"
    OAUTH_CREDENTIALS_FILE=oauth-credentials.json
    
    COUNT=0
    while :
    do
        CODE=$($CURL_WITH_PROXY $CURL_OPTS -w "%%{http_code}" --request POST $OAUTH_ENDPOINT -H "Content-Type: application/x-www-form-urlencoded" --data-urlencode "client_id=$CONNECTED_APP_CLIENT_ID" --data-urlencode "client_secret=$CONNECTED_APP_CLIENT_SECRET" --data-urlencode "grant_type=client_credentials" -o $OAUTH_CREDENTIALS_FILE || true)
        if [ "$CODE" == "200" ]; then
            OAUTH_ACCESS_TOKEN=$(cat $OAUTH_CREDENTIALS_FILE | jq -r .access_token)
            break
        fi
        let COUNT=COUNT+1
        if [ $COUNT -ge 3 ]; then
            echo "Error: Failed to fetch $COUNT times, giving up."
            exit 1
        fi
        echo "Retrying in 3 seconds..."
        sleep 3
    done
 
    echo "Exiting. Access Token = $OAUTH_ACCESS_TOKEN"
    rm $OAUTH_CREDENTIALS_FILE
}

function verify_rtf_name_is_available() {
    CURRENT_STEP=$FUNCNAME
    echo "Fetching Existing RTF information..."

    RTF_ENDPOINT="https://anypoint.mulesoft.com/runtimefabric/api/organizations/$ORGANIZATION_ID/fabrics"
    
    
    COUNT=0
    while :
    do

        CODE=$($CURL_WITH_PROXY $CURL_OPTS -w "%%{http_code}" --request GET $RTF_ENDPOINT -H "Content-Type: application/json" -H "Authorization: Bearer $OAUTH_ACCESS_TOKEN" -o $RTF_RESPONSE_JSON_FILE || true)
        echo "Returned code: $CODE"
        if [ "$CODE" == "200" ]; then
            break
        fi
        let COUNT=COUNT+1
        if [ $COUNT -ge 3 ]; then
            echo "Error: Failed to fetch existing RTFs $COUNT times, giving up."
            exit 1
        fi
        echo "Retrying in 3 seconds..."
        sleep 3
    done
    
    echo "Checking if the desired name is available ..."
    RTF_FOUND=$(jq -r --arg RTF_NAME "$RTF_NAME" '.[] | select(.name==$RTF_NAME)' $RTF_RESPONSE_JSON_FILE)
    
    if [ "$RTF_FOUND" != "" ]; then
        echo "RTF with this name already exist. Checking if Activation Data is available ..."
        echo
        RTF_ACTIVATION_DATA=$(echo $RTF_FOUND | jq -r .activationData)
        if [ "$RTF_ACTIVATION_DATA" == "" -o "$RTF_ACTIVATION_DATA" == "null" ]; then
            echo "Error: This Name is in use by another RTF running instance."
            exit 1
        fi
        echo "Activation Data [$RTF_ACTIVATION_DATA] is available for usage"
    fi
    
    rm $RTF_RESPONSE_JSON_FILE
}


function create_runtime_fabric() {
    CURRENT_STEP=$FUNCNAME

    echo "Creating RTF ..."

    echo "Checking existing RTF_ACTIVATION_DATA = '$RTF_ACTIVATION_DATA'"
    if [ ! -z "$RTF_ACTIVATION_DATA" ] && [ "$RTF_ACTIVATION_DATA" != "null" ]; then
        echo "Skipped. Using the available/provided RTF_ACTIVATION_DATA."
        return 0
    fi

    RTF_ENDPOINT="https://anypoint.mulesoft.com/runtimefabric/api/organizations/$ORGANIZATION_ID/fabrics"

    if [ -z $RTF_VERSION ]; then
        RTF_CREATE_JSON="{\"name\": \"$RTF_NAME\", \"region\": \"us-east-1\"}"
    else
        RTF_CREATE_JSON="{\"name\": \"$RTF_NAME\", \"region\": \"us-east-1\", \"version\": \"$RTF_VERSION\"}"
    fi

    echo "JSON: $RTF_CREATE_JSON"

    COUNT=0
    while :
    do
        CODE=$($CURL_WITH_PROXY $CURL_OPTS -w "%%{http_code}" --request POST $RTF_ENDPOINT -H "Content-Type: application/json" -H "Authorization: Bearer $OAUTH_ACCESS_TOKEN" --data-raw "$RTF_CREATE_JSON" -o $RTF_RESPONSE_JSON_FILE || true)
        echo "Returned code: $CODE"
        if [ "$CODE" == "201" ]; then
            break
        fi
        let COUNT=COUNT+1
        if [ $COUNT -ge 3 ]; then
            echo "Error: Failed to create RTF $COUNT times, giving up."
            exit 1
        fi
        echo "Retrying in 3 seconds..."
        sleep 3
    done    
    
    RTF_ACTIVATION_DATA=$(cat $RTF_RESPONSE_JSON_FILE | jq -r .activationData)
    
    echo "RTF Registered successful."
    echo "Activation Data [$RTF_ACTIVATION_DATA] is available for usage"

    rm $RTF_RESPONSE_JSON_FILE
}

function download_unpack_rtf_script() {
    CURRENT_STEP=$FUNCNAME
    echo "Downloading and unpacking RTF scripts ..."

    curl -L https://anypoint.mulesoft.com/runtimefabric/api/download/scripts/latest --output /root/rtf-install-scripts.zip
    mkdir -p /root/rtf-install-scripts && unzip /root/rtf-install-scripts.zip -d /root/rtf-install-scripts
    mkdir -p /opt/anypoint/runtimefabric
    cp /root/rtf-install-scripts/scripts/init.sh /opt/anypoint/runtimefabric/init.sh && chmod +x /opt/anypoint/runtimefabric/init.sh
}
function create_required_env_file() {
    CURRENT_STEP=$FUNCNAME
    echo "Create environment variables file ..."


    RTF_INSTALL_PACKAGE_URL=""
    if [ ! -z $RTF_APPLIANCE_VERSION ]; then
        RTF_INSTALL_PACKAGE_URL="$RTF_AWS_S3_URL/runtime-fabric-$RTF_APPLIANCE_VERSION.tar.gz"
        echo "Setting up a specific version URL: $RTF_INSTALL_PACKAGE_URL"
    fi

cat > /opt/anypoint/runtimefabric/env <<-EOS
    RTF_PRIVATE_IP='${private_ip}'
    RTF_INSTALLER_IP='${leader_ip}' 
    RTF_NODE_ROLE='${node_role}'
    RTF_INSTALL_ROLE='${install_role}' 
    RTF_INSTALL_PACKAGE_URL='$RTF_INSTALL_PACKAGE_URL' 
    RTF_ETCD_DEVICE='/dev/sdc' 
    RTF_DOCKER_DEVICE='/dev/sdb' 
    RTF_TOKEN='my-cluster-token' 
    RTF_NAME='runtime-fabric' 
    RTF_ACTIVATION_DATA='$RTF_ACTIVATION_DATA' 
    RTF_MULE_LICENSE='${rtf_mule_license}' 
    RTF_HTTP_PROXY='' 
    RTF_NO_PROXY='' 
    RTF_MONITORING_PROXY='' 
    RTF_SERVICE_UID='' 
    RTF_SERVICE_GID='' 
    POD_NETWORK_CIDR='${pod_network_cidr}' 
    SERVICE_CIDR='${service_cidr}' 
    DISABLE_SELINUX='true'
EOS
}

function disable_linux_services() {
    CURRENT_STEP=$FUNCNAME

    if command -v setenforce >/dev/null; then
        echo "Disabling SELinux ..."
        sudo setenforce 0
    fi

    if systemctl is-active --quiet iptables; then
        echo "Disabling Iptables ..."
        sudo systemctl stop iptables
        sudo systemctl disable iptables
    fi

    if systemctl is-active --quiet firewalld; then
        echo "Disable firewalld ..."
        sudo systemctl stop firewalld
        sudo systemctl disable firewalld
    fi
}

function resize_tmp_partition() {
    CURRENT_STEP=$FUNCNAME
    echo "Resizing TMP partition ..."

    cp /etc/fstab /etc/fstab.bak.tmpfs
    echo "none /tmp tmpfs defaults,size=20G 0 0" >> /etc/fstab
    mount /tmp
}

function install_rtf_cluster() {
    CURRENT_STEP=$FUNCNAME
    echo "Installing RTF Cluster ..."

    sudo /opt/anypoint/runtimefabric/init.sh  
#    chown -R ${gcp_user}:${gcp_user} /opt/anypoint/runtimefabric
}

function validate_variables_params() {

    if [ -z $CONNECTED_APP_CLIENT_ID ] || [ -z $CONNECTED_APP_CLIENT_SECRET ] || [ -z $ORGANIZATION_ID ]; then
        echo "The Anypoint ConnectedApp credentials and the Organization (or BGID) are required."
        exit 1
    fi

    if [ -z $RTF_NAME ] && [ -z $RTF_ACTIVATION_DATA ]; then
        echo "You Must specify either the RTF Activation Data Token or the RTF Name"
        exit 1
    fi
}

function create_default_rtf_cluster_users() {
    echo "Creating default user on the RTF Cluster ..."
    if [ "${install_role}" != "leader" ]; then
        echo "Skipped. This is not a Leader Node."
        return 0
    fi

#   In case you want to apply a random password use the command below. DON'T FORGET to output this password because there will be no other way to find it out.
#   RANDOM_PASSWORD="$(env LC_CTYPE=C tr -dc 'a-zA-Z0-9' < /dev/urandom | head -c50)" || true

    gravity planet enter -- --notty /usr/bin/gravity -- user create --ops-url=https://gravity-site.kube-system.svc.cluster.local:3009 --insecure --email=test_user --password=SomePass --type=admin
}

##########################################
# Entrypoint
##########################################

# Also log output to file
exec >& >(tee -a "$REDIRECT_LOG")


echo -e "Startup Script version: $SCRIPT_VERSION started at: $(date)"

# read -p "Enter your name [Richard]: " name
# name=$${name:-Richard}
# echo $name

# Running required steps
STEP_COUNT=8
if [ "${install_role}" == "leader" ] && [ -z $RTF_ACTIVATION_DATA ]; then
    STEP_COUNT=11
fi

#Pre requirements steps - Start
run_step validate_variables_params "Validate Variables and parameters"
run_step install_required_packages "Install required packages"

if [ "${install_role}" == "leader" ] && [ -z $RTF_ACTIVATION_DATA ]; then
    run_step fetch_runtime_access_token "Retrieve OAuth Access Token"
    run_step verify_rtf_name_is_available "Verify if the desired name is available"
    run_step create_runtime_fabric "Create RTF on Anypoint Runtime Manager"
fi

run_step download_unpack_rtf_script "Download and Unpack RTF Script"
run_step create_required_env_file "Create required environment variables"
run_step disable_linux_services "Disable Services"
run_step resize_tmp_partition "Resize TMP partition"
#Pre requirements steps - Finish

#RTF Installation Step - Start
run_step install_rtf_cluster "Install RTF Cluster"
#RTF Installation Step - Finish

#Post installation steps - Start
run_step create_default_rtf_cluster_users "Create Default RTF Cluster users"
#Post installation steps - Finish

echo -e "Startup Script completed at: $(date)"
