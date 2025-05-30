FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

# 使用台灣 NCHC 的 Ubuntu mirror
RUN sed -i 's|http://archive.ubuntu.com/ubuntu/|http://free.nchc.org.tw/ubuntu/|g' /etc/apt/sources.list && \
    sed -i 's|http://security.ubuntu.com/ubuntu|http://free.nchc.org.tw/ubuntu|g' /etc/apt/sources.list

# 安裝 Apache + PHP + MariaDB + Supervisor + ttyd 所需工具
RUN apt update && \
    apt install -y --no-install-recommends \
    apache2 php php-mysql libapache2-mod-php mariadb-server \
    wget unzip curl ca-certificates supervisor && \
    rm -rf /var/lib/apt/lists/*

# 安裝 docker CLI（只需要 client，不用 daemon）
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

# 安裝 ttyd
RUN wget https://github.com/tsl0922/ttyd/releases/download/1.7.7/ttyd.x86_64 -O /usr/local/bin/ttyd && \
    chmod +x /usr/local/bin/ttyd

# 啟用 Apache Proxy 模組
RUN a2enmod proxy proxy_http proxy_wstunnel rewrite

# 修改 Apache port 為 8080
RUN sed -i 's/80/8080/g' /etc/apache2/ports.conf /etc/apache2/sites-enabled/000-default.conf

# 設定 Apache ServerName 避免警告
RUN echo "ServerName localhost" >> /etc/apache2/apache2.conf

# 寫入 Apache 虛擬主機設定（支援 /shell → ttyd）
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

# 安裝 WordPress 並設定
RUN wget https://wordpress.org/latest.zip && \
    unzip latest.zip && \
    cp -r wordpress/* /var/www/html/ && \
    chown -R www-data:www-data /var/www/html && \
    rm -rf wordpress latest.zip && \
    rm -f /var/www/html/index.html

# 複製初始化 SQL（你要提供 init.sql）
COPY init.sql /init.sql

# 複製 supervisord 設定
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf

EXPOSE 8080

CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]

