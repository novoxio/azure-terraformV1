#!/bin/bash
# Update packages and install Apache, PHP, and MySQL client
apt-get update
apt-get install -y apache2 php php-mysql

# Create a PHP file to fetch and display data from MySQL
cat <<EOF > /var/www/html/index.php
<?php
\$servername = "${db_lb_ip}";
\$username = "appuser";
\$password = "apppassword";
\$dbname = "appdb";

// Create connection
\$conn = new mysqli(\$servername, \$username, \$password, \$dbname);

// Check connection
if (\$conn->connect_error) {
    die("Connection failed: " . \$conn->connect_error);
}

// Fetch data
\$sql = "SELECT message FROM greetings";
\$result = \$conn->query(\$sql);

if (\$result->num_rows > 0) {
    // Output data of each row
    while(\$row = \$result->fetch_assoc()) {
        echo "Message: " . \$row["message"];
    }
} else {
    echo "0 results";
}
\$conn->close();
?>
EOF

# Restart Apache service
systemctl restart apache2
