FROM php:8.0-apache
EXPOSE 80


# Apache installieren und Status prüfen
RUN apt-get update && apt-get install -y \
    libapache2-mod-security2 \
    openssl \
    vim

RUN /etc/init.d/apache2 restart

# Apache2 Module anzeigen lassen via
#RUN source /etc/apache2/envvars
ENV APACHE_RUN_USER  www-data
ENV APACHE_RUN_GROUP www-data
ENV APACHE_LOG_DIR   /var/log/apache2
ENV APACHE_PID_FILE  /var/run/apache2/apache2.pid
ENV APACHE_RUN_DIR   /var/run/apache2
ENV APACHE_LOCK_DIR  /var/lock/apache2
ENV APACHE_LOG_DIR   /var/log/apache2

RUN a2enmod rewrite ssl security2
RUN service apache2 restart

# HTML-Ablage-Verzeichnis anlegen und Test-HTMl-Seiten kopieren aus /home/dasu/Downloads/
RUN mkdir -p /var/www/uedasu.com
RUN chown -R www-data:www-data /var/www/uedasu.com/

# https://www.soscisurvey.de/help/doku.php/de:server:permissions_linux
RUN chmod 770 /var/www/uedasu.com

RUN ls /var/www/uedasu.com/
COPY ./html/* /var/www/uedasu.com/

# Zertifikat über Volume eingebunden => siehe docker-compose.yml

RUN openssl req -x509 -nodes -days 365 \
    -subj  "/C=DE/ST=BB/L=Wildau/O=THW/, Inc./OU=IT/CN=localhost" \
    -newkey rsa:2048 -keyout /etc/ssl/private/dasu_private.key \
    -out /etc/ssl/certs/dasu_server.crt

RUN cat /etc/ssl/certs/dasu_server.crt /etc/ssl/private/dasu_private.key > /etc/ssl/certs/dasu_server_private_combo.pem

# Konfig in separater Datei ssl.conf #
COPY ./data/ssl.conf /etc/apache2/mods-available/ssl.conf

# Apache-Konfig für vhosts 80 und 443
COPY ./data/uedasu.conf /etc/apache2/sites-available/


# Nicht benötigete Sites deaktivieren mit
RUN a2dissite default-ssl.conf
RUN a2dissite 000-default.conf

# Konfig in separater Datei für uedasu.conf #
RUN a2ensite uedasu.conf


RUN service apache2 restart
WORKDIR /var/www/uedasu.com/