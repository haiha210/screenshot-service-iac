project        = "project"
env            = "dev"
region         = "ap-southeast-1"
api_stage_name = "v1"

# ECS Configuration (Minimal resources for development)
ecs_cluster_name            = "screenshots-ecs-cluster"
ecs_task_definition_family  = "screenshots-task"
ecs_service_name            = "screenshots-service"
ecs_desired_count           = 1
ecs_task_cpu                = 256
ecs_task_memory             = 512
ecs_container_port          = 8080

# ECS Auto Scaling (Minimal for development)
ecs_autoscaling_enabled           = false
ecs_min_capacity                  = 1
ecs_max_capacity                  = 2
ecs_autoscale_cpu_target          = 70
ecs_autoscale_memory_target       = 80
ecs_autoscale_sqs_messages_per_task = 5
ecs_scale_in_cooldown             = 300
ecs_scale_out_cooldown            = 60

# API Gateway Configuration (No cache for development)
enable_api_cache = false
api_cache_size   = "0.5"
api_cache_ttl    = 300

# DynamoDB Configuration (Minimal for development)
enable_dynamodb_backup  = false
analytics_data_ttl_days = 7
dynamodb_billing_mode   = "PAY_PER_REQUEST"
