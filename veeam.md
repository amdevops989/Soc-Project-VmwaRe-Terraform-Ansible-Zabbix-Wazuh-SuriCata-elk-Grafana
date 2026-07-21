Open a terminal directly on your localhost and install the NFS kernel server:

Bash
sudo apt update
sudo apt install -y nfs-kernel-server
Create a folder on your host to store the VM backups:

Bash
sudo mkdir -p /srv/veeam_backups
sudo chown -R nobody:nogroup /srv/veeam_backups
sudo chmod 777 /srv/veeam_backups
Expose this directory specifically to your web server VM (192.168.100.60). Open the exports configuration on your host:

Bash
sudo nano /etc/exports
Add this line to authorize your web server VM to write to it:

Plaintext ## add all servers you want to backup
/srv/veeam_backups 192.168.100.60(rw,sync,no_subtree_check)
Apply the exports and restart the service on your host:

Bash
sudo exportfs -a
sudo systemctl restart nfs-kernel-server
# 1. Download the verified release deb package from the public agent repository
wget https://repository.veeam.com/backup/linux/agent/dpkg/debian/public/pool/veeam/v/veeam-release-deb/veeam-release-deb_1.0.11_amd64.deb

# 2. Install it locally to register the correct apt keys and sources
sudo dpkg -i veeam-release-deb_1.0.11_amd64.deb

# 3. Update your repository lists
sudo apt update

sudo apt update
sudo apt install -y veeam-nosnap
sudo apt update && sudo apt install -y nfs-common

sudo systemctl enable veeamservice
sudo systemctl start veeamservice

sudo systemctl status veeamservice

sudo veeam

Leave the [ ] Patch Veeam Recovery Media ISO box unchecked (blank).

Press your Tab key to highlight [Next] at the bottom right.

Press Enter.

Leave the File location text field blank.

Select the radio button for (X) Workstation (or change it to Server if you prefer—both will fallback to the Free Edition with slightly different feature sets, but Workstation is perfect for a single-job setup).

Press Tab to highlight the [Finish] button at the bottom right.

Press Enter.
