project        = "project"
env            = "stg"
region         = "ap-southeast-1"
api_stage_name = "v1"

# ECS Configuration (Lower resources for staging)
ecs_cluster_name            = "screenshots-ecs-cluster"
ecs_task_definition_family  = "screenshots-task"
ecs_service_name            = "screenshots-service"
ecs_desired_count           = 1
ecs_task_cpu                = 512
ecs_task_memory             = 1024
ecs_container_port          = 8080

# ECS Auto Scaling (More conservative for staging)
ecs_autoscaling_enabled           = true
ecs_min_capacity                  = 1
ecs_max_capacity                  = 5
ecs_autoscale_cpu_target          = 70
ecs_autoscale_memory_target       = 80
ecs_autoscale_sqs_messages_per_task = 5
ecs_scale_in_cooldown             = 300
ecs_scale_out_cooldown            = 60

# API Gateway Configuration (Disable cache for staging)
enable_api_cache = false
api_cache_size   = "0.5"
api_cache_ttl    = 300

# DynamoDB Configuration
enable_dynamodb_backup  = false
analytics_data_ttl_days = 30
dynamodb_billing_mode   = "PAY_PER_REQUEST"
