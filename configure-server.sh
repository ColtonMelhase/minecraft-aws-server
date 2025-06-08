#!/bin/bash

EC2_USER=ec2-user
EC2_HOST=$1
KEY_PATH=minecraft-key.pem

MC_DIR="/minecraft"
MC_JAR_URL="https://piston-data.mojang.com/v1/objects/e6ec2f64e6080b9b5d9b471b291c33cc7f509733/server.jar"
SERVICE_FILE="/etc/systemd/system/minecraft.service"

# === SCRIPT START ===

echo "Connecting to EC2 and setting up Minecraft server..."

ssh -i "$KEY_PATH" "$EC2_USER@$EC2_HOST" "bash -s" <<EOF
  set -e

  echo "Installing Java..."
  sudo yum update -y
  sudo yum install java-21-amazon-corretto -y

  echo "Creating Minecraft directory..."
  sudo mkdir -p "$MC_DIR"
  sudo chown $EC2_USER:$EC2_USER "$MC_DIR"

  echo "Downloading Minecraft server jar..."
  cd "$MC_DIR"
  wget -O $MC_DIR/server.jar $MC_JAR_URL
  chmod +x "$MC_DIR/server.jar"

  echo "Accepting EULA..."
  echo "eula=true" > "$MC_DIR/eula.txt"

  echo "Creating systemd service..."
  sudo tee "$SERVICE_FILE" > /dev/null <<SERVICE
[Unit]
Description=Minecraft Server
After=network.target
Wants=network-online.target

[Service]
WorkingDirectory=$MC_DIR
ExecStart=/usr/bin/screen -DmS minecraft java -Xmx1024M -Xms1024M -jar server.jar nogui
ExecStop=/bin/bash -c "screen -S minecraft -p 0 -X stuff 'stop^M'"
User=$EC2_USER
Restart=on-failure
RestartSec=10
TimeoutStartSec=60
SuccessExitStatus=0 1

[Install]
WantedBy=multi-user.target
SERVICE

  echo "Enabling and starting service..."
  sudo systemctl daemon-reexec
  sudo systemctl daemon-reload
  sudo systemctl enable minecraft
  sudo systemctl start minecraft

  echo "Done setting up Minecraft server!"
EOF

echo "Minecraft server setup complete on $EC2_HOST"
