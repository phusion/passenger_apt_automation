# -*- mode: ruby -*-
# vi: set ft=ruby :

# Vagrantfile API/syntax version. Don't touch unless you know what you're doing!
VAGRANTFILE_API_VERSION = "2"

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
  config.vm.box = "phusion-open-ubuntu-12.04-amd64"
  config.vm.box_url = "https://oss-binaries.phusionpassenger.com/vagrant/boxes/latest/ubuntu-12.04-amd64-vbox.box"

  if File.exist?("../../bin/passenger")
    passenger_path = File.absolute_path("../../bin/passenger")
  elsif File.directory?("../passenger")
    passenger_path = File.absolute_path("../passenger")
  end
  if passenger_path
    config.vm.synced_folder passenger_path, "/passenger"
  end

  config.vm.provider :vmware_fusion do |f, override|
    override.vm.box_url = "https://oss-binaries.phusionpassenger.com/vagrant/boxes/latest/ubuntu-12.04-amd64-vmwarefusion.box"
  end

  config.vm.provision :shell, :path => "internal/scripts/setup-vagrant.sh"
end
