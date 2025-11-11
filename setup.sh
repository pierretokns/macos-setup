#!/bin/bash
set -e

# Homebrew non-sudo user-local install in ~/homebrew
if [ ! -d "$HOME/homebrew" ]; then
  echo "Installing Homebrew locally (no sudo)..."
  mkdir -p "$HOME/homebrew"
  curl -L https://github.com/Homebrew/brew/tarball/master | tar xz --strip 1 -C "$HOME/homebrew"
  echo 'export PATH="$HOME/homebrew/bin:$PATH"' >> ~/.bash_profile
  export PATH="$HOME/homebrew/bin:$PATH"
fi

# Make sure Homebrew is in PATH for this session
export PATH="$HOME/homebrew/bin:$PATH"

# Install NVM if missing
if [ ! -d "$HOME/.nvm" ]; then
  echo "Installing NVM..."
  curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash
  export NVM_DIR="$HOME/.nvm"
  [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
fi

# Source NVM for this shell
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"


# Download and install VSCode without Homebrew (direct download, unzip to ~/Applications or ~/Desktop)
if ! command -v code &>/dev/null; then
  echo "Downloading VSCode (direct download)..."
  VSCODE_URL="https://update.code.visualstudio.com/latest/darwin/universal/stable"
  curl -L $VSCODE_URL -o ~/Downloads/VSCode.zip
  unzip -q ~/Downloads/VSCode.zip -d ~/Applications 2>/dev/null || unzip -q ~/Downloads/VSCode.zip -d ~/Desktop
  echo 'VSCode installed to ~/Applications or ~/Desktop. Drag to /Applications manually if desired.'
fi

# Install Wrangler and GitHub CLI for Node 24.11, then for all LTS versions
echo "Installing Wrangler CLI and GH CLI for Node 24.11 and all LTS versions..."
# Install Wrangler for the last 2 LTS Node versions
for version in "24.11" "24" "v22" "v20"; do
  nvm install "$version"
  nvm use "$version"
  npm install -g @anthropic-ai/claude-code
  npm install -g wrangler
  npm install -g pnpm
done


# Install GitHub CLI once if missing
if ! command -v gh &>/dev/null; then
  brew install gh || true
fi

# Git + SSH setup (user: pierretokns, email: pierretokns@gmail.com)
echo "Configuring git and SSH..."

# Configure git global settings
git config --global user.name "pierretokns"
git config --global user.email "pierretokns@gmail.com"
git config --global credential.helper osxkeychain || true
git config --global init.defaultBranch main
git config --global core.editor "code --wait"

# Generate SSH key if it doesn't exist
SSH_KEY="$HOME/.ssh/id_ed25519"
if [ ! -f "$SSH_KEY" ]; then
  echo "Generating SSH key at $SSH_KEY..."
  mkdir -p "$HOME/.ssh"
  ssh-keygen -t ed25519 -C "pierretokns@gmail.com" -f "$SSH_KEY" -N ""
  # Start ssh-agent and add key, prefer macOS keychain options when available
  eval "$(ssh-agent -s)" >/dev/null 2>&1 || true
  if ssh-add --help 2>&1 | grep -q -- '--apple-use-keychain'; then
    ssh-add --apple-use-keychain "$SSH_KEY" || true
  else
    ssh-add -K "$SSH_KEY" 2>/dev/null || ssh-add "$SSH_KEY" || true
  fi
fi

# Copy public key to clipboard and attempt upload via gh if available and authenticated
if [ -f "$SSH_KEY.pub" ]; then
  pbcopy < "$SSH_KEY.pub" || true
  echo "Public SSH key copied to clipboard: $SSH_KEY.pub"
  if command -v gh &>/dev/null; then
    if gh auth status 2>/dev/null | grep -qi 'Logged in'; then
      echo "Uploading SSH key to GitHub via gh..."
      gh ssh-key add "$SSH_KEY.pub" --title "macos-setup-$(hostname)" || true
    else
      echo "gh CLI not authenticated; run 'gh auth login' to upload the key automatically."
    fi
  else
    echo "gh CLI not installed; install or paste the clipboard key into GitHub -> Settings -> SSH keys."
  fi
fi


# Install Colima + Lima + Docker CLI for rootless Docker on macOS
if ! command -v colima &>/dev/null || ! command -v limactl &>/dev/null || ! command -v docker &>/dev/null; then
  echo "Installing lima, colima and Docker CLI (rootless Docker via Colima)..."
  # Ensure Homebrew is up to date
  brew update || true
  brew install lima colima docker docker-compose || true
fi

# Start Colima (rootless VM) if not running
if command -v colima &>/dev/null; then
  COLIMA_STATUS=$(colima status 2>/dev/null || true)
  if ! echo "$COLIMA_STATUS" | grep -qi 'running'; then
    echo "Starting Colima (rootless Docker VM)..."
    # Adjust resources as needed
    colima start --runtime docker --cpus 4 --memory 4 --disk 60
  else
    echo "Colima already running."
  fi
fi

# If Docker Desktop was previously downloaded, warn user
if [ -f ~/Downloads/Docker.dmg ]; then
  echo "Note: ~/Downloads/Docker.dmg exists. You are now using Colima (rootless) instead of Docker Desktop."
fi

brew install ollama
# brew install --cask rancher # for docker desktop replacement bc using rootless lima for security reasons

ZSHRC="$HOME/.zshrc"

# Function to add a line to .zshrc if it doesn't already exist
add_line_if_not_exists() {
  local line="$1"
  grep -qxF "$line" "$ZSHRC" || echo "$line" >> "$ZSHRC"
}

# Add Homebrew to PATH (assuming user-local install in ~/homebrew)
add_line_if_not_exists 'export PATH="$HOME/homebrew/bin:$PATH"'

# Add NVM initialization lines
add_line_if_not_exists 'export NVM_DIR="$HOME/.nvm"'
add_line_if_not_exists '[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm'
add_line_if_not_exists '[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion'

# Add GitHub CLI (gh) completions if installed via brew (adjust path if installed differently)
add_line_if_not_exists 'if command -v gh &>/dev/null; then'
add_line_if_not_exists '  source "$(brew --prefix)/share/zsh/site-functions/_gh"'
add_line_if_not_exists 'fi'

echo "Updated $ZSHRC with Homebrew, NVM, and GitHub CLI initialization."
echo "Please restart your terminal or run 'source ~/.zshrc' to apply changes."

source ~/.zshrc

# Authenticate with GitHub CLI
echo "Running 'gh auth login'..."
gh auth login

# Authenticate with Wrangler
echo "Running 'wrangler login'..."
wrangler login

echo "Development setup complete! GUI apps may require drag-and-drop install."

