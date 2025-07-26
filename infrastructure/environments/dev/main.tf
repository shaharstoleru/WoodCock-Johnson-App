terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# Get the latest Amazon Linux 2 AMI
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# IAM Role for EC2 to allow SSM
resource "aws_iam_role" "ec2_role" {
  name = "${var.project_name}-ec2-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

# Attach SSM policy to role
resource "aws_iam_role_policy_attachment" "ssm_policy" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# Instance profile
resource "aws_iam_instance_profile" "ec2_profile" {
  name = "${var.project_name}-ec2-profile"
  role = aws_iam_role.ec2_role.name
}

# VPC - רשת וירטואלית
resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name        = "${var.project_name}-vpc"
    Environment = var.environment
  }
}

# Internet Gateway
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.project_name}-igw"
  }
}

# Public Subnet
resource "aws_subnet" "public_a" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "${var.aws_region}a"
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.project_name}-public-a"
  }
}

# Route Table
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name = "${var.project_name}-public-rt"
  }
}

resource "aws_route_table_association" "public_a" {
  subnet_id      = aws_subnet.public_a.id
  route_table_id = aws_route_table.public.id
}

# Security Group
resource "aws_security_group" "web" {
  name_prefix = "${var.project_name}-web"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-web-sg"
  }
}

# Launch Template עם האפליקציה שלך
resource "aws_launch_template" "app" {
  name_prefix   = "${var.project_name}-"
  image_id      = data.aws_ami.amazon_linux.id
  instance_type = "t3.micro"

  iam_instance_profile {
    name = aws_iam_instance_profile.ec2_profile.name
  }

  vpc_security_group_ids = [aws_security_group.web.id]

  user_data = base64encode(<<-EOF
#!/bin/bash
yum update -y
yum install -y docker
systemctl start docker
systemctl enable docker

mkdir -p /var/www/html

# הורדת האפליקציה המלאה שלך מ-GitHub Raw
curl -L "https://raw.githubusercontent.com/shaharstoleru/WoodCock-Johnson-App/main/src/index.html" -o /var/www/html/index.html

# בדיקה אם ההורדה הצליחה
if [ ! -f /var/www/html/index.html ] || [ ! -s /var/www/html/index.html ]; then
  # נסה branch master
  curl -L "https://raw.githubusercontent.com/shaharstoleru/WoodCock-Johnson-App/master/src/index.html" -o /var/www/html/index.html
fi

# אם עדיין לא עובד, צור גיבוי מהאפליקציה שלך
if [ ! -f /var/www/html/index.html ] || [ ! -s /var/www/html/index.html ]; then
cat > /var/www/html/index.html << 'HTML_END'
<!DOCTYPE html>
<html lang="he" dir="rtl">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>מערכת אבחון פסיכו-חינוכית מקיפה</title>
    <style>
        * {margin: 0;padding: 0;box-sizing: border-box;}
        body {font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);min-height: 100vh;padding: 20px;direction: rtl;}
        .container {max-width: 1400px;margin: 0 auto;background: white;border-radius: 20px;box-shadow: 0 20px 40px rgba(0, 0, 0, 0.1);overflow: hidden;}
        .header {background: linear-gradient(135deg, #4facfe 0%, #00f2fe 100%);color: white;text-align: center;padding: 40px 20px;}
        .header h1 {font-size: 2.5em;margin-bottom: 10px;font-weight: 700;}
        .header p {font-size: 1.2em;opacity: 0.9;}
        .nav-tabs {display: flex;background: #f8f9fa;border-bottom: 2px solid #dee2e6;overflow-x: auto;}
        .nav-tab {padding: 15px 20px;cursor: pointer;border: none;background: none;font-size: 16px;font-weight: 600;color: #6c757d;border-bottom: 3px solid transparent;transition: all 0.3s ease;white-space: nowrap;}
        .nav-tab.active {color: #3498db;border-bottom-color: #3498db;background: white;}
        .nav-tab:hover {background: #e9ecef;color: #495057;}
        .tab-content {display: none;padding: 40px;min-height: 600px;}
        .tab-content.active {display: block;}
        .section {margin-bottom: 40px;padding: 30px;background: #f8f9fa;border-radius: 15px;border: 1px solid #e9ecef;}
        .section h2 {color: #2c3e50;margin-bottom: 20px;font-size: 1.8em;border-bottom: 3px solid #3498db;padding-bottom: 10px;}
        .form-group {margin-bottom: 20px;}
        .form-group label {display: block;margin-bottom: 8px;font-weight: 600;color: #34495e;font-size: 1.1em;}
        .form-group input, .form-group select, .form-group textarea {width: 100%;padding: 12px;border: 2px solid #e9ecef;border-radius: 8px;font-size: 1em;transition: all 0.3s ease;font-family: inherit;}
        .form-group textarea {min-height: 100px;resize: vertical;}
        .form-group input:focus, .form-group select:focus, .form-group textarea:focus {outline: none;border-color: #3498db;box-shadow: 0 0 0 3px rgba(52, 152, 219, 0.1);}
        .grid-2 {display: grid;grid-template-columns: repeat(2, 1fr);gap: 20px;}
        .button {background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);color: white;padding: 15px 30px;border: none;border-radius: 50px;font-size: 1.1em;font-weight: 600;cursor: pointer;transition: all 0.3s ease;margin: 10px;}
        .button:hover {transform: translateY(-3px);box-shadow: 0 10px 20px rgba(0, 0, 0, 0.2);}
        .success-box {background: #e8f5e8;border: 2px solid #27ae60;border-radius: 10px;padding: 20px;margin: 20px 0;text-align: center;}
        @media (max-width: 768px) {.header h1 {font-size: 2em;}.tab-content {padding: 20px;}.grid-2 {grid-template-columns: 1fr;}.nav-tabs {flex-direction: column;}.nav-tab {text-align: center;}}
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>מערכת אבחון פסיכו-חינוכית מקיפה</h1>
            <p>מערכת מתקדמת לאבחון מקיף של ילדים - כל המבחנים במקום אחד</p>
        </div>

        <div class="success-box">
            <h3>🎉 המערכת פועלת בהצלחה על AWS EC2!</h3>
            <p>רצה בפרנקפורט, גרמניה</p>
        </div>

        <nav class="nav-tabs">
            <button class="nav-tab active" onclick="showTab('student-info')">פרטי התלמיד</button>
            <button class="nav-tab" onclick="showTab('bender-test')">מבחן בנדר</button>
            <button class="nav-tab" onclick="showTab('conners-test')">קונרס</button>
            <button class="nav-tab" onclick="showTab('final-report')">דוח סופי</button>
        </nav>

        <div id="student-info" class="tab-content active">
            <div class="section">
                <h2>פרטי התלמיד</h2>
                <div class="grid-2">
                    <div class="form-group">
                        <label for="studentName">שם התלמיד:</label>
                        <input type="text" id="studentName" placeholder="הזן שם מלא">
                    </div>
                    <div class="form-group">
                        <label for="studentId">ת.ז. התלמיד:</label>
                        <input type="text" id="studentId" placeholder="מספר זהות">
                    </div>
                    <div class="form-group">
                        <label for="birthDate">תאריך לידה:</label>
                        <input type="date" id="birthDate">
                    </div>
                    <div class="form-group">
                        <label for="grade">כיתה:</label>
                        <select id="grade">
                            <option value="">בחר כיתה</option>
                            <option value="1">כיתה א'</option>
                            <option value="2">כיתה ב'</option>
                            <option value="3">כיתה ג'</option>
                        </select>
                    </div>
                </div>
            </div>
        </div>

        <div id="bender-test" class="tab-content">
            <div class="section">
                <h2>מבחן בנדר</h2>
                <div class="form-group">
                    <label>ציון גולמי:</label>
                    <input type="number" placeholder="הזן ציון">
                </div>
                <div class="form-group">
                    <label>הערות:</label>
                    <textarea placeholder="הערות על המבחן"></textarea>
                </div>
            </div>
        </div>

        <div id="conners-test" class="tab-content">
            <div class="section">
                <h2>מבחן קונרס</h2>
                <div class="form-group">
                    <label>ציון T מורים:</label>
                    <input type="number" placeholder="הזן ציון">
                </div>
                <button class="button">חשב ציונים</button>
            </div>
        </div>

        <div id="final-report" class="tab-content">
            <div class="section">
                <h2>דוח סופי</h2>
                <div class="form-group">
                    <label>סיכום:</label>
                    <textarea placeholder="סיכום הממצאים"></textarea>
                </div>
                <button class="button">צור דוח</button>
            </div>
        </div>
    </div>

    <script>
        function showTab(tabId) {
            document.querySelectorAll('.tab-content').forEach(tab => tab.classList.remove('active'));
            document.querySelectorAll('.nav-tab').forEach(button => button.classList.remove('active'));
            document.getElementById(tabId).classList.add('active');
            event.target.classList.add('active');
        }
        console.log('מערכת אבחון WoodCock Johnson - פועלת בהצלחה!');
    </script>
</body>
</html>
HTML_END
fi

# הפעל nginx
docker run -d -p 80:80 --name diagnosis-app -v /var/www/html:/usr/share/nginx/html:ro --restart unless-stopped nginx:alpine

echo "$(date): WoodCock Johnson diagnosis app deployed!" >> /var/log/deployment.log
EOF
  )

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name        = "${var.project_name}-instance"
      Environment = var.environment
    }
  }
}

# Auto Scaling Group
resource "aws_autoscaling_group" "app" {
  name                = "${var.project_name}-asg"
  vpc_zone_identifier = [aws_subnet.public_a.id]

  min_size         = 1
  max_size         = 2
  desired_capacity = 1

  launch_template {
    id      = aws_launch_template.app.id
    version = "$Latest"
  }

  health_check_type         = "EC2"
  health_check_grace_period = 300

  tag {
    key                 = "Name"
    value               = "${var.project_name}-instance"
    propagate_at_launch = true
  }

  tag {
    key                 = "Environment"
    value               = var.environment
    propagate_at_launch = true
  }
}

# Auto Scaling Policies
resource "aws_autoscaling_policy" "scale_up" {
  name                   = "${var.project_name}-scale-up"
  scaling_adjustment     = 1
  adjustment_type        = "ChangeInCapacity"
  cooldown              = 300
  autoscaling_group_name = aws_autoscaling_group.app.name
}

resource "aws_autoscaling_policy" "scale_down" {
  name                   = "${var.project_name}-scale-down"
  scaling_adjustment     = -1
  adjustment_type        = "ChangeInCapacity"
  cooldown              = 300
  autoscaling_group_name = aws_autoscaling_group.app.name
}

# CloudWatch Alarms
resource "aws_cloudwatch_metric_alarm" "high_cpu" {
  alarm_name          = "${var.project_name}-high-cpu"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "300"
  statistic           = "Average"
  threshold           = "80"
  alarm_description   = "High CPU usage"
  alarm_actions       = [aws_autoscaling_policy.scale_up.arn]

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.app.name
  }
}

resource "aws_cloudwatch_metric_alarm" "low_cpu" {
  alarm_name          = "${var.project_name}-low-cpu"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = "3"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "300"
  statistic           = "Average"
  threshold           = "20"
  alarm_description   = "Low CPU usage"
  alarm_actions       = [aws_autoscaling_policy.scale_down.arn]

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.app.name
  }
}