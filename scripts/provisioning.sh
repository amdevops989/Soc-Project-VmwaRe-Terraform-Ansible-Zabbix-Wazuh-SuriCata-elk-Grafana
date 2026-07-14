

echo "Updating the system..."
apt -qq -y update &> /dev/null
apt -qq -y upgrade &> /dev/null

echo "Installing packages..."
apt -qq -y install locate net-tools unzip &> /dev/null

echo "Cleaning apt cache..."
apt -qq -y clean &> /dev/null