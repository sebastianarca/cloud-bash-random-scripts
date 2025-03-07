#!/bin/bash
# This script list all ECR respostories with aws cli, and inspect lifecycle policy for each repository, if there is no lifecycle policy, list the repository name and inform that there is no lifecycle policy in the list of repositories.

export AWS_PROFILE=qa

declare -A repositories_with_lifecycle=()
declare -A repositories_without_lifecycle=()

echo -e "\n\n Fetching all ECR repositories..."
repositories=$(aws --profile $AWS_PROFILE ecr describe-repositories --query 'repositories[*].repositoryName' --output text)
if [ $? -ne 0 ]; then
    echo "Error fetching repositories. Please check your AWS CLI configuration."
    exit 1
fi

# repositories=(example-valid-repo) # To test, has lifecycle policy

echo -e "\n\n Inspecting lifecycle policies for each repository..."
for repository in $repositories; do
    echo "Checking repository: $repository"
    lifecycle_policy=$(aws --profile $AWS_PROFILE ecr get-lifecycle-policy --repository-name $repository --query 'lifecyclePolicyText' --output json)
    if  [ $? -ne 0 ]; then
        echo "No lifecycle policy found for repository: $repository"
        repositories_without_lifecycle[$repository]="No lifecycle policy"
    else
        echo "Lifecycle policy found for repository: $repository"
        repositories_with_lifecycle[$repository]=$lifecycle_policy
    fi
done

echo -e "\n\n Repositories with lifecycle policy:"
for repository in ${!repositories_with_lifecycle[@]}; do
    echo "$repository"
done

echo -e "\n\n Repositories without lifecycle policy:"
for repository in ${!repositories_without_lifecycle[@]}; do
    echo "$repository"
done

echo -e "\n\n Script execution completed."