#!/bin/bash

LOG_FILE="deployment_$(date +'%Y-%m-%d_%H-%M-%S').log"
exec > >(tee -a "$LOG_FILE") 2>&1
set -e

echo "🚀 Script started"

STAGE=$1
if [ -z "$STAGE" ]; then
  echo "❌ Please provide stage name like: Dev or Prod"
  exit 1
fi

CONFIG_FILE="Config/${STAGE,,}_config.sh"
if [ ! -f "$CONFIG_FILE" ]; then
  echo "❌ Config file not found: $CONFIG_FILE"
  exit 1
fi
source "$CONFIG_FILE"
echo "✅ Loaded config: REGION=$REGION, KEY_NAME=$KEY_NAME, PEM_FILE=$PEM_FILE"

echo "🚀 Installing dependencies, deploying app & configuring log uploads..."
ssh -o StrictHostKeyChecking=no -i "$PEM_FILE" ubuntu@$PUBLIC_IP <<EOF
set -e

S3_BUCKET="techeazy-app-logs-dev"
AWS_REGION="$REGION"

echo "🔷 Updating apt..."
sudo apt update -y

echo "🔷 Installing Java, Git, Curl, Unzip, AWS CLI..."
sudo apt install -y openjdk-21-jdk git curl unzip awscli

echo "🔷 Checking if Maven is installed..."
if ! command -v mvn &> /dev/null; then
    echo "🔷 Maven not found, installing via apt..."
    sudo apt install -y maven
fi

echo "📦 Cloning repo and building app..."
cd /home/ubuntu
rm -rf techeazy-devops || true
git clone https://github.com/techeazy-consulting/techeazy-devops.git
cd techeazy-devops
chmod +x mvnw || true
mvn clean package -DskipTests

echo "🚀 Running app on port 80..."
sudo nohup java -jar target/techeazy-devops-0.0.1-SNAPSHOT.jar > /home/ubuntu/app.log 2>&1 &

echo "🔷 Creating log uploader script..."
cat > /home/ubuntu/upload-logs.sh <<EOL
#!/bin/bash
export AWS_REGION="$AWS_REGION"
S3_BUCKET="$S3_BUCKET"
TIMESTAMP=\$(date +"%Y-%m-%d_%H-%M-%S")

if [ -f /home/ubuntu/app.log ]; then
  aws s3 cp /home/ubuntu/app.log s3://\$S3_BUCKET/app_logs/app_\$TIMESTAMP.log --region \$AWS_REGION
fi

if [ -f /var/log/syslog ]; then
  aws s3 cp /var/log/syslog s3://\$S3_BUCKET/ec2_logs/syslog_\$TIMESTAMP.log --region \$AWS_REGION
else
  dmesg > /home/ubuntu/ec2.log
  aws s3 cp /home/ubuntu/ec2.log s3://\$S3_BUCKET/ec2_logs/dmesg_\$TIMESTAMP.log --region \$AWS_REGION
fi
EOL

chmod +x /home/ubuntu/upload-logs.sh

echo "🔷 Scheduling cron job for log uploads..."
echo '* * * * * /home/ubuntu/upload-logs.sh >> /home/ubuntu/log-upload-cron.log 2>&1' | crontab -


echo "✅ App deployed & log upload cron job set."
EOF

echo "✅ Application deployed! Accessible at: http://$PUBLIC_IP:80"
