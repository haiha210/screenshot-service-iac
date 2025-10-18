# Screenshot Service IAC

## Architecture Overview

## Prepare
1. Setup Local Environment
    - run `./scripts/setup.sh` install terraform, awscli, jq, make, aws vault
2. Setup AWS Account
   - Create an AWS account for each environment (dev, staging, prod)
   - Create a new IAM role for Terraform with the following policies:
     - AdministratorAccess
   - Create an access key for the user and save the Access Key ID and Secret Access Key
3. Setting up AWS Vault
   - `aws-vault add screenshot-service-<env>`
   - Enter the Access Key ID and Secret Access Key when prompted.
   - Setting mfa in .aws/config
    ```
    [profile screenshot-service-<env>]
    mfa_serial = arn:aws:iam::<account_id>:mfa/<user_name>
    region = ap-southeast-1
    output = json
    ```

## Install and Configure
