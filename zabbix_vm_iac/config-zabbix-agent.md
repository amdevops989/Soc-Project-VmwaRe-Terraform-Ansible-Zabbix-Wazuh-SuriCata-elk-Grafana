# 1. Download and install the Zabbix 7.0 LTS repository
wget https://repo.zabbix.com/zabbix/7.0/ubuntu/pool/main/z/zabbix-release/zabbix-release_7.0-1+ubuntu24.04_all.deb
sudo dpkg -i zabbix-release_7.0-1+ubuntu24.04_all.deb
sudo apt update

# 2. Install Zabbix Agent 2 (the modern Go-based agent)
sudo apt install -y zabbix-agent2


sudo nano /etc/zabbix/zabbix_agent2.conf

Server=192.168.100.10
ServerActive=192.168.100.10
Hostname=Web-Server-60


sudo systemctl enable zabbix-agent2 --now

sudo ufw allow from 192.168.100.10 to any port 10050 proto tcp comment 'Allow Zabbix Server Monitoring'
sudo ufw reload

## stressing web server

sudo apt update && sudo apt install -y stress-ng

# This spikes both CPU cores to 100% and allocates 1GB of RAM for 60 seconds
stress-ng --cpu 2 --vm 1 --vm-bytes 1G --timeout 60s --metrics-brief
