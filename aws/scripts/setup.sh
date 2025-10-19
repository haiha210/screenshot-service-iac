#!/bin/bash
set -x

function Install_dependent-packages() {
  sudo apt install wget curl unzip jq make zip -y
}


function Install_terraform_packer() {
# Install Terraform
# https://developer.hashicorp.com/terraform/install
  wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
  echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
  sudo apt update && sudo apt install terraform packer -y
}

function Install_awscli() {
# Install AWS CLI
# https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html
  curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
  unzip awscliv2.zip -d ~
  sudo ~/aws/install
  rm -rf awscliv2.zip ~/aws
}

function Install_session_manager_plugin() {
# Install Session Manager plugin
# https://docs.aws.amazon.com/systems-manager/latest/userguide/install-plugin-debian-and-ubuntu.html
  curl "https://s3.amazonaws.com/session-manager-downloads/plugin/latest/ubuntu_64/session-manager-plugin.deb" -o ~/session-manager-plugin.deb
  sudo dpkg -i ~/session-manager-plugin.deb
  rm -f ~/session-manager-plugin.deb
}


function Install_tfenv() {
# Install tfenv
# https://github.com/tfenv/tfenv/releases
  git clone --depth=1 https://github.com/tfutils/tfenv.git ~/.tfenv
  sudo ln -s ~/.tfenv/bin/* /usr/local/bin
}

function Install_aws_vault() {
# Install AWS Vault
# https://github.com/99designs/aws-vault
  AWS_VAULT_VERSION=$(curl -s https://api.github.com/repos/99designs/aws-vault/releases/latest | jq -r '.tag_name' | sed 's/v//')
  wget "https://github.com/99designs/aws-vault/releases/download/v${AWS_VAULT_VERSION}/aws-vault-linux-amd64" -O aws-vault
  sudo mv aws-vault /usr/local/bin/
  sudo chmod 755 /usr/local/bin/aws-vault

  # Verify installation
  aws-vault --version

  echo "AWS Vault installed successfully!"
  echo "Usage: aws-vault add <profile-name>"
  echo "       aws-vault exec <profile-name> -- <command>"
}

# Run function
Install_dependent-packages
Install_terraform_packer
Install_awscli
Install_session_manager_plugin
Install_tfenv
Install_aws_vault
