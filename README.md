🟥 There's no shame in losing track. Everyone takes the time they need. It is much more important to approach the topic without bias; Interest and motivation usually develop over time. Until then, have fun at work..
an unknown author .. 🟥


## Absicherung Apache-Webservers via HTTPS/TLS
> 🟨 **`Voraussetzung:` Für die Übung ist `Ubuntu-VM` (ratsam via WSL) erforderlich.** 🟨
> 
> 🟨 **`Docker-Installtionsskript liegt dem GIT-Repo bei`, die entsprechende Installation wird gezeigt.** 🟨
> 
> Die konkrete Nutzung des Containers, die Zertifikatserstellung sowie entsprechende Test mit curl bezüglich http und https werden gezeigt.
> 
> 🟨 **`Nur die Umsetzung mit docker-compose wird aufgrund der vorgebenen Zeit vorgstellt und erläutert!`** 🟨
> 

***

## Was kann der Container? :monocle_face:

> [!IMPORTANT]
> * `TLS-Absicherung` auf Basis von https://ssl-config.mozilla.org
> * `OpenSSL-Zertifikat generieren / einbinden`
> * `Permanent Redirect nach HTTPS`
> * HTTP/2 aktivieren
> * HTTP Strict Transport Security
> * Verzeichnisauflistungen deaktivieren
> * Serverversion und Betriebssystem ausblenden
> 
:+1:

## Übungsdaten laden

```Bash
git clone https://github.com/wm87/dasu.git
```

## docker-compose installieren - Ubuntu
```Bash
cd dasu/

# Docker-Proxy
export http_proxy="proxy.th-wildau.de:8080"
export https_proxy="proxy.th-wildau.de:8080"

# Installationsscript
bash docker_install.sh
```

## Nutzung von docker-compose

Docker-Container bauen und starten:
```Bash
docker-compose up --build
```
Docker-Container im Hintergrund starten:
```Bash
docker-compose up -d
```

Docker-Container stoppen:
```Bash
docker-compose down
```

***

## Testphase - Was testen wir hier eigentlich? :confused:

### Terminal Ausgabe HEADER (ohne Docker)
```Bash
curl -I -k -v --tlsv1.2 --tls-max 1.2 http://localhost/dasu.html
```
```Bash
curl -I -k -v -L --tlsv1.3 --tls-max 1.3 http://localhost/dasu.html
```

### Docker Ausgabe HEADER - Unterschiede?
```Bash
docker exec dasu curl -I -k -v --tlsv1.2 --tls-max 1.2  https://localhost/dasu.html
```
```Bash
docker exec dasu curl -I -k -v -L --tlsv1.3 --tls-max 1.3  http://localhost/dasu.html
```

### Terminal Ausgabe HTML (ohne Docker)
```Bash
curl -k --tlsv1.2 --tls-max 1.2 https://localhost/dasu.html -H 'Content-Type: application/json'
```

### Docker Ausgabe HTML - Unterschiede?
```Bash
docker exec dasu curl -k --tlsv1.3 --tls-max 1.3 https://localhost/dasu.html -H 'Content-Type: application/json'
```
```Bash
docker exec dasu curl -k --tlsv1.2 --tls-max 1.2 http://localhost/dasu.html -H 'Content-Type: application/json'
```
```Bash
docker exec dasu curl -k -L --tlsv1.2 http://localhost/dasu.html -H 'Content-Type: application/json'
```

***

## Konfiguration :nerd_face:


### Permanent Redirect - uedasu.conf
```Bash
<VirtualHost *:80>
  ...
	RewriteEngine On
	# This will enable the Rewrite capabilities

	RewriteCond %{HTTPS} !=on
	# This checks to make sure the connection is not already HTTPS

	RewriteRule ^/?(.*) https://%{SERVER_NAME}/$1 [R=301,L]
	# If you are looking for a 301 Permanent Redirect, then redirect flag should be as
  ...
</VirtualHost>
```

### Verzeichnisauflistungen deaktivieren - uedasu.conf

```Bash
<IfModule mod_ssl.c>
<VirtualHost *:443>
  ...
  <Directory /var/www/uedasu.com>
    # Options Indexes FollowSymLinks       # Zeile auskommentieren
    Options FollowSymLinks                 # Zeile einfügen
    AllowOverride None
    Require all granted
  </Directory>
  ...
</VirtualHost>
</IfModule>
```


### OpenSSL-Zertificate einbinden - uedasu.conf
```Bash
<IfModule mod_ssl.c>
<VirtualHost *:443>
  ...
  SSLEngine on
  SSLCertificateFile /etc/ssl/certs/dasu_server.crt
  SSLCertificateKeyFile /etc/ssl/private/dasu_private.key
  ...
</VirtualHost>
</IfModule>
```

### Enable HTTP/2, if available - uedasu.conf
```Bash
Protocols h2 http/1.1
```

### HTTP Strict Transport Security - uedasu.conf
```Bash
# HTTP Strict Transport Security (mod_headers is required) (63072000 seconds)
Header always set Strict-Transport-Security "max-age=63072000"
```

### Serverversion und Betriebssystem ausblenden - hide_versions.conf
```Bash
ServerTokens Prod
ServerSignature Off
```

### SSL Configuration Generator - ssl.conf
```Bash
...
# intermediate configuration
# General-purpose servers with a variety of clients, recommended for almost all systems

SSLProtocol             all -SSLv3 -TLSv1 -TLSv1.1
SSLCipherSuite          ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:DHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES256-GCM-SHA384:DHE-RSA-CHACHA20-POLY1305
SSLHonorCipherOrder     off
SSLSessionTickets       off
...
```

[SSL Configuration Generator](https://ssl-config.mozilla.org/#server=apache&version=2.4.57&config=intermediate&openssl=3.0.10&ocsp=false&guideline=5.7)

***

## Container öffnen
```Bash
docker exec -it dasu /bin/bash
```

## Cipher Kommando
"Der Befehl "ciphers" konvertiert textuelle OpenSSL-Chiffrenlisten in geordnete SSL-Chiffrenpräferenzlisten. Er kann als Testwerkzeug verwendet werden, um die geeignete Chiffrenliste zu bestimmen." https://www.openssl.org/docs/man1.1.1/man1/ciphers.html

### OpenSSl Ciphers Status "LOW" - im Container
```Bash
openssl ciphers -v 'LOW' | grep TLSv1.2
openssl ciphers -v 'LOW' | grep TLSv1.2 | wc -l
openssl ciphers -v 'LOW' | grep TLSv1.3
openssl ciphers -v 'LOW' | grep TLSv1.3 | wc -l
```

### OpenSSl Ciphers Status "MEDIUM" - im Container
```Bash
openssl ciphers -v 'MEDIUM' | grep TLSv1.2
openssl ciphers -v 'MEDIUM' | grep TLSv1.2 | wc -l
openssl ciphers -v 'MEDIUM' | grep TLSv1.3
openssl ciphers -v 'MEDIUM' | grep TLSv1.3 | wc -l
```

### OpenSSl Ciphers Status "High" - im Container
```Bash
openssl ciphers -v 'HIGH' | grep TLSv1.2
openssl ciphers -v 'HIGH' | grep TLSv1.2 | wc -l
openssl ciphers -v 'HIGH' | grep TLSv1.3
openssl ciphers -v 'HIGH' | grep TLSv1.3 | wc -l
```


***


# Frequently Asked Questions

- [Wann funktioniert Let's Encrypt nicht, sodass man auf OpenSSL zurückgreifen muss?](#wann-funktioniert-lets-encrypt-nicht-sodass-man-auf-openssl-zurückgreifen-muss)
- [Kann man mit Let's Encrypt selbstsignierte Zertifikate wirklich erstellen oder braucht man vorher eine Domain eines Anbieters?](#kann-man-mit-lets-encrypt-selbstsignierte-zertifikate-wirklich-erstellen-oder-braucht-man-vorher-eine-domain-eines-anbieters)
- [Wie ist der Aufbau von Apache?](#wie-ist-der-aufbau-von-apache)
- [Wie kann man den Status abrufen und Apache neu starten?](#wie-kann-man-den-status-abrufen-und-apache-neustarten)
- [Unterschied zwischen SSL und TLS, baut hier etwas auf dem anderen auf?](#unterschied-zwischen-ssl-und-tls-baut-hier-etwas-auf-dem-anderen-auf)
- [Was macht die Datei /etc/hosts? Was macht der Eintrag 127.0.0.1 localhost?](#was-macht-die-datei-hosts-was-macht-der-eintrag-localhost)
- [Wie kann man in Apache die aktivierten Seiten anzeigen?](#wie-kann-man-in-apache-die-aktivierten-seiten-anzeigen)
- [Was sind vHosts in Apache?](#was-sind-vhosts-in-apache)
- [Wie aktiviert man Module oder überprüft ob bestimmte Module aktiviert sind?](#wie-aktiviert-man-module-oder-überprüft-ob-bestimmte-module-aktiviert-sind)
- [Welcher Port für HTTP und HTTPS?](#welcher-port-für-http-und-https)
- [Wo werden standardmäßig Dateien für Webseiten abgelegt?](#wo-werden-standardmäßig-dateien-für-webseiten-abgelegt)
- [Wo kann man sich im Browser Zertifikate anzeigen lassen?](#wo-kann-man-sich-im-browser-zertifikate-anzeigen-lassen)
- [OpenSSL Welche Dateien werden für die Zertifikatserstellung benötigt und was machen diese?](#openssl-welche-dateien-werden-für-die-zertifikatserstellung-benötigt-und-was-machen-diese)

## Wann funktioniert Lets Encrypt nicht sodass man auf Openssl zurückgreifen muss?

 `Let's Encrypt` ist eine vertrauenswürdige Zertifizierungsstelle, die kostenlose SSL/TLS-Zertifikate ausstellt. Normalerweise gibt es keinen Grund, Let's Encrypt nicht zu verwenden, da es eine einfache und kostengünstige Möglichkeit bietet, vertrauenswürdige Zertifikate für Webseiten zu erhalten. Es gibt jedoch einige Situationen, in denen man auf OpenSSL zurückgreifen könnte, anstatt Let's Encrypt zu verwenden: 
 
`Kein Internetzugang:` Wenn der Server, auf dem Sie ein Zertifikat benötigen, keinen Internetzugang hat, können Sie Let's Encrypt nicht verwenden, da es erfordert, dass Ihr Server mit dem Internet kommuniziert, um die Zertifikate zu erstellen und zu erneuern. In solchen Fällen könnten Sie stattdessen ein selbstsigniertes Zertifikat mit OpenSSL erstellen. 
 
 `Benutzerdefinierte Anforderungen:` In einigen Fällen können Sie spezielle Anforderungen an Ihr Zertifikat haben, die von Let's Encrypt nicht erfüllt werden. Let's Encrypt-Zertifikate sind auf eine begrenzte Anzahl von Domains und Subdomains beschränkt und haben bestimmte Gültigkeitsdauern. Wenn Sie sehr spezielle Anforderungen haben, könnte die Verwendung von OpenSSL und die Erstellung eines benutzerdefinierten Zertifikats die bessere Option sein. 
 
`Vertraulichkeitsanforderungen:` Selbstsignierte Zertifikate können in Umgebungen verwendet werden, in denen die Vertraulichkeit wichtiger ist als die öffentliche Vertrauenswürdigkeit. Selbstsignierte Zertifikate werden von den meisten Webbrowsern als nicht vertrauenswürdig angesehen und lösen Warnmeldungen aus. Wenn dies in Ihrer Umgebung akzeptabel ist und Sie die Verschlüsselung sicherstellen möchten, könnte die Verwendung von OpenSSL und selbstsignierten Zertifikaten in Erwägung gezogen werden. Es ist wichtig zu beachten, dass Let's Encrypt in den meisten Fällen die beste Wahl ist, insbesondere für öffentliche Websites und Dienste. Es bietet kostenlose, vertrauenswürdige Zertifikate und automatische Erneuerung, was die Verwaltung von SSL/TLS-Zertifikaten erheblich erleichtert. Die Verwendung von selbstsignierten Zertifikaten mit OpenSSL sollte sorgfältig abgewogen werden und ist normalerweise in produktiven öffentlichen Umgebungen nicht empfohlen, da Benutzer Warnungen erhalten können und die Sicherheit nicht so hoch ist wie bei von einer vertrauenswürdigen Zertifizierungsstelle ausgestellten Zertifikaten.

## Kann man mit Lets Encrypt selbstsignierte Zertifikate wirklich erstellen oder braucht man vorher eine Domain eines Anbieters?

Let's Encrypt stellt öffentlich vertrauenswürdige `Zertifikate` aus, die nicht selbstsigniert sind. Sie benötigen jedoch eine eigene Domain, um ein Let's Encrypt-Zertifikat zu beantragen, da die Zertifizierungsstelle die Domainvalidierung durchführt. Selbstsignierte Zertifikate können ohne Domain verwendet werden, sind jedoch nicht öffentlich vertrauenswürdig und lösen Warnmeldungen in Webbrowsern aus.

## Wie ist der Aufbau von Apache?

Apache ist ein weit verbreiteter Webserver, und sein Aufbau umfasst Konfigurationsdateien, Module und Verzeichnisse. Die Hauptkonfigurationsdatei ist normalerweise `httpd.conf` , aber in modernen Installationen wird oft `apache2.conf` oder ähnliche Dateien verwendet. Apache verwendet auch Konfigurationsverzeichnisse, wie `sites-available` und `sites-enabled` , um verschiedene Hosts (Virtual Hosts) und Websites zu verwalten.

## Wie kann man den Status abrufen und Apache neustarten?

Sie können den Status von Apache mit dem Befehl `systemctl status apache2` (unter Linux) oder `httpd -t` (zum Testen der Konfiguration) abrufen. Um Apache neu zu starten, verwenden Sie `systemctl restart apache2` oder `systemctl reload apache2`. Die genauen Befehle können je nach Ihrem Betriebssystem variieren.


## Unterschied zwischen SSL und TLS baut hier etwas auf dem anderen auf?

`SSL` (Secure Sockets Layer) war das ursprüngliche Protokoll für sichere Kommunikation über das Internet. `TLS` (Transport Layer Security) ist seine Weiterentwicklung und bietet verbesserte Sicherheit und Verschlüsselung. TLS baut auf den Grundprinzipien von SSL auf, aber es handelt sich um ein eigenständiges Protokoll. TLS-Versionen (z.B. TLS 1.0, 1.1, 1.2, 1.3) haben die älteren SSL-Versionen (SSL 2.0, SSL 3.0) weitgehend abgelöst.


## Was macht die Datei hosts? Was macht der Eintrag localhost?


Die Datei `/etc/hosts` auf Unix-basierten Systemen (einschließlich Linux) wird verwendet, um IP-Adressen mit Hostnamen zu verknüpfen. Der Eintrag `127.0.0.1 localhost` weist die IP-Adresse 127.0.0.1 (die sogenannte Loopback-Adresse) dem Hostnamen "localhost" zu, was bedeutet, dass `localhost` auf Ihrem eigenen Computer auf die IP-Adresse 127.0.0.1 verweist. Dies wird oft verwendet, um auf den eigenen Rechner zuzugreifen, ohne das Netzwerk zu verwenden.


## Wie kann man in Apache die aktivierten Seiten anzeigen?

Sie können die aktivierten Seiten in Apache anzeigen, indem Sie den Befehl `apachectl -S` oder `apache2ctl -S` ausführen. Dies zeigt eine Liste der verfügbaren und aktivierten Virtual Hosts und deren Konfigurationen an.


## Was sind vHosts in Apache?

`vHosts` (Virtual Hosts) sind Konfigurationen in Apache, die es ermöglichen, mehrere Websites auf demselben Server zu hosten. Jeder vHost kann eigene Einstellungen und Dokumentwurzeln haben, um unterschiedliche Websites zu bedienen.


## Wie aktiviert man Module oder überprüft ob bestimmte Module aktiviert sind?

In Apache können Sie Module aktivieren, indem Sie den Befehl `a2enmod` (z.B. `a2enmod ssl` für das SSL-Modul) verwenden und dann den Webserver neu starten. Sie können überprüfen, welche Module aktiviert sind, indem Sie den Befehl `apachectl -M` oder `httpd -M` ausführen.

## Welcher Port für HTTP und HTTPS?

Der Standard-Port für HTTP ist Port `80`, während der Standard-Port für HTTPS Port `443` ist.

## Wo werden standardmäßig Dateien für Webseiten abgelegt?

Standardmäßig werden Dateien für Webseiten unter Linux/Unix in Verzeichnissen wie `/var/www/html` oder `/var/www` abgelegt. Die genaue Konfiguration kann je nach Apache-Version und Betriebssystem variieren.

## Wo kann man sich im Browser Zertifikate anzeigen lassen?

Sie können sich im Browser Zertifikate anzeigen lassen, indem Sie die Adresse `chrome://settings/certificates` in Google Chrome verwenden oder `about:preferences#privacy` in Mozilla Firefox und dort auf "Zertifikate anzeigen" klicken. Die genaue Methode kann je nach Browser variieren.

## OpenSSL Welche Dateien werden für die Zertifikatserstellung benötigt und was machen diese?

Für die Erstellung eines `SSL/TLS-Zertifikats` mit `OpenSSL` benötigen Sie normalerweise die folgenden Dateien:
  - `Private Key (privater Schlüssel)`: Dies ist der geheime Schlüssel, der zur Entschlüsselung von verschlüsselten Daten verwendet wird.
  - `CSR (Certificate Signing Request)`: Dies ist eine Anforderung, die an eine Zertifizierungsstelle gesendet wird, um ein Zertifikat zu erhalten.
  - `Certificate (CRT)`: Dies ist das von der Zertifizierungsstelle signierte Zertifikat.
