#!/bin/bash
set -e

ALB_DNS=$1
CLUSTER_NAME="api-cluster"
SERVICE_NAME="api"
REGION="us-east-1"

echo "Stress Test - Auto-scaling "
echo "URL: http://$ALB_DNS/api"

INITIAL_TASKS=$(aws ecs describe-services --cluster $CLUSTER_NAME --services $SERVICE_NAME --region $REGION --query 'services[0].runningCount' --output text)

echo "INITIAL # TASKS: $INITIAL_TASKS"
echo ""

echo "Starting monitoring..."
(
  for i in {1..60}; do
    sleep 5
    CURRENT_TASKS=$(aws ecs describe-services --cluster $CLUSTER_NAME --services $SERVICE_NAME --region $REGION --query 'services[0].runningCount' --output text)
    DESIRED_TASKS=$(aws ecs describe-services --cluster $CLUSTER_NAME --services $SERVICE_NAME --region $REGION --query 'services[0].desiredCount' --output text)

    echo "[$i] Tasks - Running: $CURRENT_TASKS | Desired: $DESIRED_TASKS"

    if [ "$DESIRED_TASKS" -gt "$INITIAL_TASKS" ]; then
      echo "Auto-scaling triggered! Desired count increased to $DESIRED_TASKS"
    fi
  done
) &

MONITOR_PID=$!

echo ""
echo "USING hey TO GENERATE LOAD"

hey -z 600s -c 500 -q 50 http://$ALB_DNS/api

echo "FINISH TEST"

sleep 10
kill $MONITOR_PID 2>/dev/null || true

FINAL_TASKS=$(aws ecs describe-services --cluster $CLUSTER_NAME --services $SERVICE_NAME --region $REGION --query 'services[0].runningCount' --output text)

echo ""
echo "Results:"
echo "Initial tasks: $INITIAL_TASKS"
echo "Final tasks: $FINAL_TASKS"
echo ""

if [ "$FINAL_TASKS" -gt "$INITIAL_TASKS" ]; then
  echo "Auto-scaling worked! from $INITIAL_TASKS to $FINAL_TASKS TASKS"
else
  echo "No scaling detected."
fi

echo ""
echo "Check CloudWatch dashboard for detailed metrics"
