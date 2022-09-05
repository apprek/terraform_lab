
# To get the access to the effective Account ID, User ID, and ARN 
data "aws_caller_identity" "current" {}

data "aws_iam_policy" "aws_lambda_basic" {
  name = "AWSLambdaBasicExecutionRole" 
  arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}


# Lambda function policy
resource "aws_iam_policy" "lambda_policy" {
    name        = "${var.app_env}-lambda-policy"
    description = "${var.app_env}-lambda-policy"
 
    policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "s3:GetObject",
        "s3:PutObject"
      ],
      "Effect": "Allow",
      "Resource": "arn:aws:s3:::${var.app_env}-${terraform.workspace}-bucket/*"
    },
    {
      "Action": [
        "sqs:ReceiveMessage",
        "sqs:DeleteMessage",
        "sqs:GetQueueAttributes"
      ],
      "Effect": "Allow",
      "Resource":"*"
    },
    {
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      "Effect": "Allow",
      "Resource": "*"
    },
    {
        "Sid": "ListAndDescribeDynanmoDB",
        "Effect": "Allow",
        "Action": [
            "dynamodb:List*",
            "dynamodb:DescribeReservedCapacity*",
            "dynamodb:DescribeLimits",
            "dynamodb:DescribeTimeToLive"
        ],
        "Resource": "*"
    },
    {
        "Sid": "SpecificDynamoDBTable",
        "Effect": "Allow",
        "Action": [
            "dynamodb:BatchGet*",
            "dynamodb:DescribeStream",
            "dynamodb:DescribeTable",
            "dynamodb:Get*",
            "dynamodb:Query",
            "dynamodb:Scan",
            "dynamodb:BatchWrite*",
            "dynamodb:CreateTable",
            "dynamodb:Delete*",
            "dynamodb:Update*",
            "dynamodb:PutItem"
        ],
        "Resource": "arn:aws:dynamodb:*:*:table/ClaimCheck"
    }
  ]
}
EOF
}

# Lambda function role
resource "aws_iam_role" "iam_for_terraform_lambda" {
    name = "${var.app_env}-lambda-role"
    assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow"
    }
  ]
}
EOF
}

# Role to attach Lambda IAM Policy 
resource "aws_iam_role_policy_attachment" "terraform_lambda_iam_policy_basic_execution" {
    role = aws_iam_role.iam_for_terraform_lambda.id
    policy_arn = aws_iam_policy.lambda_policy.arn
}

resource "aws_iam_role_policy_attachment" "terraform_aws_lambda_basic_execution" {
    role = aws_iam_role.iam_for_terraform_lambda.id
    policy_arn = data.aws_iam_policy.aws_lambda_basic.arn
}



#############################################################
# SQS IAM policy
resource "aws_iam_policy" "sqs_policy" {
    name        = "${var.app_env}-sqs-policy"
    description = "${var.app_env}-sqs-policy"
    # queue_url = data.aws_sqs_queue.queue.id
    policy = <<POLICY
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "VisualEditor0",
            "Effect": "Allow",
            "Action": "sqs:ListQueues",
            "Resource": "*"
        },
        {
            "Sid": "VisualEditor1",
            "Effect": "Allow",
            "Action": "sqs:*",
            "Resource": "arn:aws:sqs:${var.region}:${data.aws_caller_identity.current.account_id}:${var.app_env}-queue"
        }
    ]

}
POLICY
}


# SQS role
resource "aws_iam_role" "iam_for_sqs" {
    name = "${var.app_env}-sqs-role"
    assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "sqs.amazonaws.com"
      },
      "Effect": "Allow"
    }
  ]
}
EOF
}

# Role to attach SQS IAM Policy 
resource "aws_iam_role_policy_attachment" "sqs_iam_policy_attachment" {
    role = aws_iam_role.iam_for_sqs.id
    policy_arn = aws_iam_policy.sqs_policy.arn
}
# ###################################################################
# # cloudwatch log IAM policy
# resource "aws_iam_policy" "cloudwatch_log_policy" {
#     name        = "${var.app_env}-cloudwatch_log_policy"
#     description = "${var.app_env}-cloudwatch_log_policy"
 
#     policy = <<EOF
# {

# }
# EOF
# }


# # SQS role
# resource "aws_iam_role" "iam_for_cloudwatch_log" {
#     name = "${var.app_env}-cloudwatch_log-role"
#     assume_role_policy = <<EOF
# {
#   "Version": "2012-10-17",
#   "Statement": [
#     {
#       "Action": "sts:AssumeRole",
#       "Principal": {
#         "Service": "cloudwatch.amazonaws.com"
#       },
#       "Effect": "Allow"
#     }
#   ]
# }
# EOF
# }

# # Role to attach Cloudwatch Log IAM Policy 
# resource "aws_iam_role_policy_attachment" "cloudwatch_log_iam_policy_attachment" {
#     role = aws_iam_role.iam_for_cloudwatch_log.id
#     policy_arn = aws_iam_policy.cloudwatch_log_policy.arn
# }