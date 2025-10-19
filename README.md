# Screenshot Service - Infrastructure as Code

[![Terraform](https://img.shields.io/badge/Terraform-%3E%3D1.3.9-623CE4?logo=terraform)](https://www.terraform.io/)
[![AWS](https://img.shields.io/badge/AWS-Cloud-FF9900?logo=amazon-aws)](https://aws.amazon.com/)

> **Enterprise-grade screenshot capture service with event-driven architecture, auto-scaling, and high availability on AWS**

---

## 📋 Table of Contents

- [Overview](#overview)
- [Architecture Diagram](#architecture-diagram)
- [Key Design Decisions](#key-design-decisions)
- [Technology Stack](#technology-stack)
- [Project Structure](#project-structure)
- [Prerequisites](#prerequisites)
- [Infrastructure Setup](#infrastructure-setup)
- [Deployment Guide](#deployment-guide)
- [Configuration](#configuration)
- [Monitoring & Operations](#monitoring--operations)
- [Cost Optimization](#cost-optimization)

---

## 🎯 Overview

The **Screenshot Service** is a production-ready, serverless and container-based system designed to capture website screenshots at scale. It leverages AWS managed services to provide a reliable, cost-effective, and scalable solution for automated screenshot generation.

### Key Features

- **Event-Driven Architecture**: Decoupled components using SQS message queues
- **Auto-Scaling**: ECS Fargate with dynamic scaling based on queue depth (1-10 tasks)
- **High Availability**: Multi-AZ deployment with automatic failover
- **Serverless API**: API Gateway + Lambda for REST endpoints
- **Persistent Storage**: S3 for images, DynamoDB for metadata
- **Comprehensive Monitoring**: CloudWatch alarms and dashboards
- **Race Condition Prevention**: Conditional writes to prevent duplicate processing
- **Dead Letter Queue**: Automatic retry mechanism for failed captures
- **Infrastructure as Code**: 100% Terraform-managed infrastructure

### Use Cases

- **QA Automation**: Visual regression testing for web applications
- **Compliance**: Automated compliance screenshots with timestamp records
- **Marketing**: Dynamic social media preview generation
- **Monitoring**: Website appearance monitoring across different viewports
- **Archival**: Historical snapshots of web content

---

## 🏗️ Architecture Diagram

### High-Level System Architecture

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                            AWS Cloud - VPC                                  │
│                                                                             │
│  ┌─────────────────────────────────────────────────────────────────────┐  │
│  │                         Public Subnet (Multi-AZ)                     │  │
│  │                                                                       │  │
│  │  ┌──────────────────┐         ┌──────────────────┐                  │  │
│  │  │  API Gateway     │◄────────┤  Internet        │                  │  │
│  │  │  (REST API)      │         │  Gateway         │                  │  │
│  │  └────────┬─────────┘         └──────────────────┘                  │  │
│  │           │                                                           │  │
│  │           ▼                                                           │  │
│  │  ┌──────────────────┐         ┌──────────────────┐                  │  │
│  │  │  Lambda          │         │  NAT Gateway     │                  │  │
│  │  │  - createShot    │         │  (Multi-AZ)      │                  │  │
│  │  │  - getStatus     │         └────────┬─────────┘                  │  │
│  │  │  - healthCheck   │                  │                             │  │
│  │  └────────┬─────────┘                  │                             │  │
│  └───────────┼────────────────────────────┼─────────────────────────────┘  │
│              │                            │                                 │
│              ▼                            ▼                                 │
│  ┌──────────────────────────────────────────────────────────────────────┐  │
│  │                       Private Subnet (Multi-AZ)                       │  │
│  │                                                                        │  │
│  │  ┌───────────────┐          ┌─────────────────────────────┐          │  │
│  │  │  SQS Queue    │◄─────────┤  ECS Fargate Tasks          │          │  │
│  │  │  (Standard)   │          │  ┌─────────────────────┐    │          │  │
│  │  │               │          │  │ screenshot-service  │    │          │  │
│  │  │  - Main Queue │          │  │ Container           │    │          │  │
│  │  │  - Priority Q │          │  │                     │    │          │  │
│  │  │  - FIFO Queue │          │  │ - SQS Consumer      │    │          │  │
│  │  │  - DLQ        │          │  │ - Puppeteer Engine  │    │          │  │
│  │  └───────┬───────┘          │  │ - S3 Uploader       │    │          │  │
│  │          │                  │  └─────────────────────┘    │          │  │
│  │          │                  │  Auto-scaling: 1-10 tasks   │          │  │
│  │          └──────────────────┤  Health Check Enabled       │          │  │
│  │                             └──────────┬──────────────────┘          │  │
│  └────────────────────────────────────────┼─────────────────────────────┘  │
│                                            │                                │
└────────────────────────────────────────────┼────────────────────────────────┘
                                             │
                     ┌───────────────────────┼────────────────────────┐
                     │                       │                        │
                     ▼                       ▼                        ▼
            ┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
            │  Amazon S3      │    │  DynamoDB       │    │  CloudWatch     │
            │  - Screenshots  │    │  - Metadata     │    │  - Logs         │
            │  - Versioning   │    │  - GSI (status) │    │  - Alarms       │
            │  - Encryption   │    │  - PITR Backup  │    │  - Metrics      │
            └─────────────────┘    └─────────────────┘    └─────────────────┘
```

### Request Flow Diagram

```
┌─────────┐
│ Client  │
└────┬────┘
     │
     │ 1. POST /screenshots
     │    { url: "https://example.com" }
     ▼
┌──────────────────┐
│  API Gateway     │
│  + Lambda        │
└────┬─────────────┘
     │
     │ 2. Create DynamoDB record
     │    status: "processing"
     ▼
┌──────────────────┐
│  DynamoDB Table  │◄─────────────────────────┐
│  screenshots     │                          │
└────┬─────────────┘                          │
     │                                        │
     │ 3. Send SQS message                   │ 8. Update status
     ▼                                        │    → "success"
┌──────────────────┐                          │    + s3Url
│  SQS Queue       │                          │
│  (Main)          │                          │
└────┬─────────────┘                          │
     │                                        │
     │ 4. Poll messages                      │
     │    (visibility: 5min)                 │
     ▼                                        │
┌──────────────────┐                          │
│  ECS Task        │                          │
│  Consumer        │                          │
└────┬─────────────┘                          │
     │                                        │
     │ 5. Update status                      │
     │    → "consumerProcessing"             │
     ▼                                        │
┌──────────────────┐                          │
│  Puppeteer       │                          │
│  Screenshot      │                          │
└────┬─────────────┘                          │
     │                                        │
     │ 6. Capture screenshot                 │
     ▼                                        │
┌──────────────────┐                          │
│  Amazon S3       │                          │
│  Upload Image    │                          │
└────┬─────────────┘                          │
     │                                        │
     │ 7. Return S3 URL                      │
     └────────────────────────────────────────┘

     9. Auto-delete message from SQS


┌─────────────────────────────────────────────────┐
│  Error Path (if failure occurs)                 │
│                                                  │
│  ┌──────────────┐    ┌──────────────┐          │
│  │  Error       │───▶│  DynamoDB    │          │
│  │  Thrown      │    │  status:     │          │
│  └──────┬───────┘    │  "failed"    │          │
│         │            └──────────────┘          │
│         │                                       │
│         ▼                                       │
│  ┌──────────────┐    ┌──────────────┐          │
│  │  Message     │───▶│  Dead Letter │          │
│  │  Retry (3x)  │    │  Queue       │          │
│  └──────────────┘    └──────────────┘          │
└─────────────────────────────────────────────────┘
```

### Infrastructure Layers

The Terraform infrastructure is organized into **6 logical layers**:

```
┌────────────────────────────────────────────────────────────────┐
│  Layer 1: General (Networking & Messaging)                     │
│  - VPC, Subnets, IGW, NAT Gateway                              │
│  - SQS Queues (Main, Priority, FIFO, DLQ)                      │
│  - IAM Roles & Policies                                        │
│  - Security Groups                                             │
└────────────────────────────────────────────────────────────────┘
                           ▼
┌────────────────────────────────────────────────────────────────┐
│  Layer 2: Storage (S3 Buckets)                                 │
│  - Screenshot Storage Bucket                                   │
│  - Terraform State Backend                                     │
│  - Versioning & Encryption                                     │
└────────────────────────────────────────────────────────────────┘
                           ▼
┌────────────────────────────────────────────────────────────────┐
│  Layer 3: Databases                                            │
│  - DynamoDB Tables (screenshots metadata)                      │
│  - Global Secondary Indexes (status-createdAt)                 │
│  - Point-in-Time Recovery (PITR)                               │
└────────────────────────────────────────────────────────────────┘
                           ▼
┌────────────────────────────────────────────────────────────────┐
│  Layer 4: Backend (Container Orchestration)                    │
│  - ECS Cluster                                                 │
│  - ECS Service (Fargate)                                       │
│  - Task Definitions                                            │
│  - Auto Scaling Policies (1-10 tasks)                          │
└────────────────────────────────────────────────────────────────┘
                           ▼
┌────────────────────────────────────────────────────────────────┐
│  Layer 5: Monitoring                                           │
│  - CloudWatch Log Groups                                       │
│  - CloudWatch Alarms (Queue Depth, CPU, Memory)                │
│  - SNS Topics (Alerts)                                         │
└────────────────────────────────────────────────────────────────┘
                           ▼
┌────────────────────────────────────────────────────────────────┐
│  Layer 6: API (Serverless)                                     │
│  - API Gateway REST API                                        │
│  - Lambda Functions (createScreenshot, getStatus, health)      │
│  - API Caching (optional)                                      │
└────────────────────────────────────────────────────────────────┘
```

---

## 🎯 Key Design Decisions

### 1. Event-Driven Architecture with SQS

**Decision**: Use Amazon SQS as the message broker between API and processing layer.

**Rationale**:
- **Decoupling**: API layer and processing layer are completely independent
- **Buffering**: SQS acts as a shock absorber during traffic spikes
- **Reliability**: Built-in message persistence and retry mechanism
- **No State Management**: Consumers are stateless, enabling horizontal scaling
- **Cost-Effective**: Pay only for messages processed

**Trade-offs**:
- Slight latency increase (asynchronous processing)
- Eventually consistent system (not real-time)

**Alternatives Considered**:
- ❌ **Synchronous Lambda**: Would timeout for slow page loads (15min max)
- ❌ **SNS**: No built-in retry or DLQ capabilities
- ❌ **Kinesis**: Over-engineering for this workload, higher cost

---

### 2. ECS Fargate for Container Orchestration

**Decision**: Deploy screenshot workers on ECS Fargate (not EC2 or Lambda).

**Rationale**:
- **Puppeteer Requirements**: Needs full Chrome browser runtime (~500MB)
- **Long Execution Time**: Screenshots can take 30s-2min per page
- **Memory Requirements**: Chrome requires 512MB-2GB memory
- **Custom Environment**: Alpine Linux with specific dependencies
- **No Server Management**: Fargate eliminates EC2 patching/scaling

**Trade-offs**:
- Higher cost than EC2 (but offset by no idle time with auto-scaling)
- Cold start time (~30s for new task launch)

**Alternatives Considered**:
- ❌ **Lambda**: 10GB package size limit, 15min timeout, cold starts
- ❌ **EC2 Auto Scaling**: Requires server management, slower scale-up
- ❌ **EKS**: Over-engineering, higher operational complexity

---

### 3. Multi-Queue Strategy (Main + Priority + FIFO)

**Decision**: Implement 3 separate SQS queues for different processing priorities.

**Rationale**:
- **Main Queue (Standard)**: Default processing, high throughput
- **Priority Queue**: Urgent screenshots bypass backlog
- **FIFO Queue**: Ordered processing for sequential captures (e.g., time-series)
- **Dead Letter Queue**: Failed messages after 3 retries

**Implementation**:
```terraform
# Main Queue: Standard, 5min visibility, 3 retries
module "sqs_main" {
  source              = "../../modules/sqs"
  queue_name          = "screenshot-queue-prd"
  visibility_timeout  = 300
  max_receive_count   = 3
}

# Priority Queue: Lower visibility, faster processing
module "sqs_priority" {
  source              = "../../modules/sqs"
  queue_name          = "screenshot-priority-prd"
  visibility_timeout  = 180
  max_receive_count   = 3
}

# FIFO Queue: Exactly-once processing
module "sqs_fifo" {
  source              = "../../modules/sqs"
  queue_name          = "screenshot-fifo-prd.fifo"
  fifo_queue          = true
  content_deduplication = true
}
```

---

### 4. Race Condition Prevention with Conditional Writes

**Decision**: Use DynamoDB conditional writes to prevent duplicate processing.

**Rationale**:
- **Problem**: Multiple ECS tasks might process the same message during retries
- **Solution**: `UpdateItem` with `ConditionExpression: "attribute_not_exists(s3Url)"`
- **Result**: Only first task successfully updates, others fail gracefully

**Implementation**:
```javascript
// In sqsConsumer.js
const params = {
  TableName: DYNAMODB_TABLE,
  Key: { id: requestId },
  UpdateExpression: 'SET #status = :status, updatedAt = :now',
  ConditionExpression: '#status <> :success', // Prevent overwriting success
  ExpressionAttributeNames: { '#status': 'status' },
  ExpressionAttributeValues: {
    ':status': 'consumerProcessing',
    ':success': 'success',
    ':now': new Date().toISOString()
  }
};
```

**Alternatives Considered**:
- ❌ **Distributed Locks (Redis)**: Adds complexity, single point of failure
- ❌ **SQS FIFO Deduplication**: Only works within 5-minute window

---

### 5. Layered Terraform Architecture

**Decision**: Split infrastructure into 6 independent Terraform layers.

**Rationale**:
- **Blast Radius Reduction**: Changes to API don't affect VPC
- **Team Separation**: Network team manages Layer 1, App team manages Layer 4-6
- **Faster Deployments**: Only apply changed layers
- **State File Isolation**: Smaller state files reduce lock contention
- **Dependency Management**: Clear data source references between layers

**Layer Dependency Graph**:
```
Layer 1 (VPC, SQS)
    ↓
Layer 3 (DynamoDB) ──┐
    ↓                │
Layer 4 (ECS) ───────┤
    ↓                │
Layer 5 (Monitoring) │
    ↓                │
Layer 6 (API) ───────┘
```

**Alternatives Considered**:
- ❌ **Monolithic Terraform**: 10-minute apply time, risky changes
- ❌ **Terraform Workspaces**: Shared state file, namespace pollution

---

### 6. S3 Storage with Date-Based Partitioning

**Decision**: Store screenshots in S3 with hierarchical date-based keys.

**Rationale**:
- **Performance**: S3 partitioning improves list performance (1000+ screenshots/sec)
- **Cost Management**: Easy to apply lifecycle policies per month/year
- **Organization**: Human-readable structure for debugging

**Key Pattern**:
```
s3://screenshot-bucket-prd/
├── screenshots/
│   ├── 2025/
│   │   ├── 01/
│   │   │   ├── 19/
│   │   │   │   ├── screenshot-abc123-1737331200.png
│   │   │   │   ├── screenshot-def456-1737331300.png
```

**Lifecycle Policy**:
```terraform
# Transition to Glacier after 90 days, delete after 1 year
lifecycle_rule {
  enabled = true

  transition {
    days          = 90
    storage_class = "GLACIER"
  }

  expiration {
    days = 365
  }
}
```

---

### 7. Auto-Scaling Based on Queue Depth

**Decision**: Scale ECS tasks based on SQS `ApproximateNumberOfMessagesVisible` metric.

**Rationale**:
- **Predictive Scaling**: Queue depth predicts future load better than CPU/memory
- **Cost Efficiency**: Scale down to 1 task during idle periods
- **Performance**: Maintain ~5 messages per task ratio

**Scaling Policy**:
```terraform
resource "aws_appautoscaling_policy" "ecs_policy_queue" {
  name               = "ecs-scale-on-queue"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.ecs.resource_id
  scalable_dimension = aws_appautoscaling_target.ecs.scalable_dimension
  service_namespace  = aws_appautoscaling_target.ecs.service_namespace

  target_tracking_scaling_policy_configuration {
    target_value = 5.0  # 5 messages per task

    customized_metric_specification {
      metric_name = "ApproximateNumberOfMessagesVisible"
      namespace   = "AWS/SQS"
      statistic   = "Average"

      dimensions {
        name  = "QueueName"
        value = "screenshot-queue-prd"
      }
    }
  }
}
```

**Scaling Behavior**:
- 0-5 messages: 1 task
- 6-10 messages: 2 tasks
- 11-15 messages: 3 tasks
- 50+ messages: 10 tasks (max)

---

### 8. DynamoDB with Global Secondary Index

**Decision**: Use DynamoDB with GSI on `status-createdAt` for efficient queries.

**Rationale**:
- **Primary Key**: `id` (requestId) for direct lookups
- **GSI**: Query all screenshots by status (e.g., "get all successful screenshots today")
- **Cost-Effective**: On-demand billing, no capacity planning needed
- **Performance**: Single-digit millisecond latency

**Schema Design**:
```javascript
{
  id: "screenshot-abc123",           // Partition Key
  url: "https://example.com",
  status: "success",                 // GSI Partition Key
  createdAt: "2025-01-19T10:00:00Z", // GSI Sort Key
  updatedAt: "2025-01-19T10:00:30Z",
  s3Url: "https://s3.amazonaws.com/...",
  s3Key: "screenshots/2025/01/19/screenshot-abc123.png",
  width: 1920,
  height: 1080,
  format: "png"
}
```

**Query Examples**:
```javascript
// Get all successful screenshots from last 24 hours
const params = {
  TableName: 'screenshots',
  IndexName: 'status-createdAt-index',
  KeyConditionExpression: '#status = :status AND createdAt > :yesterday',
  ExpressionAttributeNames: { '#status': 'status' },
  ExpressionAttributeValues: {
    ':status': 'success',
    ':yesterday': new Date(Date.now() - 86400000).toISOString()
  }
};
```

---

### 9. Alpine Linux for Minimal Container Image

**Decision**: Use Alpine Linux as the base image (not Ubuntu/Debian).

**Rationale**:
- **Size**: 5MB base vs 100MB+ for Ubuntu
- **Security**: Smaller attack surface (fewer packages)
- **Speed**: Faster image pull from ECR (~10s vs 60s)
- **Cost**: Less network egress charges

**Dockerfile Optimization**:
```dockerfile
FROM node:18-alpine

# Install Chromium (smaller than Chrome)
RUN apk add --no-cache chromium

# Non-root user for security
RUN addgroup -g 1001 -S appuser && \
    adduser -S -u 1001 -G appuser appuser

USER appuser

# Puppeteer environment
ENV PUPPETEER_EXECUTABLE_PATH=/usr/bin/chromium-browser
ENV PUPPETEER_SKIP_CHROMIUM_DOWNLOAD=true
```

**Image Size Comparison**:
- Ubuntu + Chrome: **1.2 GB**
- Alpine + Chromium: **450 MB** (62% reduction)

---

### 10. Separate Terraform State per Environment

**Decision**: Maintain independent Terraform state files for dev/stg/prd.

**Rationale**:
- **Isolation**: Production changes never affect development
- **Security**: Different AWS accounts, separate IAM policies
- **Rollback**: Easy to revert production without touching dev
- **Compliance**: Audit trails per environment

**State Backend Configuration**:
```terraform
# prd environment
terraform {
  backend "s3" {
    bucket         = "screenshot-service-prd-iac-state"
    key            = "layer4/backend/terraform.tfstate"
    region         = "ap-southeast-1"
    encrypt        = true
    kms_key_id     = "arn:aws:kms:ap-southeast-1:xxx:key/xxx"
    dynamodb_table = "screenshot-service-prd-iac-state-lock"
  }
}
```

---

## 🛠️ Technology Stack

### Infrastructure

| Component | Technology | Version | Purpose |
|-----------|-----------|---------|---------|
| **IaC** | Terraform | ≥ 1.3.9 | Infrastructure provisioning |
| **Cloud** | AWS | - | Cloud provider |
| **State Backend** | S3 + DynamoDB | - | Terraform state storage & locking |
| **Encryption** | AWS KMS | - | State file encryption |

### AWS Services

| Service | Purpose | Configuration |
|---------|---------|---------------|
| **VPC** | Network isolation | Multi-AZ, public/private subnets |
| **SQS** | Message queue | Standard, FIFO, DLQ |
| **S3** | Image storage | Versioning, encryption, lifecycle |
| **DynamoDB** | Metadata storage | On-demand, PITR, GSI |
| **ECS Fargate** | Container orchestration | 1-10 tasks, auto-scaling |
| **ECR** | Docker registry | Private repository |
| **Lambda** | API handlers | Node.js 18 runtime |
| **API Gateway** | REST API | Caching, throttling |
| **CloudWatch** | Monitoring | Logs, metrics, alarms |
| **IAM** | Access control | Least-privilege policies |

### Backend Application (../screenshot-service-be)

| Component | Technology | Version | Purpose |
|-----------|-----------|---------|---------|
| **Runtime** | Node.js | ≥ 18.0.0 | JavaScript execution |
| **Browser** | Puppeteer | 24.x | Headless Chrome automation |
| **Container** | Docker | - | Alpine Linux base image |
| **Logging** | Pino | - | Structured JSON logging |
| **Testing** | Jest | 30.x | Unit & integration tests |
| **Queue Client** | sqs-consumer | 10.x | SQS message processing |

---

## 📁 Project Structure

```
screenshots-service-iac/
├── aws/
│   ├── modules/                    # Reusable Terraform modules
│   │   ├── vpc/                    # VPC module (subnets, NAT, IGW)
│   │   ├── sqs/                    # SQS queue module
│   │   ├── s3/                     # S3 bucket module
│   │   ├── rest-apigateway/        # API Gateway module
│   │   └── ecs/                    # ECS cluster/service module (template)
│   │
│   ├── terraform/
│   │   └── envs/
│   │       ├── dev/                # Development environment
│   │       ├── stg/                # Staging environment
│   │       └── prd/                # Production environment
│   │           ├── 1.general/      # Layer 1: VPC, SQS, IAM
│   │           ├── 3.databases/    # Layer 3: DynamoDB
│   │           ├── 4.backend/      # Layer 4: ECS cluster & service
│   │           ├── 5.monitor/      # Layer 5: CloudWatch alarms
│   │           └── 6.api/          # Layer 6: API Gateway, Lambda
│   │
│   ├── lambdas/
│   │   └── prd/
│   │       └── be/
│   │           ├── createScreenshot/    # POST /screenshots Lambda
│   │           ├── getScreenshotStatus/ # GET /screenshots/{id} Lambda
│   │           └── healthCheck/         # GET /health Lambda
│   │
│   ├── scripts/
│   │   ├── setup.sh                     # Install Terraform, AWS CLI, etc.
│   │   ├── create-aws-sts.sh            # Setup AWS profiles with MFA
│   │   ├── create-state-backend.sh      # Create S3 + DynamoDB backend
│   │   ├── deploy-layer.sh              # Deploy specific Terraform layer
│   │   └── package-lambda.sh            # Package Lambda functions
│   │
│   └── README.md                        # This file
│
└── screenshot-service-be/               # Backend application (separate repo/folder)
    ├── src/
    │   ├── services/                    # Core business logic
    │   ├── config/                      # Configuration management
    │   └── utils/                       # Utilities (logging, etc.)
    ├── Dockerfile                       # Production container image
    ├── docker-compose.yml               # Local development with LocalStack
    └── package.json
```

---

## ✅ Prerequisites

### Local Development Tools

| Tool | Version | Installation Command |
|------|---------|---------------------|
| **Terraform** | ≥ 1.3.9 | `brew install terraform` (macOS)<br/>`./scripts/setup.sh` (Linux) |
| **AWS CLI** | ≥ 2.x | `brew install awscli` (macOS)<br/>`curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"` (Linux) |
| **AWS Vault** | Latest | `brew install aws-vault` (macOS)<br/>`./scripts/setup.sh` (Linux) |
| **jq** | Latest | `brew install jq` (macOS)<br/>`apt-get install jq` (Linux) |
| **Make** | Latest | Pre-installed on macOS/Linux |

### AWS Account Requirements

#### 1. AWS Account Setup

Create separate AWS accounts for each environment (recommended):

```
Organization Root
├── screenshot-service-dev   (Account ID: 111111111111)
├── screenshot-service-stg   (Account ID: 222222222222)
└── screenshot-service-prd   (Account ID: 333333333333)
```

**Why separate accounts?**
- Billing isolation (track costs per environment)
- Security isolation (production data never leaks to dev)
- Compliance (audit trails per environment)

#### 2. IAM User Creation

Create an IAM user with **AdministratorAccess** policy:

```bash
aws iam create-user --user-name terraform-deployer
aws iam attach-user-policy --user-name terraform-deployer \
    --policy-arn arn:aws:iam::aws:policy/AdministratorAccess
aws iam create-access-key --user-name terraform-deployer
```

**⚠️ Security Note**: In production, use least-privilege policies instead of AdministratorAccess.

#### 3. MFA (Multi-Factor Authentication)

Enable MFA for the IAM user:

```bash
# Create virtual MFA device
aws iam create-virtual-mfa-device \
    --virtual-mfa-device-name terraform-deployer-mfa \
    --outfile /tmp/qrcode.png \
    --bootstrap-method QRCodePNG

# Enable MFA (after scanning QR code with authenticator app)
aws iam enable-mfa-device \
    --user-name terraform-deployer \
    --serial-number arn:aws:iam::ACCOUNT_ID:mfa/terraform-deployer-mfa \
    --authentication-code1 CODE1 \
    --authentication-code2 CODE2
```

---

## 🚀 Infrastructure Setup

### Step 1: Install Local Tools

Run the automated setup script:

```bash
cd screenshots-service-iac/aws/scripts
./setup.sh
```

This script installs:
- Terraform
- AWS CLI
- AWS Vault
- jq
- make

**Manual Installation (if needed)**:

```bash
# macOS
brew install terraform awscli aws-vault jq

# Ubuntu/Debian
sudo apt-get update
sudo apt-get install -y unzip jq make
curl "https://releases.hashicorp.com/terraform/1.6.0/terraform_1.6.0_linux_amd64.zip" -o terraform.zip
unzip terraform.zip && sudo mv terraform /usr/local/bin/
```

---

### Step 2: Configure AWS Vault

AWS Vault securely stores AWS credentials and generates temporary session tokens with MFA.

#### 2.1 Add AWS Credentials

```bash
aws-vault add screenshot-service-prd
```

Enter your Access Key ID and Secret Access Key when prompted.

#### 2.2 Configure MFA in AWS Config

Edit `~/.aws/config`:

```ini
[profile screenshot-service-prd]
mfa_serial = arn:aws:iam::333333333333:mfa/terraform-deployer
region = ap-southeast-1
output = json
```

#### 2.3 Test AWS Vault

```bash
aws-vault exec screenshot-service-prd -- aws sts get-caller-identity
```

You should see output like:

```json
{
    "UserId": "AIDAI...",
    "Account": "333333333333",
    "Arn": "arn:aws:iam::333333333333:user/terraform-deployer"
}
```

---

### Step 3: Create Terraform State Backend

The Terraform state backend stores infrastructure state in S3 with DynamoDB locking.

#### 3.1 Run State Backend Script

```bash
cd screenshots-service-iac/aws/scripts
./create-state-backend.sh prd ap-southeast-1
```

This script creates:
- S3 bucket: `screenshot-service-prd-iac-state`
- DynamoDB table: `screenshot-service-prd-iac-state-lock`
- KMS key: For state file encryption

#### 3.2 Verify State Backend

```bash
aws-vault exec screenshot-service-prd -- aws s3 ls | grep iac-state
aws-vault exec screenshot-service-prd -- aws dynamodb list-tables | grep state-lock
```

---

### Step 4: Review Variables

Each Terraform layer has a `_variables.tf` file with configurable parameters.

**Example: [terraform/envs/prd/1.general/_variables.tf](terraform/envs/prd/1.general/_variables.tf)**

```terraform
variable "environment" {
  description = "Environment name"
  type        = string
  default     = "prd"
}

variable "vpc_cidr" {
  description = "VPC CIDR block"
  type        = string
  default     = "10.0.0.0/16"
}

variable "sqs_visibility_timeout" {
  description = "SQS message visibility timeout (seconds)"
  type        = number
  default     = 300  # 5 minutes
}
```

**Customize variables** by creating a `terraform.tfvars` file:

```terraform
# terraform/envs/prd/1.general/terraform.tfvars
vpc_cidr = "10.10.0.0/16"
sqs_visibility_timeout = 600
```

---

## 📦 Deployment Guide

### Deployment Strategy

The infrastructure is deployed in **6 sequential layers** to respect dependencies:

```
Layer 1: General (VPC, SQS, IAM) → Must deploy first
Layer 3: Databases (DynamoDB) → Depends on Layer 1
Layer 4: Backend (ECS) → Depends on Layer 1 & 3
Layer 5: Monitor (CloudWatch) → Depends on Layer 4
Layer 6: API (API Gateway, Lambda) → Depends on all previous layers
```

---

### Layer 1: General Resources

Creates VPC, subnets, SQS queues, and IAM roles.

```bash
cd terraform/envs/prd/1.general

# Initialize Terraform
aws-vault exec screenshot-service-prd -- terraform init

# Review planned changes
aws-vault exec screenshot-service-prd -- terraform plan

# Apply changes
aws-vault exec screenshot-service-prd -- terraform apply

# Save outputs for next layers
aws-vault exec screenshot-service-prd -- terraform output -json > outputs.json
```

**What gets created:**
- VPC with public/private subnets in 2 AZs
- Internet Gateway + NAT Gateway
- SQS queues: `screenshot-queue-prd`, `screenshot-priority-prd`, `screenshot-fifo-prd.fifo`
- Dead Letter Queue: `screenshot-dlq-prd`
- IAM roles: `ecs-task-execution-role`, `ecs-task-role`, `lambda-execution-role`
- Security groups for ECS and Lambda

**Verification:**

```bash
# Check VPC
aws-vault exec screenshot-service-prd -- aws ec2 describe-vpcs \
    --filters "Name=tag:Environment,Values=prd"

# Check SQS queues
aws-vault exec screenshot-service-prd -- aws sqs list-queues

# Check IAM roles
aws-vault exec screenshot-service-prd -- aws iam list-roles | grep screenshot
```

---

### Layer 3: Databases

Creates DynamoDB tables for screenshot metadata.

```bash
cd ../3.databases

# Initialize Terraform
aws-vault exec screenshot-service-prd -- terraform init

# Review planned changes
aws-vault exec screenshot-service-prd -- terraform plan

# Apply changes
aws-vault exec screenshot-service-prd -- terraform apply
```

**What gets created:**
- DynamoDB table: `screenshot-results-prd`
  - Primary Key: `id` (String)
  - Global Secondary Index: `status-createdAt-index`
  - Billing mode: PAY_PER_REQUEST (on-demand)
  - Point-in-Time Recovery: ENABLED
  - Encryption: AWS-managed KMS key

**Verification:**

```bash
# Describe table
aws-vault exec screenshot-service-prd -- aws dynamodb describe-table \
    --table-name screenshot-results-prd

# Check GSI
aws-vault exec screenshot-service-prd -- aws dynamodb describe-table \
    --table-name screenshot-results-prd \
    --query 'Table.GlobalSecondaryIndexes'
```

---

### Layer 4: Backend (ECS)

Creates ECS cluster, service, and auto-scaling policies.

#### 4.1 Build and Push Docker Image

First, build and push the backend application to ECR:

```bash
# Navigate to backend application
cd ../../../../screenshot-service-be

# Authenticate Docker to ECR
aws-vault exec screenshot-service-prd -- \
    aws ecr get-login-password --region ap-southeast-1 | \
    docker login --username AWS --password-stdin \
    333333333333.dkr.ecr.ap-southeast-1.amazonaws.com

# Create ECR repository (if not exists)
aws-vault exec screenshot-service-prd -- \
    aws ecr create-repository --repository-name screenshot-service-prd

# Build Docker image
docker build -t screenshot-service:latest .

# Tag image
docker tag screenshot-service:latest \
    333333333333.dkr.ecr.ap-southeast-1.amazonaws.com/screenshot-service:latest

# Push image
docker push 333333333333.dkr.ecr.ap-southeast-1.amazonaws.com/screenshot-service:latest
```

#### 4.2 Deploy ECS Infrastructure

```bash
cd ../screenshots-service-iac/aws/terraform/envs/prd/4.backend

# Initialize Terraform
aws-vault exec screenshot-service-prd -- terraform init

# Update variables with ECR image URI
cat > terraform.tfvars <<EOF
container_image = "333333333333.dkr.ecr.ap-southeast-1.amazonaws.com/screenshot-service:latest"
ecs_task_cpu    = "1024"   # 1 vCPU
ecs_task_memory = "2048"   # 2 GB
ecs_desired_count = 1
ecs_min_capacity  = 1
ecs_max_capacity  = 10
EOF

# Review planned changes
aws-vault exec screenshot-service-prd -- terraform plan

# Apply changes
aws-vault exec screenshot-service-prd -- terraform apply
```

**What gets created:**
- ECS Cluster: `screenshot-service-prd`
- ECS Task Definition: `screenshot-task-prd` (Fargate, 1 vCPU, 2GB RAM)
- ECS Service: `screenshot-service-prd` (desired count: 1)
- Auto Scaling Target: Scale between 1-10 tasks
- Auto Scaling Policies:
  - CPU Target: 70%
  - Memory Target: 80%
  - SQS Queue Depth: 5 messages/task

**Verification:**

```bash
# Check ECS cluster
aws-vault exec screenshot-service-prd -- aws ecs list-clusters

# Check ECS service
aws-vault exec screenshot-service-prd -- aws ecs describe-services \
    --cluster screenshot-service-prd \
    --services screenshot-service-prd

# Check running tasks
aws-vault exec screenshot-service-prd -- aws ecs list-tasks \
    --cluster screenshot-service-prd

# View task logs
aws-vault exec screenshot-service-prd -- aws logs tail \
    /ecs/screenshot-service-prd --follow
```

---

### Layer 5: Monitoring

Creates CloudWatch alarms and dashboards.

```bash
cd ../5.monitor

# Initialize Terraform
aws-vault exec screenshot-service-prd -- terraform init

# Review planned changes
aws-vault exec screenshot-service-prd -- terraform plan

# Apply changes
aws-vault exec screenshot-service-prd -- terraform apply
```

**What gets created:**
- CloudWatch Alarms:
  - `screenshot-queue-depth-high` (>50 messages for 5 minutes)
  - `screenshot-ecs-cpu-high` (>80% CPU for 5 minutes)
  - `screenshot-ecs-memory-high` (>85% memory for 5 minutes)
  - `screenshot-dlq-messages` (>0 messages in DLQ)
- SNS Topic: `screenshot-alerts-prd` (optional)
- CloudWatch Dashboard: `screenshot-service-prd`

**Verification:**

```bash
# List alarms
aws-vault exec screenshot-service-prd -- aws cloudwatch describe-alarms \
    --alarm-names screenshot-queue-depth-high

# View dashboard
aws-vault exec screenshot-service-prd -- aws cloudwatch list-dashboards
```

---

### Layer 6: API Gateway & Lambda

Creates REST API with Lambda functions.

#### 6.1 Package Lambda Functions

```bash
cd ../6.api

# Package Lambda functions
./package-lambdas.sh

# This creates:
# - lambdas/createScreenshot.zip
# - lambdas/getScreenshotStatus.zip
# - lambdas/healthCheck.zip
```

#### 6.2 Deploy API Layer

```bash
# Initialize Terraform
aws-vault exec screenshot-service-prd -- terraform init

# Review planned changes
aws-vault exec screenshot-service-prd -- terraform plan

# Apply changes
aws-vault exec screenshot-service-prd -- terraform apply

# Get API endpoint
aws-vault exec screenshot-service-prd -- terraform output api_endpoint
```

**What gets created:**
- API Gateway REST API: `screenshot-api-prd`
- Lambda Functions:
  - `createScreenshot-prd` (POST /screenshots)
  - `getScreenshotStatus-prd` (GET /screenshots/{id})
  - `healthCheck-prd` (GET /health)
- API Gateway Stage: `v1`
- API Gateway Deployment

**API Endpoint Example:**
```
https://abc123xyz.execute-api.ap-southeast-1.amazonaws.com/v1
```

**Verification:**

```bash
# Test health check
curl https://abc123xyz.execute-api.ap-southeast-1.amazonaws.com/v1/health

# Test screenshot creation
curl -X POST https://abc123xyz.execute-api.ap-southeast-1.amazonaws.com/v1/screenshots \
    -H "Content-Type: application/json" \
    -d '{"url": "https://example.com"}'

# Response:
# {
#   "requestId": "screenshot-abc123",
#   "status": "processing",
#   "message": "Screenshot request queued"
# }

# Get screenshot status
curl https://abc123xyz.execute-api.ap-southeast-1.amazonaws.com/v1/screenshots/screenshot-abc123

# Response:
# {
#   "id": "screenshot-abc123",
#   "url": "https://example.com",
#   "status": "success",
#   "s3Url": "https://screenshot-bucket-prd.s3.amazonaws.com/screenshots/2025/01/19/...",
#   "createdAt": "2025-01-19T10:00:00Z",
#   "updatedAt": "2025-01-19T10:00:30Z"
# }
```

---

## ⚙️ Configuration

### Environment Variables (ECS Task Definition)

The following environment variables are configured in [terraform/envs/prd/4.backend/main.tf](terraform/envs/prd/4.backend/main.tf):

```json
{
  "environment": [
    { "name": "AWS_REGION", "value": "ap-southeast-1" },
    { "name": "SQS_QUEUE_URL", "value": "https://sqs.ap-southeast-1.amazonaws.com/333333333333/screenshot-queue-prd" },
    { "name": "S3_BUCKET_NAME", "value": "screenshot-bucket-prd-xxxxx" },
    { "name": "DYNAMODB_TABLE_NAME", "value": "screenshot-results-prd" },
    { "name": "NODE_ENV", "value": "production" },
    { "name": "LOG_LEVEL", "value": "info" },
    { "name": "SCREENSHOT_WIDTH", "value": "1920" },
    { "name": "SCREENSHOT_HEIGHT", "value": "1080" },
    { "name": "SCREENSHOT_FORMAT", "value": "png" },
    { "name": "SCREENSHOT_QUALITY", "value": "90" },
    { "name": "SQS_BATCH_SIZE", "value": "1" },
    { "name": "SQS_WAIT_TIME_SECONDS", "value": "20" },
    { "name": "HEALTH_CHECK_PORT", "value": "5000" }
  ]
}
```

### Terraform Variables

Key variables can be customized in `terraform.tfvars`:

**VPC Configuration:**
```terraform
vpc_cidr = "10.0.0.0/16"
availability_zones = ["ap-southeast-1a", "ap-southeast-1b"]
```

**ECS Configuration:**
```terraform
ecs_task_cpu    = "1024"  # 1 vCPU (256, 512, 1024, 2048, 4096)
ecs_task_memory = "2048"  # 2 GB (512, 1024, 2048, 4096, 8192)
ecs_desired_count = 1
ecs_min_capacity  = 1
ecs_max_capacity  = 10
```

**SQS Configuration:**
```terraform
sqs_visibility_timeout = 300        # 5 minutes
sqs_message_retention  = 1209600    # 14 days
sqs_max_receive_count  = 3          # DLQ after 3 retries
```

**DynamoDB Configuration:**
```terraform
dynamodb_billing_mode = "PAY_PER_REQUEST"  # or "PROVISIONED"
dynamodb_point_in_time_recovery = true
```

---

## 📊 Monitoring & Operations

### CloudWatch Dashboards

Access the CloudWatch dashboard:

```bash
# Open in browser
aws-vault exec screenshot-service-prd -- \
    aws cloudwatch get-dashboard --dashboard-name screenshot-service-prd
```

**Dashboard Metrics:**
- SQS Queue Depth (Main, Priority, FIFO, DLQ)
- ECS Task Count (Running, Pending, Stopped)
- ECS CPU/Memory Utilization
- Lambda Invocation Count & Errors
- DynamoDB Read/Write Capacity
- API Gateway Request Count & Latency

### CloudWatch Alarms

| Alarm | Threshold | Action |
|-------|-----------|--------|
| `screenshot-queue-depth-high` | >50 messages for 5 min | Scale up ECS tasks |
| `screenshot-ecs-cpu-high` | >80% CPU for 5 min | Investigate performance issues |
| `screenshot-ecs-memory-high` | >85% memory for 5 min | Increase task memory |
| `screenshot-dlq-messages` | >0 messages | Investigate failed screenshots |

### Viewing Logs

**ECS Task Logs:**
```bash
# Tail logs in real-time
aws-vault exec screenshot-service-prd -- \
    aws logs tail /ecs/screenshot-service-prd --follow

# View specific log stream
aws-vault exec screenshot-service-prd -- \
    aws logs get-log-events \
    --log-group-name /ecs/screenshot-service-prd \
    --log-stream-name ecs/screenshot-task-prd/abc123
```

**Lambda Logs:**
```bash
# Tail Lambda logs
aws-vault exec screenshot-service-prd -- \
    aws logs tail /aws/lambda/createScreenshot-prd --follow
```

**Filter Logs by Error:**
```bash
aws-vault exec screenshot-service-prd -- \
    aws logs filter-log-events \
    --log-group-name /ecs/screenshot-service-prd \
    --filter-pattern "ERROR"
```

### Debugging Failed Screenshots

**1. Check Dead Letter Queue:**
```bash
# Receive messages from DLQ
aws-vault exec screenshot-service-prd -- \
    aws sqs receive-message \
    --queue-url https://sqs.ap-southeast-1.amazonaws.com/333333333333/screenshot-dlq-prd \
    --max-number-of-messages 10
```

**2. Query DynamoDB for Failed Screenshots:**
```bash
# Using AWS CLI
aws-vault exec screenshot-service-prd -- \
    aws dynamodb query \
    --table-name screenshot-results-prd \
    --index-name status-createdAt-index \
    --key-condition-expression "#status = :status" \
    --expression-attribute-names '{"#status":"status"}' \
    --expression-attribute-values '{":status":{"S":"failed"}}'
```

**3. View Error Details:**
```javascript
// Example failed record in DynamoDB
{
  "id": "screenshot-abc123",
  "url": "https://invalid-url.com",
  "status": "failed",
  "errorMessage": "Navigation timeout: Page load exceeded 30000ms",
  "createdAt": "2025-01-19T10:00:00Z",
  "updatedAt": "2025-01-19T10:00:35Z"
}
```

### Operational Runbooks

#### Runbook 1: Scale Up for Traffic Spike

```bash
# Temporarily increase max capacity
cd terraform/envs/prd/4.backend
echo 'ecs_max_capacity = 20' >> terraform.tfvars
aws-vault exec screenshot-service-prd -- terraform apply

# After traffic spike, scale back down
echo 'ecs_max_capacity = 10' >> terraform.tfvars
aws-vault exec screenshot-service-prd -- terraform apply
```

#### Runbook 2: Force Drain SQS Queue

```bash
# Purge all messages (use with caution!)
aws-vault exec screenshot-service-prd -- \
    aws sqs purge-queue \
    --queue-url https://sqs.ap-southeast-1.amazonaws.com/333333333333/screenshot-queue-prd
```

#### Runbook 3: Rollback ECS Deployment

```bash
# Revert to previous task definition revision
aws-vault exec screenshot-service-prd -- \
    aws ecs update-service \
    --cluster screenshot-service-prd \
    --service screenshot-service-prd \
    --task-definition screenshot-task-prd:5  # Previous revision

# Force new deployment
aws-vault exec screenshot-service-prd -- \
    aws ecs update-service \
    --cluster screenshot-service-prd \
    --service screenshot-service-prd \
    --force-new-deployment
```

---

## 💰 Cost Optimization

### Estimated Monthly Costs (Production)

| Service | Configuration | Estimated Cost |
|---------|---------------|----------------|
| **ECS Fargate** | 1-10 tasks, 1 vCPU, 2GB RAM | $30-$300/month |
| **SQS** | 1M requests/month | $0.40/month |
| **S3** | 100GB storage, 10k requests | $2.50/month |
| **DynamoDB** | On-demand, 1M reads/writes | $1.25/month |
| **Lambda** | 100k invocations, 256MB | $0.20/month |
| **API Gateway** | 1M requests | $3.50/month |
| **CloudWatch** | 10GB logs, 10 alarms | $5.00/month |
| **NAT Gateway** | 100GB data transfer | $45.00/month |
| **Total** | | **~$88-$358/month** |

### Cost Optimization Strategies

#### 1. Use Reserved Capacity for Baseline Load

If you have consistent baseline traffic, consider Savings Plans:

```terraform
# Switch to PROVISIONED billing for predictable load
dynamodb_billing_mode = "PROVISIONED"
dynamodb_read_capacity = 5
dynamodb_write_capacity = 5
```

#### 2. Enable S3 Lifecycle Policies

Automatically transition old screenshots to cheaper storage:

```terraform
# In modules/s3/main.tf
lifecycle_rule {
  enabled = true

  transition {
    days          = 30
    storage_class = "STANDARD_IA"  # Infrequent Access
  }

  transition {
    days          = 90
    storage_class = "GLACIER"  # Archive
  }

  expiration {
    days = 365  # Delete after 1 year
  }
}
```

**Cost Savings**: ~70% reduction after 30 days

#### 3. Reduce NAT Gateway Costs

Use VPC Endpoints for S3 and DynamoDB to avoid NAT Gateway:

```terraform
# Already implemented in modules/vpc/main.tf
resource "aws_vpc_endpoint" "s3" {
  vpc_id       = aws_vpc.main.id
  service_name = "com.amazonaws.${var.region}.s3"
  route_table_ids = [aws_route_table.private.id]
}
```

**Cost Savings**: ~$30-$40/month (eliminates S3/DynamoDB data transfer via NAT)

#### 4. Enable API Gateway Caching

Reduce Lambda invocations for repeated requests:

```terraform
# In terraform/envs/prd/6.api/main.tf
cache_cluster_enabled = true
cache_cluster_size    = "0.5"  # 0.5GB cache
cache_ttl_seconds     = 300    # 5 minutes
```

**Cost Savings**: ~50% reduction in Lambda invocations for cacheable endpoints

#### 5. Use Spot Instances for Development

For dev/staging environments, use Fargate Spot:

```terraform
# In terraform/envs/dev/4.backend/main.tf
capacity_provider = "FARGATE_SPOT"  # Up to 70% discount
```

---

## 🔧 Troubleshooting

### Common Issues

#### Issue 1: Terraform State Lock

**Symptom:**
```
Error: Error acquiring the state lock
Lock Info:
  ID: 12345678-1234-1234-1234-123456789012
```

**Solution:**
```bash
# Force unlock (use with caution!)
aws-vault exec screenshot-service-prd -- \
    terraform force-unlock 12345678-1234-1234-1234-123456789012

# Or delete DynamoDB lock item
aws-vault exec screenshot-service-prd -- \
    aws dynamodb delete-item \
    --table-name screenshot-service-prd-iac-state-lock \
    --key '{"LockID":{"S":"screenshot-service-prd-iac-state/layer4/backend/terraform.tfstate"}}'
```

---

#### Issue 2: ECS Task Failing to Start

**Symptom:**
```
Task stopped (Essential container exited): Screenshot service exited
```

**Diagnosis:**
```bash
# Check task stopped reason
aws-vault exec screenshot-service-prd -- \
    aws ecs describe-tasks \
    --cluster screenshot-service-prd \
    --tasks <task-id> \
    --query 'tasks[0].stoppedReason'

# Check CloudWatch logs
aws-vault exec screenshot-service-prd -- \
    aws logs tail /ecs/screenshot-service-prd --since 5m
```

**Common Causes:**
- Missing environment variables
- IAM role lacks S3/SQS/DynamoDB permissions
- Docker image not found in ECR
- Out of memory (OOM) kill

**Solution:**
```bash
# Verify IAM role permissions
aws-vault exec screenshot-service-prd -- \
    aws iam get-role-policy \
    --role-name ecs-task-role \
    --policy-name ecs-task-policy

# Check ECR image exists
aws-vault exec screenshot-service-prd -- \
    aws ecr describe-images \
    --repository-name screenshot-service-prd
```

---

#### Issue 3: Screenshots Failing with Timeout

**Symptom:**
```json
{
  "status": "failed",
  "errorMessage": "Navigation timeout: Page load exceeded 30000ms"
}
```

**Solution:**

1. **Increase Puppeteer timeout** (in backend application):
```javascript
// src/config/index.js
module.exports = {
  SCREENSHOT_TIMEOUT: 60000  // Increase to 60 seconds
};
```

2. **Increase SQS visibility timeout**:
```bash
cd terraform/envs/prd/1.general
echo 'sqs_visibility_timeout = 600' >> terraform.tfvars  # 10 minutes
aws-vault exec screenshot-service-prd -- terraform apply
```

---

#### Issue 4: High DLQ Message Count

**Symptom:**
```
CloudWatch Alarm: screenshot-dlq-messages (ALARM)
Dead Letter Queue has 15 messages
```

**Diagnosis:**
```bash
# Sample DLQ messages
aws-vault exec screenshot-service-prd -- \
    aws sqs receive-message \
    --queue-url https://sqs.ap-southeast-1.amazonaws.com/333333333333/screenshot-dlq-prd \
    --max-number-of-messages 10 \
    --attribute-names All \
    --message-attribute-names All
```

**Common Causes:**
- Invalid URLs (404, DNS resolution failures)
- Browser crashes (out of memory)
- S3 upload failures (permissions, quota)

**Solution:**
```bash
# After fixing root cause, re-drive messages from DLQ to main queue
# (Requires custom script or manual process)
```

---

### Health Check Debugging

**Check API Health:**
```bash
curl https://abc123xyz.execute-api.ap-southeast-1.amazonaws.com/v1/health
```

**Expected Response:**
```json
{
  "status": "healthy",
  "timestamp": "2025-01-19T10:00:00Z",
  "services": {
    "sqs": "connected",
    "s3": "connected",
    "dynamodb": "connected"
  }
}
```

---

## 🤝 Contributing

### Making Infrastructure Changes

1. **Create a feature branch:**
```bash
git checkout -b feature/add-sns-notifications
```

2. **Make changes in a specific layer:**
```bash
cd terraform/envs/prd/5.monitor
# Edit main.tf to add SNS topic
```

3. **Test changes in dev environment first:**
```bash
cd terraform/envs/dev/5.monitor
aws-vault exec screenshot-service-dev -- terraform plan
aws-vault exec screenshot-service-dev -- terraform apply
```

4. **Validate changes:**
```bash
# Run terraform validate
aws-vault exec screenshot-service-dev -- terraform validate

# Run terraform fmt
terraform fmt -recursive
```

5. **Deploy to staging:**
```bash
cd terraform/envs/stg/5.monitor
aws-vault exec screenshot-service-stg -- terraform apply
```

6. **Deploy to production:**
```bash
cd terraform/envs/prd/5.monitor
aws-vault exec screenshot-service-prd -- terraform apply
```

7. **Commit changes:**
```bash
git add .
git commit -m "feat: Add SNS notifications for critical alarms"
git push origin feature/add-sns-notifications
```

---

### Terraform Best Practices

1. **Always use `terraform plan` before `apply`**
2. **Never commit `terraform.tfvars` with secrets** (use `.gitignore`)
3. **Use Terraform modules for reusability**
4. **Tag all resources with environment and owner**
5. **Enable state file encryption**
6. **Use separate AWS accounts for dev/stg/prd**
7. **Document all variables in `_variables.tf`**

---
