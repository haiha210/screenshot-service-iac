# Lambda + API Gateway Configuration

This module manages Lambda functions and API Gateway for the Screenshots Service.

## Structure

```
3.lambda-api/
├── _backend.tf           # Terraform backend configuration
├── _data.tf              # Data sources and remote state
├── _outputs.tf           # Output values
├── _variables.tf         # Variable definitions
├── locals.tf             # Local values and transformations
├── lambda.tf             # Lambda function resources
├── apigateway.tf         # API Gateway configuration
├── lambda-config.yaml    # Lambda functions configuration (YAML)
└── README.md             # This file
```

## Lambda Configuration

All Lambda functions are defined in `lambda-config.yaml`. This makes it easy to:
- Add new Lambda functions
- Modify existing configurations
- Manage API paths and HTTP methods
- Control environment variables

### Adding a New Lambda Function

Edit `lambda-config.yaml` and add a new function:

```yaml
- name: my-new-function
  handler: handlers/my/function.handler
  runtime: nodejs18.x
  timeout: 30
  memory_size: 256
  description: My new function description
  api_path: /my/endpoint
  http_method: POST
  environment:
    MY_VAR: my-value
```

## Deployment

### Prerequisites

1. Run `1.general` first to create VPC and IAM roles
2. Create Lambda deployment packages

### Create Lambda Placeholder (for first deployment)

```bash
# Create a placeholder Lambda package
cd /home/gm/projects/devops/screenshots-service-iac/aws/terraform/envs/dev/3.lambda-api
echo 'exports.handler = async (event) => { return { statusCode: 200, body: "OK" }; };' > index.js
zip lambda-placeholder.zip index.js
rm index.js
```

### Initialize and Apply

```bash
cd /home/gm/projects/devops/screenshots-service-iac/aws/terraform/envs/dev/3.lambda-api

# Initialize Terraform
terraform init

# Plan changes
terraform plan -var-file=../terraform.stg.tfvars

# Apply changes
terraform apply -var-file=../terraform.stg.tfvars
```

## Outputs

After deployment, you'll get:
- `api_gateway_url`: The invoke URL for your API
- `api_gateway_id`: The API Gateway ID
- `lambda_functions`: Map of all Lambda functions with their ARNs
- `lambda_function_names`: List of Lambda function names

## Usage Example

```bash
# Get API Gateway URL
terraform output api_gateway_url

# Example: https://abc123.execute-api.ap-southeast-1.amazonaws.com/v1

# Test endpoints
curl https://abc123.execute-api.ap-southeast-1.amazonaws.com/v1/health
curl https://abc123.execute-api.ap-southeast-1.amazonaws.com/v1/screenshots
curl -X POST https://abc123.execute-api.ap-southeast-1.amazonaws.com/v1/screenshots \
  -H "Content-Type: application/json" \
  -d '{"url": "https://example.com"}'
```

## Managing Many Lambda Functions

### Scaling to 100+ Functions

1. **Split by domain**: Create separate YAML files
   ```
   lambda-config-screenshots.yaml
   lambda-config-processing.yaml
   lambda-config-analytics.yaml
   ```

2. **Load multiple configs**: Update `locals.tf`
   ```hcl
   locals {
     screenshots_config = yamldecode(file("${path.module}/lambda-config-screenshots.yaml"))
     processing_config  = yamldecode(file("${path.module}/lambda-config-processing.yaml"))
     
     lambda_functions = merge(
       { for fn in local.screenshots_config.functions : fn.name => {...} },
       { for fn in local.processing_config.functions : fn.name => {...} }
     )
   }
   ```

3. **Split Terraform state**: Create separate folders
   ```
   3.lambda-screenshots/
   4.lambda-processing/
   5.lambda-analytics/
   ```

## CI/CD Integration

### Update Lambda Code

```bash
# Build and deploy specific Lambda
aws lambda update-function-code \
  --function-name screenshots-service-dev-screenshot-create \
  --zip-file fileb://dist/screenshot-create.zip

# Or use CodePipeline/CodeBuild for automated deployments
```

## Monitoring

- Lambda logs: `/aws/lambda/{project}-{env}-{function-name}`
- API Gateway logs: `/aws/apigateway/{project}-{env}-screenshots-api`
- X-Ray tracing enabled for all Lambda functions

## Best Practices

1. ✅ Use Lambda Layers for shared dependencies
2. ✅ Set appropriate timeout and memory for each function
3. ✅ Use environment variables for configuration
4. ✅ Enable X-Ray tracing for debugging
5. ✅ Use CloudWatch Logs with appropriate retention
6. ✅ Implement proper error handling in Lambda functions
7. ✅ Use API Gateway request validation
8. ✅ Implement throttling and rate limiting

## Troubleshooting

### Lambda Permission Issues
```bash
# Check if Lambda has permission to be invoked by API Gateway
aws lambda get-policy --function-name {function-name}
```

### API Gateway 502 Errors
- Check Lambda execution role permissions
- Verify Lambda function returns proper response format
- Check CloudWatch logs for Lambda errors

### API Gateway 403 Errors
- Verify API Gateway resource policy
- Check Lambda permission for API Gateway invoke
