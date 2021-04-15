## Install local LEMP for macOS

For *Front End development*, a full Vagrant box is not always needed. If you have a new Macbook Pro, you can install local LEMP (Linux, nginx, MariaDB and PHP) with this single liner below. Please see [installation steps](#installation-steps).

```` bash
wget -O - https://raw.githubusercontent.com/digitoimistodude/macos-lemp-setup/master/install.sh | bash
````

**Please note:** Don't trust blindly to the script, use only if you know what you are doing. You can view the file [here](https://github.com/digitoimistodude/osx-lemp-setup/blob/master/install.sh) if having doubts what commands are being run. However, script is tested working many times and should be safe to run even if you have some or all of the components already installed.

## Table of contents

1. [Background](#background)
2. [Features](#features)
3. [Requirements](#requirements)
4. [Installation](#installation)
5. [Post installations](#post-installations)
6. [Use Linux-style aliases](#use-linux-style-aliases)
7. [File sizes](#file-sizes)
8. [XDebug](#xdebug)
9. [Redis](#redis)
10. [Troubleshooting](#troubleshooting)

### Background

Read the full story by [@ronilaukkarinen](https://github.com/ronilaukkarinen): **[Moving from Vagrant to a LEMP stack directly on a Macbook Pro (for WordPress development)](https://medium.com/@rolle/moving-from-vagrant-to-a-lemp-stack-directly-on-a-macbook-pro-e935b1bc5a38)**

### Features

- PHP 7.2
- nginx 1.19.2
- Super lightweight
- Native packages
- Always on system service
- HTTPS support
- Consistent with production setup
- Works even [on Windows](https://github.com/digitoimistodude/windows-lemp-setup)

### Requirements

- [Homebrew](https://brew.sh/)
- macOS, preferably 10.14.2 (Mojave)
- wget
- [mkcert](https://github.com/FiloSottile/mkcert)

### Installation

1. Install wget, `brew install wget`
2. Run oneliner installation script `wget -O - https://raw.githubusercontent.com/digitoimistodude/macos-lemp-setup/master/install.sh | bash`
3. Link PHP executable like this: **Run:** `sudo find / -name 'php'`. When you spot link that looks like this (yours might be different version) */usr/local/Cellar/php@7.2/7.2.24/bin/php*, symlink it to correct location to override MacOS's own file: `sudo ln -s /usr/local/Cellar/php@7.2/7.2.24/bin/php /usr/local/bin/php`
4. Check the version with `php --version`, it should match the linked file.
5. Brew should have already handled other links, you can test the correct versions with `sudo mysql --version` (if it's something like _mysql  Ver 15.1 Distrib 10.5.5-MariaDB, for osx10.15 (x86_64) using readline 5.1_ it's the correct one) and `sudo nginx -v` (if it's something like nginx version: nginx/1.19.3 it's the correct one)
6. Add `export PATH="$(brew --prefix php@7.2)/bin:$PATH"` to .bash_profile (or to your zsh profile or to whatever term profile you are currently using)
7. Run [Post install](#post-install)
8. Enjoy! If you use [dudestack](https://github.com/digitoimistodude/dudestack), please check instructions from [its own repo](https://github.com/digitoimistodude/dudestack).

### Post installations

You may want to add your user and group correctly to `/usr/local/etc/php/7.2/php-fpm.d/www.conf` and set these to the bottom:

```` nginx
catch_workers_output = yes
php_flag[display_errors] = On
php_admin_value[error_log] = /var/log/fpm7.2-php.www.log 
slowlog = /var/log/fpm7.2-php.slow.log 
php_admin_flag[log_errors] = On
php_admin_value[memory_limit] = 1024M
request_slowlog_timeout = 10
php_admin_value[upload_max_filesize] = 100M
php_admin_value[post_max_size] = 100M
````

Default vhost for your site (/etc/nginx/sites-enabled/sitename.test) could be something like:

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

For mysql, <b>remember to run `sudo mysql_secure_installation`</b>, answer as suggested, add/change root password, remove test users etc. <b>Only exception!</b> Answer with <kbd>n</kbd> to the question <code>Disallow root login remotely? [Y/n]</code>. Your logs can be found at `/usr/local/var/mysql/yourcomputername.err` (where yourcomputername is obviously your hostname).

After that, get to know [dudestack](https://github.com/digitoimistodude/dudestack) to get everything up and running smoothly. Current version of dudestack supports macOS LEMP stack.

You should remember to add vhosts to your /etc/hosts file, for example: `127.0.0.1 site.test`.

### Use Linux-style aliases

Add this to */usr/local/bin/service* and chmod it +x:

```` bash
#!/bin/bash
# Alias for unix type of commands
brew services "$2" "$1";
````

Now you are able to restart nginx and mysql unix style like this:

```` bash
sudo service nginx restart
sudo service mariadb restart
````

### File sizes

You might want to increase file sizes for development environment in case you need to test compression plugins and other stuff in WordPress. To do so, edit `/usr/local/etc/php/7.2/php-fpm.d/www.conf` and `/usr/local/etc/php/7.2/php.ini` and change all **memory_limit**, **post_max_size** and **upload_max_filesize** to something that is not so limited, for example **500M**.

Please note, you also need to change **client_max_body_size** to the same amount in `/etc/nginx/nginx.conf`. After this, restart php-fpm with `sudo brew services restart php@7.2` and nginx with `sudo brew services restart nginx`.

### Certificates for localhost

First things first, if you haven't done it yet, generate general dhparam:

```` bash
sudo su -
cd /etc/ssl/certs
openssl dhparam -out dhparam.pem 4096 
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

### XDebug

1. Check your PHP version with `php --version`
2. Search pecl `find -L "$(brew --prefix php@7.3)" -name pecl -o -name pear`
3. Symlink pecl based on result, for example `sudo ln -s /usr/local/opt/php@7.3/bin/pecl /usr/local/bin/pecl`
4. Add executable permissions `sudo chmod +x /usr/local/bin/pecl`
5. Install xdebug `pecl install xdebug`
6. Check `php --version`, it should display something like this:

``` shell
$ php --version
PHP 7.3.21 (cli) (built: Aug  7 2020 18:56:36) ( NTS )
Copyright (c) 1997-2018 The PHP Group
Zend Engine v3.3.21, Copyright (c) 1998-2018 Zend Technologies
    with Xdebug v3.0.3, Copyright (c) 2002-2021, by Derick Rethans
    with Zend OPcache v7.3.21, Copyright (c) 1999-2018, by Zend Technologies
```

7. Check where your php.ini file is with `php --ini`
8. Edit php.ini, for example `sudo nano `
9. Make sure these are on the first lines:

```
zend_extension="xdebug.so"
xdebug.mode=debug
xdebug.client_port=9003
xdebug.client_host=127.0.0.1
xdebug.remote_handler=dbgp
xdebug.start_with_request=yes
xdebug.discover_client_host=0
xdebug.show_error_trace = 1
xdebug.max_nesting_level=250
xdebug.var_display_max_depth=10
xdebug.log=/var/log/xdebug.log
```

10. Save and close with <kbd>ctrl</kbd> + <kbd>O</kbd> and <kbd>ctrl</kbd> + <kbd>X</kbd>
11. Make sure the log exists `sudo touch /var/log/xdebug.log && sudo chmod 777 /var/log/xdebug.log`
12. Restart services (requires [Linux-style aliases](#use-linux-style-aliases)) `sudo service php@7.3 restart && sudo service nginx restart`
13. Install [PHP Debug VSCode plugin](https://marketplace.visualstudio.com/items?itemName=felixfbecker.php-debug)
14. Add following to launch.json (<kbd>cmd</kbd> + + <kbd>shift</kbd> + <kbd>P</kbd>, "Open launch.json"):

``` json
{
  "version": "0.2.0",
  "configurations": [
    {
      //"debugServer": 4711, // Uncomment for debugging the adapter
      "name": "Listen for Xdebug",
      "type": "php",
      "request": "launch",
      "port": 9003,
      "log": true
    },
    {
      //"debugServer": 4711, // Uncomment for debugging the adapter
      "name": "Launch",
      "request": "launch",
      "type": "php",
      "program": "${file}",
      "cwd": "${workspaceRoot}",
      "externalConsole": false
    }
  ]
}
```
15. Xdebug should now work on your editor
16. PHPCS doesn't need xdebug but will warn about it not working... this causes error in [phpcs-vscode](https://marketplace.visualstudio.com/items?itemName=ikappas.phpcs) because it depends on outputted phpcs json that is not valid with the warning _"Xdebug: [Step Debug] Could not connect to debugging client. Tried: 127.0.0.1:9003 (through xdebug.client_host/xdebug.client_port) :-(_". This can be easily fixed by installing a bash "wrapper":
17. Rename current phpcs with `sudo mv /usr/local/bin/phpcs /usr/local/bin/phpcs.bak`
18. Install new with `sudo nano /usr/local/bin/phpcs`:

``` bash
#!/bin/bash
XDEBUG_MODE=off /Users/rolle/Projects/phpcs/bin/phpcs "$@"
```

19. Add permissions `sudo chmod +x /usr/local/bin/phpcs`
20. Make sure VSCode settings.json has this setting:

``` json
"phpcs.executablePath": "/usr/local/bin/phpcs",
```

### Redis

Redis is an open source, in-memory data structure store, used as a database, cache.

We are going to install Redis and php-redis.

1. Check that `pecl` command works
2. Run `brew update` first
3. Install Redis, `brew install redis`
4. Start Redis `brew services start redis`, this will also make sure that Redis is always started on reboot
5. Test if Redis server is running `redis-cli ping`, expected response is `OK`
6. Install PHP Redis extention `pecl install redis-5.3.4`. When asked about enabling some supports, answer `no`.
7. Restart nginx and php-redis should be available, you can test it with `php -r "if (new Redis() == true){ echo \"\r\n OK \r\n\"; }"` command, expected response is `OK`

### Troubleshooting

If you have something like this in your /var/log/nginx/error.log:

```
2019/08/12 14:09:04 [crit] 639#0: *129 open() "/usr/local/var/run/nginx/client_body_temp/0000000005" failed (13: Permission denied), client: 127.0.0.1, server: project.test, request: "POST /wp/wp-admin/async-upload.php HTTP/1.1", host: "project.test", referrer: "http://project.test/wp/wp-admin/upload.php"
```

If you cannot login to mysql from other than localhost, please answer with <kbd>n</kbd> to the question <code>Disallow root login remotely? [Y/n]</code> when running <code>mysql_secure_install</code>.

**Make sure you run nginx and php-fpm on your root user and mariadb on your regular user**. This is important. Stop nginx from running on your default user by `brew services stop nginx` and run it with sudo `sudo brew services start nginx`.

<code>sudo brew services list</code> should look like this:

``` shell
~ sudo brew services list
Name       Status  User  Plist
dnsmasq    started root  /Library/LaunchDaemons/homebrew.mxcl.dnsmasq.plist
mariadb    started rolle /Users/rolle/Library/LaunchAgents/homebrew.mxcl.mariadb.plist
nginx      started root  /Library/LaunchDaemons/homebrew.mxcl.nginx.plist
php@7.3    started root  /Library/LaunchDaemons/homebrew.mxcl.php@7.3.plist
```

You may have "unknown" as status or different PHP version, but **User** should be like in the list above. Then everything should work.  
