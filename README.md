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
- Terraform validation with `terraform init -backend=false` and `terraform validate`.
- Application build/test using `python -m py_compile server.py` and Docker image build.
- A simple Dockerfile quality check using Hadolint.

Deployment:

- Authenticate to AWS using GitHub OIDC and the `AWS_ROLE_ARN` secret.
- Run Terraform plan against AWS after merge to `main`.
- Build the Docker image.
- Push the `latest` tag to ECR.
- Deploy the new version with Terraform and force a new ECS deployment so ECS pulls the updated `latest` image.
- Confirm application health through the ALB `/health` endpoint.
- Handle unhealthy deployments by failing the workflow when the health check does not pass.

GitHub authenticates to AWS with OIDC, so there are no long-lived AWS access keys stored in the repository. The workflow assumes an IAM role whose trust policy is limited to this repository and the `main` branch.

Production deployment is gated by the `production` GitHub Environment, which should require reviewer approval before the deploy job can run. The workflow uses a small approval job first, then runs the AWS deployment job only after that approval passes.

Pull requests can validate the code and Terraform syntax, but they do not receive AWS credentials and cannot push images or deploy infrastructure. A different repository, an unapproved branch, or a developer working outside the protected deployment flow would not match the IAM role trust policy or pass the GitHub environment approval step.

## Incident Investigation

Scenario: a new release has deployed, GitHub Actions reports success, ECS shows the expected number of tasks running, but customers receive HTTP `503` responses and the ALB reports unhealthy targets.

I would first check the ALB target group health. If the targets are unhealthy, the issue is usually between the load balancer and the ECS task: health check path, container port, security group rules, task startup, or application behavior.

Services and signals to inspect:

- ALB target group health: target status, reason codes, and health check failures.
- CloudWatch metrics: `UnHealthyHostCount`, `HTTPCode_Target_5XX_Count`, and `TargetResponseTime`.
- ECS service events: failed deployments, task replacement, or target registration issues.
- ECS task details: stopped task reasons, container exit codes, and image pull errors.
- CloudWatch Logs: `/ecs/<service-name>` for application startup and request errors.
- Security groups: ALB ingress, ECS task ingress from the ALB security group, and task egress.

Possible causes and how I would prove or eliminate them:

- Wrong health check path or response: call `/health` directly through the task if possible, check application logs, and confirm the target group health check path matches the app.
- Port mismatch: confirm the container listens on `8000`, the task definition exposes `8000`, the ECS service maps `8000`, and the target group points to `8000`.
- Security group issue: confirm the ECS task security group allows inbound traffic from the ALB security group on port `8000`.
- Application starts but fails after boot: check CloudWatch Logs for exceptions and ECS task restarts.
- Bad image or missing image tag: check ECS task events for image pull errors and confirm the expected image exists in ECR.

The safest immediate recovery action is to roll back to the last known good task definition or image tag, then force a new ECS deployment. If rollback is not ready, temporarily revert the application image to the previous working ECR tag and redeploy.

To prevent this reaching customers again, the pipeline should run a post-deployment health check against the ALB and fail the deployment if `/health` does not pass. For production, I would also use immutable image tags, ECS deployment circuit breaker with rollback, and a staged deployment strategy before shifting all traffic.

## Engineering Judgement

### Architecture

I chose ECS Fargate because it fits a small containerized HTTP service without requiring EC2 host management. ECR stores the image, ALB handles public traffic and health checks, ECS runs the container in private subnets, and CloudWatch provides logs, metrics, and alarms.

A reasonable alternative was EC2 with Docker or an Auto Scaling Group. I rejected it because it adds server patching, AMI management, and more operational work than this assessment needs.

### Reliability

If a new deployment starts but fails health checks, the ALB should stop sending traffic to the unhealthy tasks. ECS will try to keep the desired task count running, but users may still see errors if there are not enough healthy old tasks available.

Rollback would use the previous working image tag or task definition revision, then force a new ECS deployment. In production I would enable ECS deployment circuit breaker rollback and avoid relying only on the mutable `latest` tag.

### Cost

The two largest likely cost drivers are NAT gateway usage and ECS Fargate runtime.

To control NAT cost, this design uses one NAT gateway for the assessment. For production, I would consider VPC endpoints for ECR, S3, and CloudWatch Logs to reduce NAT data processing charges.

To control ECS cost, I would right-size CPU and memory, keep desired task count appropriate for traffic, use autoscaling, and separate dev/prod capacity.

### Production Readiness

The three most important improvements before using this for a fintech production platform are:

- Stronger security controls: least-privilege IAM, private VPC endpoints, WAF, secrets management, image vulnerability scanning, and tighter network rules.
- Safer deployments: immutable image tags, automated rollback, deployment circuit breaker, separate staging environment, and production approval gates.
- Better observability and resilience: structured logs, dashboards, alert routing, longer retention where required, multi-AZ NAT or VPC endpoints, and tested incident runbooks.
