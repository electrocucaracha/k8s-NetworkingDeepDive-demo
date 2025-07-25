# frozen_string_literal: true

# -*- mode: ruby -*-
# vi: set ft=ruby :
##############################################################################
# Copyright (c)
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Apache License, Version 2.0
# which accompanies this distribution, and is available at
# http://www.apache.org/licenses/LICENSE-2.0
##############################################################################

host = RbConfig::CONFIG["host_os"]

no_proxy = ENV["NO_PROXY"] || ENV["no_proxy"] || "127.0.0.1,localhost"
(1..254).each do |i|
  no_proxy += ",10.0.2.#{i}"
end

case host
when /darwin/
  mem = `sysctl -n hw.memsize`.to_i / 1024
when /linux/
  mem = `grep 'MemTotal' /proc/meminfo | sed -e 's/MemTotal://' -e 's/ kB//'`.to_i
when /mswin|mingw|cygwin/
  mem = `wmic computersystem Get TotalPhysicalMemory`.split[1].to_i / 1024
end

Vagrant.configure("2") do |config|
  config.vm.provider :libvirt
  config.vm.provider :virtualbox

  config.vm.box = "generic/ubuntu2204"
  config.vm.box_check_update = false

  %i[virtualbox libvirt].each do |provider|
    config.vm.provider provider do |p|
      p.cpus = ENV["CPUS"] || 2
      p.memory = ENV["MEMORY"] || mem / 1024 / 4
    end
  end

  config.vm.provider "virtualbox" do |v|
    v.gui = false
    v.customize ["modifyvm", :id, "--nictype1", "virtio", "--cableconnected1", "on"]
    # https://bugs.launchpad.net/cloud-images/+bug/1829625/comments/2
    v.customize ["modifyvm", :id, "--uart1", "0x3F8", "4"]
    v.customize ["modifyvm", :id, "--uartmode1", "file", File::NULL]
    # Enable nested paging for memory management in hardware
    v.customize ["modifyvm", :id, "--nestedpaging", "on"]
    # Use large pages to reduce Translation Lookaside Buffers usage
    v.customize ["modifyvm", :id, "--largepages", "on"]
    # Use virtual processor identifiers  to accelerate context switching
    v.customize ["modifyvm", :id, "--vtxvpid", "on"]
  end

  config.vm.provider :libvirt do |v|
    v.random_hostname = true
    v.management_network_address = "10.0.2.0/24"
    v.management_network_name = "administration"
    v.cpu_mode = "host-passthrough"
  end

  if !ENV["http_proxy"].nil? && !ENV["https_proxy"].nil? && Vagrant.has_plugin?("vagrant-proxyconf")
    config.proxy.http = ENV["http_proxy"] || ENV["HTTP_PROXY"] || ""
    config.proxy.https    = ENV["https_proxy"] || ENV["HTTPS_PROXY"] || ""
    config.proxy.no_proxy = no_proxy
    config.proxy.enabled = { docker: false }
  end

  %w[pause ipvs flannel bash ebpf].each do |instance|
    config.vm.define instance do |demo|
      [{ host: "./common", guest: "/opt/common" },
       { host: instance.to_s, guest: "/vagrant" }].each do |mapping|
        demo.vm.synced_folder (mapping[:host]).to_s, (mapping[:guest]).to_s
        demo.vm.provider :libvirt do |v, override|
          override.vm.synced_folder (mapping[:host]).to_s, (mapping[:guest]).to_s, type: 'nfs', nfs_version: ENV.fetch('VAGRANT_NFS_VERSION', 3)
        end
      end
      demo.vm.provision "shell", privileged: false, inline: <<~SHELL
        set -o errexit
        set -o pipefail
        cd /vagrant/

        ./install.sh | tee /tmp/install.log
        ./configure.sh | tee /tmp/configure.log
        ./demo.sh | tee ~/demo.log
      SHELL
    end
  end
end
