#!/bin/bash

echo "[+] Creating directory structure..."
mkdir -p $HOME/tools
mkdir -p $HOME/deps
mkdir -p $HOME/wordlists
mkdir -p $HOME/nuclei-templates
mkdir -p $HOME/priv8-templates

echo "[+] Updating system..."
sudo apt update && sudo apt upgrade -y

echo "[+] Installing dependencies in deps/..."
sudo apt install -y curl wget git unzip jq tmux build-essential

echo "[+] Installing Python in deps/..."
sudo apt install -y python3 python3-pip

echo "[+] Installing Go in deps/..."
cd $HOME/deps
wget https://go.dev/dl/go1.21.5.linux-amd64.tar.gz
sudo rm -rf /usr/local/go
sudo tar -C /usr/local -xzf go1.21.5.linux-amd64.tar.gz
rm go1.21.5.linux-amd64.tar.gz

echo "[+] Configuring Go environment..."
echo 'export PATH=$PATH:/usr/local/go/bin' >> ~/.bashrc
echo 'export GOPATH=$HOME/tools' >> ~/.bashrc
echo 'export PATH=$PATH:$GOPATH/bin' >> ~/.bashrc
source ~/.bashrc

echo "[+] Installing Ruby in deps/..."
sudo apt install -y ruby-full

echo "[+] Installing common security tools in tools/..."
cd $HOME/tools
sudo apt install -y nmap gobuster subfinder 

echo "[+] Installing Go-based tools in tools/..."
go install -v github.com/projectdiscovery/subfinder/v2/cmd/subfinder@latest
go install -v github.com/projectdiscovery/nuclei/v3/cmd/nuclei@latest
go install -v github.com/owasp-amass/amass/v4/...@master

echo "[+] Setting up gf patterns..."
mkdir -p $HOME/.gf
cp -r $GOPATH/pkg/mod/github.com/tomnomnom/gf@*/examples/* $HOME/.gf/

echo "[+] Downloading SecLists into wordlists/..."
cd $HOME/wordlists
git clone https://github.com/danielmiessler/SecLists.git

echo "[+] Installing additional tools in tools/..."
cd $HOME/tools
git clone https://github.com/mchklt/auth-bypass.git
git clone https://github.com/Dheerajmadhukar/4-ZERO-3.git

echo "[+] Downloading Nuclei Templates..."
cd $HOME/nuclei-templates
git clone https://github.com/projectdiscovery/nuclei-templates.git

echo "[+] Downloading Private Nuclei Templates (CoffinXP)..."
cd $HOME/priv8-templates
git clone https://github.com/coffinxp/nuclei-templates.git

echo "[+] Checking installed tools..."
echo "---- subfinder ----"
subfinder -h | head -n 5
echo "---- nuclei ----"
nuclei -h | head -n 5
echo "---- amass ----"
amass -h | head -n 5

echo "[+] Configuration check for tools..."
declare -A config_files
config_files["Amass"]="$HOME/.config/amass/config.ini"
config_files["Subfinder"]="$HOME/.config/subfinder/config.yaml"
config_files["Nuclei"]="$HOME/.config/nuclei/config.yaml"

for tool in "${!config_files[@]}"; do
    if [ -f "${config_files[$tool]}" ]; then
        read -p "[?] Do you want to edit ${tool}'s config file now? (y/n) " choice
        if [[ "$choice" == "y" ]]; then
            nano "${config_files[$tool]}"
        fi
    fi
done

echo "[+] Updating PATH for all tools..."
echo 'export PATH=$PATH:$HOME/tools/bin' >> ~/.bashrc
source ~/.bashrc

echo "[+] Setup complete! Tools are in ~/tools, dependencies in ~/deps, SecLists in ~/wordlists."
echo "[+] Nuclei templates are in ~/nuclei-templates, and private templates in ~/priv8-templates."
