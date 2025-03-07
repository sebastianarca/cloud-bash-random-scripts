#!/bin/bash
# This script list all ECR respostories with aws cli, and count the number of images in each repository. Then get the latest image upload date for each repository. The output is a file csv with format: repository_name, number_of_images, latest_image_upload_date.

export AWS_PROFILE=prod

declare -A ecr_count_images=()
declare -A ecr_date_latest_image_pushed=()

echo -e "\n\n Fetching all ECR repositories..."
repositories=$(aws --profile $AWS_PROFILE ecr describe-repositories --query 'repositories[*].repositoryName' --output text)
if [ $? -ne 0 ]; then
    echo "Error fetching repositories. Please check your AWS CLI configuration."
    exit 1
fi

echo "" > ecr_count_images.csv.log

echo -e "\n\n Counting images in each repository..."
echo "\n\n Counting images in each repository" >> ecr_count_images.csv.log
for repository in $repositories; do
    echo "Counting images in repository: $repository"
    echo "\n\n $repository" >> ecr_count_images.csv.log
    images_count=$(aws --profile $AWS_PROFILE ecr describe-images --repository-name $repository  --query 'sum(to_array(length(imageDetails[*])))' --output json)
    echo ":$images_count" >> ecr_count_images.csv.log
    ecr_count_images[$repository]=$images_count
done

echo -e "\n\n Getting latest image pushed date in each repository..."
echo "\n\n Getting latest image pushed date in each repository" >> ecr_count_images.csv.log
for repository in $repositories; do
    echo "Getting latest image pushed date in repository: $repository"
    
    echo "\n\n $repository" >> ecr_count_images.csv.log
    # Get timestamp and clean microseconds + adjust timezone
    latest_pushed_image=$(aws --profile $AWS_PROFILE ecr describe-images --repository-name $repository --query 'sort(to_array(sort_by(imageDetails,&imagePushedAt)[-1].imagePushedAt))[-1]' --output json)
    echo ":$latest_pushed_image" >> ecr_count_images.csv.log
    
    ecr_date_latest_image_pushed["$repository"]="N/A"
    
    if [ -n "$latest_pushed_image" ]; then
        ecr_date_latest_image_pushed["$repository"]=$latest_pushed_image
        # formatted_date=$(date -d "$(echo "$latest_pushed_image" | sed 's/\(\.[0-9]\{6\}\)\([-+][0-9]\{2\}\):\([0-9]\{2\}\)/\1\2\3/' )" +"%Y-%m-%d %H:%M:%S" 2>/dev/null)
        # if [ $? -eq 0 ]; then
        #     ecr_date_latest_image_pushed["$repository"]=$formatted_date
        # else
        #     echo "Fail: Invalid date format for $repository. Using raw value."
        #     ecr_date_latest_image_pushed["$repository"]=$latest_pushed_image
        # fi
    fi
done

echo -e "\n\n Generate output as CSV format..."
echo "repository_name,number_of_images,latest_image_upload_date" > ecr_count_images.csv

for repository in $repositories; do
    echo "$repository,${ecr_count_images[$repository]},${ecr_date_latest_image_pushed[$repository]}" >> ecr_count_images.csv
done