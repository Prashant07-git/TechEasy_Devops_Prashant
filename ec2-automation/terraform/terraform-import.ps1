Write-Output "🔷 Checking and importing existing AWS resources…"

$region = "ap-south-1"
$sgName = "dev-ec2-sg"
$roleName = "dev-ec2-s3-role"

# Go to Terraform dir
Set-Location ec2-automation/terraform

# Initialize Terraform
terraform init

# Check if SG exists in AWS
$sgId = aws ec2 describe-security-groups --region $region --filters Name=group-name,Values=$sgName `
    --query "SecurityGroups[0].GroupId" --output text

if ($sgId -ne "None" -and $sgId -ne "") {
    Write-Output "✅ Security Group '$sgName' exists with ID: $sgId"
    Write-Output "🔷 Importing Security Group into Terraform state…"
    terraform import aws_security_group.ec2_sg $sgId
}
else {
    Write-Output "🔷 Security Group '$sgName' does not exist. Terraform will create it."
}

# Check if IAM Role exists in AWS
$role = aws iam get-role --role-name $roleName -–region $region -ErrorAction SilentlyContinue

if ($LASTEXITCODE -eq 0) {
    Write-Output "✅ IAM Role '$roleName' exists"
    Write-Output "🔷 Importing IAM Role into Terraform state…"
    terraform import aws_iam_role.ec2_s3_role $roleName
}
else {
    Write-Output "🔷 IAM Role '$roleName' does not exist. Terraform will create it."
}

Write-Output "✅ Pre-import complete. You can now run 'terraform plan' and 'terraform apply'."
