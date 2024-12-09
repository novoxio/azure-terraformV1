<!DOCTYPE html>
<html lang="no">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Terraform Deployment for Azure</title>
</head>
<body>

<h1>Terraform Deployment for Azure</h1>

<p>Denne Terraform-konfigurasjonen oppretter ressurser på Azure, inkludert virtuelle maskiner for webservere og databaser, og konfigurerer MySQL og Apache/PHP på de respektive VM-ene. Den inkluderer også en lastbalanserer for webservere og databaser.</p>

<h2>Forutsetninger</h2>
<p>Før du begynner, må du ha følgende på plass:</p>
<ul>
    <li><strong>Terraform:</strong> Terraform må være installert på systemet ditt. Se <a href="https://www.terraform.io/docs/install/index.html">Terraform Installation Guide</a> for installasjonsinstruksjoner.</li>
    <li><strong>Azure CLI:</strong> Azure CLI må være installert for autentisering mot Azure. Se <a href="https://learn.microsoft.com/en-us/cli/azure/install-azure-cli">Azure CLI Installation</a> for installasjonsinstruksjoner.</li>
    <li><strong>Azure Subscription:</strong> Du må ha en aktiv Azure-konto og tilgang til ressursgruppen og abonnementet.</li>
</ul>

<h2>Installasjon</h2>

<h3>1. Logg inn på Azure</h3>
<p>Før du kan bruke Terraform med Azure, må du logge inn via Azure CLI:</p>
<pre><code>az login</code></pre>

<h3>2. Konfigurer Terraform</h3>
<p>Oppdater <code>terraform.tfvars</code> med dine spesifikasjoner:</p>
<ul>
    <li><strong>subscription_id:</strong> Ditt Azure-abonnement ID.</li>
    <li><strong>region:</strong> Azure-regionen der ressursene skal opprettes.</li>
    <li><strong>resource_group_name:</strong> Navnet på ressursgruppen.</li>
    <li><strong>vm_size:</strong> Størrelsen på virtuelle maskiner.</li>
    <li><strong>admin_username og admin_password:</strong> Administrasjonsbrukernavn og passord for VM-ene.</li>
</ul>
<p>Eksempel på <code>terraform.tfvars</code>:</p>
<pre><code>
region = "West Europe"
vm_size = "Standard_B1s"  # Free student-tier size
resource_group_name = "my-resource-group"
admin_username = "admin123"
admin_password = "Password123!"
db_lb_public_ip = "your-load-balancer-ip-here"  # Sett dette til din Load Balancer IP
</code></pre>

<h3>3. Initialiser Terraform</h3>
<p>Kjør følgende kommando i katalogen der Terraform-konfigurasjonen er plassert for å initialisere Terraform:</p>
<pre><code>terraform init</code></pre>

<h3>4. Kjør Terraform Plan</h3>
<p>Kjør denne kommandoen for å vise hva som vil bli opprettet på Azure:</p>
<pre><code>terraform plan</code></pre>

<h3>5. Kjør Terraform Apply</h3>
<p>For å opprette ressursene på Azure, kjør følgende kommando:</p>
<pre><code>terraform apply</code></pre>
<p>Følg instruksjonene i Terraform for å bekrefte opprettelsen av ressursene.</p>

<h2>MySQL og Webserver Installasjon via Cloud-init</h2>

<p>Terraform-konfigurasjonen inkluderer to skript (<code>cloud-init-mysql.sh</code> og <code>cloud-init-web.sh</code>) som blir brukt til å installere og konfigurere MySQL og Apache/PHP på virtuelle maskiner (VM-er).</p>

<h3>1. MySQL Server Installering (på Database VM-er)</h3>
<p>På database-VM-ene blir følgende handlinger utført:</p>
<ul>
    <li><strong>Oppdatering av systemet:</strong></li>
    <pre><code>apt-get update && apt-get upgrade -y</code></pre>

    <li><strong>Installasjon av MySQL:</strong></li>
    <pre><code>apt-get install -y mysql-server</code></pre>

    <li><strong>Konfigurering av MySQL for å lytte på alle IP-adresser:</strong></li>
    <pre><code>sed -i "s/^bind-address.*/bind-address = 0.0.0.0/" /etc/mysql/mysql.conf.d/mysqld.cnf</code></pre>

    <li><strong>Sikre MySQL-installasjonen ved å sette et nytt passord og fjerne testdatabasen:</strong></li>
    <pre><code>
    mysql -e "ALTER USER 'root'@'localhost' IDENTIFIED WITH 'mysql_native_password' BY 'rootpassword';"
    mysql -e "DELETE FROM mysql.user WHERE User='';"
    mysql -e "DROP DATABASE IF EXISTS test;"
    mysql -e "FLUSH PRIVILEGES;"
    </code></pre>

    <li><strong>Opprettelse av applikasjonsdatabase og bruker:</strong></li>
    <pre><code>
    mysql -u root -prootpassword -e "CREATE DATABASE appdb;"
    mysql -u root -prootpassword -e "CREATE USER 'appuser'@'%' IDENTIFIED BY 'apppassword';"
    mysql -u root -prootpassword -e "GRANT ALL PRIVILEGES ON appdb.* TO 'appuser'@'%';"
    mysql -u root -prootpassword -e "FLUSH PRIVILEGES;"
    </code></pre>

    <li><strong>Innsatt testdata i databasen:</strong></li>
    <pre><code>
    mysql -u root -prootpassword -e "USE appdb; CREATE TABLE greetings (id INT AUTO_INCREMENT PRIMARY KEY, message VARCHAR(255));"
    mysql -u root -prootpassword -e "USE appdb; INSERT INTO greetings (message) VALUES ('Hello from MySQL!');"
    </code></pre>
</ul>

<h3>2. Apache og PHP Installering (på Webserver VM-er)</h3>
<p>På webserver-VM-ene blir følgende utført:</p>
<ul>
    <li><strong>Installasjon av Apache, PHP og MySQL-klienten:</strong></li>
    <pre><code>apt-get update</code></pre>
    <pre><code>apt-get install -y apache2 php php-mysql</code></pre>

    <li><strong>Opprettelse av en PHP-fil som henter data fra MySQL (Lastbalansererens IP brukes her):</strong></li>
    <pre><code>
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
    </code></pre>

    <li><strong>Restart Apache:</strong></li>
    <pre><code>systemctl restart apache2</code></pre>
</ul>

<h2>Lastbalansering</h2>


<h2>Feilsøking</h2>
<h3>1. Autentisering</h3>
<p>Hvis du får problemer med autentisering, kan du bruke Azure CLI til å logge inn før du kjører Terraform:</p>
<pre><code>az login</code></pre>

<h3>2. Oppdatering av tilstanden</h3>
<p>Hvis Terraform-klienten ikke finner nødvendige ressurser, kan du bruke <code>terraform refresh</code> for å oppdatere tilstanden før du fortsetter:</p>
<pre><code>terraform refresh</code></pre>

</bod
