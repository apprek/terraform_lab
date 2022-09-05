# Cuurent Region
data "aws_region" "current" {}

# To get the access to the effective Account ID, User ID, and ARN 
data "aws_caller_identity" "current" {}


# Data resource to archive Lambda function code
data "archive_file" "lambda2_zip" {
    source_dir  = "${path.module}/lambda2/"
    output_path = "${path.module}/lambda2.zip"
    type        = "zip"
}


# Data resource to archive Lambda role
data "aws_iam_role" "lambda_role" {
    name = "${var.app_env}-lambda-role"
}


# # Key for encrypting S3 bucket
# resource "aws_kms_key" "bucketkey" {
#   description             = "This key is used to encrypt bucket objects"
#   deletion_window_in_days = 10
# }

# Create S3 bucket 
resource "aws_s3_bucket" "bucket" {
  bucket = "${var.app_env}-${terraform.workspace}-bucket"
}

# resource "aws_s3_bucket_acl" "bucket_acl" {
#   bucket = aws_s3_bucket.bucket.bucket
#   acl    = "private"
# }

# # Enable encryption on bucket
# resource "aws_s3_bucket_server_side_encryption_configuration" "encrypt_bucket" {
#   bucket = aws_s3_bucket.bucket.bucket

#   rule {
#     apply_server_side_encryption_by_default {
#       kms_master_key_id = aws_kms_key.bucketkey.arn
#       sse_algorithm     = "aws:kms"
#     }
#   }
# }

# # Make bucket private
# resource "aws_s3_bucket_acl" "private_objects" {
#   bucket = aws_s3_bucket.bucket.id
#   acl    = "private"
# }

# resource "aws_s3_bucket_public_access_block" "private_bucket" {
#   bucket = aws_s3_bucket.bucket.id

#   block_public_acls       = true
#   block_public_policy     = true
#   ignore_public_acls      = true
#   restrict_public_buckets = true
# }

# Create SQS Queue
resource "aws_sqs_queue" "queue" {
  name = "${var.app_env}-s3-event-notification-queue"
  # kms_master_key_id                 = "alias/aws/sqs"
  # kms_data_key_reuse_period_seconds = 300
  # visibility_timeout_seconds  = 90

  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": "*",
      "Action": "sqs:SendMessage",
      "Resource": "arn:aws:sqs:${var.region}:${data.aws_caller_identity.current.account_id}:${var.app_env}-s3-event-notification-queue"

    }
  ]
}
POLICY
}


# S3 event filter
resource "aws_s3_bucket_notification" "bucket_notification" { 
      bucket = aws_s3_bucket.bucket.id
      queue {
            id = aws_sqs_queue.queue.id
            queue_arn =   aws_sqs_queue.queue.arn
            events        = ["s3:ObjectCreated:*"]
        }
      depends_on = [aws_sqs_queue.queue] 
}

# Lambda function declaration
resource "aws_lambda_function" "sqs_processor" {
    filename = "lambda2.zip"
    source_code_hash = data.archive_file.lambda2_zip.output_base64sha256
    function_name = "${var.app_env}-lambda2"
    role =  data.aws_iam_role.lambda_role.arn 
    handler = "sqs_check.handler"
    runtime = "python3.8"
    timeout = 180
}

# # Event source from SQS
# resource "aws_lambda_event_source_mapping" "event_source_mapping" {
#   event_source_arn = aws_sqs_queue.queue.arn
#   enabled          = true
#   function_name    = aws_lambda_function.sqs_processor.arn
#   batch_size       = 1
  
# }

# # CloudWatch Log Group for the Lambda function
# resource "aws_cloudwatch_log_group" "lambda_loggroup" {
#     name = "/aws/lambda/${aws_lambda_function.sqs_processor.function_name}"
#     retention_in_days = 14
# }


resource "aws_dynamodb_table" "check-claim-dynamodb-table" {
  name           = "ClaimCheck"
  billing_mode   = "PROVISIONED"
  read_capacity  = 1
  write_capacity = 1
  hash_key       = "ObjectKey"
  range_key      = "S3Bucket"
 

  attribute {
    name = "ObjectKey"
    type = "S"
  }

  attribute {
    name = "S3Bucket"
    type = "S"
  }


  tags = {
    Name        = "${var.app_env}-dynamodb-table"
    Environment = "${var.region}"
  }
}


# Cloudwatch event rule to execute Lambda function every 5 minutes
resource "aws_cloudwatch_event_rule" "every_five_minutes" {
  name                = "every-five-minutes"
  description         = "Fires every five minutes"
  schedule_expression = "rate(5 minutes)"
}

# Cloudwatch target every 5 minutes
resource "aws_cloudwatch_event_target" "check_sqs_queue_every_five_minutes" {
  rule      = "${aws_cloudwatch_event_rule.every_five_minutes.name}"
  target_id = "lambda"
  arn       = "${aws_lambda_function.sqs_processor.arn}"
}


# Invoke lambda to allow_cloudwatch_to_call_check_sqs_queue
resource "aws_lambda_permission" "allow_cloudwatch_to_call_check_sqs_queue" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = "${aws_lambda_function.sqs_processor.function_name}"
  principal     = "events.amazonaws.com"
  source_arn    = "${aws_cloudwatch_event_rule.every_five_minutes.arn}"
}
