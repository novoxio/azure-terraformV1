#!/bin/bash
export DEBIAN_FRONTEND=noninteractive

# Oppdatering og installasjon av nødvendige pakker (Apache, PHP, MySQL-klient)
echo "Oppdaterer pakker og installerer Apache, PHP og MySQL-klient..."
apt-get update && apt-get upgrade -y
apt-get install -y apache2 php libapache2-mod-php php-mysql mysql-client

# Aktiver Apache2 for oppstart ved boot
echo "Aktiverer Apache2 for oppstart ved boot..."
systemctl enable apache2

# Start Apache2-tjenesten
echo "Starter Apache2-tjenesten..."
systemctl start apache2

# Konfigurerer Apache for PHP
echo "Konfigurerer Apache for PHP..."
cat <<'EOL' > /var/www/html/db_status.php
<?php
$db_vms = ["db-vm-1", "db-vm-2"];  // Erstatt med faktiske DB VM-IP-er eller DNS-navn
$username = "appuser";
$password = "apppassword";
$dbname = "appdb";

$connected_db = null;
$status_details = [];
$greeting_message = "Ingen melding funnet.";
$failover_status = "Alle databasetilkoblinger feilet.";

// Prøv å koble til hver database
foreach ($db_vms as $db_vm) {
    $conn = @new mysqli($db_vm, $username, $password, $dbname);
    if ($conn->connect_error) {
        // Legg til status for feilet tilkobling
        $status_details[] = [
            "db" => $db_vm,
            "status" => "Feil",
            "message" => $conn->connect_error
        ];
    } else {
        // Legg til status for suksessfull tilkobling
        $status_details[] = [
            "db" => $db_vm,
            "status" => "Suksess",
            "message" => "Tilkoblet"
        ];

        // Sett opp tilkoblet database og henting av melding
        if (!$connected_db) {
            $connected_db = $db_vm;
            $failover_status = ($db_vm == $db_vms[0]) ? "Primær DB tilkoblet." : "Failover DB aktivert.";
            
            // Hent melding fra databasen
            $result = $conn->query("SELECT message FROM greetings LIMIT 1");
            if ($result && $result->num_rows > 0) {
                $greeting_message = $result->fetch_assoc()['message'];
            }
        }
        $conn->close();
    }
}
?>

<!DOCTYPE html>
<html lang="no">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Databasestatus</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            margin: 0;
            padding: 20px;
            background: #f9f9f9;
        }
        h1 {
            color: #333;
            text-align: center;
        }
        table {
            width: 100%;
            border-collapse: collapse;
            margin: 20px 0;
        }
        table, th, td {
            border: 1px solid #ddd;
        }
        th, td {
            text-align: left;
            padding: 12px;
        }
        th {
            background-color: #f4f4f4;
        }
        .success {
            color: green;
            font-weight: bold;
        }
        .fail {
            color: red;
            font-weight: bold;
        }
        footer {
            margin-top: 20px;
            text-align: center;
            font-size: 14px;
            color: #666;
        }
        .status-table {
            background-color: #fff;
            border-radius: 8px;
            box-shadow: 0 2px 5px rgba(0,0,0,0.1);
            padding: 20px;
            margin: 20px 0;
        }
    </style>
</head>
<body>
    <h1>Status for Databasetilkobling</h1>
    <div class="status-table">
        <p><strong>Tilkoblet database:</strong> <?php echo $connected_db ?: "Ingen"; ?></p>
        <p><strong>Status for Failover:</strong> <?php echo $failover_status; ?></p>
    </div>

    <h2>Tilkoblingsforsøk:</h2>
    <table>
        <thead>
            <tr>
                <th>Database VM</th>
                <th>Status</th>
                <th>Melding</th>
            </tr>
        </thead>
        <tbody>
            <?php foreach ($status_details as $detail): ?>
                <tr>
                    <td><?php echo $detail['db']; ?></td>
                    <td class="<?php echo strtolower($detail['status']); ?>"><?php echo $detail['status']; ?></td>
                    <td><?php echo $detail['message']; ?></td>
                </tr>
            <?php endforeach; ?>
        </tbody>
    </table>

    <h2>Hilsen fra databasen:</h2>
    <p><?php echo $greeting_message; ?></p>

    <footer>
        Laget av Torben Zucker
    </footer>
</body>
</html>
EOL

# Start Apache på nytt for å laste PHP-innhold
echo "Starter Apache på nytt for å laste oppdateringer..."
systemctl restart apache2

# Skriv ut IP-adressen til serveren
echo "Websiden er tilgjengelig på: http://$(hostname -I | awk '{print $1}')/db_status.php"
