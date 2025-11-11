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

# Install Node.js v24.11
echo "Installing Node.js v24.11..."
nvm install 24.11.0
nvm use 24.11.0

# Download and install VSCode without Homebrew (direct download, unzip to ~/Applications or ~/Desktop)
if ! command -v code &>/dev/null; then
  echo "Downloading VSCode (direct download)..."
  VSCODE_URL="https://update.code.visualstudio.com/latest/darwin/universal/stable"
  curl -L $VSCODE_URL -o ~/Downloads/VSCode.zip
  unzip -q ~/Downloads/VSCode.zip -d ~/Applications 2>/dev/null || unzip -q ~/Downloads/VSCode.zip -d ~/Desktop
  echo 'VSCode installed to ~/Applications or ~/Desktop. Drag to /Applications manually if desired.'
fi

# Download Docker Desktop (no sudo install, but user will need to drag .app to Applications)
if ! command -v docker &>/dev/null; then
  echo "Downloading Docker Desktop (drag to install)..."
  DOCKER_URL="https://desktop.docker.com/mac/main/arm64/Docker.dmg"
  curl -L $DOCKER_URL -o ~/Downloads/Docker.dmg
  echo 'Please open ~/Downloads/Docker.dmg and drag Docker.app to Applications or Desktop.'
fi

# Download Llama Desktop (drag to install)
if [ ! -e ~/Downloads/Llama.zip ]; then
  echo "Downloading Llama Desktop (drag to install)..."
  LLAMA_URL="https://github.com/llama/llama/releases/latest/download/Llama-macOS.zip"
  curl -L $LLAMA_URL -o ~/Downloads/Llama.zip
  unzip -q ~/Downloads/Llama.zip -d ~/Desktop
  echo 'Llama Desktop unpacked on your Desktop. Move to Applications if you like.'
fi

# Install Wrangler and GitHub CLI for Node 24.11, then for all LTS versions
echo "Installing Wrangler CLI and GH CLI for Node 24.11 and all LTS versions..."
for version in 24.11.0 $(nvm ls-remote --lts | awk '{print $1}'); do
  nvm install "$version"
  nvm use "$version"
  npm install -g wrangler
  if ! command -v gh &>/dev/null; then
    brew install gh
  fi
done

echo "Development setup complete! GUI apps may require drag-and-drop install."

