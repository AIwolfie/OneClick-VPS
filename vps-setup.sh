#!/bin/bash

# Detect Shell Config File
if [ "$SHELL" == "/bin/zsh" ]; then
    SHELL_CONFIG="$HOME/.zshrc"
else
    SHELL_CONFIG="$HOME/.bashrc"
fi

# Function to Check and Add PATH Variables
update_shell_config() {
    local line="$1"
    local file="$SHELL_CONFIG"
    grep -qxF "$line" "$file" || echo "$line" >> "$file"
}

# Create Directory Structure
echo "[+] Creating directory structure..."
mkdir -p $HOME/tools $HOME/deps $HOME/wordlists $HOME/nuclei-templates $HOME/priv8-templates

# Update System
echo "[+] Updating system..."
sudo apt update && sudo apt upgrade -y

# Install Dependencies
echo "[+] Installing dependencies..."
sudo apt install -y curl wget git unzip jq tmux build-essential fzf masscan nmap

# Install Python
echo "[+] Installing Python..."
sudo apt install -y python3 python3-pip
pip3 install --pre bbot

# Install Ruby
echo "[+] Installing Ruby..."
sudo apt install -y ruby-full

# Install Go
echo "[+] Installing Go..."
cd $HOME/deps
wget https://go.dev/dl/go1.21.5.linux-amd64.tar.gz || { echo "Failed to download Go"; exit 1; }
sudo rm -rf /usr/local/go
sudo tar -C /usr/local -xzf go1.21.5.linux-amd64.tar.gz
rm go1.21.5.linux-amd64.tar.gz

# Configure Go Environment
update_shell_config 'export PATH=$PATH:/usr/local/go/bin'
update_shell_config 'export GOPATH=$HOME/tools'
update_shell_config 'export PATH=$PATH:$GOPATH/bin'
source "$SHELL_CONFIG"

# Install Go-based Tools in Parallel
echo "[+] Installing Go-based tools..."
go install -v github.com/projectdiscovery/subfinder/v2/cmd/subfinder@latest &
go install -v github.com/projectdiscovery/nuclei/v3/cmd/nuclei@latest &
go install -v github.com/owasp-amass/amass/v4/...@master &
go install -v github.com/projectdiscovery/naabu/v2/cmd/naabu@latest &
go install -v github.com/tomnomnom/ffuf@latest &
go install -v github.com/projectdiscovery/dnsx/cmd/dnsx@latest &
go install -v github.com/projectdiscovery/httpx/cmd/httpx@latest &
go install -v github.com/projectdiscovery/mapcidr/cmd/mapcidr@latest &
go install -v github.com/lc/gau/v2/cmd/gau@latest &
go install -v github.com/tomnomnom/waybackurls@latest &
go install -v github.com/projectdiscovery/katana/cmd/katana@latest &
go install -v github.com/tomnomnom/httprobe@latest &
go install -v github.com/Emoe/kxss@latest &
go install -v github.com/tomnomnom/gf@latest &  # Added gf explicitly
go install -v github.com/lc/uro@latest &
go install -v github.com/Emoe/Gxss@latest &
wait
echo "[+] Go-based tools installation completed!"

# Install Additional Security Tools
echo "[+] Installing additional security tools..."
clone_repo() {
    if [ -d "$HOME/tools/$2" ]; then
        echo "[+] $1 already exists, skipping..."
    else
        echo "[+] Cloning $1..."
        git clone $2 $HOME/tools/$2
    fi
}
cd $HOME/tools
clone_repo "auth-bypass" "https://github.com/mchklt/auth-bypass.git"
clone_repo "4-ZERO-3" "https://github.com/Dheerajmadhukar/4-ZERO-3.git"
clone_repo "XSStrike" "https://github.com/s0md3v/XSStrike.git"
clone_repo "xss_vibes" "https://github.com/ROBOT-X-cyber/xss_vibes.git"
clone_repo "waymore" "https://github.com/xnl-h4ck3r/waymore.git"
cd $HOME/tools/waymore && pip3 install -r requirements.txt

# Download SecLists
echo "[+] Downloading SecLists..."
git clone https://github.com/danielmiessler/SecLists.git $HOME/wordlists/SecLists

# Download Nuclei Templates
echo "[+] Downloading Nuclei Templates..."
git clone https://github.com/projectdiscovery/nuclei-templates.git $HOME/nuclei-templates

echo "[+] Downloading Private Nuclei Templates (CoffinXP)..."
git clone https://github.com/coffinxp/nuclei-templates.git $HOME/priv8-templates

# Set Up gf Patterns
echo "[+] Setting up gf patterns..."
mkdir -p $HOME/.gf
# Use direct download instead of relying on GOPATH/pkg/mod
curl -sL https://raw.githubusercontent.com/tomnomnom/gf/master/examples/xss.json -o $HOME/.gf/xss.json
# Add more patterns if desired
curl -sL https://raw.githubusercontent.com/tomnomnom/gf/master/examples/ssrf.json -o $HOME/.gf/ssrf.json

# Check Installed Tools
echo "[+] Verifying installed tools..."
echo "---- subfinder ----"
subfinder -h | head -n 5
echo "---- nuclei ----"
nuclei -h | head -n 5
echo "---- amass ----"
amass -h | head -n 5
echo "---- kxss ----"
kxss -h | head -n 5
echo "---- uro ----"
uro -h | head -n 5
echo "---- Gxss ----"
Gxss -h | head -n 5
echo "---- gf ----"
gf -h | head -n 5

# Configure Tools (if necessary)
declare -A config_files
config_files=(
    [Amass]="$HOME/.config/amass/config.ini"
    [Subfinder]="$HOME/.config/subfinder/config.yaml"
    [Nuclei]="$HOME/.config/nuclei/config.yaml"
)

for tool in "${!config_files[@]}"; do
    if [ ! -f "${config_files[$tool]}" ]; then
        echo "[+] Creating default config file for $tool..."
        mkdir -p "$(dirname "${config_files[$tool]}")"
        touch "${config_files[$tool]}"
    fi
    read -p "[?] Do you want to edit ${tool}'s config file now? (y/n) " choice
    if [[ "$choice" == "y" ]]; then
        nano "${config_files[$tool]}"
    fi
done

# Enable Auto-Completion
echo "[+] Enabling auto-completion..."
nuclei -autocomplete-install
subfinder -autocomplete-install
amass -autocomplete-install
source "$SHELL_CONFIG"

# Update Option
echo "[+] Adding update script..."
echo -e "#!/bin/bash\ngo install -v github.com/projectdiscovery/nuclei/v3/cmd/nuclei@latest\ngo install -v github.com/projectdiscovery/subfinder/v2/cmd/subfinder@latest\ngo install -v github.com/owasp-amass/amass/v4/...@master\ngo install -v github.com/Emoe/kxss@latest\ngo install -v github.com/lc/uro@latest\ngo install -v github.com/Emoe/Gxss@latest\ngo install -v github.com/tomnomnom/gf@latest" > $HOME/tools/update_tools.sh
chmod +x $HOME/tools/update_tools.sh

echo "[+] Setup complete!"
echo "[+] Tools are in ~/tools, dependencies in ~/deps, SecLists in ~/wordlists."
echo "[+] Nuclei templates are in ~/nuclei-templates, private templates in ~/priv8-templates."
echo "[+] To update tools, run: ~/tools/update_tools.sh"
echo "[+] Don't forget to add your API keys to the config files."
echo "[+] Happy hacking!"