#!/bin/bash -i
#
# Script d'installation ruTorrent / Nginx
# Auteur : Ex_Rat
#
# Nécessite Debian 9/10 - 64 bits & un serveur fraîchement installé
#
# Multi-utilisateurs
# Inclus VsFTPd (ftp & ftps sur le port 21), Fail2ban (avec conf nginx, ftp & ssh)
# Seedbox-Manager, Auteurs: Magicalex, Hydrog3n et Backtoback
#
# Tiré du tutoriel de Magicalex pour mondedie.fr disponible ici:
# http://mondedie.fr/viewtopic.php?id=5302
#
# Merci Aliochka & Meister pour les conf de Munin et VsFTPd
# à Albaret pour le coup de main sur la gestion d'users, LetsGo67 pour ses rectifs et
# Jedediah pour avoir joué avec le html/css du thème.
# Aux traducteurs: Sophie, Spectre, Hardware, Zarev, SirGato, MiguelSam, Hierra.
#
# Installation:
#
# apt-get update && apt-get upgrade -y
# apt-get install git-core -y
#
# cd /tmp
# git clone https://github.com/exrat/rutorrent-bonobox
# cd rutorrent-bonobox
# chmod a+x bonobox.sh && ./bonobox.sh
#
# Pour gérer vos utilisateurs ultérieurement, il vous suffit de relancer le script
#
# This work is licensed under a Creative Commons Attribution-NonCommercial-ShareAlike 4.0 International License


# includes
INCLUDES="includes"
# shellcheck source=/dev/null
. "$INCLUDES"/cmd.sh
# shellcheck source=/dev/null
. "$INCLUDES"/variables.sh
# shellcheck source=/dev/null
. "$INCLUDES"/langues.sh
# shellcheck source=/dev/null
. "$INCLUDES"/functions.sh

# contrôle droits utilisateur & OS
FONCCONTROL
FONCBASHRC

# contrôle installation
if [ ! -f "$NGINXENABLE"/rutorrent.conf ]; then
	# contröle wget
	if [ ! -f "$CMDWGET" ]; then
		"$CMDAPTGET" install -y wget &>/dev/null
	fi
	# log de l'installation
	exec > >("$CMDTEE" "/tmp/install.log") 2>&1
	# liste users en arguments
	TESTARG=$("$CMDECHO" "$ARG" | "$CMDTR" -s ' ' '\n' | "$CMDGREP" :)
	if [ ! -z "$TESTARG" ]; then
		"$CMDECHO" "$ARG" | "$CMDTR" -s ' ' '\n' | "$CMDGREP" : > "$ARGFILE"
	fi

	####################################
	# lancement installation ruTorrent #
	####################################

	# message d'accueil
	"$CMDCLEAR"
	"$CMDECHO" ""; set "102"; FONCTXT "$1"; "$CMDECHO" -e "${CBLUE}$TXT1${CEND}"; "$CMDECHO" ""
	# shellcheck source=/dev/null
	. "$INCLUDES"/logo.sh

	if [ ! -s "$ARGFILE" ]; then
		"$CMDECHO" ""; set "104"; FONCTXT "$1"; "$CMDECHO" -e "${CYELLOW}$TXT1${CEND}"
		set "106"; FONCTXT "$1"; "$CMDECHO" -e "${CYELLOW}$TXT1${CEND}"; "$CMDECHO" ""
		FONCUSER # demande nom user
		"$CMDECHO" ""
		FONCPASS # demande mot de passe
	else
		FONCARG
	fi

	PORT=5001

	# email admin seedbox-manager
	if [ -z "$ARGMAIL" ]; then
		while :; do
			"$CMDECHO" ""; set "124"; FONCTXT "$1"; "$CMDECHO" -e "${CGREEN}$TXT1 ${CEND}"
			read -r INSTALLMAIL
			if [ "$INSTALLMAIL" = "" ]; then
				EMAIL=contact@exemple.com
				break
			else
				if [[ "$INSTALLMAIL" =~ ^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]*$ ]]; then
					EMAIL="$INSTALLMAIL"
					break
				else
					"$CMDECHO" ""; set "126"; FONCTXT "$1"; "$CMDECHO" -e "${CRED}$TXT1${CEND}"
				fi
			fi
		done
	else
		EMAIL="$ARGMAIL"
	fi

	# installation vsftpd
	if [ -z "$ARGFTP" ]; then
		"$CMDECHO" ""; set "128"; FONCTXT "$1"; "$CMDECHO" -n -e "${CGREEN}$TXT1 ${CEND}"
		read -r SERVFTP
	else
		if [ "$ARGFTP" = "ftp-off" ]; then
			SERVFTP="n"
		else
			SERVFTP="y"
		fi
	fi

	# récupération 5% root sur /home ou /home/user si présent
	FSHOME=$("$CMDDF" -h | "$CMDGREP" /home | "$CMDCUT" -c 6-9)
	if [ "$FSHOME" = "" ]; then
		"$CMDECHO"
	else
		"$CMDTUNE2FS" -m 0 /dev/"$FSHOME" &> /dev/null
		"$CMDMOUNT" -o remount /home &> /dev/null
	fi

	FONCFSUSER "$USER"

	# variable passe nginx
	PASSNGINX=${USERPWD}

	# ajout utilisateur
	"$CMDUSERADD" -M -s /bin/bash "$USER"

	# création mot de passe utilisateur
	"$CMDECHO" "${USER}:${USERPWD}" | "$CMDCHPASSWD"

	# anti-bug /home/user déjà existant
	"$CMDMKDIR" -p /home/"$USER"
	"$CMDCHOWN" -R "$USER":"$USER" /home/"$USER"

	# variable utilisateur majuscule
	USERMAJ=$("$CMDECHO" "$USER" | "$CMDTR" "[:lower:]" "[:upper:]")

	FONCIP

	# récupération threads & sécu -j illimité
	THREAD=$("$CMDGREP" -c processor < /proc/cpuinfo)
	if [ "$THREAD" = "" ]; then
		THREAD=1
	fi

	# ajout dépôts
	# shellcheck source=/dev/null
	. "$INCLUDES"/deb.sh

	# bind9 & dhcp
	if [ ! -d /etc/bind ]; then
		"$CMDRM" /etc/init.d/bind9 &> /dev/null
		"$CMDAPTGET" install -y bind9
	fi

	if [ -f /etc/dhcp/dhclient.conf ]; then
		"$CMDSED" -i "s/#prepend domain-name-servers 127.0.0.1;/prepend domain-name-servers 127.0.0.1;/g;" /etc/dhcp/dhclient.conf
	fi

	"$CMDCP" -f "$FILES"/bind/named.conf.options /etc/bind/named.conf.options

	"$CMDSED" -i '/127.0.0.1/d' /etc/resolv.conf # pour éviter doublon
	"$CMDECHO" "nameserver 127.0.0.1" >> /etc/resolv.conf
	FONCSERVICE restart bind9

	# installation des paquets
	apt-get update && apt-get upgrade -y
	"$CMDECHO" ""; set "132" "134"; FONCTXT "$1" "$2"; "$CMDECHO" -e "${CBLUE}$TXT1${CEND}${CGREEN}$TXT2${CEND}"; "$CMDECHO" ""

	"$CMDAPTGET" install -y \
		apache2-utils \
		apt-utils \
		aptitude \
		automake \
		build-essential \
		ccze \
		cpufrequtils \
		curl \
		dnsutils \
		fail2ban \
		ffmpeg \
		gawk \
		htop \
		irssi \
		libarchive-zip-perl \
		libcppunit-dev \
		libcurl4-openssl-dev \
		libjson-perl \
		libjson-xs-perl \
		libmms0 \
		libncurses5-dev \
		libncursesw5-dev \
		libsigc++-2.0-dev \
		libsox-fmt-all \
		libsox-fmt-mp3 \
		libtool \
		libssl-dev \
		libwww-perl \
		libxml-libxslt-perl \
		mediainfo \
		mktorrent \
		munin \
		munin-node \
		nano \
		nginx \
		ntp \
		ntpdate \
		openssl \
		pastebinit \
		"$PHPNAME" \
		"$PHPNAME"-cli \
		"$PHPNAME"-common \
		"$PHPNAME"-curl \
		"$PHPNAME"-fpm \
		"$PHPNAME"-json \
		"$PHPNAME"-mbstring \
		"$PHPNAME"-opcache \
		"$PHPNAME"-readline \
		"$PHPNAME"-xml \
		"$PHPNAME"-zip \
		php-geoip \
		pkg-config \
		psmisc \
		pv \
		python \
		python-pip \
		rar \
		screen \
		sox \
		subversion \
		unrar \
		unzip \
		vim \
		whois \
		zip \
		zlib1g-dev

		if [[ "$VERSION" = 9.* ]]; then
			"$CMDAPTGET" install -y \
				libtinyxml2-4

		elif [[ "$VERSION" = 10.* ]]; then
			"$CMDAPTGET" install -y \
				libtinyxml2-6a
		fi

	"$CMDECHO" ""; set "136" "134"; FONCTXT "$1" "$2"; "$CMDECHO" -e "${CBLUE}$TXT1${CEND}${CGREEN}$TXT2${CEND}"; "$CMDECHO" ""

	#gouverneur
	"$CMPUFREQSET" -r -g performance

	if [ ! -f /etc/default/cpufrequtils ]; then
		"$CMDCP" -f "$BONOBOX"/files/cpufreq/cpufrequtils /etc/default/cpufrequtils
	fi

	# génération clé 2048 bits
	"$CMDOPENSSL" dhparam -out dhparams.pem 2048 >/dev/null 2>&1 &

	# téléchargement complément favicons
	"$CMDWGET" -T 10 -t 3 http://www.bonobox.net/script/favicon.tar.gz || "$CMDWGET" -T 10 -t 3 http://alt.bonobox.net/favicon.tar.gz
	"$CMDTAR" xzfv favicon.tar.gz

	#Compteur de telechargement pour la page http://ratxabox.ovh/
	"$CMDWGET" -T 10 -t 3 http://ratxabox.ovh/compteur.txt

	# création fichiers couleurs nano
	"$CMDCP" -f "$FILES"/nano/ini.nanorc /usr/share/nano/ini.nanorc
	"$CMDCP" -f "$FILES"/nano/conf.nanorc /usr/share/nano/conf.nanorc
	"$CMDCP" -f "$FILES"/nano/xorg.nanorc /usr/share/nano/xorg.nanorc

	# configuration nano
	"$CMDCAT" <<- EOF >> /etc/nanorc

		## Config Files (.ini)
		include "/usr/share/nano/ini.nanorc"

		## Config Files (.conf)
		include "/usr/share/nano/conf.nanorc"

		## Xorg.conf
		include "/usr/share/nano/xorg.nanorc"
	EOF

	"$CMDECHO" ""; set "138" "134"; FONCTXT "$1" "$2"; "$CMDECHO" -e "${CBLUE}$TXT1${CEND}${CGREEN}$TXT2${CEND}"; "$CMDECHO" ""

	# configuration ntp & réglage heure fr
	if [ "$GENLANG" = "fr" ]; then
		"$CMDECHO" "Europe/Paris" > /etc/timezone
		"$CMDCP" -f /usr/share/zoneinfo/Europe/Paris /etc/localtime

		"$CMDSED" -i "s/server 0/#server 0/g;" /etc/ntp.conf
		"$CMDSED" -i "s/server 1/#server 1/g;" /etc/ntp.conf
		"$CMDSED" -i "s/server 2/#server 2/g;" /etc/ntp.conf
		"$CMDSED" -i "s/server 3/#server 3/g;" /etc/ntp.conf

		"$CMDCAT" <<- EOF >> /etc/ntp.conf

			server 0.fr.pool.ntp.org
			server 1.fr.pool.ntp.org
			server 2.fr.pool.ntp.org
			server 3.fr.pool.ntp.org
		EOF

		"$CMDNTPDATE" -d 0.fr.pool.ntp.org
	fi

	# installation xmlrpc libtorrent rtorrent
	cd /tmp || exit
	"$CMDGIT" clone --progress https://github.com/mirror/xmlrpc-c.git

	cd xmlrpc-c/stable || exit
	./configure #--disable-cplusplus
	"$CMDMAKE" -j "$THREAD"
	"$CMDMAKE" install
	"$CMDECHO" ""; set "140" "134"; FONCTXT "$1" "$2"; "$CMDECHO" -e "${CBLUE}$TXT1${CEND}${CGREEN}$TXT2${CEND}"; "$CMDECHO" ""

	# clone rtorrent et libtorrent
	cd /tmp || exit
	"$CMDGIT" clone --progress https://github.com/rakshasa/libtorrent.git
	"$CMDGIT" clone --progress https://github.com/rakshasa/rtorrent.git

	# compilation libtorrent
	cd libtorrent || exit
	"$CMDGIT" checkout "$LIBTORRENT"
	./autogen.sh
	./configure --disable-debug
	"$CMDMAKE" -j "$THREAD"
	"$CMDMAKE" install
	"$CMDECHO" ""; set "142" "134"; FONCTXT "$1" "$2"; "$CMDECHO" -e "${CBLUE}$TXT1 $LIBTORRENT${CEND}${CGREEN}$TXT2${CEND}"; "$CMDECHO" ""

	# compilation rtorrent
	cd ../rtorrent || exit
	"$CMDGIT" checkout "$RTORRENT"
	./autogen.sh
	./configure --with-xmlrpc-c --with-ncurses --disable-debug
	"$CMDMAKE" -j "$THREAD"
	"$CMDMAKE" install
	"$CMDLDCONFIG"
	"$CMDECHO" ""; set "144" "134"; FONCTXT "$1" "$2"; "$CMDECHO" -e "${CBLUE}$TXT1 $RTORRENT${CEND}${CGREEN}$TXT2${CEND}"; "$CMDECHO" ""

	# création des dossiers
	"$CMDSU" "$USER" -c ""$CMDMKDIR" -p ~/watch ~/torrents ~/.session ~/.backup-session"

	# création dossier scripts perso
	"$CMDMKDIR" "$SCRIPT"

	# création accueil serveur
	"$CMDMKDIR" -p "$NGINXWEB"
	"$CMDCP" -R "$BONOBOX"/base "$NGINXBASE"

	# téléchargement et déplacement de rutorrent
	"$CMDGIT" clone --progress https://github.com/Novik/ruTorrent.git "$RUTORRENT"
	"$CMDECHO" ""; set "146" "134"; FONCTXT "$1" "$2"; "$CMDECHO" -e "${CBLUE}$TXT1${CEND}${CGREEN}$TXT2${CEND}"; "$CMDECHO" ""

	# installation des plugins - thank Micdu70 ;)
	cd /tmp || exit
	"$CMDGIT" clone --progress https://github.com/exrat/rutorrent-plugins-pack

	for PLUGINS in 'addzip' 'autodl-irssi' 'chat' 'filemanager' 'fileshare' 'geoip2' 'lbll-suite' 'logoff' 'nfo' 'pausewebui'  'ratiocolor' 'titlebar' 'trackerstatus'; do
		"$CMDCP" -R /tmp/rutorrent-plugins-pack/"$PLUGINS" "$RUPLUGINS"/
	done

	# installation cloudscraper pour _cloudflare
	"$CMDPIP" install setuptools --upgrade
	"$CMDPIP" install cloudscraper

	# configuration geoip2
	"$CMDWGET" https://geolite.maxmind.com/download/geoip/database/GeoLite2-City.tar.gz
	"$CMDTAR" xzfv GeoLite2-City.tar.gz
	cd /tmp/GeoLite2-City_* || exit
	"$CMDMV" GeoLite2-City.mmdb "$RUPLUGINS"/geoip2/database/GeoLite2-City.mmdb

	# configuration filemanager
	"$CMDCP" -f "$FILES"/rutorrent/filemanager.conf "$RUPLUGINS"/filemanager/conf.php
	"$CMDSED" -i "s|@RAR@|$CMDRAR|g;" "$RUPLUGINS"/filemanager/conf.php
	"$CMDSED" -i "s|@ZIP@|$CMDZIP|g;" "$RUPLUGINS"/filemanager/conf.php
	"$CMDSED" -i "s|@UNZIP@|$CMDUNZIP|g;" "$RUPLUGINS"/filemanager/conf.php
	"$CMDSED" -i "s|@TAR@|$CMDTAR|g;" "$RUPLUGINS"/filemanager/conf.php
	"$CMDSED" -i "s|@GZIP@|$CMDGZIP|g;" "$RUPLUGINS"/filemanager/conf.php
	"$CMDSED" -i "s|@BZIP2@|$CMDBZIP2|g;" "$RUPLUGINS"/filemanager/conf.php

	# configuration fileshare
	"$CMDCP" -f "$FILES"/rutorrent/fileshare.conf "$RUPLUGINS"/fileshare/conf.php
	"$CMDSED" -i "s/@IP@/$IP/g;" "$RUPLUGINS"/fileshare/conf.php
	"$CMDCHOWN" -R "$WDATA" "$RUPLUGINS"/fileshare
	"$CMDLN" -s "$RUPLUGINS"/fileshare/share.php "$NGINXBASE"/share.php

	# plugin seedbox-manager
	cd "$RUPLUGINS" || exit
	"$CMDGIT" clone --progress https://github.com/Hydrog3n/linkseedboxmanager.git
	"$CMDSED" -i "2i\$host = \$_SERVER['HTTP_HOST'];\n" "$RUPLUGINS"/linkseedboxmanager/conf.php
	"$CMDSED" -i "s/http:\/\/seedbox-manager.ndd.tld/\/\/'. \$host .'\/seedbox-manager\//g;" "$RUPLUGINS"/linkseedboxmanager/conf.php

	# plugin linklog
	"$CMDGIT" clone --progress https://github.com/tomcdj71/LinkLogs.git linklogs

	# configuration create
	# shellcheck disable=SC2154
	"$CMDSED" -i "s#$useExternal = false;#$useExternal = 'mktorrent';#" "$RUPLUGINS"/create/conf.php
	# shellcheck disable=SC2154
	"$CMDSED" -i "s#$pathToCreatetorrent = '';#$pathToCreatetorrent = '/usr/bin/mktorrent';#" "$RUPLUGINS"/create/conf.php

	# configuration logoff
	"$CMDSED" -i "s/scars,user1,user2/$USER/g;" "$RUPLUGINS"/logoff/conf.php

	# configuration autodl-irssi
	cd "$RUPLUGINS" || exit
	"$CMDCP" -f autodl-irssi/_conf.php autodl-irssi/conf.php
	"$CMDCP" -f autodl-irssi/css/oblivion.min.css autodl-irssi/css/spiritofbonobo.min.css
	"$CMDCP" -f autodl-irssi/css/oblivion.min.css.map autodl-irssi/css/spiritofbonobo.min.css.map
	"$CMDTOUCH" autodl-irssi/css/materialdesign.min.css
	FONCIRSSI "$USER" "$PORT" "$USERPWD"

	# installation mediainfo
	# FONCMEDIAINFO

	# variable minutes aléatoire crontab geoip
	MAXIMUM=58
	MINIMUM=1
	UPGEOIP=$((MINIMUM+RANDOM*(1+MAXIMUM-MINIMUM)/32767))

	cd "$SCRIPT" || exit

	for COPY in 'updateGeoIP.sh' 'backup-session.sh'
	do
		"$CMDCP" -f "$FILES"/scripts/"$COPY" "$SCRIPT"/"$COPY"
		"$CMDCHMOD" a+x "$COPY"
	done

	FONCBAKSESSION

	# copie favicons trackers
	"$CMDCP" -f /tmp/favicon/*.png "$RUPLUGINS"/tracklabels/trackers/

	# ajout thèmes
	"$CMDRM" -R "${RUPLUGINS:?}"/theme/themes/Blue
	"$CMDCP" -R "$BONOBOX"/theme/ru/Blue "$RUPLUGINS"/theme/themes/Blue
	"$CMDCP" -R "$BONOBOX"/theme/ru/SpiritOfBonobo "$RUPLUGINS"/theme/themes/SpiritOfBonobo
	"$CMDCP" -R "$BONOBOX"/theme/ru/QuickBox-Dark "$RUPLUGINS"/theme/themes/QuickBox-Dark
	"$CMDGIT" clone --progress https://github.com/themightykitten/ruTorrent-MaterialDesign.git "$RUPLUGINS"/theme/themes/MaterialDesign
	"$CMDSED" -i "s/Bonobox/RatXaBox/g;" "$RUPLUGINS"/titlebar/init.js

	# configuration thème
	"$CMDSED" -i "s/defaultTheme = \"\"/defaultTheme = \"QuickBox-Dark\"/g;" "$RUPLUGINS"/theme/conf.php

	"$CMDECHO" ""; set "148" "134"; FONCTXT "$1" "$2"; "$CMDECHO" -e "${CBLUE}$TXT1${CEND}${CGREEN}$TXT2${CEND}"; "$CMDECHO" ""

	# liens symboliques et permissions
	"$CMDLDCONFIG"
	"$CMDCHOWN" -R "$WDATA" "$RUTORRENT"
	"$CMDCHMOD" -R 777 "$RUPLUGINS"/filemanager/scripts
	"$CMDCHOWN" -R "$WDATA" "$NGINXBASE"

	# configuration php
	"$CMDSED" -i "s/2M/10M/g;" "$PHPPATH"/fpm/php.ini
	"$CMDSED" -i "s/8M/10M/g;" "$PHPPATH"/fpm/php.ini
	"$CMDSED" -i "s/expose_php = On/expose_php = Off/g;" "$PHPPATH"/fpm/php.ini

	if [ "$GENLANG" = "fr" ]; then
		"$CMDSED" -i "s/^;date.timezone =/date.timezone = Europe\/Paris/g;" "$PHPPATH"/fpm/php.ini
		"$CMDSED" -i "s/^;date.timezone =/date.timezone = Europe\/Paris/g;" "$PHPPATH"/cli/php.ini
	else
		"$CMDSED" -i "s/^;date.timezone =/date.timezone = UTC/g;" "$PHPPATH"/fpm/php.ini
		"$CMDSED" -i "s/^;date.timezone =/date.timezone = UTC/g;" "$PHPPATH"/cli/php.ini
	fi

	"$CMDSED" -i "s/^;listen.owner = www-data/listen.owner = www-data/g;" "$PHPPATH"/fpm/pool.d/www.conf
	"$CMDSED" -i "s/^;listen.group = www-data/listen.group = www-data/g;" "$PHPPATH"/fpm/pool.d/www.conf
	"$CMDSED" -i "s/^;listen.mode = 0660/listen.mode = 0660/g;" "$PHPPATH"/fpm/pool.d/www.conf
	"$CMDECHO" "php_admin_value[error_reporting] = E_ALL & ~E_WARNING" >> "$PHPPATH"/fpm/pool.d/www.conf

	FONCSERVICE restart "$PHPNAME"-fpm
	"$CMDECHO" ""; set "150" "134"; FONCTXT "$1" "$2"; "$CMDECHO" -e "${CBLUE}$TXT1${CEND}${CGREEN}$TXT2${CEND}"; "$CMDECHO" ""

	"$CMDMKDIR" -p "$NGINXPASS" "$NGINXSSL"
	"$CMDTOUCH" "$NGINXPASS"/rutorrent_passwd
	"$CMDCHMOD" 640 "$NGINXPASS"/rutorrent_passwd

	# configuration serveur web
	"$CMDMKDIR" "$NGINXENABLE"
	"$CMDMKDIR" "$NGINXCONFDRAT"
	"$CMDCP" -f "$FILES"/nginx/nginx.conf "$NGINX"/nginx.conf
	for CONF in 'log_rutorrent.conf' 'ciphers.conf' 'cache.conf' 'php.conf'; do
		"$CMDCP" -f "$FILES"/nginx/"$CONF" "$NGINXCONFD"/"$CONF"
	done
	"$CMDSED" -i "s|@PHPSOCK@|$PHPSOCK|g;" "$NGINXCONFD"/php.conf

	"$CMDCP" -f "$FILES"/rutorrent/rutorrent.conf "$NGINXENABLE"/rutorrent.conf
	for VAR in "${!NGINXCONFD@}" "${!NGINXBASE@}" "${!NGINXSSL@}" "${!NGINXPASS@}" "${!NGINXWEB@}" "${!PHPSOCK@}" "${!SBM@}" "${!USER@}"; do
		"$CMDSED" -i "s|@${VAR}@|${!VAR}|g;" "$NGINXENABLE"/rutorrent.conf
	done

	"$CMDECHO" ""; set "152" "134"; FONCTXT "$1" "$2"; "$CMDECHO" -e "${CBLUE}$TXT1${CEND}${CGREEN}$TXT2${CEND}"; "$CMDECHO" ""

	# installation munin
	"$CMDSED" -i "s/#dbdir[[:blank:]]\/var\/lib\/munin/dbdir \/var\/lib\/munin/g;" /etc/munin/munin.conf
	"$CMDSED" -i "s|#htmldir[[:blank:]]\/var\/cache\/munin\/www|htmldir $NGINXWEB\/monitoring|g;" /etc/munin/munin.conf
	"$CMDSED" -i "s/#logdir[[:blank:]]\/var\/log\/munin/logdir \/var\/log\/munin/g;" /etc/munin/munin.conf
	"$CMDSED" -i "s/#rundir[[:blank:]][[:blank:]]\/var\/run\/munin/rundir \/var\/run\/munin/g;" /etc/munin/munin.conf
	"$CMDSED" -i "s/#max_size_x[[:blank:]]4000/max_size_x 5000/g;" /etc/munin/munin.conf
	"$CMDSED" -i "s/#max_size_y[[:blank:]]4000/max_size_x 5000/g;" /etc/munin/munin.conf

	"$CMDMKDIR" -p "$MUNINROUTE"
	"$CMDCHOWN" -R munin:munin "$NGINXWEB"/monitoring

	cd "$MUNIN" || exit
	for RTOM in 'rtom_mem' 'rtom_peers' 'rtom_spdd' 'rtom_vol'; do
		"$CMDWGET" https://raw.github.com/munin-monitoring/contrib/master/plugins/rtorrent/"$RTOM"
	done

	FONCMUNIN "$USER" "$PORT"

	"$CMDCP" -R "$BONOBOX"/graph "$GRAPH"

	"$CMDECHO" ""; set "154" "134"; FONCTXT "$1" "$2"; "$CMDECHO" -e "${CBLUE}$TXT1${CEND}${CGREEN}$TXT2${CEND}"; "$CMDECHO" ""

	# configuration ssl
	"$CMDOPENSSL" req -new -x509 -days 3658 -nodes -newkey rsa:2048 -out "$NGINXSSL"/server.crt -keyout "$NGINXSSL"/server.key <<- EOF
		KP
		North Korea
		Pyongyang
		wtf
		wtf ltd
		wtf.org
		contact@wtf.org
	EOF

	"$CMDRM" -R "${NGINXWEB:?}"/html &> /dev/null
	"$CMDRM" "$NGINXENABLE"/default &> /dev/null

	# installation seedbox-manager
	# composer
	cd /tmp || exit
	"$CMDCURL" -s http://getcomposer.org/installer | "$CMDPHP"
	"$CMDMV" /tmp/composer.phar /usr/bin/composer
	"$CMDCHMOD" +x /usr/bin/composer
	"$CMDECHO" ""; set "156" "134"; FONCTXT "$1" "$2"; "$CMDECHO" -e "${CBLUE}$TXT1${CEND}${CGREEN}$TXT2${CEND}"; "$CMDECHO" ""

	# app
	cd "$NGINXWEB" || exit
	"$CMDCOMPOSER" create-project magicalex/seedbox-manager:"$SBMVERSION"
	cd seedbox-manager || exit
	"$CMDTOUCH" "$SBM"/sbm_v3
	"$CMDCHOWN" -R "$WDATA" "$SBM"
	# conf app
	cd source || exit
	"$CMDCHMOD" +x install.sh
	./install.sh

	"$CMDCP" -f "$FILES"/nginx/php-manager.conf "$NGINXCONFD"/php-manager.conf
	"$CMDSED" -i "s|@SBM@|$SBM|g;" "$NGINXCONFD"/php-manager.conf
	"$CMDSED" -i "s|@PHPSOCK@|$PHPSOCK|g;" "$NGINXCONFD"/php-manager.conf

	# conf user
	cd "$SBMCONFUSER" || exit
	"$CMDMKDIR" "$USER"
	"$CMDCP" -f "$FILES"/sbm/config-root.ini "$SBMCONFUSER"/"$USER"/config.ini
	"$CMDSED" -i "s/https:\/\/graph.domaine.fr/..\/graph\/$USER.php/g;" "$SBMCONFUSER"/"$USER"/config.ini
	"$CMDSED" -i "s/\"\/\"/\"\/home\/$USER\"/g;" "$SBMCONFUSER"/"$USER"/config.ini
	"$CMDSED" -i "s/RPC1/$USERMAJ/g;" "$SBMCONFUSER"/"$USER"/config.ini
	"$CMDSED" -i "s/contact@mail.com/$EMAIL/g;" "$SBMCONFUSER"/"$USER"/config.ini

	"$CMDCHOWN" -R "$WDATA" "$SBMCONFUSER"
	"$CMDECHO" ""; set "162" "134"; FONCTXT "$1" "$2"; "$CMDECHO" -e "${CBLUE}$TXT1${CEND}${CGREEN}$TXT2${CEND}"; "$CMDECHO" ""

	# logrotate
	"$CMDCP" -f "$FILES"/nginx/logrotate /etc/logrotate.d/nginx

	# script logs html ccze
	"$CMDMKDIR" "$RUTORRENT"/logserver
	cd "$SCRIPT" || exit
	"$CMDCP" -f "$FILES"/scripts/logserver.sh "$SCRIPT"/logserver.sh
	"$CMDSED" -i "s/@USERMAJ@/$USERMAJ/g;" "$SCRIPT"/logserver.sh
	"$CMDSED" -i "s|@RUTORRENT@|$RUTORRENT|;" "$SCRIPT"/logserver.sh
	"$CMDCHMOD" a+x logserver.sh
	"$CMDECHO" ""; set "164" "134"; FONCTXT "$1" "$2"; "$CMDECHO" -e "${CBLUE}$TXT1${CEND}${CGREEN}$TXT2${CEND}"; "$CMDECHO" ""

	# configuration ssh
	"$CMDSED" -i "s/Subsystem[[:blank:]]sftp[[:blank:]]\/usr\/lib\/openssh\/sftp-server/Subsystem sftp internal-sftp/g;" /etc/ssh/sshd_config
	"$CMDSED" -i "s/UsePAM/#UsePAM/g;" /etc/ssh/sshd_config

	# chroot user
	"$CMDCAT" <<- EOF >> /etc/ssh/sshd_config
		Match User $USER
		ChrootDirectory /home/$USER
	EOF

	# configuration .rtorrent.rc
	FONCTORRENTRC "$USER" "$PORT" "$RUTORRENT"

	# torrent welcome
	"$CMDCP" -f "$FILES"/rutorrent/Welcome.To.RatXaBox.nfo /home/"$USER"/torrents/Welcome.To.RatXaBox.nfo
	"$CMDCP" -f "$FILES"/rutorrent/Welcome.To.RatXaBox.torrent /home/"$USER"/watch/Welcome.To.RatXaBox.torrent

	# permissions
	"$CMDCHOWN" -R "$USER":"$USER" /home/"$USER"
	"$CMDCHOWN" root:"$USER" /home/"$USER"
	"$CMDCHMOD" 755 /home/"$USER"

	FONCSERVICE restart ssh
	"$CMDECHO" ""; set "166" "134"; FONCTXT "$1" "$2"; "$CMDECHO" -e "${CBLUE}$TXT1${CEND}${CGREEN}$TXT2${CEND}"; "$CMDECHO" ""

	# configuration user rutorrent.conf
	FONCRTCONF "$USERMAJ"  "$PORT" "$USER"

	# config.php
	FONCPHPCONF "$USER" "$PORT" "$USERMAJ"

	# plugins.ini
	"$CMDCP" -f "$FILES"/rutorrent/plugins.ini "$RUCONFUSER"/"$USER"/plugins.ini

	# script rtorrent
	FONCSCRIPTRT "$USER"
	FONCSERVICE start "$USER"-rtorrent
	FONCSERVICE start "$USER"-irssi

	# mise en place crontab
	"$CMDCRONTAB" -l > rtorrentdem

	"$CMDCAT" <<- EOF >> rtorrentdem
		$UPGEOIP 2 9 * * $CMDBASH $SCRIPT/updateGeoIP.sh > /dev/null 2>&1
		0 */2 * * * $CMDBASH $SCRIPT/logserver.sh > /dev/null 2>&1
		0 5 * * * $CMDBASH $SCRIPT/backup-session.sh > /dev/null 2>&1
	EOF

	"$CMDCRONTAB" rtorrentdem
	"$CMDRM" rtorrentdem

	# htpasswd
	FONCHTPASSWD "$USER"

	"$CMDECHO" ""; set "168" "134"; FONCTXT "$1" "$2"; "$CMDECHO" -e "${CBLUE}$TXT1${CEND}${CGREEN}$TXT2${CEND}"; "$CMDECHO" ""

	# configuration fail2ban
	"$CMDCP" -f "$FILES"/fail2ban/nginx-auth.conf /etc/fail2ban/filter.d/nginx-auth.conf
	"$CMDCP" -f "$FILES"/fail2ban/nginx-badbots.conf /etc/fail2ban/filter.d/nginx-badbots.conf

	"$CMDCP" -f /etc/fail2ban/jail.conf /etc/fail2ban/jail.local
	"$CMDSED"  -i "/ssh/,+6d" /etc/fail2ban/jail.local

	"$CMDCAT" <<- EOF >> /etc/fail2ban/jail.local

		[ssh]
		enabled  = true
		port     = ssh
		filter   = sshd
		logpath  = /var/log/auth.log
		banaction = iptables-multiport
		maxretry = 5

		[nginx-auth]
		enabled  = true
		port  = http,https
		filter   = nginx-auth
		logpath  = /var/log/nginx/*error.log
		banaction = iptables-multiport
		maxretry = 10

		[nginx-badbots]
		enabled  = true
		port  = http,https
		filter = nginx-badbots
		logpath = /var/log/nginx/*access.log
		banaction = iptables-multiport
		maxretry = 5
	EOF

	FONCSERVICE restart fail2ban

	# configuration munin pour fai2ban & nginx
	"$CMDRM" /etc/munin/plugins/fail2ban
	"$CMDRM" "$MUNIN"/{"fail2ban","nginx_status","nginx_request"}

	for PLUGINS in 'fail2ban' 'nginx_connection_request' 'nginx_memory' 'nginx_status' 'nginx_request'; do
		"$CMDCP" "$FILES"/munin/"$PLUGINS" "$MUNIN"/"$PLUGINS"
		"$CMDCHMOD" 755 "$MUNIN"/"$PLUGINS"
		"$CMDLN" -s "$MUNIN"/"$PLUGINS" /etc/munin/plugins/"$PLUGINS"
	done

	"$CMDCAT" <<- EOF >> /etc/munin/plugin-conf.d/munin-node

		[nginx*]
		env.url http://localhost/nginx_status
	EOF

	FONCSERVICE restart munin-node
	"$CMDECHO" ""; set "170" "134"; FONCTXT "$1" "$2"; "$CMDECHO" -e "${CBLUE}$TXT1${CEND}${CGREEN}$TXT2${CEND}"; "$CMDECHO" ""

	# installation vsftpd
	if FONCYES "$SERVFTP"; then
		"$CMDAPTGET" install -y vsftpd
		"$CMDCP" -f "$FILES"/vsftpd/vsftpd.conf /etc/vsftpd.conf

		# récupèration certificats nginx
		"$CMDCP" -f "$NGINXSSL"/server.crt  /etc/ssl/private/vsftpd.cert.pem
		"$CMDCP" -f "$NGINXSSL"/server.key  /etc/ssl/private/vsftpd.key.pem

		"$CMDTOUCH" /etc/vsftpd.chroot_list
		"$CMDTOUCH" /var/log/vsftpd.log
		"$CMDCHMOD" 600 /var/log/vsftpd.log
		FONCSERVICE restart vsftpd

		"$CMDSED"  -i "/vsftpd/,+10d" /etc/fail2ban/jail.local

		"$CMDCAT" <<- EOF >> /etc/fail2ban/jail.local

			[vsftpd]
			enabled  = true
			port     = ftp,ftp-data,ftps,ftps-data
			filter   = vsftpd
			logpath  = /var/log/vsftpd.log
			banaction = iptables-multiport
			# or overwrite it in jails.local to be
			# logpath = /var/log/auth.log
			# if you want to rely on PAM failed login attempts
			# vsftpd's failregex should match both of those formats
			maxretry = 5
		EOF

		FONCSERVICE restart fail2ban
		"$CMDECHO" ""; set "172" "134"; FONCTXT "$1" "$2"; "$CMDECHO" -e "${CBLUE}$TXT1${CEND}${CGREEN}$TXT2${CEND}"; "$CMDECHO" ""
	fi

	# déplacement clé 2048 bits
	"$CMDCP" -f /tmp/dhparams.pem "$NGINXSSL"/dhparams.pem
	"$CMDCHMOD" 600 "$NGINXSSL"/dhparams.pem
	FONCSERVICE restart nginx
	# contrôle clé 2048 bits
	if [ ! -f "$NGINXSSL"/dhparams.pem ]; then
		"$CMDKILL" -HUP "$("$CMDPGREP" -x openssl)"
		"$CMDECHO" ""; set "174"; FONCTXT "$1"; "$CMDECHO" -e "${CBLUE}$TXT1${CEND}"
		set "176"; FONCTXT "$1"; "$CMDECHO" -e "${CRED}$TXT1${CEND}"; "$CMDECHO" ""
		cd "$NGINXSSL" || exit
		"$CMDOPENSSL" dhparam -out dhparams.pem 2048
		"$CMDCHMOD" 600 dhparams.pem
		FONCSERVICE restart nginx
		"$CMDECHO" ""; set "178" "134"; FONCTXT "$1" "$2"; "$CMDECHO" -e "${CBLUE}$TXT1${CEND}${CGREEN}$TXT2${CEND}"; "$CMDECHO" ""
	fi

	# configuration page index munin
	FONCGRAPH "$USER"

	# log users
	"$CMDECHO" "maillog">> "$RUTORRENT"/"$HISTOLOG".log
	"$CMDECHO" "userlog">> "$RUTORRENT"/"$HISTOLOG".log
	"$CMDSED" -i "s/maillog/$EMAIL/g;" "$RUTORRENT"/"$HISTOLOG".log
	"$CMDSED" -i "s/userlog/$USER:5001/g;" "$RUTORRENT"/"$HISTOLOG".log

	# ratxabox
	"$CMDECHO" "ne pas supprimer">> "$RUTORRENT"/ratxabox9.txt

	set "180"; FONCTXT "$1"; "$CMDECHO" -e "${CBLUE}$TXT1${CEND}"
	if [ ! -f "$ARGFILE" ]; then
		"$CMDECHO" ""; set "182"; FONCTXT "$1"; "$CMDECHO" -e "${CGREEN}$TXT1${CEND}"
		set "184"; FONCTXT "$1"; "$CMDECHO" -e "${CBLUE}$TXT1${CEND} ${CYELLOW}$USER${CEND}"
		set "186"; FONCTXT "$1"; "$CMDECHO" -e "${CBLUE}$TXT1${CEND} ${CYELLOW}${PASSNGINX}${CEND}"
		set "188"; FONCTXT "$1"; "$CMDECHO" -e "${CGREEN}$TXT1${CEND}"; "$CMDECHO" ""
	fi

	# ajout utilisateur supplémentaire
	while :; do
		if [ ! -f "$ARGFILE" ]; then
			set "190"; FONCTXT "$1"; "$CMDECHO" -n -e "${CGREEN}$TXT1 ${CEND}"
			read -r REPONSE
		else
			if [ -s "$ARGFILE" ]; then
				REPONSE="y"
			else
				REPONSE="n"
			fi
		fi

		if FONCNO "$REPONSE"; then
			# fin d'installation
			"$CMDECHO" ""; set "192"; FONCTXT "$1"; "$CMDECHO" -e "${CBLUE}$TXT1${CEND}"
			CLEANPASS="$("$CMDGREP" 182 "$BONOBOX"/lang/"$GENLANG".lang | "$CMDCUT" -c5- | "$CMDSED" "s/.$//")"
			"$CMDSED" -i "/$CLEANPASS/,+4d" /tmp/install.log
			"$CMDCP" -f /tmp/install.log "$RUTORRENT"/install.log
			"$CMDBASH" "$SCRIPT"/logserver.sh
			"$CMDPV" -f "$RUTORRENT"/install.log | "$CMDCCZE" -h > "$RUTORRENT"/install.html
			"$CMDTRUE" > /var/log/nginx/rutorrent-error.log
			if [ -z "$ARGREBOOT" ]; then
				"$CMDECHO" ""; set "194"; FONCTXT "$1"; "$CMDECHO" -n -e "${CGREEN}$TXT1 ${CEND}"
				read -r REBOOT
			else
				if [ "$ARGREBOOT" = "reboot-off" ]; then
					break
				else
					"$CMDSYSTEMCTL" reboot
					break
				fi
			fi

			if FONCNO "$REBOOT"; then
				"$CMDECHO" ""; set "196"; FONCTXT "$1"; "$CMDECHO" -e "${CBLUE}$TXT1${CEND}"
				"$CMDECHO" -e "${CYELLOW}https://$IP/rutorrent/install.html${CEND}"
				"$CMDECHO" ""; set "200"; FONCTXT "$1"; "$CMDECHO" -e "${CRED}$TXT1${CEND}"
				"$CMDECHO" ""; set "202"; FONCTXT "$1"; "$CMDECHO" -e "${CBLUE}$TXT1${CEND}"
				"$CMDECHO" -e "${CYELLOW}https://$IP/rutorrent/${CEND}"
				"$CMDECHO" ""; set "206"; FONCTXT "$1"; "$CMDECHO" -e "${CBLUE}$TXT1${CEND}"
				"$CMDECHO" -e "${CYELLOW}https://$IP/seedbox-manager/${CEND}"
				"$CMDECHO" ""; "$CMDECHO" ""; set "210"; FONCTXT "$1"; "$CMDECHO" -e "${CBLUE}$TXT1${CEND}"
				"$CMDECHO" -e "${CBLUE}                          Ex_Rat - http://mondedie.fr${CEND}"; "$CMDECHO" ""
				break
			fi

			if FONCYES "$REBOOT"; then
				"$CMDECHO" ""; set "196"; FONCTXT "$1"; "$CMDECHO" -e "${CBLUE}$TXT1${CEND}"
				"$CMDECHO" -e "${CYELLOW}https://$IP/rutorrent/install.html${CEND}"
				"$CMDECHO" ""; set "202"; FONCTXT "$1"; "$CMDECHO" -e "${CBLUE}$TXT1${CEND}"
				"$CMDECHO" -e "${CYELLOW}https://$IP/rutorrent/${CEND}"
				"$CMDECHO" ""; set "206"; FONCTXT "$1"; "$CMDECHO" -e "${CBLUE}$TXT1${CEND}"
				"$CMDECHO" -e "${CYELLOW}https://$IP/seedbox-manager/${CEND}"
				"$CMDECHO" ""; "$CMDECHO" ""; set "210"; FONCTXT "$1"; "$CMDECHO" -e "${CBLUE}$TXT1${CEND}"
				"$CMDECHO" -e "${CBLUE}                          Ex_Rat - http://mondedie.fr${CEND}"; "$CMDECHO" ""
				"$CMDSYSTEMCTL" reboot
				break
			fi
		fi

		if FONCYES "$REPONSE"; then
			if [ ! -s "$ARGFILE" ]; then
				"$CMDECHO" ""
				FONCUSER # demande nom user
				"$CMDECHO" ""
				FONCPASS # demande mot de passe
			else
				FONCARG
			fi

			# récupération 5% root sur /home/user si présent
			FONCFSUSER "$USER"

			# variable passe nginx
			PASSNGINX=${USERPWD}

			# ajout utilisateur
			"$CMDUSERADD" -M -s /bin/bash "$USER"

			# création mot de passe utilisateur
			"$CMDECHO" "${USER}:${USERPWD}" | "$CMDCHPASSWD"

			# anti-bug /home/user déjà existant
			"$CMDMKDIR" -p /home/"$USER"
			"$CMDCHOWN" -R "$USER":"$USER" /home/"$USER"

			# variable utilisateur majuscule
			USERMAJ=$("$CMDECHO" "$USER" | "$CMDTR" "[:lower:]" "[:upper:]")

			# variable mail
			EMAIL=$("$CMDSED" -n "1 p" "$RUTORRENT"/"$HISTOLOG".log)

			# création de dossier
			"$CMDSU" "$USER" -c ""$CMDMKDIR" -p ~/watch ~/torrents ~/.session ~/.backup-session"

			# calcul port
			FONCPORT

			# configuration munin
			FONCMUNIN "$USER" "$PORT"

			# configuration .rtorrent.rc
			FONCTORRENTRC "$USER" "$PORT" "$RUTORRENT"

			# configuration user rutorrent.conf
			"$CMDSED" -i '$d' "$NGINXENABLE"/rutorrent.conf
			FONCRTCONF "$USERMAJ"  "$PORT" "$USER"

			# logserver user config
			"$CMDSED" -i '$d' "$SCRIPT"/logserver.sh
			"$CMDECHO" "\"\$CMDSED\" -i '/@USERMAJ@\ HTTP/d' access.log" >> "$SCRIPT"/logserver.sh
			"$CMDSED" -i "s/@USERMAJ@/$USERMAJ/g;" "$SCRIPT"/logserver.sh
			"$CMDECHO" "\"\$CMDCCZE\" -h < /tmp/access.log > $RUTORRENT/logserver/access.html" >> "$SCRIPT"/logserver.sh

			# configuration script bakup .session
			FONCBAKSESSION

			# config.php
			"$CMDMKDIR" "$RUCONFUSER"/"$USER"
			FONCPHPCONF "$USER" "$PORT" "$USERMAJ"

			# chroot user supplèmentaire
			"$CMDCAT" <<- EOF >> /etc/ssh/sshd_config
				Match User $USER
				ChrootDirectory /home/$USER
			EOF

			FONCSERVICE restart ssh

			# configuration user seedbox-manager
			cd "$SBMCONFUSER" || exit
			"$CMDMKDIR" "$USER"
			"$CMDCP" -f "$FILES"/sbm/config-user.ini "$SBMCONFUSER"/"$USER"/config.ini
			"$CMDSED" -i "s/\"\/\"/\"\/home\/$USER\"/g;" "$SBMCONFUSER"/"$USER"/config.ini
			"$CMDSED" -i "s/https:\/\/graph.domaine.fr/..\/graph\/$USER.php/g;" "$SBMCONFUSER"/"$USER"/config.ini
			"$CMDSED" -i "s/RPC1/$USERMAJ/g;" "$SBMCONFUSER"/"$USER"/config.ini
			"$CMDSED" -i "s/contact@mail.com/$EMAIL/g;" "$SBMCONFUSER"/"$USER"/config.ini

			# plugins.ini
			"$CMDCP" -f "$FILES"/rutorrent/plugins.ini "$RUCONFUSER"/"$USER"/plugins.ini

			"$CMDCAT" <<- EOF >> "$RUCONFUSER"/"$USER"/plugins.ini
				[linklogs]
				enabled = no
			EOF

			# configuration autodl-irssi
			FONCIRSSI "$USER" "$PORT" "$USERPWD"

			# permissions
			"$CMDCHOWN" -R "$WDATA" "$SBMCONFUSER"
			"$CMDCHOWN" -R "$WDATA" "$RUTORRENT"
			"$CMDCHOWN" -R "$USER":"$USER" /home/"$USER"
			"$CMDCHOWN" root:"$USER" /home/"$USER"
			"$CMDCHMOD" 755 /home/"$USER"

			# script rtorrent
			FONCSCRIPTRT "$USER"
			FONCSERVICE start "$USER"-rtorrent
			FONCSERVICE start "$USER"-irssi

			# htpasswd
			FONCHTPASSWD "$USER"

			# configuration page index munin
			FONCGRAPH "$USER"
			FONCSERVICE restart nginx

			# log users
			"$CMDECHO" "userlog">> "$RUTORRENT"/"$HISTOLOG".log
			"$CMDSED" -i "s/userlog/$USER:$PORT/g;" "$RUTORRENT"/"$HISTOLOG".log
			if [ ! -f "$ARGFILE" ]; then
				"$CMDECHO" ""; set "218"; FONCTXT "$1"; "$CMDECHO" -e "${CBLUE}$TXT1${CEND}"; "$CMDECHO" ""
				set "182"; FONCTXT "$1"; "$CMDECHO" -e "${CGREEN}$TXT1${CEND}"
				set "184"; FONCTXT "$1"; "$CMDECHO" -e "${CBLUE}$TXT1${CEND} ${CYELLOW}$USER${CEND}"
				set "186"; FONCTXT "$1"; "$CMDECHO" -e "${CBLUE}$TXT1${CEND} ${CYELLOW}${PASSNGINX}${CEND}"
				set "188"; FONCTXT "$1"; "$CMDECHO" -e "${CGREEN}$TXT1${CEND}"; "$CMDECHO" ""
			fi
		fi
	done
else
	# lancement lancement gestion des utilisateurs
	"$CMDCHMOD" +x ./gestion-users.sh
	# shellcheck source=/dev/null
	source ./gestion-users.sh
fi
