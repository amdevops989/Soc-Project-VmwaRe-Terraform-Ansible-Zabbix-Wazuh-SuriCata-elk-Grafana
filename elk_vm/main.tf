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
  default = "192.168.100.20" 
}

resource "random_id" "vm_suffix" { 
  byte_length = 4 
}

# --- VM Resource ---
resource "vmworkstation_vm" "elk_vm" {
  sourceid     = "91L6RKBEQS49AKKKEL2ABUFOVURBUA28"
  denomination = "elk-vm-${random_id.vm_suffix.hex}"
  description  = "VM managed by Terraform + Triple Playbook Pipeline"
  path         = "/home/ironops/vmware/elk-vm-${random_id.vm_suffix.hex}/elk-vm-${random_id.vm_suffix.hex}.vmx"
  processors   = 2
  memory       = 4096 # CRITICAL FIX: Changed from 2048 to 4096. ELK will crash with Out Of Memory errors on 2GB RAM.

  # STEP 1: Power On
  provisioner "local-exec" {
    command = "curl -X PUT http://localhost:8697/api/vms/${self.id}/power -H 'Accept: application/vnd.vmware.vmw.rest-v1+json' -H 'Content-Type: application/vnd.vmware.vmw.rest-v1+json' -u 'ubuntu:Lukaku@@001' -d 'on'"
  }

  # STEP 2: Run Netplan Playbook (via initial DHCP IP)
  provisioner "local-exec" {
    command = <<EOT
      sleep 20
      ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -i ${var.vm_dhcp_ip}, \
      --extra-vars "ansible_user=${var.ssh_username} ansible_password=${var.ssh_password} ansible_become_password=${var.ssh_password}" \
      setup_network.yml
    EOT
  }

  # STEP 3: CRITICAL FIX - Authenticated Terminal Interceptor Loop
  provisioner "local-exec" {
    command = <<EOT
      echo "Validating stable authenticated SSH terminal access on ${var.vm_static_ip}..."
      sleep 5
      for i in {1..20}; do
        SSHPASS="${var.ssh_password}" sshpass -e ssh -o StrictHostKeyChecking=no -o ConnectTimeout=3 ${var.ssh_username}@${var.vm_static_ip} "echo TerminalReady" && exit 0
        echo "Network interface settling down... Retrying terminal authentication hook."
        sleep 4
      done
      echo "Failed to verify stable SSH terminal runtime environment on static endpoint." && exit 1
    EOT
  }

  # STEP 4: CRITICAL FIX - Run ELK Deployment Playbook with clean SSH arguments
  # provisioner "local-exec" {
  #   command = <<EOT
  #     ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -i ${var.vm_static_ip}, \
  #     --extra-vars "ansible_user=${var.ssh_username} ansible_password=${var.ssh_password} ansible_become_password=${var.ssh_password}" \
  #     --ssh-extra-args="-o ControlMaster=no -o ControlPath=none" \
  #     setup_elk.yml
  #   EOT
  # }
}

# --- Outputs ---
output "vm_id" { 
  value = vmworkstation_vm.elk_vm.id 
}

output "vm_name" { 
  value = vmworkstation_vm.elk_vm.denomination 
}