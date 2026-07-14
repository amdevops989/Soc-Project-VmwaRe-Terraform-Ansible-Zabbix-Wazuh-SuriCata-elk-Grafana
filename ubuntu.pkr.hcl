packer {
  required_version = ">= 1.7.0"
  required_plugins {
    vmware = {
      version = ">= 2.0.0"
      source  = "github.com/hashicorp/vmware"
    }
  }
}

# ==========================================
# VARIABLES
# ==========================================

variable "iso" {
  type        = string
  description = "A URL to the ISO file"
  default     = "https://releases.ubuntu.com/noble/ubuntu-24.04.4-live-server-amd64.iso"
}

variable "checksum" {
  type        = string
  description = "The checksum for the ISO file"
  default     = "sha256:e907d92eeec9df64163a7e454cbc8d7755e8ddc7ed42f99dbc80c40f1a138433"
}

variable "headless" {
  type        = bool
  description = "When this value is set to true, the machine will start without a console"
  default     = true
}

variable "name" {
  type        = string
  description = "This is the name of the new virtual machine"
  default     = "vm-ubuntuserver24_04"
}

variable "username" {
  type        = string
  description = "The username to connect to SSH"
  default     = "ubuntu"
}

variable "password" {
  type        = string
  description = "A plaintext password to authenticate with SSH"
  default     = "MotDePasse"
}

# ==========================================
# BUILD SOURCE (VMWARE ISO)
# ==========================================

source "vmware-iso" "ubuntuserver24_04" {
  // Documentation : https://developer.hashicorp.com/packer/integrations/vmware/vmware/latest/components/builder/iso

  // ISO configuration
  iso_url      = var.iso
  iso_checksum = var.checksum

  // Hardware configuration
  vm_name              = var.name
  vmdk_name            = var.name
  firmware             = "bios"
  version              = 21
  guest_os_type        = "ubuntu-64"
  cpus                 = 4
  vmx_data = {
    "numvcpus" = "4"
  }
  memory               = 4096
  disk_size            = 20000
  disk_adapter_type    = "scsi"
  disk_type_id         = "1"
  network              = "nat"
  network_adapter_type = "e1000"
  sound                = false
  usb                  = false

  // Run configuration
  headless = var.headless

  // Shutdown configuration
  shutdown_command = "echo '${var.password}' | sudo -S systemctl poweroff"

  // Http directory configuration
  http_directory = "http"

  // Boot configuration
  boot_command = ["e<wait><down><down><down><end> autoinstall 'ds=nocloud;s=http://{{ .HTTPIP }}:{{ .HTTPPort }}/'<F10>"]
  boot_wait    = "10s"

  // Communicator configuration
  communicator = "ssh"
  ssh_username = var.username
  ssh_password = var.password
  ssh_timeout  = "30m"

  // Output configuration
  output_directory = "template"

  // Export configuration
  format          = "vmx"
  skip_compaction = false
}

# ==========================================
# PROVISIONING ENGINE
# ==========================================

build {
  sources = ["source.vmware-iso.ubuntuserver24_04"]

  # Step 1: Execute your foundational bash scripts
  provisioner "shell" {
    execute_command = "echo '${var.password}' | sudo -S env {{ .Vars }} {{ .Path }}"
    scripts = [
      "scripts/provisioning.sh"
    ]
  }

  # Step 2: Inject the Ansible playbook for OS Hardening & SOC Agent deployments
  provisioner "ansible" {
    playbook_file   = "ansible/playbooks/harden-and-agents.yml"
    user            = var.username
    use_proxy       = true
    extra_arguments = [
      "--extra-vars", "ansible_sudo_pass=${var.password}"
    ]
  }
}