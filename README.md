# Finzla Cloud & Platform Engineer Technical Assessment

This repository contains a small Python HTTP service packaged with Docker and deployed to AWS using Terraform. The infrastructure uses ECR for image storage, ECS Fargate for compute, an Application Load Balancer for ingress, and CloudWatch for logs, metrics, and alerts.

## Application

The service listens on port `8000` and exposes:

- `GET /` returns a basic hello response.
- `GET /health` returns `200 OK` for load balancer and deployment health checks.
- `GET /version` returns the application version.

## Infrastructure

Terraform is organized into reusable modules under `Terraform/modules` and a deployable development environment under `Terraform/environments/dev`.

Implemented modules:

- `vpc`: VPC, public subnets, private subnets, route tables, internet gateway, and one NAT gateway.
- `ecr`: private ECR repository for the Docker image.
- `alb`: public Application Load Balancer, listener, target group, and ALB security group.
- `ecs`: ECS Fargate cluster, task definition, service, task execution role, task security group, and CloudWatch log group.
- `cloudwatch`: CloudWatch alarms for HTTP errors, latency, and unhealthy targets.

## Cost And Reliability Tradeoff

The VPC uses one NAT gateway for private subnet egress. This reduces cost compared with one NAT gateway per Availability Zone, which is appropriate for this assessment and a small non-production environment.

The tradeoff is reduced Availability Zone isolation. If the Availability Zone containing the NAT gateway has an outage, ECS tasks in private subnets may lose outbound access to services such as ECR and CloudWatch Logs. A production deployment would normally use one NAT gateway per Availability Zone or private VPC endpoints for ECR, S3, and CloudWatch Logs.

## Deployment

From `Terraform/environments/dev`:

```bash
terraform init
terraform validate
terraform plan
terraform apply
```

The Docker image is built locally, tagged with the ECR repository URL, and pushed to ECR:

```bash
docker build -t python-http-service .
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin 536697239284.dkr.ecr.us-east-1.amazonaws.com
docker tag python-http-service:latest 536697239284.dkr.ecr.us-east-1.amazonaws.com/python-http-service:latest
docker push 536697239284.dkr.ecr.us-east-1.amazonaws.com/python-http-service:latest
```

After deployment, get the ALB DNS name:

```bash
terraform output alb_dns_name
```

Verify the service:

```bash
curl http://<alb-dns-name>/
curl http://<alb-dns-name>/health
curl http://<alb-dns-name>/version
```

## Monitoring And Logging

Application logs are written by the ECS task to CloudWatch Logs through the `awslogs` driver. Logs are found in:

```text
/ecs/<service-name>
```

The current retention period is `7` days. This keeps enough recent operational history for troubleshooting while limiting storage cost in a small assessment environment. A production environment may use longer retention or export logs to S3 depending on audit and compliance requirements.

### Useful Metrics

The CloudWatch module defines three useful ALB-based service health metrics:

- `HTTPCode_Target_5XX_Count`: counts HTTP 5xx responses returned by the ECS targets. This detects backend application failures.
- `TargetResponseTime`: measures request latency from the ALB to the target. This detects slow responses before the service becomes fully unavailable.
- `UnHealthyHostCount`: counts unhealthy targets in the ALB target group. This detects failed ECS tasks, failed health checks, or networking issues between the ALB and service.

Additional ECS metrics worth tracking in production are CPU utilization, memory utilization, and running task count.

### Alerts

The CloudWatch module creates these alarms:

- High HTTP 5xx alarm
  - Trigger: `HTTPCode_Target_5XX_Count >= 5` over five 1-minute periods.
  - Why it matters: users are receiving server errors from the application.
  - Receiver: platform/on-call engineer through an SNS topic or incident management integration.
  - First investigation step: check ECS service events and the CloudWatch log group `/ecs/<service-name>` for application errors.

- High latency alarm
  - Trigger: average `TargetResponseTime >= 1` second over five 1-minute periods.
  - Why it matters: the application may be degraded even if requests are still succeeding.
  - Receiver: platform/on-call engineer through an SNS topic or incident management integration.
  - First investigation step: inspect recent application logs, ECS CPU and memory utilization, and ALB target response trends.

- Unhealthy targets alarm
  - Trigger: `UnHealthyHostCount >= 1` over three 1-minute periods.
  - Why it matters: the ALB has reduced or no healthy ECS capacity to route traffic to.
  - Receiver: platform/on-call engineer through an SNS topic or incident management integration.
  - First investigation step: check ALB target group health, ECS task status, task stop reasons, and the `/health` endpoint behavior.

Alarm actions are configurable through the CloudWatch module's `alarm_actions` variable. In a production environment this should point to an SNS topic connected to the team email, chat, or incident response tool.

## CI/CD And Deployment Pipeline

The GitHub Actions workflow is defined in `.github/workflows/ci-cd.yml`.

The pipeline as instructed should demonstrate:

```text
Pull Request -> Validation -> Review -> Merge -> Build -> Push -> Deploy -> Health Check
```

Pull request checks include:

- Terraform formatting with `terraform fmt -check -recursive`.
- Terraform validation with `terraform init` and `terraform validate`.
- Terraform plan for the target environment.
- Application build/test using `python -m py_compile server.py` and Docker image build.
- A simple Dockerfile quality check using Hadolint.

Deployment:

- Build the Docker image.
- Push the `latest` tag to ECR.
- Deploy the new version with Terraform and force a new ECS deployment so ECS pulls the updated `latest` image.
- Confirm application health through the ALB `/health` endpoint.
- Handle unhealthy deployments by failing the workflow when the health check does not pass.

GitHub should authenticate to AWS using OIDC and short-lived credentials. Permanent AWS access keys must not be stored in GitHub secrets.

Production deployments use the `production` GitHub Environment. This environment should be configured with required reviewers before deployment jobs can run.

GitHub authenticates to AWS using OIDC through an IAM role stored as the `AWS_ROLE_ARN` secret. The AWS IAM role trust policy should restrict access by repository, branch, workflow, and environment claims. This prevents another GitHub repository, a compromised workflow from an untrusted branch, or an individual developer without review approval from freely deploying into production.

The deployment job runs only after changes are merged to `main`. Pull requests can validate and plan, but they cannot push images or deploy infrastructure.
