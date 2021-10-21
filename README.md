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

    vagrant up <pause|ipvs|flannel>

## Linux Networking concepts

### vtap

A virtual "tap" device is a single point to point device which can be used by a
program in user-space or a virtual machine to send Ethernet packets on layer 2
directly to the kernel or receive packets from it. A file descriptor (fd) is
read/written during such a transmission. KVM/qemu virtualization uses "tap"
devices to equip virtualized guest system with a virtual and configurable
ethernet interface - which then interacts with the fd. A tap device can on
the other side be attached to a virtual Linux bridge; the kernel handles the
packet transfer as if it occurred over a virtual bridge port.

### veth

The "veth" devices are instead created as pairs of connected virtual Ethernet
interfaces. These 2 devices can be imagined as being connected by a network
cable; each veth-device of a pair can be attached to different virtual entities
as OpenVswitch bridges, LXC containers or Linux standard bridges. veth pairs are
ideal to connect virtual devices to each other.

### Aspects and properties of Linux bridges

- A "tap" device attached to one Linux bridge cannot be attached to another
  Linux bridge.
- All attached devices are switched into the promiscuous mode.
- The bridge itself (not a tap device at a port!) can get an IP address and may
  work as a standard Ethernet device. The host can communicate via this address
  with other guests attached to the bridge.
- You may attach several physical Ethernet devices (without IP !) of the host to
  a bridge - each as a kind of "uplink" to other physical switches/hubs and
  connected systems. With the spanning tree protocol activated all physical
  systems attached to the network behind each physical interface may communicate
  with physical or virtual guests linked to the bridge by other physical
  interfaces or virtual ports.
- Properly configured the bridge transfers packets directly between two specific
  bridge ports related to the communication stream of 2 attached guests -
  without exposing the communication to other ports and other guests. The bridge
  may learn and update the relevant association of MAC addresses to bridge
  ports.
- The virtual bridge device itself - in its role as an Ethernet device - does
  not work in promiscuous mode. However, packets arriving through one of its
  ports for (yet) unknown addresses may be flooded to all ports.
- You cannot bridge a Linux bridge directly by or with another Linux bridge (no
  Linux bridge cascading). You can neither connect a Linux bride to another
  Linux bridge via a "tap" device.

[1]: https://www.vagrantup.com/
[2]: https://github.com/electrocucaracha/bootstrap-vagrant
