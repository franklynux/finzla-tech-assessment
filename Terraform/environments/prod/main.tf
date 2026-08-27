module "vpc" {
  source = "../../modules/vpc"
}

module "ecr" {
  source          = "../../modules/ecr"
  repository_name = var.repo_name
}

module "alb" {
  source            = "../../modules/alb"
  vpc_id            = module.vpc.vpc_id
  public_subnet_ids = module.vpc.public_subnet_ids
}

module "ecs" {
  source             = "../../modules/ecs"
  vpc_id             = module.vpc.vpc_id
  target_group_arn   = module.alb.target_group_arn
  private_subnet_ids = module.vpc.app_private_subnet_ids
  public_subnet_ids  = module.vpc.public_subnet_ids
  container_image    = "${module.ecr.repository_url}:latest"
  alb_sg_id          = module.alb.alb_sg_id
}

module "cloudwatch" {
  source                  = "../../modules/cloudwatch"
  service_name            = module.ecs.ecs_service_name
  alb_arn_suffix          = module.alb.alb_arn_suffix
  target_group_arn_suffix = module.alb.target_group_arn_suffix
}
