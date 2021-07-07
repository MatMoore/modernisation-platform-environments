ami_image_id         = "ami-03dd3e42b5ea48f45"
instance_type        = "t3.large"
key_name             = "performance-hub-ec2"
app_count            = "1"
ec2_desired_capacity = 2
ec2_max_size         = 3
ec2_min_size         = 2
# cidr_access                   = []
server_port            = "80"
container_version      = "latest"
container_cpu          = "512"
container_memory       = "4096"
db_user                = "admin"
db_password_key        = "performance_hub_db"
db_snapshot_identifier = "performance-hub-initial"
