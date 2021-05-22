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

At the end of chectl's execution (the Eclipse Che installer), a link
will be displayed that should be usable to load Eclipse Che's
dashboard in the web browser running on the host machine.
This link ressembles https://che-eclipse-che.192.168.34.100.nip.io where
192.168.34.100 is the Vagrant VM's "external IP". This IP should be
available to the Vagrant host, for connecting with a Web browser
running on the host.
<BR>
However, as the TLS certificate which is generated during installation
will be self-signed, you will need to add the CA cert to your
browser's store, for testing Eclipse Che.
<BR>
That certificate will be available in /tmp/vagrant/cheCA.crt on the
host, as mentioned in the installation messages.

You can obtain it by running following command:
```
vagrant ssh -c "cat /tmp/cheCA.crt"
```
How to import SSL certificate for few popular browsers you can read here:
https://www.pico.net/kb/how-do-you-get-chrome-to-accept-a-self-signed-certificate <BR>
https://support.globalsign.com/digital-certificates/digital-certificate-installation/install-client-digital-certificate-firefox-windows <BR>

Other useful information like keycloak provider auth login details save it somewhere safe, but initially for https://che-eclipse-che.192.168.34.100.nip.io initial username and password are:
```
username: admin
password: admin
```
