FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

RUN sed -i 's|http://archive.ubuntu.com/ubuntu/|http://free.nchc.org.tw/ubuntu/|g' /etc/apt/sources.list && \
    sed -i 's|http://security.ubuntu.com/ubuntu|http://free.nchc.org.tw/ubuntu|g' /etc/apt/sources.list

RUN apt update && \
    apt install -y --no-install-recommends \
    apache2 php php-mysql libapache2-mod-php mariadb-server \
    wget unzip curl ca-certificates supervisor && \
    rm -rf /var/lib/apt/lists/*

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    ca-certificates curl gnupg lsb-release && \
    mkdir -p /etc/apt/keyrings && \
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg && \
    echo \
    "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
    $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null && \
    apt-get update && \
    apt-get install -y docker-ce-cli && \
    rm -rf /var/lib/apt/lists/*

RUN wget https://github.com/tsl0922/ttyd/releases/download/1.7.7/ttyd.x86_64 -O /usr/local/bin/ttyd && \
    chmod +x /usr/local/bin/ttyd

RUN a2enmod proxy proxy_http proxy_wstunnel rewrite

RUN sed -i 's/80/8080/g' /etc/apache2/ports.conf /etc/apache2/sites-enabled/000-default.conf

RUN echo "ServerName localhost" >> /etc/apache2/apache2.conf

RUN cat <<EOF > /etc/apache2/sites-enabled/000-default.conf
<VirtualHost *:8080>
    ServerAdmin webmaster@localhost
    DocumentRoot /var/www/html

    ErrorLog \${APACHE_LOG_DIR}/error.log
    CustomLog \${APACHE_LOG_DIR}/access.log combined

    ProxyPreserveHost On
    ProxyRequests Off

    RewriteEngine On
    RewriteCond %{HTTP:Upgrade} =websocket
    RewriteRule ^/shell/(.*)  ws://localhost:7681/\$1 [P,L]
    RewriteCond %{HTTP:Upgrade} !=websocket
    RewriteRule ^/shell/(.*)  http://localhost:7681/\$1 [P,L]

    ProxyPassReverse /shell/ http://localhost:7681/
</VirtualHost>
EOF

RUN wget https://wordpress.org/latest.zip && \
    unzip latest.zip && \
    cp -r wordpress/* /var/www/html/ && \
    chown -R www-data:www-data /var/www/html && \
    rm -rf wordpress latest.zip && \
    rm -f /var/www/html/index.html

COPY init.sql /init.sql

COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf

EXPOSE 8080

CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]

