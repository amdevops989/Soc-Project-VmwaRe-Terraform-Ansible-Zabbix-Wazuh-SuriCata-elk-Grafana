You are building an automated, enterprise-grade Security Operations Center (SOC) Platform Lab. Instead of manually clicking through menus to install operating systems and configure networks over and over, you are engineering a full Infrastructure as Code (IaC) pipeline to spin up a hardened cyber defense sandbox instantly.

Here is the architectural overview of what we are building together:

🏗️ The Engineering Pipeline (How It's Built)
Your project uses a modern three-stage automation loop designed to eliminate manual administration completely:

[ Official ISO ]
         │
         ▼
 ┌───────────────┐
 │    PACKER     │ ──► Mounts ISO, runs autoinstall, executes Ansible playbooks
 └───────────────┘     to harden the OS and install base monitoring agents.
         │
         ▼
 ┌───────────────┐
 │ GOLDEN IMAGE  │ ──► A clean, pre-hardened VMX template folder.
 └───────────────┘
         │
         ▼
 ┌───────────────┐
 │   TERRAFORM   │ ──► Reads the template and clones it 7 times to build
 └───────────────┘     your entire infrastructure layout instantly.

 🌐 The Network Architecture (vmnet8)
Everything lives inside the private vmnet8 sandbox subnet we just finalized (192.168.100.0/24).

Your host computer sits at 192.168.100.1, giving you a direct management line into the lab via SSH or Ansible.

The internal VMware NAT engine allows your lab machines to securely pull updates from the internet while completely shielding them from outside exposure.

🖥️ The 7-Node SOC Target Architecture
Once Packer drops that finished golden image template into your folder, Terraform will use it to provision 7 distinct, specialized virtual machines on your vmnet8 network:

1. The Core Monitoring & Security Stack (3 Nodes)
Wazuh Master / Manager Node: The central brain of your SIEM/XDR stack. It collects, parses, and analyzes log files, system events, and integrity data sent from your entire infrastructure.

Elasticsearch / Indexer Node: The high-speed database engine that indexes all security logs, alerts, and system behaviors sent from the Wazuh manager for near-instant search retrieval.

Kibana / Wazuh Dashboard Node: Your graphical command center. This is the UI dashboard where you will visualize alerts, monitor system states, and track security events.

2. Network Visibility & Management Stack (2 Nodes)
Suricata NIDS Node: A dedicated Network Intrusion Detection System acting as a security camera on your virtual switch, sniffing packet traffic for malicious signatures or suspicious network behavior.

Zabbix Server Node: Your core infrastructure and performance monitoring platform, tracking CPU loads, RAM utilization, interface health, and server uptime across the entire lab.

3. The Target Infrastructure Nodes (2 Nodes)
Ubuntu Production Target Node: A standard Linux server running your active production containers or apps, equipped with a Wazuh security agent tracking its logs and configurations.

Windows Server Target Node: A simulated corporate server endpoint with a Wazuh agent active, monitoring Active Directory behaviors, Windows Event logs, and potential exploit attempts.

🎯 The Ultimate Goal
When this project is fully built, you will have a production-mirror sandbox to test defensive strategies, write custom detection rules, run vulnerability monitoring, and orchestrate automation scripts.

If a machine gets compromised or cluttered during testing, you won't need to rebuild it manually. You'll just run a single command:

Bash
terraform destroy && terraform apply
Within minutes, your entire clean, pre-hardened 7-node enterprise SOC lab will spin right back up out of the dirt, completely configured and ready for action.