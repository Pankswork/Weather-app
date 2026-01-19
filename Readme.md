Create a weather app using python and flask:
 create s3 bucket first :
 # Create the bucket
aws s3 mb s3://weather-app-panks-bucket --region us-east-1

# Enable versioning (highly recommended for state files)
aws s3api put-bucket-versioning --bucket weather-app-panks-bucket --versioning-configuration Status=Enabled

# if lockstate/creating new s3
terraform import aws_iam_policy.lbc_iam_policy arn:aws:iam::668227158023:policy/AWSLoadBalancerControllerIAMPolicy
