# -*- mode: ruby -*-
# vi: set ft=ruby :

VAGRANTFILE_API_VERSION = "2"
Vagrant.require_version ">= 2.0.0"

ENV['VAGRANT_DEFAULT_PROVIDER'] = "virtualbox"

# just a single node is required
NODES = ENV['NODES'] || 1

# Memory & CPUs
MEM = ENV['MEM'] || 4096
CPUS = ENV['CPUS'] || 2

# User Data Mount
#SRCDIR = ENV['SRCDIR'] || "/home/"+ENV['USER']+"/test"
SRCDIR = ENV['SRCDIR'] || "/tmp/vagrant"
DSTDIR = ENV['DSTDIR'] || "/home/vagrant/data"

# Management
GROWPART = ENV['GROWPART'] || "true"

# Minikube Variables
KUBERNETES_VERSION = ENV['KUBERNETES_VERSION'] || "1.17.17"

# Set env. var CHE_MULTIUSER to "true" to test Eclipse Che in multi-user mode
CHE_MULTIUSER = ENV['CHE_MULTIUSER'] || "false"

#required_plugins = %w(vagrant-sshfs vagrant-vbguest vagrant-libvirt)
required_plugins = %w(vagrant-sshfs vagrant-vbguest)

required_plugins.each do |plugin|
  need_restart = false
  unless Vagrant.has_plugin? plugin
    system "vagrant plugin install #{plugin}"
    need_restart = true
  end
  exec "vagrant #{ARGV.join(' ')}" if need_restart
end


def configureVM(vmCfg, hostname, cpus, mem, srcdir, dstdir)

  vmCfg.vm.box = "roboxes/ubuntu1804"

  vmCfg.vm.hostname = hostname
  #vmCfg.vm.network "private_network", type: "dhcp",  :model_type => "virtio", :autostart => true
  vmCfg.vm.network "private_network", id: "antidote_primary", ip: '192.168.34.100',  :model_type => "virtio", :autostart => true

  vmCfg.vm.synced_folder '.', '/vagrant', disabled: true
  # sync your laptop's development with this Vagrant VM
  vmCfg.vm.synced_folder srcdir, dstdir, type: "rsync", rsync__exclude: ".git/", create: true

  # First Provider - Libvirt
  vmCfg.vm.provider "libvirt" do |provider, override|
    provider.memory = mem
    provider.cpus = cpus
    provider.driver = "kvm"
    provider.disk_bus = "scsi"
    provider.machine_virtual_size = 64
    provider.video_vram = 64


    override.vm.synced_folder srcdir, dstdir, type: 'sshfs', ssh_opts_append: "-o Compression=yes", sshfs_opts_append: "-o cache=no", disabled: false, create: true
  end

  vmCfg.vm.provider "virtualbox" do |provider, override|
    provider.memory = mem
    provider.cpus = cpus
    provider.customize ["modifyvm", :id, "--cableconnected1", "on"]

    override.vm.synced_folder srcdir, dstdir, type: 'virtualbox', create: true
  end

  vmCfg.vm.provider "hyperv" do |provider, override|
    provider.memory = mem
    provider.cpus = cpus
  end

  # ensure docker is installed # Use our script so we can get a proper support version
  #vmCfg.vm.provision "shell", inline: $docker, privileged: false
  vmCfg.vm.provision "default", type: "shell", path: "docker.sh", privileged: false
  # Script to prepare the VM
  #vmCfg.vm.provision "shell", inline: $installer, privileged: false
  vmCfg.vm.provision "shell", path: "installer.sh", privileged: false
  #vmCfg.vm.provision "shell", inline: $growpart, privileged: false if GROWPART == "true"
  vmCfg.vm.provision "shell", path: "growpart.sh", privileged: false if GROWPART == "true"
  #vmCfg.vm.provision "shell", inline: $minikubescript, privileged: false, env: {"KUBERNETES_VERSION" => KUBERNETES_VERSION}

  vmCfg.vm.provision "file", source: "minikubescript.sh", destination: "$HOME/minikubescript.sh"
  vmCfg.vm.provision "file", source: "chescript.sh", destination: "$HOME/chescript.sh"
  vmCfg.vm.provision "file", source: "che-workspace-pv.yaml", destination: "$HOME/che-workspace-pv.yaml"
  vmCfg.vm.provision "file", source: "workspace-storage.yaml", destination: "$HOME/workspace-storage.yaml"
  vmCfg.vm.provision "file", source: "che-postgresql-pv.yaml", destination: "$HOME/che-postgresql-pv.yaml"
  vmCfg.vm.provision "file", source: "che-data-pv.yaml", destination: "$HOME/che-data-pv.yaml"

  # Running initial selfmedicate script as the Vagrant user.
  $script = "/bin/bash --login $HOME/minikubescript.sh start"
  vmCfg.vm.provision "custom", type: "shell", privileged: false, inline: $script, env: {"KUBERNETES_VERSION" => KUBERNETES_VERSION, "CHE_MULTIUSER" => CHE_MULTIUSER}
  
  #vmCfg.vm.provision "shell", inline: $chescript, privileged: false
  #vmCfg.vm.provision "shell", path: "chescript.sh", privileged: false

  # Start k8s on reload
  $script = "/bin/bash --login $HOME/minikubescript.sh resume"
  vmCfg.vm.provision "reload", type: "shell", privileged: false, inline: $script, run: "always", env: {"KUBERNETES_VERSION" => KUBERNETES_VERSION, "CHE_MULTIUSER" => CHE_MULTIUSER}
  
  return vmCfg
end

# Entry point of this Vagrantfile
Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|

  config.vbguest.auto_update = false

  1.upto(NODES.to_i) do |i|
    hostname = "minikube-vagrant-%02d" % [i]
    cpus = CPUS
    mem = MEM
    srcdir = SRCDIR
    dstdir = DSTDIR

    config.vm.define hostname do |vmCfg|
      vmCfg = configureVM(vmCfg, hostname, cpus, mem, srcdir, dstdir)
    end
  end

end
