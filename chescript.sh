#!/bin/bash

hostaddress=$(kubectl get nodes --selector=kubernetes.io/role!=master -o jsonpath={.items[*].status.addresses[?\(@.type==\"InternalIP\"\)].address})

sub_help(){
    echo "Usage: $PROGNAME <subcommand> [options]"
    echo "Subcommands:"
    echo "    start    Start local instance of Antidote"
    echo "    resume   Resume stopped Antidote instance"
    echo ""
    echo "options:"
    echo "-h    show brief help"
    echo ""
    echo "For help with each subcommand run:"
    echo "$PROGNAME <subcommand> -h|--help"
    echo ""
}
  
sub_resume(){

    #sudo chectl server:start --platform minikube --installer=helm --domain $hostaddress.nip.io --workspace-pvc-storage-class-name=workspace-storage
    #kubectl rollout status -w -n eclipse-che deployment/eclipse-che
    sudo chectl server:deploy --platform minikube --installer=helm --domain 192.168.34.100.nip.io --workspace-pvc-storage-class-name=standard --telemetry=off

    if [ $? -eq 0 ]; then
        echo
        echo "Installation completed."
        echo "Eclipse Che should be up on https://che-eclipse-che.$hostaddress.nip.io/"
        echo "You may need to install the CA certificate file for the TLS certificate,"
        echo "available in /tmp/cheCA.crt (on a Linux host) - retrieve its content with:"
        echo ' vagrant ssh -c "cat /tmp/cheCA.crt"'
        echo 'or copy/paste the following:'
        cat /tmp/cheCA.crt
    fi

}

sub_start(){

    echo "Installing Eclipse Che"

    export MINIKUBE_WANTUPDATENOTIFICATION=false
    export MINIKUBE_WANTREPORTERRORPROMPT=false
    export MINIKUBE_HOME=$HOME
    export CHANGE_MINIKUBE_NONE_USER=true
    export KUBECONFIG=$HOME/.kube/config

    # Install chectl
    curl -q -Lo chectl-install.sh https://www.eclipse.org/che/chectl/  2>/dev/null
    chmod +x chectl-install.sh
    sudo yes | ./chectl-install.sh 2>/dev/null

    # Install Helm
    curl https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3 2>/dev/null | bash

    sudo mkdir -p /home/vagrant/workspace-storage
    sudo chmod a+trwx /home/vagrant/workspace-storage

    kubectl apply -f /home/vagrant/che-workspace-pv.yaml
    kubectl apply -f /home/vagrant/workspace-storage.yaml

    if [ "$CHE_MULTIUSER" = "true" ]; then
        sudo mkdir /home/vagrant/postgres-storage
        sudo chmod a+trwx /home/vagrant/postgres-storage

        kubectl apply -f /home/vagrant/che-postgresql-pv.yaml

        cat <<EOF >get-access-token.sh
#!/bin/sh

CHE_USER=admin
CHE_PASSWORD=xxxxx

if [ "\$CHE_PASSWORD" = "xxxxx" ]; then
   echo "You must set the admin user's password as the value of CHE_PASSWORD in \$0 !" >&2
   exit 1
fi

KEYCLOAK_HOSTNAME=keycloak-che.$hostaddress.nip.io
TOKEN_ENDPOINT="https://\${KEYCLOAK_HOSTNAME}/auth/realms/che/protocol/openid-connect/token"

#echo "Retrieving 'admin' user's token from https://\${KEYCLOAK_HOSTNAME}" >&2
echo \$(curl -k -sfSL --data "grant_type=password&client_id=che-public&username=\${CHE_USER}&password=\${CHE_PASSWORD}" \${TOKEN_ENDPOINT} | jq -r .access_token)
EOF

        chmod +x get-access-token.sh

        sudo chectl server:deploy --platform minikube --installer=helm --multiuser --domain $hostaddress.nip.io --workspace-pvc-storage-class-name=workspace-storage --postgres-pvc-storage-class-name=postgres-storage --telemetry=off
    else
        sudo mkdir -p /home/vagrant/che-data-storage
        sudo chmod a+trwx /home/vagrant/che-data-storage

        kubectl apply -f /home/vagrant/che-data-pv.yaml
        
        sudo chectl server:deploy --platform minikube --installer=helm --domain $hostaddress.nip.io --workspace-pvc-storage-class-name=standard --telemetry=off
    fi
    
    if [ $? -eq 0 ]; then
        cp /tmp/cheCA.crt /home/vagrant/data/

        echo
        echo "Installation completed."
        echo "Eclipse Che should be up on https://che-eclipse-che.$hostaddress.nip.io/"
        echo "You may need to install the CA certificate file for the TLS certificate,"
        echo "available in /tmp/cheCA.crt (on a Linux host) - retrieve its content with:"
        echo ' vagrant ssh -c "cat /tmp/cheCA.crt"'
    fi

}


while getopts "h" OPTION
do
	case $OPTION in
		h)
            sub_help
            exit
            ;;
		\?)
			sub_help
			exit
			;;
	esac
done

# Direct to appropriate subcommand
subcommand=$1
case $subcommand in
    "")
        sub_help
        ;;
    *)
        shift
        sub_${subcommand} $@
        if [ $? = 127 ]; then
            echo "Error: '$subcommand' is not a known subcommand." >&2
            echo "       Run '$PROGNAME --help' for a list of known subcommands." >&2
            exit 1
        fi
        ;;
esac

exit 0
