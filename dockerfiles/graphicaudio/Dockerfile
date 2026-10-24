# ==============================================================================
# BOOKS MODULE - GRAPHICAUDIO DOCKERFILE
# ==============================================================================
# Description: Custom ABS metadata provider for GraphicAudio titles (PHP/Apache)
# Author: Matt Barham
# Created: 2026-03-15
# Modified: 2026-10-24
# Version: 1.0.2
# Host: Your Server
# ==============================================================================
# Type: Dockerfile
# Base Image: php:8.3-apache
# Documentation: https://github.com/binyaminyblatt/graphicaudio_scraper
# Component: module: books / service: graphicaudio
# ==============================================================================

FROM php:8.3-apache

RUN a2enmod rewrite

RUN pecl install apcu \
    && docker-php-ext-enable apcu \
    && rm -rf /tmp/pear

# AllowOverride for .htaccess, disable covers directory listing
RUN printf '<Directory /var/www/html>\n    AllowOverride All\n    Options -Indexes\n</Directory>\n<Directory /var/www/html/covers>\n    Options -Indexes\n</Directory>\n' \
    > /etc/apache2/conf-available/allowoverride.conf \
    && a2enconf allowoverride

ADD https://raw.githubusercontent.com/binyaminyblatt/graphicaudio_scraper/main/index.php /var/www/html/index.php
ADD https://raw.githubusercontent.com/binyaminyblatt/graphicaudio_scraper/main/.htaccess /var/www/html/.htaccess

# Strip the <Directory> block from .htaccess — not valid in .htaccess context;
# handled above in allowoverride.conf instead
RUN sed -i '/<Directory/,/<\/Directory>/d' /var/www/html/.htaccess

RUN sed -i "s|define('REFRESH_KEY', '.*');|define('REFRESH_KEY', getenv('REFRESH_KEY') ?: 'changeme');|" /var/www/html/index.php \
    && sed -i "s|define('AUDIOBOOKSHELF_KEY', '.*');|define('AUDIOBOOKSHELF_KEY', getenv('AUDIOBOOKSHELF_KEY') ?: 'abs');|" /var/www/html/index.php

RUN mkdir -p /var/www/html/covers \
    && chown -R www-data:www-data /var/www/html

# Docker secrets support: REFRESH_KEY_FILE / AUDIOBOOKSHELF_KEY_FILE -> env vars
COPY graphicaudio_entrypoint.sh /usr/local/bin/graphicaudio_entrypoint.sh
RUN chmod 755 /usr/local/bin/graphicaudio_entrypoint.sh

ENTRYPOINT ["/usr/local/bin/graphicaudio_entrypoint.sh"]
CMD ["apache2-foreground"]
