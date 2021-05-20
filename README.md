# Kubernetes Networking deep dive Demo
[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](https://opensource.org/licenses/Apache-2.0)

## Summary

This project collects instructions to discover, analyze and learn how
Kubernetes connects containers in different setups.

## Virtual Machines

The [Vagrant tool][1] is used for provisioning Ubuntu Focal Virtual
Machines. It's highly recommended to use the  *setup.sh* script
of the [bootstrap-vagrant project][2] for installing Vagrant
dependencies and plugins required for this project. That script
supports two Virtualization providers (Libvirt and VirtualBox) which
are determine by the **PROVIDER** environment variable.

    curl -fsSL http://bit.ly/initVagrant | PROVIDER=libvirt bash

Once Vagrant is installed, it's possible to provision a Virtual
Machine using the following instructions:

    vagrant up <pause|ipvs>

[1]: https://www.vagrantup.com/
[2]: https://github.com/electrocucaracha/bootstrap-vagrant
