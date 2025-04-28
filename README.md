# Studio 14 DevOps Engineer Test - WordPress Deployment

This repository contains configuration files and documentation for deploying a WordPress application using Dokku with monitoring and backup capabilities.

## Setup Guide

### Prerequisites
- Ubuntu 22.04 LTS server
- SSH access to the server
- Domain pointing to the server (or local hosts file entry)

### 1. Server Preparation

```bash
# Update system
sudo apt update && sudo apt upgrade -y

# Install Dokku
wget -qO- https://packagecloud.io/dokku/dokku/gpgkey | sudo tee /etc/apt/trusted.gpg.d/dokku.asc
echo "deb https://packagecloud.io/dokku/dokku/ubuntu/ focal main" | sudo tee /etc/apt/sources.list.d/dokku.list
sudo apt update
sudo apt install -y dokku

# Configure hostname
sudo hostnamectl set-hostname devops.s14.local
echo "127.0.0.1 devops.s14.local" | sudo tee -a /etc/hosts

# Complete Dokku setup
sudo dokku domains:set-global devops.s14.local
```

### 2. WordPress Deployment

```bash
# Create WordPress app
dokku apps:create wordpress

# Set up MySQL database
dokku plugin:install https://github.com/dokku/dokku-mysql.git
dokku mysql:create wordpress-db
dokku mysql:link wordpress-db wordpress

# Create persistent storage for WordPress
mkdir -p /var/lib/dokku/data/storage/wordpress/wp-content
chown -R dokku:dokku /var/lib/dokku/data/storage/wordpress
dokku storage:mount wordpress /var/lib/dokku/data/storage/wordpress/wp-content:/var/www/html/wp-content

# Deploy WordPress (first time)
git clone https://github.com/your-username/wordpress-dokku.git
cd wordpress-dokku
git remote add dokku dokku@devops.s14.local:wordpress
git push dokku main
```

### 3. SSL Configuration

```bash
# Install Let's Encrypt plugin
sudo dokku plugin:install https://github.com/dokku/dokku-letsencrypt.git

# Configure Let's Encrypt
dokku config:set --no-restart wordpress DOKKU_LETSENCRYPT_EMAIL=your-email@example.com
dokku letsencrypt:enable wordpress
dokku letsencrypt:cron-job --add
```

### 4. CI/CD Pipeline Setup

1. Add the necessary GitHub repository secrets:
   - `DOKKU_HOST`: Your Dokku server hostname
   - `DOKKU_SSH_PRIVATE_KEY`: SSH private key for Dokku access
   - `SLACK_WEBHOOK`: Webhook URL for deployment notifications

2. The GitHub Actions workflow is configured to:
   - Build the WordPress Docker image
   - Deploy to Dokku on push to main branch
   - Send a notification on successful/failed deployment

### 5. Monitoring Setup

```bash
# Deploy Prometheus, Grafana, Node Exporter, and cAdvisor
docker-compose -f docker-compose-monitoring.yml up -d

# Access Grafana at http://devops.s14.local:3000
# Default credentials: admin/admin
```

### 6. Security Configuration

```bash
# Disable password authentication for SSH
sudo sed -i 's/#PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config
sudo service ssh restart
```

### 7. Backup Configuration

```bash
# Make the backup script executable
chmod +x /path/to/backup.sh

# Add to crontab to run daily at 2 AM
(crontab -l 2>/dev/null; echo "0 2 * * * /path/to/backup.sh") | crontab -
```

## Backup Restoration Procedure

To restore from a backup:

1. **Database Restoration**:
   ```bash
   # Extract the backup archive
   tar -xzf /var/backups/wordpress/wordpress_backup_YYYYMMDD_HHMMSS.tar.gz -C /tmp/
   
   # Restore the database
   MYSQL_CONTAINER=$(dokku mysql:info wordpress-db --container-id)
   cat /tmp/wordpress_backup_YYYYMMDD_HHMMSS/database.sql | docker exec -i ${MYSQL_CONTAINER} mysql -u ${MYSQL_USER} -p${MYSQL_PASSWORD} ${MYSQL_DATABASE}
   ```

2. **Files Restoration**:
   ```bash
   # Restore wp-content directory
   tar -xzf /tmp/wordpress_backup_YYYYMMDD_HHMMSS/wp-content.tar.gz -C /var/lib/dokku/data/storage/wordpress/wp-content/
   
   # Fix permissions
   chown -R dokku:dokku /var/lib/dokku/data/storage/wordpress/wp-content/
   ```

3. **Restart the WordPress application**:
   ```bash
   dokku ps:restart wordpress
   ```

## What Works

- WordPress deployment using Dokku and Docker
- SSL certificates via Let's Encrypt
- CI/CD pipeline with GitHub Actions
- Monitoring with Prometheus and Grafana
- Automated daily backups
- SSH key-only authentication

## Future Improvements

With more time, I would implement:

1. **High Availability**: Set up redundant infrastructure with load balancing
2. **Network Security**: Add a WAF and implement more restrictive firewall rules
3. **Database Optimization**: Tune MySQL for better performance
4. **Advanced Monitoring**: Add application-level metrics and logs in Prometheus
5. **Remote Backup Storage**: Configure automated backup uploads to S3 or similar cloud storage
6. **Container Hardening**: Implement additional security measures for Docker containers
7. **Resource Limitations**: Add CPU and memory constraints to Docker containers
8. **Blue-Green Deployment**: Implement zero-downtime deployments