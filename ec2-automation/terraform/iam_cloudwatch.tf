resource "aws_iam_policy" "cloudwatch_policy" {
  name        = "${var.stage}-cloudwatch-policy"
  description = "Policy for EC2 to send logs to CloudWatch"
  policy      = <<EOT
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents",
        "logs:DescribeLogStreams"
      ],
      "Resource": "*"
    }
  ]
}
EOT
}

resource "aws_iam_role_policy_attachment" "attach_cloudwatch_policy" {
  role       = aws_iam_role.s3_upload_role.name
  policy_arn = aws_iam_policy.cloudwatch_policy.arn
}
