#!/bin/bash

export MINIKUBE_WANTUPDATENOTIFICATION=false
export MINIKUBE_WANTREPORTERRORPROMPT=false
export MINIKUBE_HOME=$HOME
export CHANGE_MINIKUBE_NONE_USER=true
export KUBECONFIG=$HOME/.kube/config


sub_help(){
    echo "Usage: $PROGNAME <subcommand> [options]"
    echo "Subcommands:"
    echo "    start    Start local instance of Antidote"
    echo "    reload   Reload Antidote components"
    echo "    stop     Stop local instance of Antidote"
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

    minikube config set WantReportErrorPrompt false
    if [ ! -f $HOME/.minikube/config/config.json ]; then
        echo -e "${RED}No existing cluster detected.${NC}"
        echo -e "This subcommand is used to resume an existing selfmedicate setup."
        echo -e "Please use the ${WHITE}'start'${NC} subcommand instead."
        exit 1
    fi

        ## Start minikube
    export MINIKUBE_IN_STYLE=false
    PRIVATE_NETWORK_IP=$(ifconfig eth1 | grep "inet " | cut -d' ' -f 10)
    sudo -E minikube start -v 4 --vm-driver none --kubernetes-version v${KUBERNETES_VERSION} --bootstrapper kubeadm \
         --extra-config kubelet.node-ip=$PRIVATE_NETWORK_IP \
         2>/dev/null

    echo "Wait a bit for the cluster to restart..."
    sleep 30
    
    # Wait for ingress-nginx
    echo "Waiting for ingress..."
    #kubectl wait --timeout=300s --for=condition=Ready -n kube-system pod -l app.kubernetes.io/component=controller,app.kubernetes.io/name=ingress-nginx
    kubectl rollout status -w -n kube-system deployment/ingress-nginx-controller
    #kubectl get -A all

    /home/vagrant/chescript.sh resume

}

sub_start(){

    #Install minikube
    echo "Downloading Minikube"
    curl -q -Lo minikube https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64 2>/dev/null
    chmod +x minikube
    sudo mv minikube /usr/local/bin/

    #Install kubectl
    echo "Downloading Kubectl"
    curl -q -Lo kubectl https://storage.googleapis.com/kubernetes-release/release/v${KUBERNETES_VERSION}/bin/linux/amd64/kubectl 2>/dev/null
    chmod +x kubectl
    sudo mv kubectl /usr/local/bin/

    #Setup minikube
    echo "127.0.0.1 minikube minikube." | sudo tee -a /etc/hosts
    mkdir -p $HOME/.minikube
    mkdir -p $HOME/.kube
    touch $HOME/.kube/config

    export KUBECONFIG=$HOME/.kube/config

    # Permissions
    sudo chown -R $USER:$USER $HOME/.kube
    sudo chown -R $USER:$USER $HOME/.minikube

    # Disable SWAP since is not supported on a kubernetes cluster
    sudo swapoff -a

    ## Start minikube
    export MINIKUBE_IN_STYLE=false
    PRIVATE_NETWORK_IP=$(ifconfig eth1 | grep "inet " | cut -d' ' -f 10)
    sudo -E minikube start -v 4 --vm-driver none --kubernetes-version v${KUBERNETES_VERSION} --bootstrapper kubeadm \
         --extra-config kubelet.node-ip=$PRIVATE_NETWORK_IP \
         2>/dev/null

    ## Addons
    sudo -E minikube addons  enable ingress

    ## Configure vagrant clients dir

    printf "export MINIKUBE_WANTUPDATENOTIFICATION=false\n" >> /home/vagrant/.bashrc
    printf "export MINIKUBE_WANTREPORTERRORPROMPT=false\n" >> /home/vagrant/.bashrc
    printf "export MINIKUBE_HOME=/home/vagrant\n" >> /home/vagrant/.bashrc
    printf "export CHANGE_MINIKUBE_NONE_USER=true\n" >> /home/vagrant/.bashrc
    printf "export KUBECONFIG=/home/vagrant/.kube/config\n" >> /home/vagrant/.bashrc
    printf "source <(kubectl completion bash)\n" >> /home/vagrant/.bashrc

    # Permissions
    sudo chown -R $USER:$USER $HOME/.kube
    sudo chown -R $USER:$USER $HOME/.minikube

    # Enforce sysctl
    sudo sysctl -w vm.max_map_count=262144
    sudo echo "vm.max_map_count=262144" | sudo tee -a /etc/sysctl.d/90-vm_max_map_count.conf

    # Wait for the cluster to be up
    echo "Waiting for kube-proxy..."
    kubectl wait --timeout=300s --for=condition=Ready -n kube-system pod -l k8s-app=kube-proxy
    echo "Waiting for etcd..."
    sleep 120
    kubectl wait --timeout=300s --for=condition=Ready -n kube-system pod -l component=etcd

    # Wait for coredns to be up
    echo "Waiting for coredns..."
    kubectl wait --timeout=300s --for=condition=Ready -n kube-system pod -l k8s-app=kube-dns

    # Wait for ingress-nginx
    echo "Waiting for ingress..."
    kubectl wait --timeout=300s --for=condition=Ready -n kube-system pod -l app.kubernetes.io/component=controller,app.kubernetes.io/name=ingress-nginx

    chmod +x /home/vagrant/chescript.sh
    /home/vagrant/chescript.sh start
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
