aws_region   = "us-east-1"
project_name = "claude-automation"
environment  = "dev"

# Networking
vpc_cidr            = "10.0.0.0/16"
availability_zones  = ["us-east-1a", "us-east-1b"]
public_subnet_cidrs = ["10.0.1.0/24", "10.0.2.0/24"]
app_subnet_cidrs    = ["10.0.11.0/24", "10.0.12.0/24"]
db_subnet_cidrs     = ["10.0.21.0/24", "10.0.22.0/24"]

# Web Tier
web_instance_type    = "t3.micro"
web_min_size         = 2
web_max_size         = 6
web_desired_capacity = 2

# App Tier
app_instance_type    = "t3.small"
app_min_size         = 2
app_max_size         = 6
app_desired_capacity = 2

# EC2 shared
ami_id          = "ami-0c02fb55956c7d316" # Amazon Linux 2 — us-east-1
key_name        = ""                       # Set to your key pair name, e.g. "my-keypair"
certificate_arn = ""                       # Set ACM ARN to enable HTTPS

# Database
db_name           = "appdb"
db_username       = "dbadmin"
db_instance_class = "db.t3.micro"
db_engine         = "mysql"
db_engine_version = "8.0"
db_multi_az       = false
db_allocated_storage = 20
