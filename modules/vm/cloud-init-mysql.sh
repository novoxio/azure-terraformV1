#!/bin/bash

# Update packages and install MySQL
echo "Updating packages and installing MySQL..."
apt-get update && apt-get upgrade -y
apt-get install -y mysql-server

# Set MySQL to listen on all interfaces
echo "Configuring MySQL to listen on all interfaces..."
sed -i "s/^bind-address.*/bind-address = 0.0.0.0/" /etc/mysql/mysql.conf.d/mysqld.cnf

# Restart MySQL service
echo "Restarting MySQL service..."
systemctl restart mysql

# Secure MySQL installation (adjust commands as needed)
echo "Securing MySQL installation..."
mysql -e "ALTER USER 'root'@'localhost' IDENTIFIED WITH 'mysql_native_password' BY 'rootpassword';"
mysql -e "DELETE FROM mysql.user WHERE User='';"
mysql -e "DROP DATABASE IF EXISTS test;"
mysql -e "FLUSH PRIVILEGES;"

# Create a database and a user for the application
echo "Creating application database and user..."
mysql -u root -prootpassword -e "CREATE DATABASE appdb;"
mysql -u root -prootpassword -e "CREATE USER 'appuser'@'%' IDENTIFIED BY 'apppassword';"
mysql -u root -prootpassword -e "GRANT ALL PRIVILEGES ON appdb.* TO 'appuser'@'%';"
mysql -u root -prootpassword -e "FLUSH PRIVILEGES;"

# Insert sample data
echo "Inserting sample data into appdb..."
mysql -u root -prootpassword -e "USE appdb; CREATE TABLE greetings (id INT AUTO_INCREMENT PRIMARY KEY, message VARCHAR(255));"
mysql -u root -prootpassword -e "USE appdb; INSERT INTO greetings (message) VALUES ('Hello from MySQL!');"

echo "MySQL setup completed successfully."

