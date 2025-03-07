#!/bin/bash
# This script list all ECR respostories with aws cli, and count the number of images in each repository. Then get the latest image upload date for each repository. The output is a file csv with format: repository_name, number_of_images, latest_image_upload_date.

export AWS_PROFILE=qa

declare -A ecr_count_images=()
declare -A ecr_date_latest_image_pushed=()

echo -e "\n\n Fetching all ECR repositories..."
repositories=$(aws --profile $AWS_PROFILE ecr describe-repositories --query 'repositories[*].repositoryName' --output text)
if [ $? -ne 0 ]; then
    echo "Error fetching repositories. Please check your AWS CLI configuration."
    exit 1
fi

echo -e "\n\n Counting images in each repository..."
for repository in $repositories; do
    echo "Checking repository: $repository"
    images_count=$(aws --profile $AWS_PROFILE ecr describe-images --repository-name $repository  --query 'length(imageDetails[*])' --output text)
    ecr_count_images[$repository]=$images_count
done

echo -e "\n\n Getting latest image pushed date in each repository..."
for repository in $repositories; do
    echo "Checking repository: $repository"
    latest_pushed_image=$(aws --profile $AWS_PROFILE ecr describe-images --repository-name $repository  --query 'sort_by(imageDetails,&imagePushedAt)[-1].imagePushedAt' --output text)
    ecr_date_latest_image_pushed[$repository]=$(date -d "$latest_pushed_image" +"%Y-%m-%d %H:%M:%S")
done

echo -e "\n\n Generate output as CSV format..."
echo "repository_name,number_of_images,latest_image_upload_date" > ecr_count_images.csv

for repository in $repositories; do
    echo "$repository,${ecr_count_images[$repository]},${ecr_date_latest_image_pushed[$repository]}" >> ecr_count_images.csv
done