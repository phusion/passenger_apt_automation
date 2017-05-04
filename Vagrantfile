# -*- mode: ruby -*-
# vi: set ft=ruby :

# Vagrantfile API/syntax version. Don't touch unless you know what you're doing!
VAGRANTFILE_API_VERSION = "2"

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
  config.vm.box = "boxcutter/ubuntu1604"

  if File.exist?("../../bin/passenger")
    passenger_path = File.absolute_path("../../")
  elsif File.directory?("../passenger")
    passenger_path = File.absolute_path("../passenger")
  end
  if passenger_path
    config.vm.synced_folder passenger_path, "/passenger"
  end

  config.vm.provision :shell, :path => "internal/scripts/setup-vagrant.sh"

  config.vm.provider "virtualbox" do |v|
    v.memory = 2048
    v.cpus = 2
  end

  config.vm.provider "vmware_fusion" do |v|
    v.vmx["memsize"] = "2048"
    v.vmx["numvcpus"] = "2"
  end
end
