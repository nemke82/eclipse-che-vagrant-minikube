# eclipse-che-vagrant-minikube
Eclipse Che IDE Platform (multiuser) on a k8s running inside a Vagrant VM, deployed via minikube + none driver

This project contains the means to test Eclipse Che, deployed in
single-user mode (by default), inside a VM.
The VM runs via Vagrant, and contains a Kubernetes (k8s) mono-node
cluster.

Install Pre-requisites
Ensure you have vagrant installed (should also support mac/windows)
https://www.vagrantup.com/docs/installation/

Start VM with following command:
```
CHE_MULTIUSER=true vagrant up
```
