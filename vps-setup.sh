#!/bin/bash

# Check for root privileges
if [ "$EUID" -ne 0 ]; then
    echo "Please run as root: sudo $0"
    exit 1
fi

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
apt update && apt upgrade -y

# Install Dependencies
echo "[+] Installing dependencies..."
apt install -y curl wget git unzip jq tmux build-essential fzf masscan nmap

# Install Python
echo "[+] Installing Python..."
apt install -y python3 python3-pip
pip3 install --pre bbot

# Install Ruby
echo "[+] Installing Ruby..."
apt install -y ruby-full

# Install Go
echo "[+] Installing Go..."
cd $HOME/deps
wget -q --show-progress https://go.dev/dl/go1.21.5.linux-amd64.tar.gz -O go.tar.gz || { echo "Failed to download Go"; exit 1; }
rm -rf /usr/local/go
tar -C /usr/local -xzf go.tar.gz
rm go.tar.gz

# Configure Go Environment
update_shell_config 'export PATH=$PATH:/usr/local/go/bin'
update_shell_config 'export GOPATH=$HOME/tools'
update_shell_config 'export PATH=$PATH:$GOPATH/bin'
source "$SHELL_CONFIG"

# Install Go-based Tools with Controlled Parallelism
echo "[+] Installing Go-based tools..."
cat <<EOF | xargs -P 4 -I{} go install -v {}
github.com/projectdiscovery/subfinder/v2/cmd/subfinder@latest
github.com/projectdiscovery/nuclei/v3/cmd/nuclei@latest
github.com/owasp-amass/amass/v4/...@master
github.com/projectdiscovery/naabu/v2/cmd/naabu@latest
github.com/tomnomnom/ffuf@latest
github.com/projectdiscovery/dnsx/cmd/dnsx@latest
github.com/projectdiscovery/httpx/cmd/httpx@latest
github.com/projectdiscovery/mapcidr/cmd/mapcidr@latest
github.com/lc/gau/v2/cmd/gau@latest
github.com/tomnomnom/waybackurls@latest
github.com/projectdiscovery/katana/cmd/katana@latest
github.com/tomnomnom/httprobe@latest
github.com/Emoe/kxss@latest
github.com/tomnomnom/gf@latest
github.com/lc/uro@latest
github.com/Emoe/Gxss@latest
EOF
echo "[+] Go-based tools installation completed!"

# Install Additional Security Tools
echo "[+] Installing additional security tools..."
clone_repo() {
    repo_name=$(basename "$1" .git)
    if [ -d "$HOME/tools/$repo_name" ]; then
        echo "[+] $repo_name already exists, skipping..."
    else
        echo "[+] Cloning $repo_name..."
        git clone "$1" "$HOME/tools/$repo_name"
    fi
}
cd $HOME/tools
clone_repo "https://github.com/mchklt/auth-bypass.git"
clone_repo "https://github.com/Dheerajmadhukar/4-ZERO-3.git"
clone_repo "https://github.com/s0md3v/XSStrike.git"
clone_repo "https://github.com/ROBOT-X-cyber/xss_vibes.git"
clone_repo "https://github.com/xnl-h4ck3r/waymore.git"
cd $HOME/tools/waymore && pip3 install -r requirements.txt

# Download SecLists with Update Check
echo "[+] Downloading SecLists..."
if [ -d "$HOME/wordlists/SecLists" ]; then
    cd "$HOME/wordlists/SecLists" && git pull
else
    git clone https://github.com/danielmiessler/SecLists.git "$HOME/wordlists/SecLists"
fi

# Download Nuclei Templates with Update Check
echo "[+] Downloading Nuclei Templates..."
if [ -d "$HOME/nuclei-templates" ]; then
    cd "$HOME/nuclei-templates" && git pull
else
    git clone https://github.com/projectdiscovery/nuclei-templates.git "$HOME/nuclei-templates"
fi

echo "[+] Downloading Private Nuclei Templates (CoffinXP)..."
if [ -d "$HOME/priv8-templates" ]; then
    cd "$HOME/priv8-templates" && git pull
else
    git clone https://github.com/coffinxp/nuclei-templates.git "$HOME/priv8-templates"
fi

# Set Up gf Patterns
echo "[+] Setting up gf patterns..."
mkdir -p $HOME/.gf
curl -sL https://raw.githubusercontent.com/tomnomnom/gf/master/examples/xss.json -o $HOME/.gf/xss.json || { echo "Failed to download xss.json"; exit 1; }
curl -sL https://raw.githubusercontent.com/tomnomnom/gf/master/examples/ssrf.json -o $HOME/.gf/ssrf.json || { echo "Failed to download ssrf.json"; exit 1; }

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

# Configure Tools
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
echo -e "#!/bin/bash\ncat <<EOF | xargs -P 4 -I{} go install -v {}\ngithub.com/projectdiscovery/nuclei/v3/cmd/nuclei@latest\ngithub.com/projectdiscovery/subfinder/v2/cmd/subfinder@latest\ngithub.com/owasp-amass/amass/v4/...@master\ngithub.com/Emoe/kxss@latest\ngithub.com/lc/uro@latest\ngithub.com/Emoe/Gxss@latest\ngithub.com/tomnomnom/gf@latest\nEOF" > $HOME/tools/update_tools.sh
chmod +x $HOME/tools/update_tools.sh

echo "[+] Setup complete!"
echo "[+] Tools are in ~/tools, dependencies in ~/deps, SecLists in ~/wordlists."
echo "[+] Nuclei templates are in ~/nuclei-templates, private templates in ~/priv8-templates."
echo "[+] To update tools, run: ~/tools/update_tools.sh"
echo "[+] Happy hacking!"