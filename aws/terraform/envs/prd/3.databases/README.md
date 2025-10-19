# DynamoDB Configuration for Screenshots Service

This directory contains the DynamoDB table configurations for the Screenshots Service production environment.

## Tables

### 1. Screenshot Results Table (`screenshot-results-prd`) - **Main Backend Table**

**PRIMARY TABLE** used directly by the backend service. Matches the schema expected by `src/services/dynamodbService.js`.

**Primary Key:**
- Hash Key: `id` (String) - Unique screenshot identifier

**Attributes:**
- `id` - Unique screenshot identifier (partition key)
- `url` - Original URL that was screenshotted
- `s3Url` - S3 URL of the generated screenshot
- `s3Key` - S3 object key for the screenshot file
- `status` - Processing status: "success", "failed", "processing"
- `width` - Screenshot width in pixels
- `height` - Screenshot height in pixels  
- `format` - Image format (png, jpeg, etc.)
- `errorMessage` - Error details if status is "failed"
- `createdAt` - ISO timestamp when record was created
- `updatedAt` - ISO timestamp when record was last updated

**Global Secondary Indexes:**
- `status-createdAt-index` - Used by `queryScreenshotsByStatus()` method
  - Hash Key: `status` (String)
  - Range Key: `createdAt` (String)

**Backend Service Environment Variable:**
```bash
# Production environment
DYNAMODB_TABLE_NAME=screenshot-results-prd

# Development with LocalStack
DYNAMODB_TABLE_NAME=screenshot-results
```

**LocalStack Compatibility:**
This table structure exactly matches the DynamoDB table created by `screenshot-service-be/scripts/init-awslocal.sh`:
- Same table name: `screenshot-results`
- Same GSI name: `status-createdAt-index`
- Same attribute definitions and key schema
- Compatible throughput settings (5 RCU/WCU when using PROVISIONED mode)

### 2. Screenshots Metadata Table (`screenshots-metadata-prd`)

**Additional table** for extended metadata and user information.

**Primary Key:**
- Hash Key: `id` (String) - Unique identifier for each screenshot

**Attributes:**
- `id` - Unique screenshot identifier
- `user_id` - User who created the screenshot  
- `created_at` - Timestamp when screenshot was created
- Additional metadata fields as needed

**Global Secondary Indexes:**
- `UserIdIndex` - Allows querying screenshots by user_id and created_at

### 3. Analytics Events Table (`analytics-events-prd`)

**Analytics table** for storing user interaction and system events.

**Primary Key:**
- Hash Key: `event_id` (String) - Unique identifier for each event
- Range Key: `timestamp` (String) - Event timestamp

**Attributes:**
- `event_id` - Unique event identifier
- `timestamp` - Event timestamp
- `user_id` - User associated with the event
- `event_type` - Type/category of the event
- `ttl` - TTL field for automatic data expiration

**Global Secondary Indexes:**
- `UserIdIndex` - Query events by user_id and timestamp
- `EventTypeIndex` - Query events by event_type and timestamp

**Features:**
- TTL enabled (data expires after configured days)
- Point-in-time recovery enabled
- Server-side encryption enabled
- Configurable billing mode

## Configuration Variables

| Variable | Description | Default | Type |
|----------|-------------|---------|------|
| `enable_dynamodb_backup` | Enable point-in-time recovery | `true` | bool |
| `analytics_data_ttl_days` | Days to retain analytics data | `90` | number |
| `dynamodb_billing_mode` | Billing mode (PROVISIONED/PAY_PER_REQUEST) | `PAY_PER_REQUEST` | string |

## Outputs

| Output | Description |
|--------|-------------|
| `screenshot_results_table_name` | **Main backend table** - Name of the screenshot results table |
| `screenshot_results_table_arn` | **Main backend table** - ARN of the screenshot results table |
| `screenshots_metadata_table_name` | Name of the screenshots metadata table |
| `screenshots_metadata_table_arn` | ARN of the screenshots metadata table |
| `analytics_events_table_name` | Name of the analytics events table |
| `analytics_events_table_arn` | ARN of the analytics events table |
| `lambda_dynamodb_access_policy_arn` | IAM policy ARN for Lambda DynamoDB access |
| `ecs_dynamodb_access_policy_arn` | IAM policy ARN for ECS DynamoDB access |

## Backend Service Integration

The **screenshot-results** table is the primary table used by the backend service:

**Backend Service Methods:**
- `saveScreenshotResult()` - Saves screenshot processing results
- `getScreenshot()` / `getScreenshotById()` - Retrieves screenshot by ID
- `updateScreenshotStatus()` - Updates processing status and metadata
- `queryScreenshotsByStatus()` - Queries screenshots by status using GSI

**Required Environment Variables:**
```bash
DYNAMODB_TABLE_NAME=screenshot-results-prd  # Points to main results table
AWS_REGION=ap-southeast-1
```

## Security & IAM

- **Server-side encryption**: Enabled on all tables
- **Point-in-time recovery**: Configurable via `enable_dynamodb_backup` variable
- **IAM policies**: Separate policies created for different access patterns:
  - `lambda_dynamodb_access_policy_arn` - For Lambda functions
  - `ecs_dynamodb_access_policy_arn` - For ECS tasks (backend service)

**Permissions included in IAM policies:**
- `dynamodb:GetItem`
- `dynamodb:PutItem` 
- `dynamodb:UpdateItem`
- `dynamodb:DeleteItem`
- `dynamodb:Query`
- `dynamodb:Scan`

**IAM policies cover all tables and their indexes.**

## LocalStack Development

For development with LocalStack, a separate table configuration is available:

**File: `dynamodb-localstack.tf`**
- Creates a table that matches exactly with `screenshot-service-be/scripts/init-awslocal.sh`
- Uses PROVISIONED billing mode (5 RCU/WCU)
- Only deployed when `var.env == "dev"`
- Table name: `screenshot-results` (without environment suffix)

**Environment Variables for LocalStack:**
```bash
DYNAMODB_TABLE_NAME=screenshot-results  # No environment suffix
AWS_ENDPOINT=http://localhost:4566
```

## Deployment

To deploy the DynamoDB tables:

```bash
cd aws/terraform/envs/prd/3.databases
terraform init
terraform plan
terraform apply
```

**For different environments:**
```bash
# Production - uses screenshot-results-prd
terraform apply -var="env=prd"

# Development - creates both standard and LocalStack compatible tables
terraform apply -var="env=dev" 

# Staging
terraform apply -var="env=stg"
```

Make sure the `1.general` module has been deployed first as this module depends on outputs from it.