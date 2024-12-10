<!DOCTYPE html>
<html lang="no">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Terraform Prosjekt for Azure Infrastruktur</title>
</head>
<body>

    <h1>Terraform Prosjekt for Azure Infrastruktur</h1>

    <p>Dette prosjektet bruker <strong>Terraform</strong> for å sette opp og administrere en infrastruktur på <strong>Azure</strong>, inkludert virtuelle maskiner (VM), lastbalanserer, og nettverkskomponenter. Skriptene inkluderer også <strong>cloud-init</strong> for automatisk konfigurasjon av MySQL og webserver på de virtuelle maskinene.</p>

    <h2>Forutsetninger</h2>
    <p>Før du kan bruke dette Terraform-prosjektet, må du ha følgende installert:</p>
    <ul>
        <li><strong>Terraform</strong> (Versjon 1.0 eller høyere)</li>
        <li><strong>Azure CLI</strong> (Versjon 2.0 eller høyere)</li>
        <li>En aktiv <strong>Azure-konto</strong></li>
    </ul>

    <h2>Steg 1: Forberedelser</h2>
    <h3>1. Autentisering mot Azure:</h3>
    <p>Kjør følgende kommando for å logge inn i Azure via CLI:</p>
    <pre><code>az login</code></pre>
    <p>Dette åpner en nettleser der du kan logge inn med Azure-kontoen din.</p>

    <h3>2. Sett Subscription ID i provider.tf:</h3>
    <p>Du må angi din Azure Subscription ID i <strong>provider.tf</strong>:</p>
    <pre><code>provider "azurerm" {
  features {}
  subscription_id = "&lt;din_subscription_id&gt;"
}</code></pre>

    <h2>Steg 2: Terraform Konfigurasjon</h2>
    <p>Prosjektet består av tre hovedmoduler:</p>
    <ul>
        <li><strong>Network Module</strong>: Konfigurerer et virtuelt nettverk og subnets.</li>
        <li><strong>VM Module</strong>: Oppretter virtuelle maskiner som er konfigurert med MySQL og webserver.</li>
        <li><strong>Load Balancer Module</strong>: Konfigurerer lastbalanserer for høyt tilgjengelige applikasjoner.</li>
    </ul>

    <h3>Struktur</h3>
    <ul>
        <li><strong>variables.tf</strong>: Definerer variabler som region, størrelse på VM, og brukernavn/passord for administrasjon.</li>
        <li><strong>terraform.tfvars</strong>: Her kan du endre variablene til ditt behov.</li>
        <li><strong>main.tf</strong>: Konfigurerer ressursene i Azure, inkludert virtuelle maskiner, nettverk og lastbalanserer.</li>
        <li><strong>modules/</strong>: Inneholder moduler for nettverk, VM, og lastbalanserer.</li>
    </ul>

    <h2>Steg 3: Kjøring av Terraform</h2>
    <ol>
        <li><strong>Initialiser Terraform-prosjektet:</strong> Før du kan bruke Terraform, må du initialisere prosjektet:</li>
        <pre><code>terraform init</code></pre>
        <li><strong>Planlegg distribusjonen:</strong> Kjør kommandoen for å generere en plan for distribusjonen av infrastrukturen:</li>
        <pre><code>terraform plan</code></pre>
        <p>Dette gir deg en oversikt over hva som vil bli opprettet på Azure.</p>
        <li><strong>Distribuer infrastrukturen:</strong> For å opprette ressursene i Azure, kjør:</li>
        <pre><code>terraform apply</code></pre>
        <p>Terraform vil be deg om å bekrefte ved å skrive <code>yes</code>.</p>
        <li><strong>Ferdigstilling:</strong> Når Terraform er ferdig med distribusjonen, vil du få utdata med IP-adressen til de nye virtuelle maskinene og lastbalansereren i Azure GUI. Web-VM har en Offentlig IP.</li>
    </ol>

    <h2>Steg 4: Testing av Web-applikasjon</h2>
    <p>Etter at Terraform har opprettet ressursene, kan du teste PHP-applikasjonen ved å:</p>
    <ol>
        <li><strong>Hente IP-adressen:</strong> IP-adressen til webserveren skal være tilgjengelig etter distribusjon. Du kan finne denne i Terraform-utdataene eller via Azure-portalen.</li>
        <li><strong>Test Websiden:</strong> Åpne nettleseren din og skriv inn <code>http://&lt;ip-adresse&gt;/db_setup.php</code>. Du bør se en PHP-side som bekrefter at serverne fungerer med status om DB-VM-tilkoblinger og database-melding.</li>
        <li><strong>Test Failover MySQL-tilkobling:</strong> Test ved å slå av en DB-VM. Refreshe siden og du ser at den bytter til andre DB-VM. Statusen til andre VM-en blir "failed", og tilkoblingen til databasen blir byttet til partneren.</li>
    </ol>

    <h3>Testing PHP-siden</h3>
    <p>For å teste at PHP fungerer som det skal, kan du åpne nettleseren din og navigere til <code>http://&lt;ip-adresse&gt;/db_setup.php</code> til den virtuelle maskinen som kjører webserveren. PHP-siden skal vise status til tilkobling av database og hente innhold fra databasen.</p>

    <h2>cloud-init-web.sh</h2>
    <p>Dette skriptet brukes til å konfigurere webserveren (Apache og PHP) på de virtuelle maskinene. Den installerer Apache, PHP, og PHP-MySQL-modulen, og sørger for at webserveren er oppe og kjører, samtidig som det sjekker statusen til databasene og henter ut data.</p>

    <h2>cloud-init-mysql.sh</h2>
    <p>Dette skriptet settes opp på de virtuelle maskinene som skal bruke MySQL, og utfører følgende:</p>
    <ul>
        <li>Installere og konfigurere MySQL</li>
        <li>Sette opp replikering (hvis nødvendig)</li>
        <li>Opprette en database og bruker</li>
    </ul>

    <h2>Steg 5: Rydde opp</h2>
    <p>Når du er ferdig med å teste infrastrukturen, kan du rydde opp ressursene som ble opprettet av Terraform:</p>
    <pre><code>terraform destroy</code></pre>
    <p>Dette fjerner alle ressurser fra Azure og stopper eventuelle kostnader som kan påløpe.</p>

    <h2>Konklusjon</h2>
    <p>Dette Terraform-prosjektet gir deg en fullstendig infrastruktur med virtuelle maskiner, nettverkskomponenter, og lastbalansering på Azure. Det er bygget for å være skalerbart og lett å bruke for å håndtere applikasjonsdrift i et produksjonsmiljø.</p>

</body>
</html>
