#!/bin/bash

# WordPress Backup Script

# Configuration
BACKUP_DIR="/var/backups/wordpress"
MYSQL_CONTAINER=$(dokku mysql:info wordpress-db --container-id)
WP_CONTENT_DIR="/var/lib/dokku/data/storage/wordpress/wp-content"
BACKUP_RETENTION_DAYS=7
DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_NAME="wordpress_backup_${DATE}"

# Create backup directory if it doesn't exist
mkdir -p ${BACKUP_DIR}

# Create a directory for this backup
mkdir -p ${BACKUP_DIR}/${BACKUP_NAME}

# Backup WordPress database
echo "Creating database backup..."
docker exec ${MYSQL_CONTAINER} sh -c 'mysqldump -u $MYSQL_USER -p$MYSQL_PASSWORD $MYSQL_DATABASE' > ${BACKUP_DIR}/${BACKUP_NAME}/database.sql

# Backup WordPress files
echo "Creating wp-content backup..."
tar -czf ${BACKUP_DIR}/${BACKUP_NAME}/wp-content.tar.gz -C ${WP_CONTENT_DIR} .

# Create a single archive of the entire backup
echo "Creating consolidated backup archive..."
tar -czf ${BACKUP_DIR}/${BACKUP_NAME}.tar.gz -C ${BACKUP_DIR} ${BACKUP_NAME}

# Remove the temporary directory
rm -rf ${BACKUP_DIR}/${BACKUP_NAME}

# Remove backups older than retention period
find ${BACKUP_DIR} -name "wordpress_backup_*.tar.gz" -type f -mtime +${BACKUP_RETENTION_DAYS} -delete

# Set appropriate permissions
chmod 600 ${BACKUP_DIR}/${BACKUP_NAME}.tar.gz

echo "Backup completed: ${BACKUP_DIR}/${BACKUP_NAME}.tar.gz"

# Optional: Send backup to remote storage
# aws s3 cp ${BACKUP_DIR}/${BACKUP_NAME}.tar.gz s3://your-backup-bucket/wordpress/

# Optional: Notify admin
# echo "WordPress backup completed on $(date)" | mail -s "WordPress Backup Notification" admin@example.com