# LEMP: Local Environment Made Powerful 
(Just kidding, it's really **Linux + nginx [engine x] + MySQL + PHP-FPM**)

## Still the best way to locally develop WordPress.

![pop-lemp](https://github.com/raikasdev/pop-lemp-setup/assets/29684625/78dcc17c-87e5-4a81-b766-decc3cbcde90)

**Pop LEMP Setup is designed for Pop!_OS only!**

It *might* work on Ubuntu, Debian, Mint or any other fork. No guarantees.

Interested in similar approach on Mac? 👉 [macos-lemp-stack](https://github.com/digitoimistodude/macos-lemp-stack). \
Interested in similar approach on Windows? 👉 [Setting up a local server on Windows 10 for WordPress theme development (or any web development for that matter)](https://rolle.design/local-server-on-windows-10-for-wordpress-theme-development).

## Install local LEMP for Pop!_OS

For *Front End development*, a full Vagrant box, docker container per site or Local by Flywheel is not really needed. If you have a desktop or laptop running Pop!_OS, you can install local LEMP (Linux, nginx, MariaDB and PHP) with this single liner below. 

Please see [installation steps](#installation) instructions first.

```` bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/raikasdev/pop-lemp-setup/master/install.sh)"
````

**Please note:** Don't trust blindly to the script, use only if you know what you are doing. You can view the file [here](https://github.com/raikasdev/pop-lemp-setup/blob/master/install.sh) if having doubts what commands are being run. However, script is tested working many times and should be safe to run even if you have some or all of the components already installed.

## Table of contents

1. [Background](#background)
2. [Features](#features)
3. [Requirements](#requirements)
4. [Installation](#installation)
5. [Post installations](#post-installations)
   1. [Mailhog](#MailHog)
6. [Use Linux-style aliases](#use-linux-style-aliases)
7. [File sizes](#file-sizes)
8. [XDebug](#xdebug)
9. [Redis](#redis)
10. [Troubleshooting](#troubleshooting)

### Background

Pop!_OS LEMP setup is a fork of Digitoimisto Dude's macos-lemp-stack.

Read the full story by [@ronilaukkarinen](https://github.com/ronilaukkarinen): **[Moving from Vagrant to a LEMP stack directly on a Macbook Pro (for WordPress development)](https://medium.com/@rolle/moving-from-vagrant-to-a-lemp-stack-directly-on-a-macbook-pro-e935b1bc5a38)**

### Features

- PHP 7.4
- nginx 1.19.2
- Super lightweight
- Native packages
- Always on system service
- HTTPS support
- Consistent with production setup
- Works even [on Windows](https://github.com/digitoimistodude/windows-lemp-setup)

### Requirements

- Pop!_OS 22.04 LTS
- wget

### Installation

1. Run oneliner installation script `/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/raikasdev/pop-lemp-setup/master/install.sh)"` and follow the instructions.
2. You should answer "yes" to all questions MariaDB asks you, **except** disallowing root login remotely. Remember what password you set, you will need it later.
3. Go through [post installations](#post-installations)
4. Enjoy! If you use [dudestack](https://github.com/digitoimistodude/dudestack), please check instructions from [its own repo](https://github.com/digitoimistodude/dudestack).

### Post installations

#### PHP permissions

You may want to add your user to the `www-data` group by using `usermod -a -G www-data $USER`.

If you use sudo to create or edit files or directories in `/var/www`, you should do the following:
- `chown -R www-data:www-data /var/www`
- `chmod -R 775 /var/www`

#### Default nginx config

Make sure you have default vhost for your site (`/etc/nginx/sites-enabled/sitename.test`) could be something like:

```` nginx
server {
    listen 80;
    root /var/www/example;
    index index.html index.htm index.php;
    server_name example.test www.example.test;
    include php7.conf;
    include global/wordpress.conf;
}
````

#### Default MySQL my.cnf

Default my.cnf would be something like this (already added by install.sh in `/usr/local/etc/my.cnf`:

````
#
# This group is read both both by the client and the server
# use it for options that affect everything
#
[client-server]

#
# include all files from the config directory
#
!includedir /usr/local/etc/my.cnf.d

[mysqld]
innodb_log_file_size = 32M
innodb_buffer_pool_size = 1024M
innodb_log_buffer_size = 4M
slow_query_log = 1
query_cache_limit = 512K
query_cache_size = 128M
skip-name-resolve
````

Again, if the correct file cannot be found, you can find it with:

```
sudo find / -name 'my.cnf'
```

After that, get to know [dudestack](https://github.com/digitoimistodude/dudestack) to get everything up and running smoothly. Current version of dudestack **doesn't** support Pop!_OS LEMP stack.

If you don't use dudestack, you should remember to add vhosts to your /etc/hosts file, for example: `127.0.0.1 site.test`.

#### MailHog

E-mails won't be sent on local environment because there is no email server configured. This is where [MailHog](https://github.com/mailhog/MailHog) comes in.

MailHog should be pre-installed but if not, run following:

``` bash
sudo apt update && sudo apt-get -y install golang-go && go install github.com/mailhog/MailHog@latest
```

Ensure you have the latest [air-helper](https://github.com/digitoimistodude/air-helper) or [MailHog for WordPress](https://wordpress.org/plugins/wp-mailhog-smtp/) activated to enable MailHog routing for local environment.

Then just run:

``` bash
mailhog
```

You should now get a log in command line and web interface is available in http://0.0.0.0:8025/.

### File sizes

You might want to increase file sizes for development environment in case you need to test compression plugins and other stuff in WordPress. To do so, edit `/etc/php/7.4/fpm/pool.d/www.conf` and `/etc/php/7.4/fpm/php.ini` and change all **memory_limit**, **post_max_size** and **upload_max_filesize** to something that is not so limited, for example **500M**.

Please note, you also need to change **client_max_body_size** to the same amount in `/etc/nginx/nginx.conf`. After this, restart php-fpm with `sudo systemctl restart php7.4-fpm` and nginx with `sudo systemctl restart nginx`.

### Certificates for localhost

Dudestack users: Dudestack handles this.

First things first, if you haven't done it yet, generate general dhparam:

```` bash
sudo su -
cd /etc/ssl/certs
sudo openssl dhparam -dsaparam -out dhparam.pem 4096
````

Generating certificates for dev environment is easiest with [mkcert](https://github.com/FiloSottile/mkcert). After installing mkcert, just run:

```` bash
mkdir -p /var/www/certs && cd /var/www/certs && mkcert "project.test"
````

Then edit your vhost as following (change all from *project* to your project name):

```` nginx
server {
    listen 443 ssl http2;
    root /var/www/project;
    index index.php;    
    server_name project.test;

    include php7.conf;
    include global/wordpress.conf;

    ssl_certificate /var/www/certs/project.test.pem;
    ssl_certificate_key /var/www/certs/project.test-key.pem;
    ssl_protocols TLSv1 TLSv1.1 TLSv1.2;
    ssl_prefer_server_ciphers on;
    ssl_dhparam /etc/ssl/certs/dhparam.pem;
    ssl_ciphers 'ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-AES256-GCM-SHA384:DHE-RSA-AES128-GCM-SHA256:DHE-DSS-AES128-GCM-SHA256:kEDH+AESGCM:ECDHE-RSA-AES128-SHA256:ECDHE-ECDSA-AES128-SHA256:ECDHE-RSA-AES128-SHA:ECDHE-ECDSA-AES128-SHA:ECDHE-RSA-AES256-SHA384:ECDHE-ECDSA-AES256-SHA384:ECDHE-RSA-AES256-SHA:ECDHE-ECDSA-AES256-SHA:DHE-RSA-AES128-SHA256:DHE-RSA-AES128-SHA:DHE-DSS-AES128-SHA256:DHE-RSA-AES256-SHA256:DHE-DSS-AES256-SHA:DHE-RSA-AES256-SHA:AES128-GCM-SHA256:AES256-GCM-SHA384:AES128-SHA256:AES256-SHA256:AES128-SHA:AES256-SHA:AES:CAMELLIA:DES-CBC3-SHA:!aNULL:!eNULL:!EXPORT:!DES:!RC4:!MD5:!PSK:!aECDH:!EDH-DSS-DES-CBC3-SHA:!EDH-RSA-DES-CBC3-SHA:!KRB5-DES-CBC3-SHA';
    ssl_session_timeout 1d;
    ssl_session_cache shared:SSL:50m;
    ssl_stapling_verify on;
    add_header Strict-Transport-Security max-age=15768000;
}

server {
    listen 80;
    server_name project.test;
    return 301 https://$host$request_uri;
}
````

Test with `sudo nginx -t` and if everything is OK, restart nginx.

### Redis

Redis is an open source, in-memory data structure store, used as a database, cache. We are going to install Redis and php-redis.

1. Check that `pecl` command works, if not run `sudo apt install php-pear`
2. Run `sudo apt update` first
3. Install Redis, `sudo apt install redis`
4. Start Redis `sudo systemctl enable --now redis-server`, this will also make sure that Redis is always started on reboot
5. Test if Redis server is running `redis-cli ping`, expected response is `PONG`
6. Install PHP igbinary extension `pecl install igbinary`
6. Install PHP Redis extension `pecl install redis`. When asked about enabling some supports, answer `no`.
7. Restart nginx and php-redis should be available, you can test it with `php -r "if (new Redis() == true){ echo \"\r\n OK \r\n\"; }"` command, expected response is `OK`

### Troubleshooting

**Testing which version of PHP you run**

Test with `php --version` what version of PHP you are using, if the command returns something like `PHP is included in macOS for compatibility with legacy software` and especially when `which php` is showing /usr/bin/php then you are using macOS built-in version (which will be removed in the future anyway) and things most probably won't work as expected.

To fix this, run command `sudo ln -s /usr/local/Cellar/php@7.4/7.4.23/bin/php /usr/local/bin/php` which symlinks the homebrew version to be used instead of macOS version OR use bashrc export as defined [here in step 4](https://github.com/digitoimistodude/macos-lemp-setup#installation).

#### PHP or mysql not working at all

If you have something like this in your /var/log/nginx/error.log:

```
2019/08/12 14:09:04 [crit] 639#0: *129 open() "/usr/local/var/run/nginx/client_body_temp/0000000005" failed (13: Permission denied), client: 127.0.0.1, server: project.test, request: "POST /wp/wp-admin/async-upload.php HTTP/1.1", host: "project.test", referrer: "http://project.test/wp/wp-admin/upload.php"
```

If you cannot login to mysql from other than localhost, please answer with <kbd>n</kbd> to the question <code>Disallow root login remotely? [Y/n]</code> when running <code>sudo mysql_secure_installation</code>.

#### MySQL/MariaDb issues

If you get problems like:

```
ERROR 2002 (HY000): Can't connect to MySQL server on '127.0.0.1' (36)
```

It seems you have messed up with your root password. Try resetting root password by following the guide [here](https://www.digitalocean.com/community/tutorials/how-to-reset-your-mysql-or-mariadb-root-password-on-ubuntu-20-04).

If you are still having problems connecting with WordPress and prompting `Access denied for user 'root'@'127.0.0.1'`, try this in `mysql -u root -p`:

``` sql
GRANT ALL PRIVILEGES ON *.* TO root@localhost IDENTIFIED BY 'YOUR_MYSQL_ROOT_PASSWORD' WITH GRANT OPTION;
GRANT ALL PRIVILEGES ON *.* TO root@127.0.0.1 IDENTIFIED BY 'YOUR_MYSQL_ROOT_PASSWORD' WITH GRANT OPTION;
```

#### *2 open() "/var/www/test.txt" failed (13: Permission denied), client: 127.0.0.1

If you are getting permission denied by nginx, you need to make sure your php-fpm and nginx are running on the same user.

Open `/etc/php/7.4/fpm/pool.d/www.conf` and change the user to your username and group to www-data and listen to following:

Open `/etc/nginx/nginx.conf` and add to first line:

```ini
user your_username www-data;
```

#### "Primary script unknown" error in nginx log or "File not found." in browser

This is caused by php-fpm not running properly. Please [make sure the PHP runs on correct permissions](#make-sure-the-php-runs-on-correct-permissions) section.
