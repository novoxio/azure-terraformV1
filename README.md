<!DOCTYPE html>
<html lang="no">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
</head>
<body>

<h1>Terraform Azure Infrastructure Setup</h1>

<p>Dette prosjektet bruker Terraform for å sette opp og administrere en infrastruktur på Azure. Infrastrukturene som implementeres inkluderer virtuelle maskiner (VM-er), lastbalanserer, og nettverkskomponenter. Dette prosjektet konfigurerer også MySQL og en webserver på de virtuelle maskinene ved hjelp av <code>cloud-init</code> skript.</p>

<h2>Forutsetninger</h2>
<p>Før du kan bruke dette Terraform-prosjektet, må du ha følgende installert:</p>
<ul>
    <li><a href="https://www.terraform.io/downloads.html">Terraform</a> (Versjon 1.0 eller høyere)</li>
    <li><a href="https://learn.microsoft.com/en-us/cli/azure/install-azure-cli">Azure CLI</a> (Versjon 2.0 eller høyere)</li>
    <li>En aktiv Azure-konto</li>
</ul>

<h2>Steg 1: Forberedelser</h2>

<h3>1. Autentisering mot Azure</h3>
<p>Logg inn på din Azure-konto ved å kjøre følgende kommando:</p>
<pre><code>az login</code></pre>
<p>Dette åpner en nettleser der du kan logge inn med Azure-kontoen din.</p>

<h3>2. Sett Subscription ID i <code>provider.tf</code></h3>
<p>Du må angi din Azure Subscription ID i <code>provider.tf</code>. Åpne <code>provider.tf</code>-filen og legg til din Subscription ID:</p>
<pre><code>
provider "azurerm" {
  features {}
  subscription_id = "&lt;din_subscription_id&gt;"
}
</code></pre>

<h2>Steg 2: Terraform Konfigurasjon</h2>
<p>Prosjektet består av tre hovedmoduler:</p>

<h3>1. <strong>Network Module</strong></h3>
<p>Konfigurerer et virtuelt nettverk og subnets.</p>

<h3>2. <strong>VM Module</strong></h3>
<p>Oppretter virtuelle maskiner (VM-er) som er konfigurert med MySQL og webserver (Apache + PHP).</p>

<h3>3. <strong>Load Balancer Module</strong></h3>
<p>Konfigurerer en lastbalanserer for høy tilgjengelighet og skalerbarhet.</p>

<h2>Steg 3: Terraform Kommandorer</h2>
<p>Følg disse trinnene for å bruke Terraform til å distribuere infrastrukturen:</p>

<h3>1. Initialiser Terraform-prosjektet</h3>
<p>Før du kan bruke Terraform, må du initialisere prosjektet:</p>
<pre><code>terraform init</code></pre>

<h3>2. Planlegg distribusjonen</h3>
<p>Kjør kommandoen for å generere en plan for distribusjonen av infrastrukturen:</p>
<pre><code>terraform plan</code></pre>
<p>Dette gir deg en oversikt over hva som vil bli opprettet på Azure.</p>

<h3>3. Distribuer infrastrukturen</h3>
<p>For å opprette ressursene i Azure, kjør:</p>
<pre><code>terraform apply</code></pre>
<p>Terraform vil be deg om å bekrefte ved å skrive <code>yes</code>.</p>

<h3>4. Ferdigstilling</h3>
<p>Når Terraform er ferdig med distribusjonen, vil du få utdata med IP-adressen til de nye virtuelle maskinene og lastbalansereren i Azure GUI. Web-VM har en Offentlig IP.</p>

<h2>Steg 4: Testing av Web-applikasjon</h2>
<p>Etter at Terraform har opprettet ressursene, kan du teste PHP-applikasjonen ved å:</p>

<h3>1. Hente IP-adressen</h3>
<p>IP-adressen til webserveren skal være tilgjengelig etter distribusjon. Du kan finne denne i Terraform-utdataene eller via Azure-portalen.</p>

<h3>2. Test Websiden</h3>
<p>Åpne nettleseren din og skriv inn <code>http://&lt;ip-adresse&gt;/db_status.php</code>. Du bør se en PHP-side som bekrefter at serverne fungerer med status om DB-VM-tilkoblinger og database-melding.</p>

<h3>3. Test Failover MySQL-tilkobling</h3>
<p>Test ved å slå av en DB_VM. Refreshe siden, og du ser at den byttet til den andre DB-VM-en. Statusen til den andre VM-en skal være "failed", og tilkoblingen til databasen vil bytte over til partneren.</p>

<h2>Testing PHP-siden</h2>
<p>For å teste at PHP fungerer som det skal, kan du åpne nettleseren din og navigere til <code>http://&lt;ip-adresse&gt;/db_status.php</code> på den virtuelle maskinen som kjører webserveren. PHP-siden skal vise status for tilkobling til databasen og hente innhold fra databasen.</p>

<h2>cloud-init-web.sh</h2>
<p>Dette skriptet brukes til å konfigurere webserveren (Apache og PHP) på de virtuelle maskinene. Den installerer Apache, PHP, og PHP-MySQL-modulen, og sørger for at webserveren er oppe og kjører. Den sjekker også statusen til databasene og henter ut data.</p>

<h2>cloud-init-mysql.sh</h2>
<p>Dette skriptet settes opp på de virtuelle maskinene som skal bruke MySQL, og utfører følgende:</p>
<ul>
    <li>Installerer og konfigurerer MySQL</li>
    <li>Setter opp replikering (hvis nødvendig)</li>
    <li>Oppretter en database og bruker</li>
</ul>

<h2>Steg 5: Rydde opp</h2>
<p>Når du er ferdig med å teste infrastrukturen, kan du rydde opp ressursene som ble opprettet av Terraform:</p>
<pre><code>terraform destroy</code></pre>
<p>Dette fjerner alle ressurser fra Azure og stopper eventuelle kostnader som kan påløpe.</p>

<h2>Konklusjon</h2>
<p>Dette Terraform-prosjektet gir deg en fullstendig infrastruktur med virtuelle maskiner, nettverkskomponenter og lastbalansering på Azure. Det er bygget for å være skalerbart og lett å bruke for å håndtere applikasjonsdrift i et produksjonsmiljø.</p>

</body>
</html>

