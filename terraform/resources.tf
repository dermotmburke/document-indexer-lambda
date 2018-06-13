provider "aws" {
  access_key = "${var.accessKey}"
  secret_key = "${var.secretKey}"
  region = "${var.region}"
}

resource "aws_iam_role" "iam_for_terraform_lambda" {
  name = "app_${var.appEnv}_lambda"
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

resource "aws_iam_role_policy_attachment" "terraform_lambda_iam_policy_basic_execution" {
  role = "${aws_iam_role.iam_for_terraform_lambda.id}"
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy_attachment" "terraform_lambda_iam_policy_s3_read_access" {
  role = "${aws_iam_role.iam_for_terraform_lambda.id}"
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess"
}

resource "aws_lambda_permission" "allow_terraform_bucket" {
  statement_id = "AllowExecutionFromS3Bucket"
  action = "lambda:InvokeFunction"
  function_name = "${aws_lambda_function.terraform_func.arn}"
  principal = "s3.amazonaws.com"
  source_arn = "${aws_s3_bucket.terraform_bucket.arn}"
}

resource "aws_lambda_function" "terraform_func" {
  function_name = "${var.lambdaFunctionName}"
  role = "${aws_iam_role.iam_for_terraform_lambda.arn}"
  handler = "${var.lambdaFunctionHandler}"
  runtime = "${var.runtime}"
  timeout = "${var.timeout}"
  memory_size = "${var.memorySize}"
  s3_bucket = "${var.lambdaFunctionBucket}"
  s3_key = "${var.artifactId}-all-${var.version}.jar"
  environment {
    variables = {
      DOCUMENT_INDEX = "https://${aws_elasticsearch_domain.es.endpoint}"
    }
  }
}

resource "aws_s3_bucket" "terraform_bucket" {
  bucket = "bp-poc-documents-${var.appEnv}"
  force_destroy = "${var.appEnv == "dev" ? true : false}"
}

resource "aws_s3_bucket_notification" "bucket_terraform_notification" {
  bucket = "${aws_s3_bucket.terraform_bucket.id}"
  lambda_function {
    lambda_function_arn = "${aws_lambda_function.terraform_func.arn}"
    events = ["s3:ObjectCreated:*"]
    filter_suffix = ".pdf"
  }
}

resource "aws_elasticsearch_domain" "es" {
  domain_name           = "search-bp-documents-${var.appEnv}"
  elasticsearch_version = "6.2"
  cluster_config {
    instance_type = "t2.small.elasticsearch"
  }

  ebs_options {
    ebs_enabled = true
    volume_size = 10
    volume_type = "standard"
  }

  advanced_options {
    "rest.action.multi.allow_explicit_index" = "true"
  }

  access_policies = <<CONFIG
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "AWS": "*"
      },
      "Action": "es:*",
      "Resource": "arn:aws:es:us-east-1:079634347139:domain/search-bp-documents-${var.appEnv}/*"
    }
  ]
}
CONFIG

  snapshot_options {
    automated_snapshot_start_hour = 23
  }

  tags {
    Domain = "TestDomain"
  }
}

output "esEndpoint" {
  value = "https://${aws_elasticsearch_domain.es.endpoint}"
}
