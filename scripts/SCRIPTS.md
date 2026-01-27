## Testing Scripts

The project includes automated test scripts to validate resilience and auto-scaling capabilities.

### Prerequisites for Testing

Install the load testing tool `hey`:

```bash
# macOS
brew install hey

# Linux
go install github.com/rakyll/hey@latest

# Or download binary from: https://github.com/rakyll/hey/releases
```

### 1. Simulate Task Failure Test

This script tests ECS service resilience by stopping a running task and monitoring automatic recovery.

**What it does:**
- Lists current running tasks
- Stops one task to simulate a failure
- Monitors the service until it recovers to the desired count
- Validates that ECS automatically starts a replacement task

**How to run:**

```bash
cd scripts
./simulate-task-failure.sh
```

**Expected output:**
```
ECS TASK FAILURE SIMULATION

1. TASKS INFO
#TASKS: 2
ARNs:
arn:aws:ecs:us-east-1:443370700365:task/api-cluster/abc123...

2. STOPPING: arn:aws:ecs:us-east-1:443370700365:task/api-cluster/abc123...
3. LOOP CHECK.

[1] RUNNING #: 1
[2] RUNNING #: 2

ALL SET!!
```

**What to verify:**
- Task count drops by 1 initially
- Service automatically launches a new task
- Recovery completes within 30-60 seconds

### 2. Auto-Scaling Stress Test

This script generates sustained load to trigger auto-scaling policies.

**What it does:**
- Records the initial task count
- Generates HTTP load using `hey` (500 concurrent connections for 10 minutes)
- Monitors task count every 5 seconds
- Reports when auto-scaling triggers
- Shows final task count after test

**How to run:**

First, get your ALB DNS name:

```bash
cd infra
ALB_DNS=$(terraform output -raw alb_dns)
echo $ALB_DNS
```

Then run the stress test:

```bash
cd ../scripts
./stress-test.sh $ALB_DNS
```

**Example:**
```bash
./stress-test.sh api-ha-alb-123456789.us-east-1.elb.amazonaws.com
```

**Expected output:**
```
Stress Test - Auto-scaling
URL: http://api-ha-alb-123456789.us-east-1.elb.amazonaws.com/api
INITIAL # TASKS: 2

Starting monitoring...
[1] Tasks - Running: 2 | Desired: 2
[2] Tasks - Running: 2 | Desired: 2
[3] Tasks - Running: 2 | Desired: 4
Auto-scaling triggered! Desired count increased to 4
[4] Tasks - Running: 3 | Desired: 4
[5] Tasks - Running: 4 | Desired: 4

USING hey TO GENERATE LOAD
...

Results:
Initial tasks: 2
Final tasks: 4

Auto-scaling worked! from 2 to 4 TASKS
```

**What to verify:**
- Task count increases when CPU/Memory reaches threshold (>70%)
- New tasks are launched and become healthy
- Load is distributed across all tasks
- Check CloudWatch metrics for CPU and Memory utilization

### Monitor CloudWatch During Tests

While tests are running, monitor these CloudWatch metrics:

1. **ECS Service Metrics:**
   - CPU Utilization
   - Memory Utilization
   - Running Task Count

2. **ALB Metrics:**
   - Request Count
   - Target Response Time
   - Healthy/Unhealthy Host Count

3. **CloudWatch Alarms:**
   - Check if alarms triggered (email notifications)

Access metrics:
```bash
# View recent CPU utilization
aws cloudwatch get-metric-statistics \
  --namespace AWS/ECS \
  --metric-name CPUUtilization \
  --dimensions Name=ServiceName,Value=api Name=ClusterName,Value=api-cluster \
  --start-time $(date -u -d '10 minutes ago' +%Y-%m-%dT%H:%M:%S) \
  --end-time $(date -u +%Y-%m-%dT%H:%M:%S) \
  --period 60 \
  --statistics Average \
  --region us-east-1
```

### Customizing Test Scripts

You can modify the scripts to adjust test parameters:

**simulate-task-failure.sh:**
- `CLUSTER_NAME`: Your ECS cluster name (default: `api-cluster`)
- `SERVICE_NAME`: Your ECS service name (default: `api`)
- `REGION`: AWS region (default: `us-east-1`)

**stress-test.sh:**
- `-z 600s`: Duration (default: 10 minutes)
- `-c 500`: Concurrent connections (default: 500)
- `-q 50`: Queries per second per worker (default: 50)

Example with custom parameters:
```bash
# High intensity test (1000 concurrent for 5 minutes)
hey -z 300s -c 1000 -q 100 http://$ALB_DNS/api
```