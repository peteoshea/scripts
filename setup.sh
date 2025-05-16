#!/bin/bash

# Drop out if one of the commands fails
set -e

# Ensure we are working from the setup folder
cd "$(dirname "$0")"
top_dir=$(pwd)
echo "Current path: $top_dir"

# Common function to output important messages
function output_message {
  message=$1
  if [[ -z $message ]]
  then
    echo "output_message called without a message?"
    exit
  fi

  echo
  echo "==> $message"
}

output_message "Running setup script…"

# Install linux distro specific packages
package_manager=unknown
packages_updated=false

function update_packages {
  if [[ $packages_updated = true ]]
  then
    return
  fi

  case $package_manager in
    apt)
      output_message "Updating apt packages…"
      sudo apt update
      sudo apt -y upgrade
      sudo apt -y auto-remove
      ;;
    yum)
      output_message "Updating yum packages…"
      sudo yum update
      ;;
  esac
  packages_updated=true
}

# shellcheck disable=SC1091
. /etc/os-release
distro=$ID
echo "Current distro is: $distro"

case $distro in
  centos | rhel | fedora)
    package_manager=yum
    ;;
  ubuntu | debian)
    package_manager=apt
    ;;
esac
update_packages

# Set default permissions for WSL automount
wsl_conf_file="/etc/wsl.conf"
function populate_automount_options {
  echo "[automount]" | sudo tee -a $wsl_conf_file
  echo 'options = "metadata,umask=22"' | sudo tee -a $wsl_conf_file
  echo
  echo '************************************************'
  echo '** Please restart WSL for this to take effect **'
  echo '************************************************'
  exit 1
}

if [[ ! -f $wsl_conf_file ]]
then
  echo "Populate $wsl_conf_file"
  populate_automount_options
elif grep -q "\[automount\]" $wsl_conf_file
then
  echo "WSL automount options are set"
else
  echo "Add WSL automount options to $wsl_conf_file"
  echo | sudo tee -a $wsl_conf_file
  populate_automount_options
fi

# Defaults editor to vim rather than nano
sudo update-alternatives --set editor /usr/bin/vim.basic

# Setup Git
# ssh_directory="$HOME/.ssh"
# if [[ ! -d $ssh_directory ]]
# then
#   mkdir $ssh_directory
#   chmod 700 $ssh_directory
# fi
# cd $ssh_directory
# cp /mnt/c/Users/pete/.ssh/id_rsa* .
# chmod 600 id_rsa
# chmod 644 id_rsa.pub

# Configue git

# TODO - Check if config items already exists first!

read -rp "Enter your name for git on this machine: " git_username
read -rp "Enter your email for git on this machine: " git_email
git config --global user.name "$git_username"
git config --global user.email "$git_email"
git config --global core.autocrlf false
git config --global fetch.prune true

read -rp "Enter GPG signing key: " gpg_key
git config --global commit.gpgsign true
git config --global tag.gpgSign true
git config --global gpg.program "/usr/bin/gpg"
git config --global user.signingkey "$gpg_key"

# Install Homebrew
if command -v brew > /dev/null
then
  output_message "Updating Homebrew…"
  brew update
else
  output_message "Installing Homebrew…"
  curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh | bash

  # Install recommended packages
  update_packages
  case $package_manager in
    apt)
      sudo apt -y install build-essential
      ;;
    yum)
      sudo yum -y groupinstall 'Development Tools'
      ;;
  esac

  # Add Homebrew environment variables to current shell
  eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"

  # Install gcc as recommended in the next steps
  brew install gcc
fi

if brew bundle check > /dev/null 2>&1
then
  echo "Homebrew dependencies are up to date"
else
  output_message "Installing Homebrew dependencies…"
  brew bundle
fi

if [[ -d ~/dotfiles ]]
then
  echo "Dotfiles repository already exists"
else
  echo "Cloning dotfiles repository"
  git clone git@github.com:peteoshea/dotfiles.git ~/dotfiles
fi
cd ~/dotfiles
stow .

# Add overrides to bash config
bash_config=~/.bashrc
if grep -q "^# Personalised additions$" $bash_config
then
  echo "Personalised additions already exist in ~/.bashrc"
else
  echo "Adding personalised additions to ~/.bashrc"
  {
    echo
    echo "# Personalised additions"
    echo "if [[ -d ~/.bashrc.d ]]"
    echo "then"
    echo "  for bash_addition in ~/.bashrc.d/*"
    echo "  do"
    echo "    if [[ -r \$bash_addition ]]"
    echo "    then"
    echo "      echo Applying \"\$bash_addition\""
    echo "      source \"\$bash_addition\""
    echo "    fi"
    echo "  done"
    echo "  unset bash_addition"
    echo "fi"
  } >> $bash_config

  # Run the additions manually to avoid needing to restart the shell
  if [[ -d ~/dotfiles/.bashrc.d ]]
  then
    for bash_addition in ~/dotfiles/.bashrc.d/*
    do
      if [[ -r $bash_addition ]]
      then
        echo Applying "$bash_addition"
        # shellcheck disable=SC1090
        source "$bash_addition"
      fi
    done
    unset bash_addition
  fi
fi

# TODO
# git clone git@github.com:peteoshea/scripts.git
