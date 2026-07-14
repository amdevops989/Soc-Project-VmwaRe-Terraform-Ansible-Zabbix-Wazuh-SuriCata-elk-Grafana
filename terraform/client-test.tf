terraform {
  required_version = ">= 0.13"
  required_providers {
    libvirt = {
      source  = "dmacvicar/libvirt"
      version = "0.7.6" # Pinning a stable verified version prevents schema mismatches
    }
  }
}

provider "libvirt" {
  uri = "qemu:///system"
}

# 1. Base Image definition using the correct attributes
resource "libvirt_volume" "golden_base" {
  name   = "ubuntu-jammy-golden-base.qcow2"
  pool   = "default"
  source = "../output-jammy/ubuntu-jammy.img"
}

# 2. Allocate Instance Disk linking back to our base volume
resource "libvirt_volume" "client_vm_disk" {
  name           = "test-client-boot-disk.qcow2"
  pool           = "default"
  base_volume_id = libvirt_volume.golden_base.id
  size           = 16106127360 # 15 GB
}

# 3. Define the compute profile with required 'kvm' type
resource "libvirt_domain" "client_vm" {
  name   = "security-client-test"
  memory = "2048"
  vcpu   = 2
  type   = "kvm" # Bypasses the "Missing type argument" error

  network_interface {
    network_name = "default"
  }

  disk {
    volume_id = libvirt_volume.client_vm_disk.id
  }

  graphics {
    type        = "spice"
    listen_type = "address"
  }

  console {
    type        = "pty"
    target_port = "0"
    target_type = "serial"
  }
}

output "client_private_ip" {
  value       = length(libvirt_domain.client_vm.network_interface[0].addresses) > 0 ? libvirt_domain.client_vm.network_interface[0].addresses[0] : "Waiting for DHCP..."
  description = "The DHCP IP address allocated to our new client machine"
}