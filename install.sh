# Helper variables
txtbold=$(tput bold)
boldyellow=${txtbold}$(tput setaf 3)
boldgreen=${txtbold}$(tput setaf 2)
yellow=$(tput setaf 3)
green=$(tput setaf 2)
white=$(tput setaf 7)
txtreset=$(tput sgr0)

echo "${yellow}Getting dependencies.${txtreset}"
echo "${yellow}Installing nginx.${txtreset}"
sudo apt install nginx
sudo systemctl enable --now nginx
curl -IL http://127.0.0.1:80
echo "${boldgreen}nginx installed and running.${txtreset}"
echo "${yellow}Setting up nginx.${txtreset}"
sudo mkdir -p "/etc/nginx/global"
sudo mkdir -p "/etc/nginx/sites-enabled"
sudo mkdir -p "/etc/nginx/sites-available"
sudo chmod -R 775 "/etc/nginx/global"
sudo chmod -R 775 "/etc/nginx/sites-enabled"
sudo chmod -R 775 "/etc/nginx/sites-available"
sudo echo "user $(whoami) www-data;
worker_processes 18;
  
events {  
        multi_accept on;
        accept_mutex on;
        worker_connections 1024;
}

http {  

        ##  
        # Optimization  
        ##  
  
        sendfile on;
        sendfile_max_chunk 512k;
        tcp_nopush on;  
        tcp_nodelay on;  
        keepalive_timeout 120;
        keepalive_requests 100000;  
        types_hash_max_size 2048;
        server_tokens off;
        client_body_buffer_size      128k;  
        client_max_body_size         10m;  
        client_header_buffer_size    1k;  
        large_client_header_buffers  4 32k;  
        output_buffers               1 32k;  
        postpone_output              1460;
  
        server_names_hash_max_size 1024;  
        #server_names_hash_bucket_size 64;  
        # server_name_in_redirect off;  
  
        include /etc/nginx/mime.types;  
        default_type application/octet-stream;  

        ##
        # Logging Settings
        ##
        access_log off;
        access_log /var/log/nginx/access.log combined;
        error_log /var/log/nginx/error.log;

        ##
        # Virtual Host Configs
        ##
        
        include /etc/nginx/sites-enabled/*;
}" | sudo tee "/etc/nginx/nginx.conf"
sudo mkdir -p /var/log/nginx
sudo touch /var/log/nginx/access.log
sudo chmod 777 /var/log/nginx/access.log
sudo touch /var/log/nginx/error.log
sudo chmod 777 /var/log/nginx/error.log
sudo echo "location ~ \.php\$ {
  try_files                     \$fastcgi_script_name =404;

  # default fastcgi_params
  include                       fastcgi_params;

  # fastcgi settings
  fastcgi_index                 index.php;
  fastcgi_buffers               8 16k;
  fastcgi_buffer_size           32k;

  # fastcgi params
  fastcgi_param DOCUMENT_ROOT   \$realpath_root;
  fastcgi_param SCRIPT_FILENAME \$realpath_root\$fastcgi_script_name;
  fastcgi_param PHP_ADMIN_VALUE \"open_basedir=\$document_root/:/usr/lib/php/:/tmp/\";

  fastcgi_pass unix:/var/run/php/php-fpm.sock;
}" | sudo tee "/etc/nginx/php7.conf"
sudo echo "# WordPress single site rules.
# Designed to be included in any server {} block.
# Upstream to abstract backend connection(s) for php
location = /favicon.ico {
        log_not_found off;
        access_log off;
}

location = /robots.txt {
        allow all;
        log_not_found off;
        access_log off;
}

location / {
        # This is cool because no php is touched for static content.
        # include the "?\$args" part so non-default permalinks doesn't break when using query string
        try_files \$uri \$uri/ /index.php?\$args;
}

# Add trailing slash to */wp-admin requests.
rewrite /wp-admin\$ \$scheme://\$host\$uri/ permanent;

# Directives to send expires headers and turn off 404 error logging.
location ~* ^.+\.(ogg|ogv|svg|svgz|eot|otf|woff|mp4|ttf|rss|atom|jpg|jpeg|gif|png|ico|zip|tgz|gz|rar|bz2|doc|xls|exe|ppt|tar|mid|midi|wav|bmp|rtf)\$ {
       access_log off; log_not_found off; expires max;
}" | sudo tee "/etc/nginx/global/wordpress.conf"
sudo echo "server {
        listen 80 default_server;
        root /var/www/html;
        index index.html index.htm index.php;
        server_name localhost;
        include php7.conf;
        include global/wordpress.conf;
}" | sudo tee "/etc/nginx/sites-available/default"
sudo echo "types {
  text/html                             html htm shtml;
  text/css                              css;
  text/xml                              xml rss;
  image/gif                             gif;
  image/jpeg                            jpeg jpg;
  application/x-javascript              js;
  text/plain                            txt;
  text/x-component                      htc;
  text/mathml                           mml;
  image/png                             png;
  image/x-icon                          ico;
  image/x-jng                           jng;
  image/vnd.wap.wbmp                    wbmp;
  application/java-archive              jar war ear;
  application/mac-binhex40              hqx;
  application/pdf                       pdf;
  application/x-cocoa                   cco;
  application/x-java-archive-diff       jardiff;
  application/x-java-jnlp-file          jnlp;
  application/x-makeself                run;
  application/x-perl                    pl pm;
  application/x-pilot                   prc pdb;
  application/x-rar-compressed          rar;
  application/x-redhat-package-manager  rpm;
  application/x-sea                     sea;
  application/x-shockwave-flash         swf;
  application/x-stuffit                 sit;
  application/x-tcl                     tcl tk;
  application/x-x509-ca-cert            der pem crt;
  application/x-xpinstall               xpi;
  application/zip                       zip;
  application/octet-stream              deb;
  application/octet-stream              bin exe dll;
  application/octet-stream              dmg;
  application/octet-stream              eot;
  application/octet-stream              iso img;
  application/octet-stream              msi msp msm;
  audio/mpeg                            mp3;
  audio/x-realaudio                     ra;
  video/mpeg                            mpeg mpg;
  video/quicktime                       mov;
  video/x-flv                           flv;
  video/x-msvideo                       avi;
  video/x-ms-wmv                        wmv;
  video/x-ms-asf                        asx asf;
  video/x-mng                           mng;
}" | sudo tee "/etc/nginx/mime.types"
sudo echo "fastcgi_param  QUERY_STRING       \$query_string;
fastcgi_param  REQUEST_METHOD     \$request_method;
fastcgi_param  CONTENT_TYPE       \$content_type;
fastcgi_param  CONTENT_LENGTH     \$content_length;

fastcgi_param  SCRIPT_NAME        \$fastcgi_script_name;
fastcgi_param  REQUEST_URI        \$request_uri;
fastcgi_param  DOCUMENT_URI       \$document_uri;
fastcgi_param  DOCUMENT_ROOT      \$document_root;
fastcgi_param  SERVER_PROTOCOL    \$server_protocol;
fastcgi_param  REQUEST_SCHEME     \$scheme;
fastcgi_param  HTTPS              \$https if_not_empty;

fastcgi_param  GATEWAY_INTERFACE  CGI/1.1;
fastcgi_param  SERVER_SOFTWARE    nginx/\$nginx_version;

fastcgi_param  REMOTE_ADDR        \$remote_addr;
fastcgi_param  REMOTE_PORT        \$remote_port;
fastcgi_param  SERVER_ADDR        \$server_addr;
fastcgi_param  SERVER_PORT        \$server_port;
fastcgi_param  SERVER_NAME        \$server_name;

# PHP only, required if PHP was built with --enable-force-cgi-redirect
fastcgi_param  REDIRECT_STATUS    200;" | sudo tee "/etc/nginx/fastcgi_params"
sudo ln -sfnv /etc/nginx/sites-available/default /etc/nginx/sites-enabled/default
sudo mkdir -p /var/www/html
sudo echo "<!DOCTYPE html><html><head><title>Hello world</title></head><body>Hello world!</body></html>" | sudo tee "/var/www/html/index.html"
sudo chown -R $(whoami):www-data /var/www
sudo chmod -R 777 /var/www
echo "${yellow}Installing PHP.${txtreset}"
sudo apt update
sudo add-apt-repository --yes ppa:ondrej/php
sudo apt update
sudo apt install php7.4 php7.4-curl php7.4-redis php7.4-xml php7.4-fpm php7.4-igbinary php7.4-json php7.4-dev php-pear
sudo systemctl enable --now php-fpm
sudo sed -i -e "s/user = www-data/user = $(whoami)/g" /etc/php/7.4/fpm/pool.d/www.conf
echo "${boldgreen}PHP installed and running.${txtreset}"

echo "${yellow}Installing MariaDB.${txtreset}"
sudo apt install mariadb-server
sudo systemctl enable --now mysql
echo "${yellow}Configuring MariaDB (mysql_secure_installation). Please answer yes to all except denying all outside connections. Set a root password and remember it.${txtreset}"
if [[ "$DONT_SECURE_INSTALL_MYSQL" != "yes" ]]; then
  # CI
  mysql_secure_installation
fi
echo "${boldgreen}MariaDB installed and running.${txtreset}"

echo "${yellow}Installing MailHog.${txtreset}"
sudo apt-get -y install golang-go
go install github.com/mailhog/MailHog@latest
echo "${boldgreen}MailHog installed (run mailhog to start mail server).${txtreset}"

echo "${yellow}Installing mkcert.${txtreset}"
curl -JLO "https://dl.filippo.io/mkcert/latest?for=linux/amd64"
sudo chmod +x mkcert-v*-linux-amd64
sudo mv mkcert-v*-linux-amd64 /usr/local/bin/mkcert
echo "${boldgreen}mkcert installed.${txtreset}"

echo "${yellow}Restarting services....${txtreset}"
# These need to be running as root, because of the port 80 and other privileges.
sudo systemctl restart nginx
sudo systemctl restart php7.4-fpm
sudo systemctl restart mysql

sudo nginx -t

echo "${boldgreen}You should now be able to use http://localhost. If not, test with commands sudo nginx -t and sudo php-fpm -t and fix errors. Add new vhosts to /opt/homebrew/etc/nginx/sites-available and symlink them just like you would do in production. Have fun!${txtreset}"
