# Infrastructure as code (IaC)

 is the process of managing and provisioning of infrastructure through machine-readable definition files, rather than physical hardware configuration or interactive configuration tools. The definitions may be in a version control system. It can use either scripts or declarative definitions, rather than manual processes

- Benefits:
  - Cost reduction
  - Increase in speed of deployments
  - Reduce errors
  - Improve infrastructure consistency
  - Eliminate configuration drift

![IaC](/images/iac.png)

## IaC Experiences

### Cloud Platform

- [x] AWS
- [ ] Azure
- [ ] GCP

### Operation System (OS)

- [x] Ubuntu
- [ ] CentOS
- [ ] Windows
- [x] MacOS

### Basic Configuration

- [x] Ruby on Rails
- [x] PHP
- [x] Javascripts
- [ ] Python

### Antivirus

- [x] ESET
- [ ] Trendmicro

## IaC Tools

- [**Terraform**](https://github.com/framgia/sun-infra-iac/blob/master/terraform.md)

## How to do

### Install

<details><summary>Ubuntu 20.04</summary><br>

```bash
sudo add-apt-repository ppa:xapienz/curl34
sudo apt update
sudo apt install -y libcurl4=7.68.0-1ubuntu2.5ppa1
sudo apt install -y unzip software-properties-common python3 python3-pip
python3 -m pip install --upgrade pip
curl -L "$(curl -s https://api.github.com/repos/terraform-docs/terraform-docs/releases/latest | grep -o -E -m 1 "https://.+?-linux-amd64.tar.gz")" > terraform-docs.tgz && tar -xzf terraform-docs.tgz terraform-docs && rm terraform-docs.tgz && chmod +x terraform-docs && sudo mv terraform-docs /usr/bin/
curl -L "$(curl -s https://api.github.com/repos/terraform-linters/tflint/releases/latest | grep -o -E -m 1 "https://.+?_linux_amd64.zip")" > tflint.zip && unzip tflint.zip && rm tflint.zip && sudo mv tflint /usr/bin/
wget -qO- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.2/install.sh | bash
nvm install node && nvm use node
npm install --save-dev @commitlint/{cli,config-conventional}
echo "module.exports = { extends: ['@commitlint/config-conventional'] };" > commitlint.config.js
wget https://golang.org/dl/go1.19.3.linux-amd64.tar.gz
rm -rf /usr/local/go && tar -C /usr/local -xzf go1.19.3.linux-amd64.tar.gz && export PATH=$PATH:/usr/local/go/bin
go install github.com/git-chglog/git-chglog/cmd/git-chglog@0.9.1 && sudo cp ~/go/bin/git-chglog /usr/local/bin/
```

</details>

<details><summary>MacOS</summary><br>

```bash
brew install terraform-docs
brew install tflint
brew install go
brew install nvm
echo "source $(brew --prefix nvm)/nvm.sh" >> ~/.zshrc
nvm install node && nvm use node
npm install --save-dev @commitlint/{cli,config-conventional}
echo "module.exports = { extends: ['@commitlint/config-conventional'] };" > commitlint.config.js
go install github.com/git-chglog/git-chglog/cmd/git-chglog@0.9.1 && sudo cp ~/go/bin/git-chglog /usr/local/bin/
```

</details>

### Setup

- pre-commit

  ```bash
  make pre-commit
  ```

### Pick IaC for project

- Clone this branch, keep only Cloud Provider folder that project using and follow the instructions

  - [AWS](/examples/aws/README.md)

  **Note**: Remove the remaining Cloud provider folders if your project don't use.

- Choose IaC tools you need to use and follow the instructions

  <pre>
  ├── aws
  │   └── <a href="https://github.com/framgia/sun-infra-iac/blob/master/examples/aws/terraform/README.md">terraform</a>
  </pre>

  **Note**: Remove the remaining IaC tool folders if your project don't use.

## Contributor

### Do "Install" step in [How to do](#how-to-do)

### Do "Setup" step in [How to do](#how-to-do)

### Git flow

- Before **_add/change/deprecate/remove_** to this module, please checkout new branch like this `feature/<iac-tool>-<cloud-provider>` or `feature/<function>`

- Before **_fix_** to this module, please checkout new branch like this `bugfix/<iac-tool>-<cloud-provider>` or `bugfix/<function>`

- PR to `master` branch with [Commit Message Header](#commit-header) format.

- Follow our [Coding Rules](#rules).

#### <a name="commit-header"></a>Commit Message Header

 ```
 <type>(<scope>): <short summary>
   │       │             │
   │       │             └─⫸ Summary in present tense. Not capitalized. No period at the end.
   │       │
   │       └─⫸ Commit Scope(Optional): terraform-aws-<terraform-module>-<function(optional)>
   │
   └─⫸ Commit Type: build|ci|docs|feat|fix|perf|refactor|test
 ```

Example:

- feat(terraform-aws-vpc): My description here
- docs(terraform-aws-vpc): cut the terraform-aws-vpc_vx.y.z release

##### Type

Must be one of the following:

- **build**: Changes that affect the build system or external dependencies (example scopes: gulp, broccoli, npm)
- **ci**: Changes to our CI configuration files and scripts (examples: CircleCi, SauceLabs)
- **docs**: Documentation only changes
- **feat**: A new feature
- **fix**: A bug fix
- **perf**: A code change that improves performance
- **refactor**: A code change that neither fixes a bug nor adds a feature
- **test**: Adding missing tests or correcting existing tests

##### Scope (Optional)

The scope should be the name of the module/feature affected:

  ```
  <iac-tool>-<cloud-provider>-<module-name>-<function-name(optional)>
  ```

##### Summary

Use the summary field to provide a succinct description of the change:

- use the imperative, present tense: "change" not "changed" nor "changes"
- don't capitalize the first letter
- no dot (.) at the end

##### Revert commits

If the commit reverts a previous commit, it should begin with `revert:`, followed by the header of the reverted commit.

The content of the commit message body should contain:

- information about the SHA of the commit being reverted in the following format: `This reverts commit <SHA>`,
- a clear description of the reason for reverting the commit message.

#### <a name="rules"></a> Coding Rules

To ensure consistency throughout the source code, keep these rules in mind as you are working:

- All features or bug fixes **must be tested** by one or more apply.
- **must be documented**.

### Diagram GitFlow

![Diagram](/images/gitflow-infra-team-v0.0.1.png)

## License

Apache 2 Licensed. See [LICENSE](/LICENSE) for full details.
