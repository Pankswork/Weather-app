Create a weather app using python and flask:
 create s3 bucket first :
 
# 1. Create the bucket
aws s3 mb s3://weather-app-panks-bucket --region us-east-1

# Enable versioning (highly recommended for state files)
aws s3api put-bucket-versioning --bucket weather-app-panks-bucket --versioning-configuration Status=Enabled

# if lockstate/creating new s3
terraform import aws_iam_policy.lbc_iam_policy arn:aws:iam::668227158023:policy/AWSLoadBalancerControllerIAMPolicy

# 2. create .env file
#Api keys and credentials
WEATHER_API_KEY="your api key"
DB_HOST=db
DB_USER="your username"
DB_PASSWORD="your password"
DB_NAME="your database name"
DOCKER_IMAGE="your docker image"
DOCKER_TAG="your docker tag"

# 3. Add secrets to github
AWS_ACCESS_KEY_ID
AWS_SECRET_ACCESS_KEY
DB_PASSWORD
DB_USERNAME
DOCKER_PASSWORD
DOCKER_USERNAME

# 4. create terraform.tfvars file
aws_region       = "your aws region"
cluster_name     = "your cluster name"
docker_hub_image = "your docker image"
mysql_username   = "your username"
mysql_password   = "your password"
secret_name      = "your secret name"

# 5. Changes 
changes account id in deployment.yaml and serviceaccount.yaml

# 6. Trigger CI/CD pipeline
push changes to github repo (make changes to readme file) since it is configured to trigger on push to master branch.
once pushed go to actions > left side top > cicd piple > run workflow(since auto triggered is disabled)

# 7. Access the application
Once the pipeline is complete, you can access the application at the URL provided by the Load Balancer.



