#!/bin/bash
set -e

CLUSTER_NAME="api-cluster"
SERVICE_NAME="api"
REGION="us-east-1"

echo "ECS TASK FAILURE SIMULATION"
echo ""

echo "1. TASKS INFO"
CURRENT_TASKS=$(aws ecs list-tasks --cluster $CLUSTER_NAME --service-name $SERVICE_NAME --region $REGION --query 'taskArns[]' --output text)
TASK_COUNT=$(echo $CURRENT_TASKS | wc -w)

echo "#TASKS: $TASK_COUNT"
echo "ARNs:"
echo "$CURRENT_TASKS" | tr '\t' '\n'
echo ""

TASK_TO_KILL=$(echo $CURRENT_TASKS | awk '{print $1}')

echo "2. STOPPING: $TASK_TO_KILL"
aws ecs stop-task --cluster $CLUSTER_NAME --task $TASK_TO_KILL --region $REGION --reason "Simulated failure for resilience testing" --output json > /dev/null

# Monitor the recovery
echo "3. LOOP CHECK."
echo ""

for i in {1..12}; do
  sleep 5
  NEW_TASKS=$(aws ecs list-tasks --cluster $CLUSTER_NAME --service-name $SERVICE_NAME --region $REGION --query 'taskArns[]' --output text)
  NEW_TASK_COUNT=$(echo $NEW_TASKS | wc -w)

  echo "[$i] RUNNING #: $NEW_TASK_COUNT"

  if [ $NEW_TASK_COUNT -ge $TASK_COUNT ]; then
    echo ""
    echo "ALL SET!!"
    echo "ARNs: "
    echo "$NEW_TASKS" | tr '\t' '\n'
    exit 0
  fi
done

echo ""
echo "TIMEOUT :: Check AWS Console"
