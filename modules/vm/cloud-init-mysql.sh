#!/bin/bash

# Set DEBIAN_FRONTEND to noninteractive to prevent prompts during installation
export DEBIAN_FRONTEND=noninteractive

# Define MySQL Root Password and Admin Username (Change this to something more secure)
MYSQL_ROOT_PASSWORD="rootpassword"
MYSQL_APP_USER="appuser"
MYSQL_APP_PASSWORD="apppassword"
MYSQL_DB="appdb"
ADMIN_USERNAME="adminuser"  # Set this to the actual admin username

# Ensure the admin user has sudo privileges
echo "Adding ${ADMIN_USERNAME} to the sudo group..."
usermod -aG sudo ${ADMIN_USERNAME}

# Function to exit script on error
set -e

echo "Updating packages and installing MySQL..."
# Update and install MySQL
sudo apt-get update && sudo apt-get upgrade -y
sudo apt-get install -y mysql-server

echo "Configuring MySQL to listen on all interfaces..."
# Set MySQL to listen on all interfaces (for load-balanced setup)
sudo sed -i "s/^bind-address.*/bind-address = 0.0.0.0/" /etc/mysql/mysql.conf.d/mysqld.cnf

echo "Configuring MySQL for replication..."
# Enable GTID-based replication
sudo bash -c "cat >> /etc/mysql/mysql.conf.d/mysqld.cnf <<EOL
[mysqld]
server-id = $(hostname | tr -cd '[:digit:]')  # Unique server-id based on VM hostname (ensure each node has a unique ID)
log-bin = mysql-bin
binlog-format = ROW
gtid-mode = ON
enforce-gtid-consistency = TRUE
log_slave_updates = TRUE
replicate-same-server-id = FALSE
EOL"

echo "Restarting MySQL service..."
# Restart MySQL to apply the configuration
sudo systemctl restart mysql

echo "Securing MySQL installation..."
# Secure MySQL installation (setting root password, removing insecure default settings)
sudo mysql -u root <<-EOF
  ALTER USER 'root'@'localhost' IDENTIFIED WITH 'mysql_native_password' BY '$MYSQL_ROOT_PASSWORD';
  DELETE FROM mysql.user WHERE User='';
  DROP DATABASE IF EXISTS test;
  FLUSH PRIVILEGES;
EOF

echo "Creating application database and user..."
# Create the database and application user
sudo mysql -u root -p$MYSQL_ROOT_PASSWORD <<-EOF
  CREATE DATABASE IF NOT EXISTS $MYSQL_DB;
  CREATE USER IF NOT EXISTS '$MYSQL_APP_USER'@'%' IDENTIFIED BY '$MYSQL_APP_PASSWORD';
  GRANT ALL PRIVILEGES ON $MYSQL_DB.* TO '$MYSQL_APP_USER'@'%';
  FLUSH PRIVILEGES;
EOF

echo "Inserting sample data into appdb..."
# Insert some sample data
sudo mysql -u root -p$MYSQL_ROOT_PASSWORD <<-EOF
  USE $MYSQL_DB;
  CREATE TABLE IF NOT EXISTS greetings (id INT AUTO_INCREMENT PRIMARY KEY, message VARCHAR(255));
  INSERT INTO greetings (message) VALUES ('Hallo fra MySQL Database!');
EOF

echo "Setting up replication..."

# Check if the hostname is the first node (adjust to your actual hostname, for example: db-vm-1)
if [ "$(hostname)" == "db-vm-1" ]; then
    echo "Setting up master replication..."

    # Set up replication user on master
    sudo mysql -u root -p$MYSQL_ROOT_PASSWORD <<-EOF
      GRANT REPLICATION SLAVE ON *.* TO 'replication_user'@'%' IDENTIFIED BY 'replication_password';
      FLUSH PRIVILEGES;
EOF

    echo "Master replication user created. To set up the slave, use the following commands:"
    echo "  On the slave node, run:"
    echo "    mysql -u root -p$MYSQL_ROOT_PASSWORD -e \"CHANGE MASTER TO MASTER_HOST='<replication_master_ip>', MASTER_USER='replication_user', MASTER_PASSWORD='replication_password', MASTER_AUTO_POSITION = 1;\""
    echo "    mysql -u root -p$MYSQL_ROOT_PASSWORD -e \"START SLAVE;\""
else
    echo "This is not the master node. Skipping master replication setup."
fi

echo "Checking replication status..."
# Check replication status (run on slave nodes)
sudo mysql -u root -p$MYSQL_ROOT_PASSWORD -e "SHOW SLAVE STATUS\G" || echo "Replication status check failed (likely not a slave node)."

echo "MySQL setup completed successfully."
