# This calls a custom RDS module to create a single RDS instance with option & parameter groups & multi-az and perf insights engabled.
# Also includes secrets manager storage for the randomised password that is (TO BE DONE) cycled periodically.

module "rds" {
  source = "./modules/rds"

  application_name            = local.application_name
  identifier_name             = local.application_name
  environment                 = local.environment
  region                      = local.application_data.accounts[local.environment].region
  allocated_storage           = local.application_data.accounts[local.environment].allocated_storage
  engine                      = local.application_data.accounts[local.environment].engine
  engine_version              = local.application_data.accounts[local.environment].engine_version
  instance_class              = local.application_data.accounts[local.environment].instance_class
  allow_major_version_upgrade = local.application_data.accounts[local.environment].allow_major_version_upgrade
  auto_minor_version_upgrade  = local.application_data.accounts[local.environment].auto_minor_version_upgrade
  storage_type                = local.application_data.accounts[local.environment].storage_type
  backup_retention_period     = local.application_data.accounts[local.environment].backup_retention_period
  backup_window               = local.application_data.accounts[local.environment].backup_window
  maintenance_window          = local.application_data.accounts[local.environment].maintenance_window
  character_set_name          = local.application_data.accounts[local.environment].character_set_name
  availability_zone           = local.application_data.accounts[local.environment].availability_zone
  multi_az                    = local.application_data.accounts[local.environment].multi_az
  username                    = local.application_data.accounts[local.environment].username
  db_password_rotation_period = local.application_data.accounts[local.environment].db_password_rotation_period
  license_model               = local.application_data.accounts[local.environment].license_model
  lz_vpc_cidr                 = local.application_data.accounts[local.environment].lz_vpc_cidr
  deletion_protection         = local.application_data.accounts[local.environment].deletion_protection
  vpc_shared_id               = data.aws_vpc.shared.id
  vpc_shared_cidr             = data.aws_vpc.shared.cidr_block
  vpc_subnet_a_id             = data.aws_subnet.data_subnets_a.id
  vpc_subnet_b_id             = data.aws_subnet.data_subnets_b.id
  vpc_subnet_c_id             = data.aws_subnet.data_subnets_c.id
}