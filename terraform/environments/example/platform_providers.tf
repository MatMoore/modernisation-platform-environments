# AWS provider for the workspace you're working in (every resource will default to using this, unless otherwise specified)
provider "aws" {
  alias  = "original-session"
  region = "eu-west-2"
}

provider "aws" {
  region = "eu-west-2"
  assume_role {
    role_arn = can(regex("modernisation-platform-developer", data.aws_iam_session_context.whoami.issuer_arn)) ? null : "arn:aws:iam::${data.aws_caller_identity.original_session.id}:role/MemberInfrastructureAccess"
  }
}

# AWS provider for the Modernisation Platform, to get things from there if required
provider "aws" {
  alias  = "modernisation-platform"
  region = "eu-west-2"
  assume_role {
    role_arn = "arn:aws:iam::${local.modernisation_platform_account_id}:role/modernisation-account-limited-read-member-access"
  }
}

# AWS provider for core-vpc-<environment>, to share VPCs into this account
provider "aws" {
  alias  = "core-vpc"
  region = "eu-west-2"
  assume_role {
    role_arn = can(regex("modernisation-platform-developer", data.aws_iam_session_context.whoami.issuer_arn)) ? "arn:aws:iam::${local.environment_management.account_ids[local.provider_name]}:role/member-delegation-read-only" : "arn:aws:iam::${local.environment_management.account_ids[local.provider_name]}:role/member-delegation-${local.vpc_name}-${local.environment}"
  }
}

# AWS provider for network services to enable dns entries for certificate validation to be created
provider "aws" {
  alias  = "core-network-services"
  region = "eu-west-2"
  assume_role {
    role_arn = can(regex("modernisation-platform-developer", data.aws_iam_session_context.whoami.issuer_arn)) ? "arn:aws:iam::${local.environment_management.account_ids["core-network-services-production"]}:role/read-dns-records" : "arn:aws:iam::${local.environment_management.account_ids["core-network-services-production"]}:role/modify-dns-records"
  }
}
