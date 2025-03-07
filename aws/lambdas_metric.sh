#!/bin/bash
# This script list all Lambda functions with aws cli, and get the number of invocations in  last 7 days time frame, ordered by invocations from more to less.

# Set start and end times for the last 7 days
end_time=$(date -u +"%Y-%m-%dT%H:%M:00Z")
start_time=$(date -u -d "-7 days" +"%Y-%m-%dT%H:%M:00Z")

declare -A invocations

# Get list of Lambda functions
function_names=$(aws lambda list-functions --query 'Functions[*].FunctionName' --output text)

# Recorrer cada función y obtener la métrica "Invocations"
for function_name in $function_names; do
    echo $function_name
    sum=$(aws cloudwatch get-metric-statistics \
        --metric-name Invocations \
        --start-time "$start_time" \
        --end-time "$end_time" \
        --period 86400 \
        --namespace AWS/Lambda \
        --statistics Sum \
        --dimensions Name=FunctionName,Value="$function_name" \
        --query 'Datapoints[0].Sum' \
        --output text)
    
    # Evaluate if sum is None or null
    if [[ $sum == "None" ]] || [[ $sum == "null" ]]; then
        sum=0
    fi
    
    invocations[$function_name]=$sum
done

# Order and print the functions from most to least used
for function in "${!invocations[@]}"; do
    echo -e "${invocations[$function]}\t$function"
done | sort -rn