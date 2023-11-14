FROM ubuntu:mantic
EXPOSE 80

# Software installieren
RUN apt-get update && apt-get install -y \
    apache2 \
    libapache2-mod-security2 \
    openssl \
    curl \
    vim

# Apache2 Umgebungsvariablen setzen
ENV APACHE_RUN_USER  www-data
ENV APACHE_RUN_GROUP www-data
ENV APACHE_LOG_DIR   /var/log/apache2
ENV APACHE_PID_FILE  /var/run/apache2/apache2.pid
ENV APACHE_RUN_DIR   /var/run/apache2
ENV APACHE_LOCK_DIR  /var/lock/apache2
ENV APACHE_LOG_DIR   /var/log/apache2

# Apache-Module aktivieren bzw. deaktivieren
RUN a2enmod rewrite ssl security2 headers
RUN a2dismod mpm_prefork
RUN a2enmod mpm_event
RUN a2enmod http2

RUN service apache2 restart

# HTML-Ablage-Verzeichnis anlegen und Test-HTMl-Seiten kopieren aus /home/dasu/Downloads/
RUN mkdir -p /var/www/uedasu.com
RUN chown -R www-data:www-data /var/www/uedasu.com/

# https://www.soscisurvey.de/help/doku.php/de:server:permissions_linux
RUN chmod 770 /var/www/uedasu.com

COPY ./html/* /var/www/uedasu.com/

# Zertifikat über Volume eingebunden => siehe docker-compose.yml

RUN openssl req -x509 -nodes -days 365 \
    -subj  "/C=DE/ST=BB/L=Wildau/O=THW/OU=IT/CN=localhost" \
    -newkey rsa:4096 -keyout /etc/ssl/private/dasu_private.key \
    -out /etc/ssl/certs/dasu_server.crt

# Konfig in separater Datei ssl.conf
COPY ./data/ssl.conf /etc/apache2/mods-available/ssl.conf

# Apache-Konfig für vhosts 80 und 443 in Container kopieren
COPY ./data/uedasu.conf /etc/apache2/sites-available/

# Serverversion und Betriebssystem ausblenden
COPY ./data/hide_versions.conf /etc/apache2/sites-available/

# Nicht benötigete Sites deaktivieren mit
RUN a2dissite default-ssl.conf
RUN a2dissite 000-default.conf

# conf in separater Datei
RUN a2ensite uedasu.conf
RUN a2ensite hide_versions.conf

# Apache neustarten
RUN service apache2 restart

# Arbeitsverzeichnis setzen
WORKDIR /var/www/uedasu.com/

# Launch Apache
CMD ["/usr/sbin/apache2ctl", "-DFOREGROUND"]

