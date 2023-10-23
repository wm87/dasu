
## Absicherung des Apache2-Webservers mittels HTTPS und TLS 1.2

Für die Ausführung ist eine Docker-Laufzeitumgebung erforderlich.

Für die Übung ist es aufgrund der Komplexität des Themas ratsam den zur Verfügung gestellten Container container_name: dasu zu nutzen.

Die konkrete Nutzung des Containers, die Zertifikatserstellung sowie entsprechende Test mit curl bezüglich http und https werden gezeigt.

Nur die Umsetzung mit docker-compose wird aufgrund der vorgebenen Zeit vorgstellt und erläutert!


## I GIT - Übungsdaten laden

```Bash
git clone https://github.com/wm87/dasu.git
```

## How to install Docker and docker compose on Ubuntu?
```Bash
cd dasu/

# Docker-Proxy
export http_proxy="proxy.th-wildau.de:8080"
export https_proxy="proxy.th-wildau.de:8080"

# Installationsscript
bash docker_install.sh
```

## How start docker-compose?

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

## Terminal Ausgabe HEADER (ohne Docker)
```Bash
curl -I -k -v --tlsv1.2 --tls-max 1.2 http://localhost/dasu.html
```
```Bash
curl -I -k -v -L --tlsv1.2 --tls-max 1.2 http://localhost/dasu.html
```

## Docker Ausgabe HEADER - Unterschiede?
```Bash
docker exec dasu curl -I -k -v --tlsv1.2 --tls-max 1.2  https://localhost/dasu.html
```
```Bash
docker exec dasu curl -I -k -v -L --tlsv1.2 --tls-max 1.2  http://localhost/dasu.html
```

## Terminal Ausgabe HTML (ohne Docker)
```Bash
curl -k --tlsv1.2 --tls-max 1.2 https://localhost/dasu.html -H 'Content-Type: application/json'
```


## Docker Ausgabe HTML - Unterschiede?
```Bash
docker exec dasu curl -k --tlsv1.2 --tls-max 1.2 https://localhost/dasu.html -H 'Content-Type: application/json'
```
```Bash
docker exec dasu curl -k --tlsv1.2 --tls-max 1.2 http://localhost/dasu.html -H 'Content-Type: application/json'
```
```Bash
docker exec dasu curl -k -L --tlsv1.2 --tls-max 1.2 http://localhost/dasu.html -H 'Content-Type: application/json'
```
