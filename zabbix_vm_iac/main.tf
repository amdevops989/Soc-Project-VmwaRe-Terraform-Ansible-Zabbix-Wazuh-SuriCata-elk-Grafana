terraform {
  required_version = ">= 1.0.0"
  required_providers {
    vmworkstation = {
      source  = "elsudano/vmworkstation"
      version = "1.0.4"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }
}

provider "vmworkstation" {
  user     = "ubuntu"
  password = "Lukaku@@001"     
  url      = "http://localhost:8697/api"
  https    = false
  debug    = false
}

# --- Variables ---
variable "ssh_password" { 
  type    = string 
  default = "MotDePasse" 
}

variable "ssh_username" { 
  type    = string 
  default = "ubuntu" 
}

variable "vm_dhcp_ip" { 
  type    = string 
  default = "192.168.100.143" 
}

variable "vm_static_ip" { 
  type    = string 
  default = "192.168.100.10" 
}

resource "random_id" "vm_suffix" { 
  byte_length = 4 
}

# --- VM Resource ---
resource "vmworkstation_vm" "zabbix_vm" {
  sourceid     = "91L6RKBEQS49AKKKEL2ABUFOVURBUA28"
  denomination = "zabbix-vm-${random_id.vm_suffix.hex}"
  description  = "VM managed by Terraform + Triple Playbook Pipeline"
  path         = "/home/ironops/vmware/zabbix-vm-${random_id.vm_suffix.hex}/zabbix-vm-${random_id.vm_suffix.hex}.vmx"
  processors   = 2
  memory       = 2048

  # STEP 1: Power On
  provisioner "local-exec" {
    command = "curl -X PUT http://localhost:8697/api/vms/${self.id}/power -H 'Accept: application/vnd.vmware.vmw.rest-v1+json' -H 'Content-Type: application/vnd.vmware.vmw.rest-v1+json' -u 'ubuntu:Lukaku@@001' -d 'on'"
  }

  # STEP 2: Run Netplan Playbook (via DHCP IP)
  provisioner "local-exec" {
    command = <<EOT
      sleep 20
      ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -i ${var.vm_dhcp_ip}, \
      --extra-vars "ansible_user=${var.ssh_username} ansible_password=${var.ssh_password} ansible_become_password=${var.ssh_password}" \
      setup_network.yml
    EOT
  }

  # # STEP 3: Run Services Playbook (via New Static IP)
  # provisioner "local-exec" {
  #   command = <<EOT
  #     sleep 15
  #     ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -i ${var.vm_static_ip}, \
  #     --extra-vars "ansible_user=${var.ssh_username} ansible_password=${var.ssh_password} ansible_become_password=${var.ssh_password}" \
  #     /home/ironops/Desktop/Soc-Vmware/ansible/playbooks/setup_services.yml
  #   EOT
  # }

  # STEP 4: Run zabbix and grafanaPlaybook (via New Static IP)
  provisioner "local-exec" {
    command = <<EOT
      ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -i ${var.vm_static_ip}, \
      --extra-vars "ansible_user=${var.ssh_username} ansible_password=${var.ssh_password} ansible_become_password=${var.ssh_password}" \
      setup_zabbix_server.yml
    EOT
  }

  # STEP 5: Clean Shutdown
  # provisioner "local-exec" {
  #   command = "curl -X PUT http://localhost:8697/api/vms/${self.id}/power -H 'Accept: application/vnd.vmware.vmw.rest-v1+json' -H 'Content-Type: application/vnd.vmware.vmw.rest-v1+json' -u 'ubuntu:Lukaku@@001' -d 'off'"
  # }
}

# --- Outputs ---
output "vm_id" { 
  value = vmworkstation_vm.zabbix_vm.id 
}

output "vm_name" { 
  value = vmworkstation_vm.zabbix_vm.denomination 
}