Terraform Deployment for Azure
Denne Terraform-konfigurasjonen oppretter ressurser på Azure, inkludert virtuelle maskiner for webservere og databaser, og konfigurerer MySQL og Apache/PHP på de respektive VM-ene. Den inkluderer også en lastbalanserer for webservere og databaser.

Forutsetninger
Før du begynner, må du ha følgende på plass:

Terraform: Terraform må være installert på systemet ditt. Se Terraform Installation Guide for installasjonsinstruksjoner.
Azure CLI: Azure CLI må være installert for autentisering mot Azure. Se Azure CLI Installation for installasjonsinstruksjoner.
Azure Subscription: Du må ha en aktiv Azure-konto og tilgang til ressursgruppen og abonnementet.
Installasjon
1. Logg inn på Azure
Før du kan bruke Terraform med Azure, må du logge inn via Azure CLI:

bash
Copy code
az login
2. Konfigurer Terraform
Oppdater terraform.tfvars med dine spesifikasjoner:

subscription_id: Ditt Azure-abonnement ID.
region: Azure-regionen der ressursene skal opprettes.
resource_group_name: Navnet på ressursgruppen.
vm_size: Størrelsen på virtuelle maskiner.
admin_username og admin_password: Administrasjonsbrukernavn og passord for VM-ene.
Eksempel på terraform.tfvars:

hcl
Copy code
region              = "West Europe"
vm_size             = "Standard_B1s"  # Free student-tier size
resource_group_name = "my-resource-group"
admin_username      = "admin123"
admin_password      = "Password123!"
db_lb_public_ip     = "your-load-balancer-ip-here"  # Sett dette til din Load Balancer IP
3. Initialiser Terraform
Kjør følgende kommando i katalogen der Terraform-konfigurasjonen er plassert for å initialisere Terraform:

bash
Copy code
terraform init
4. Kjør Terraform Plan
Kjør denne kommandoen for å vise hva som vil bli opprettet på Azure:

bash
Copy code
terraform plan
5. Kjør Terraform Apply
For å opprette ressursene på Azure, kjør følgende kommando:

bash
Copy code
terraform apply
Følg instruksjonene i Terraform for å bekrefte opprettelsen av ressursene.

MySQL og Webserver Installasjon via Cloud-init
Terraform-konfigurasjonen inkluderer to skript (cloud-init-mysql.sh og cloud-init-web.sh) som blir brukt til å installere og konfigurere MySQL og Apache/PHP på virtuelle maskiner (VM-er).

1. MySQL Server Installering (på Database VM-er)
På database-VM-ene blir følgende handlinger utført:

Oppdatering av systemet:

bash
Copy code
apt-get update && apt-get upgrade -y
Installasjon av MySQL:

bash
Copy code
apt-get install -y mysql-server
Konfigurering av MySQL for å lytte på alle IP-adresser:

bash
Copy code
sed -i "s/^bind-address.*/bind-address = 0.0.0.0/" /etc/mysql/mysql.conf.d/mysqld.cnf
Sikre MySQL-installasjonen ved å sette et nytt passord og fjerne testdatabasen:

bash
Copy code
mysql -e "ALTER USER 'root'@'localhost' IDENTIFIED WITH 'mysql_native_password' BY 'rootpassword';"
mysql -e "DELETE FROM mysql.user WHERE User='';"
mysql -e "DROP DATABASE IF EXISTS test;"
mysql -e "FLUSH PRIVILEGES;"
Opprettelse av applikasjonsdatabase og bruker:

bash
Copy code
mysql -u root -prootpassword -e "CREATE DATABASE appdb;"
mysql -u root -prootpassword -e "CREATE USER 'appuser'@'%' IDENTIFIED BY 'apppassword';"
mysql -u root -prootpassword -e "GRANT ALL PRIVILEGES ON appdb.* TO 'appuser'@'%';"
mysql -u root -prootpassword -e "FLUSH PRIVILEGES;"
Innsatt testdata i databasen:

bash
Copy code
mysql -u root -prootpassword -e "USE appdb; CREATE TABLE greetings (id INT AUTO_INCREMENT PRIMARY KEY, message VARCHAR(255));"
mysql -u root -prootpassword -e "USE appdb; INSERT INTO greetings (message) VALUES ('Hello from MySQL!');"
2. Apache og PHP Installering (på Webserver VM-er)
På webserver-VM-ene blir følgende utført:

Installasjon av Apache, PHP og MySQL-klienten:

bash
Copy code
apt-get update
apt-get install -y apache2 php php-mysql
Opprettelse av en PHP-fil som henter data fra MySQL (Lastbalansererens IP brukes her):

php
Copy code
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
Restart Apache:

bash
Copy code
systemctl restart apache2
