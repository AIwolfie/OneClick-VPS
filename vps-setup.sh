#!/bin/bash

echo "[+] Detecting shell..."
if [[ $SHELL == "/bin/zsh" ]]; then
    SHELL_CONFIG="$HOME/.zshrc"
else
    SHELL_CONFIG="$HOME/.bashrc"
fi
echo "[+] Using $SHELL_CONFIG for environment variables."

echo "[+] Creating directory structure..."
mkdir -p $HOME/tools
mkdir -p $HOME/deps
mkdir -p $HOME/wordlists
mkdir -p $HOME/nuclei-templates
mkdir -p $HOME/priv8-templates

echo "[+] Updating system..."
sudo apt update && sudo apt upgrade -y

echo "[+] Installing dependencies..."
sudo apt install -y curl wget git unzip jq tmux build-essential nano python3 python3-pip python3-venv python3-dev ruby-full

echo "[+] Installing pipx..."
sudo apt install -y pipx
pipx ensurepath

echo "[+] Installing Go..."
cd $HOME/deps
wget https://go.dev/dl/go1.21.5.linux-amd64.tar.gz
sudo rm -rf /usr/local/go
sudo tar -C /usr/local -xzf go1.21.5.linux-amd64.tar.gz
rm go1.21.5.linux-amd64.tar.gz

echo "[+] Configuring Go environment in $SHELL_CONFIG..."
echo 'export PATH=$PATH:/usr/local/go/bin' >> $SHELL_CONFIG
echo 'export GOPATH=$HOME/tools' >> $SHELL_CONFIG
echo 'export PATH=$PATH:$GOPATH/bin' >> $SHELL_CONFIG
source $SHELL_CONFIG

echo "[+] Installing common security tools..."
sudo apt install -y nmap gobuster subfinder 

echo "[+] Installing Go-based tools..."
go install -v github.com/projectdiscovery/subfinder/v2/cmd/subfinder@latest
go install -v github.com/projectdiscovery/nuclei/v3/cmd/nuclei@latest
go install -v github.com/owasp-amass/amass/v4/...@master
go install -v github.com/projectdiscovery/naabu/v2/cmd/naabu@latest
go install -v github.com/tomnomnom/ffuf@latest
go install -v github.com/projectdiscovery/dnsx/cmd/dnsx@latest
go install -v github.com/projectdiscovery/httpx/cmd/httpx@latest
go install -v github.com/projectdiscovery/mapcidr/cmd/mapcidr@latest
go install -v github.com/lc/gau/v2/cmd/gau@latest
go install -v github.com/tomnomnom/waybackurls@latest

echo "[+] Cloning additional tools into tools/..."
cd $HOME/tools
git clone https://github.com/mchklt/auth-bypass.git
git clone https://github.com/Dheerajmadhukar/4-ZERO-3.git
git clone https://github.com/s0md3v/XSStrike.git
git clone https://github.com/ROBOT-X-cyber/xss_vibes.git

echo "[+] Setting up gf patterns..."
mkdir -p $HOME/.gf
cp -r $GOPATH/pkg/mod/github.com/tomnomnom/gf@*/examples/* $HOME/.gf/

echo "[+] Downloading SecLists into wordlists/..."
cd $HOME/wordlists
git clone https://github.com/danielmiessler/SecLists.git

echo "[+] Downloading Nuclei Templates..."
cd $HOME/nuclei-templates
git clone https://github.com/projectdiscovery/nuclei-templates.git

echo "[+] Downloading Private Nuclei Templates (CoffinXP)..."
cd $HOME/priv8-templates
git clone https://github.com/coffinxp/nuclei-templates.git

echo "[+] Installing bbot (stable)..."
pipx install bbot

echo "[+] Installing bbot (bleeding edge)..."
pipx install --pip-args '\--pre' bbot

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

echo "[+] Setup complete!"
echo "[+] Tools are in ~/tools, dependencies in ~/deps, SecLists in ~/wordlists."
echo "[+] Nuclei templates are in ~/nuclei-templates, and private templates in ~/priv8-templates."
echo "[+] All installed tools should be available globally in your shell."
echo "[+] Happy hacking!"