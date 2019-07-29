#!/bin/bash

FONCCONTROL () {
	if [[ $("$CMDUNAME" -m) == x86_64 ]] &&  [[ "$VERSION" = 9.* ]] || [[ "$VERSION" = 10.* ]]; then
		if [ "$("$CMDID" -u)" -ne 0 ]; then
			"$CMDECHO" ""; set "100"; FONCTXT "$1"; "$CMDECHO" -e "${CRED}$TXT1${CEND}"; "$CMDECHO" ""
			exit 1
		fi
	else
		"$CMDECHO" ""; set "130"; FONCTXT "$1"; "$CMDECHO" -e "${CRED}$TXT1${CEND}"; "$CMDECHO" ""
		exit 1
	fi
}

FONCBASHRC () {
	unalias cp 2>/dev/null
	unalias rm 2>/dev/null
	unalias mv 2>/dev/null
	export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
}

FONCUSER () {
	while :; do
		set "214"; FONCTXT "$1"; "$CMDECHO" -e "${CGREEN}$TXT1 ${CEND}"
		read -r TESTUSER
		"$CMDGREP" -w "$TESTUSER" /etc/passwd &> /dev/null
		if [ $? -eq 1 ]; then
			if [[ "$TESTUSER" =~ ^[a-z0-9]{3,}$ ]]; then
				USER="$TESTUSER"
				# shellcheck disable=SC2104
				break
			else
				"$CMDECHO" ""; set "110"; FONCTXT "$1"; "$CMDECHO" -e "${CRED}$TXT1${CEND}"; "$CMDECHO" ""
			fi
		else
			"$CMDECHO" ""; set "198"; FONCTXT "$1"; "$CMDECHO" -e "${CRED}$TXT1${CEND}"; "$CMDECHO" ""
		fi
	done
}

FONCPASS () {
	while :; do
		set "112" "114" "116"; FONCTXT "$1" "$2" "$3"; "$CMDECHO" -e "${CGREEN}$TXT1${CEND} ${CYELLOW}$TXT2${CEND} ${CGREEN}$TXT3 ${CEND}"
		read -r REPPWD
		if [ "$REPPWD" = "" ]; then
			AUTOPWD=$(tr -dc "1-9a-nA-Np-zP-Z" < /dev/urandom | "$CMDHEAD" -c 8)
			"$CMDECHO" ""; set "118" "120"; FONCTXT "$1" "$2"; "$CMDECHO"  -n -e "${CGREEN}$TXT1${CEND} ${CYELLOW}$AUTOPWD${CEND} ${CGREEN}$TXT2 ${CEND}"
			read -r REPONSEPWD
			if FONCNO "$REPONSEPWD"; then
				"$CMDECHO"
			else
				USERPWD="$AUTOPWD"
				# shellcheck disable=SC2104
				break
			fi
		else
			if [[ "$REPPWD" =~ ^[a-zA-Z0-9]{6,}$ ]]; then
				# shellcheck disable=SC2034
				USERPWD="$REPPWD"
				# shellcheck disable=SC2104
				break
			else
				"$CMDECHO" ""; set "122"; FONCTXT "$1"; "$CMDECHO" -e "${CRED}$TXT1${CEND}"; "$CMDECHO" ""
			fi
		fi
	done
}

FONCIP () {
	"$CMDAPTGET" install -y net-tools
	IP=$("$CMDIP" -4 addr | "$CMDGREP" "inet" | "$CMDGREP" -vE '127\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}' | "$CMDAWK" '{print $2}' | "$CMDCUT" -d/ -f1)

	if [ "$IP" = "" ]; then
		IP=$("$CMDWGET" -qO- ipv4.icanhazip.com)
			if [ "$IP" = "" ]; then
				IP=$("$CMDWGET" -qO- ipv4.bonobox.net)
				if [ "$IP" = "" ]; then
					IP=x.x.x.x
				fi
			fi
	fi
}

FONCPORT () {
	HISTO=$("$CMDWC" -l < "$RUTORRENT"/"$HISTOLOG".log)
	# shellcheck disable=SC2034
	PORT=$(( 5001+HISTO ))
}

#FONCPORT () {
#	HISTO=$("$CMDWC" -l < "$1"/histo.log)
#	PORT=$(( $(($2))+HISTO ))
#}

##########
# FONCSCRIPT ça je n'ai pas ou plus chez moi, je ne sais pas si tu t'en sers, sinon tu vires
FONCSCRIPT () {
	"$CMDUPDATERC" "$2"-"$1" defaults
}
##########

FONCYES () {
	[ "$1" = "y" ] || [ "$1" = "Y" ] || [ "$1" = "o" ] || [ "$1" = "O" ] || [ "$1" = "j" ] || [ "$1" = "J" ] || [ "$1" = "д" ] || [ "$1" = "s" ] || [ "$1" = "S" ]
}

FONCNO () {
	[ "$1" = "n" ] || [ "$1" = "N" ] || [ "$1" = "h" ] || [ "$1" = "H" ]
}

FONCTXT () {
	TXT1="$("$CMDGREP" "$1" "$BONOBOX"/lang/"$GENLANG".lang | "$CMDCUT" -c5-)"
	TXT2="$("$CMDGREP" "$2" "$BONOBOX"/lang/"$GENLANG".lang | "$CMDCUT" -c5-)"
	# shellcheck disable=SC2034
	TXT3="$("$CMDGREP" "$3" "$BONOBOX"/lang/"$GENLANG".lang | "$CMDCUT" -c5-)"
}

FONCSERVICE () {
	"$CMDSYSTEMCTL" "$1" "$2".service
}
# FONCSERVICE $1 {start/stop/restart} $2 {nom service}

FONCFSUSER () {
	FSUSER=$("$CMDGREP" /home/"$1" /etc/fstab | "$CMDCUT" -c 6-9)
	if [ "$FSUSER" = "" ]; then
		"$CMDECHO"
	else
		"$CMDTUNE2FS" -m 0 /dev/"$FSUSER" &> /dev/null
		"$CMDMOUNT" -o remount /home/"$1" &> /dev/null
	fi
}

FONCMUNIN () {
	"$CMDCP" -f "$MUNIN"/rtom_mem "$MUNIN"/rtom_"$1"_mem
	"$CMDCP" -f "$MUNIN"/rtom_peers "$MUNIN"/rtom_"$1"_peers
	"$CMDCP" -f "$MUNIN"/rtom_spdd "$MUNIN"/rtom_"$1"_spdd
	"$CMDCP" -f "$MUNIN"/rtom_vol "$MUNIN"/rtom_"$1"_vol

	"$CMDCHMOD" 755 "$MUNIN"/rtom_*

	"$CMDLN" -s "$MUNIN"/rtom_"$1"_mem /etc/munin/plugins/rtom_"$1"_mem
	"$CMDLN" -s "$MUNIN"/rtom_"$1"_peers /etc/munin/plugins/rtom_"$1"_peers
	"$CMDLN" -s "$MUNIN"/rtom_"$1"_spdd /etc/munin/plugins/rtom_"$1"_spdd
	"$CMDLN" -s "$MUNIN"/rtom_"$1"_vol /etc/munin/plugins/rtom_"$1"_vol

	"$CMDCAT" <<- EOF >> /etc/munin/plugin-conf.d/munin-node

		[rtom_@USER@_*]
		user @USER@
		env.ip 127.0.0.1
		env.port @PORT@
		env.diff yes
		env.category @USER@
	EOF

	"$CMDSED" -i "s/@USER@/$1/g;" /etc/munin/plugin-conf.d/munin-node
	"$CMDSED" -i "s/@PORT@/$2/g;" /etc/munin/plugin-conf.d/munin-node

	FONCSERVICE restart munin-node

	"$CMDCAT" <<- EOF >> /etc/munin/munin.conf

		rtom_@USER@_peers.graph_width 700
		rtom_@USER@_peers.graph_height 500
		rtom_@USER@_spdd.graph_width 700
		rtom_@USER@_spdd.graph_height 500
		rtom_@USER@_vol.graph_width 700
		rtom_@USER@_vol.graph_height 500
		rtom_@USER@_mem.graph_width 700
		rtom_@USER@_mem.graph_height 500
	EOF

	"$CMDSED" -i "s/@USER@/$1/g;" /etc/munin/munin.conf
}

FONCGRAPH () {
	for PICS in 'mem-day' 'mem-week' 'mem-month'; do "$CMDCP" -f "$BONOBOX"/graph/img/tmp.png "$MUNINROUTE"/rtom_"$1"_"$PICS".png; done
	for PICS in 'peers-day' 'peers-week' 'peers-month'; do "$CMDCP" -f "$BONOBOX"/graph/img/tmp.png "$MUNINROUTE"/rtom_"$1"_"$PICS".png; done
	for PICS in 'spdd-day' 'spdd-week' 'spdd-month'; do "$CMDCP" -f "$BONOBOX"/graph/img/tmp.png "$MUNINROUTE"/rtom_"$1"_"$PICS".png; done
	for PICS in 'vol-day' 'vol-week' 'vol-month'; do "$CMDCP" -f "$BONOBOX"/graph/img/tmp.png "$MUNINROUTE"/rtom_"$1"_"$PICS".png; done

	"$CMDCHOWN" munin:munin "$MUNINROUTE"/rtom_"$1"_* && "$CMDCHMOD" 644 "$MUNINROUTE"/rtom_"$1"_*

	"$CMDLN" -s "$MUNINROUTE"/rtom_"$1"_mem-day.png "$GRAPH"/img/rtom_"$1"_mem-day.png
	"$CMDLN" -s "$MUNINROUTE"/rtom_"$1"_mem-week.png "$GRAPH"/img/rtom_"$1"_mem-week.png
	"$CMDLN" -s "$MUNINROUTE"/rtom_"$1"_mem-month.png "$GRAPH"/img/rtom_"$1"_mem-month.png

	"$CMDLN" -s "$MUNINROUTE"/rtom_"$1"_peers-day.png "$GRAPH"/img/rtom_"$1"_peers-day.png
	"$CMDLN" -s "$MUNINROUTE"/rtom_"$1"_peers-week.png "$GRAPH"/img/rtom_"$1"_peers-week.png
	"$CMDLN" -s "$MUNINROUTE"/rtom_"$1"_peers-month.png "$GRAPH"/img/rtom_"$1"_peers-month.png

	"$CMDLN" -s "$MUNINROUTE"/rtom_"$1"_spdd-day.png "$GRAPH"/img/rtom_"$1"_spdd-day.png
	"$CMDLN" -s "$MUNINROUTE"/rtom_"$1"_spdd-week.png "$GRAPH"/img/rtom_"$1"_spdd-week.png
	"$CMDLN" -s "$MUNINROUTE"/rtom_"$1"_spdd-month.png "$GRAPH"/img/rtom_"$1"_spdd-month.png

	"$CMDLN" -s "$MUNINROUTE"/rtom_"$1"_vol-day.png "$GRAPH"/img/rtom_"$1"_vol-day.png
	"$CMDLN" -s "$MUNINROUTE"/rtom_"$1"_vol-week.png "$GRAPH"/img/rtom_"$1"_vol-week.png
	"$CMDLN" -s "$MUNINROUTE"/rtom_"$1"_vol-month.png "$GRAPH"/img/rtom_"$1"_vol-month.png

	"$CMDCP" -f "$GRAPH"/user.php "$GRAPH"/"$1".php

	"$CMDSED" -i "s/@USER@/$1/g;" "$GRAPH"/"$1".php
	"$CMDSED" -i "s/@RTOM@/rtom_$1/g;" "$GRAPH"/"$1".php

	"$CMDCHOWN" -R "$WDATA" "$GRAPH"
}

FONCHTPASSWD () {
	"$CMDHTPASSWD" -bs "$NGINXPASS"/rutorrent_passwd "$1" "${PASSNGINX}"
	"$CMDHTPASSWD" -cbs "$NGINXPASS"/rutorrent_passwd_"$1" "$1" "${PASSNGINX}"
	"$CMDCHMOD" 640 "$NGINXPASS"/*
	"$CMDCHOWN" -c "$WDATA" "$NGINXPASS"/*
}

FONCRTCONF () {
	"$CMDCAT" <<- EOF >> "$NGINXENABLE"/rutorrent.conf

		        location /$1 {
		                include scgi_params;
		                scgi_pass 127.0.0.1:$2;
		                auth_basic "seedbox";
		                auth_basic_user_file "$NGINXPASS/rutorrent_passwd_$3";
		        }
		}
	EOF

	if [ -f "$NGINXCONFD"/log_rutorrent.conf ]; then
		"$CMDSED" -i "2i\  /$USERMAJ 0;" "$NGINXCONFD"/log_rutorrent.conf
	fi
}

FONCPHPCONF () {
	"$CMDTOUCH" "$RUCONFUSER"/"$1"/config.php

	"$CMDCAT" <<- EOF > "$RUCONFUSER"/"$1"/config.php
		<?php
		\$pathToExternals = array(
		    "curl"  => '/usr/bin/curl',
		    "stat"  => '/usr/bin/stat',
		    "php"    => '/usr/bin/@PHPNAME@',
		    "pgrep"  => '/usr/bin/pgrep',
		    "python" => '/usr/bin/python2.7'
		    );
		\$topDirectory = '/home/$1';
		\$scgi_port = $2;
		\$scgi_host = '127.0.0.1';
		\$XMLRPCMountPoint = '/$3';
	EOF

	"$CMDSED" -i "s/@PHPNAME@/$PHPNAME/g;" "$RUCONFUSER"/"$1"/config.php
}

FONCTORRENTRC () {
	"$CMDCP" -f "$FILES"/rutorrent/rtorrent.rc /home/"$1"/.rtorrent.rc
	"$CMDSED" -i "s/@USER@/$1/g;" /home/"$1"/.rtorrent.rc
	"$CMDSED" -i "s/@PORT@/$2/g;" /home/"$1"/.rtorrent.rc
	"$CMDSED" -i "s|@RUTORRENT@|$3|;" /home/"$1"/.rtorrent.rc
}

FONCSCRIPTRT () {
	"$CMDCP" -f "$FILES"/rutorrent/init.conf /etc/init.d/"$1"-rtorrent
	"$CMDSED" -i "s/@USER@/$1/g;" /etc/init.d/"$1"-rtorrent
	"$CMDCHMOD" +x /etc/init.d/"$1"-rtorrent
	"$CMDUPDATERC" "$1"-rtorrent defaults
}

FONCIRSSI () {
	IRSSIPORT=1"$2"
	"$CMDMKDIR" -p /home/"$1"/.irssi/scripts/autorun
	cd /home/"$1"/.irssi/scripts || exit
	"$CMDCURL" -sL http://git.io/vlcND | "$CMDGREP" -Po '(?<="browser_download_url": ")(.*-v[\d.]+.zip)' | "$CMDXARGS" "$CMDWGET" --quiet -O autodl-irssi.zip
	"$CMDUNZIP" -o autodl-irssi.zip
	command "$CMDRM" autodl-irssi.zip
	"$CMDCP" -f /home/"$1"/.irssi/scripts/autodl-irssi.pl /home/"$1"/.irssi/scripts/autorun
	"$CMDMKDIR" -p /home/"$1"/.autodl

	"$CMDCAT" <<- EOF > /home/"$1"/.autodl/autodl.cfg
		[options]
		gui-server-port = $IRSSIPORT
		gui-server-password = $3
	EOF

	"$CMDMKDIR" -p  "$RUCONFUSER"/"$1"/plugins/autodl-irssi

	"$CMDCAT" <<- EOF > "$RUCONFUSER"/"$1"/plugins/autodl-irssi/conf.php
		<?php
		\$autodlPort = $IRSSIPORT;
		\$autodlPassword = "$3";
		?>
	EOF

	"$CMDCP" -f "$FILES"/rutorrent/irssi.conf /etc/init.d/"$1"-irssi
	"$CMDSED" -i "s/@USER@/$1/g;" /etc/init.d/"$1"-irssi
	"$CMDCHMOD" +x /etc/init.d/"$1"-irssi
	"$CMDUPDATERC" "$1"-irssi defaults
}

FONCBAKSESSION () {
	"$CMDSED" -i '$d' "$SCRIPT"/backup-session.sh

	"$CMDCAT" <<- EOF >> "$SCRIPT"/backup-session.sh
		FONCBACKUP $USER
		exit 0
	EOF
}

FONCGEN () {
	if [[ -f "$RAPPORT" ]]; then
		"$CMDRM" "$RAPPORT"
	fi
	"$CMDTOUCH" "$RAPPORT"

	"$CMDCAT" <<-EOF >> "$RAPPORT"

		### Report generated on $DATE ###

		User ruTorrent --> $USERNAME
		Debian : $VERSION
		Kernel : $NOYAU
		CPU : $CPU
		nGinx : $NGINX_VERSION
		ruTorrent : $RUTORRENT_VERSION
		rTorrent : $RTORRENT_VERSION
		PHP : $PHP_VERSION
	EOF
}

FONCCHECKBIN () {
	if hash "$1" 2>/dev/null; then
		"$CMDECHO"
	else
		"$CMDAPTGET" -y install "$1"
		"$CMDECHO" ""
	fi
}

FONCGENRAPPORT () {
	LINK=$("$CMDPASTEBINIT" -b "$PASTEBIN" "$RAPPORT" 2>/dev/null)
	"$CMDECHO" -e "${CBLUE}Report link:${CEND} ${CYELLOW}$LINK${CEND}"
	"$CMDECHO" -e "${CBLUE}Report backup:${CEND} ${CYELLOW}$RAPPORT${CEND}"
}

FONCRAPPORT () {
	# $1 = Fichier
	if ! [[ -z "$1" ]]; then
		if [[ -f "$1" ]]; then
			if [[ $("$CMDWC" -l < "$1") == 0 ]]; then
				FILE="--> Empty file"
			else
				FILE=$("$CMDCAT" "$1")
				# domain.tld
				if [[ "$1" = /etc/nginx/sites-enabled/* ]]; then
					SERVER_NAME=$("$CMDGREP" server_name < "$1" | "$CMDCUT" -d';' -f1 | "$CMDSED" 's/ //' | "$CMDCUT" -c13-)
					LETSENCRYPT=$("$CMDGREP" letsencrypt < "$1" | "$CMDHEAD" -1 | "$CMDCUT" -f 5 -d '/')
					if ! [[ "$SERVER_NAME" = _ ]]; then
						if [ -z "$LETSENCRYPT" ]; then
							FILE=$("$CMDSED" "s/server_name[[:blank:]]${SERVER_NAME};/server_name domain.tld;/g;" "$1")
						else
							FILE=$("$CMDSED" "s/server_name[[:blank:]]${SERVER_NAME};/server_name domain.tld;/g; s/$LETSENCRYPT/domain.tld/g;" "$1")
						fi
					fi
				fi
			fi
		else
			FILE="--> Invalid File"
		fi
	else
		FILE="--> Invalid File"
	fi

	# $2 = Nom à afficher
	if [[ -z $2 ]]; then
		NAME="No name given"
	else
		NAME=$2
	fi

	# $3 = Affichage header
	if [[ $3 == 1 ]]; then
		"$CMDCAT" <<-EOF >> "$RAPPORT"

			.......................................................................................................................................
			## $NAME
			## File : $1
			.......................................................................................................................................
		EOF

		cat <<-EOF >> "$RAPPORT"

			$FILE
		EOF
	fi
}

FONCTESTRTORRENT () {

	SCGI="$("$CMDSED" -n '/^network.scgi.open_port/p' /home/"$USERNAME"/.rtorrent.rc | "$CMDCUT" -b 36-)"
	PORT_LISTENING=$("$CMDNETSTAT" -aultnp | "$CMDAWK" '{print $4}' | "$CMDGREP" -E ":$SCGI\$" -c)
	RTORRENT_LISTENING=$("$CMDNETSTAT" -aultnp | "$CMDSED" -n '/'$SCGI'/p' | "$CMDGREP" rtorrent -c)

	"$CMDCAT" <<-EOF >> "$RAPPORT"

		.......................................................................................................................................
		## Check rTorrent & sgci
		.......................................................................................................................................

	EOF

	# rTorrent lancé
	if [[ "$("$CMDPS" uU "$USERNAME" | "$CMDGREP" -e 'rtorrent' -c)" == [0-1] ]]; then
		"$CMDECHO" -e "rTorrent down" >> "$RAPPORT"
	else
		"$CMDECHO" -e "rTorrent Up" >> "$RAPPORT"
	fi

	# socket
	if (( PORT_LISTENING >= 1 )); then
		"$CMDECHO" -e "A socket listens on the port $SCGI" >> "$RAPPORT"
		if (( RTORRENT_LISTENING >= 1 )); then
			"$CMDECHO" -e "It is well rTorrent that listens on the port $SCGI" >> "$RAPPORT"
		else
			"$CMDECHO" -e "It's not rTorrent listening on the port $SCGI" >> "$RAPPORT"
		fi
	else
		"$CMDECHO" -e "No program listening on the port $SCGI" >> "$RAPPORT"
	fi

	# ruTorrent
	if [[ -f "$RUTORRENT"/conf/users/"$USERNAME"/config.php ]]; then
		if [[ $("$CMDCAT" "$RUTORRENT"/conf/users/"$USERNAME"/config.php) =~ "\$scgi_port = $SCGI" ]]; then
			"$CMDECHO" -e "Good SCGI port specified in the config.php file" >> "$RAPPORT"
		else
			"$CMDECHO" -e "Wrong SCGI port specified in config.php" >> "$RAPPORT"
		fi
	else
		"$CMDECHO" -e "User directory found but config.php file does not exist" >> "$RAPPORT"
	fi

	# nginx
	if [[ $("$CMDCAT" "$NGINXENABLE"/rutorrent.conf) =~ $SCGI ]]; then
		"$CMDECHO" -e "The ports nginx and the one indicated match" >> "$RAPPORT"
	else
		"$CMDECHO" -e "The nginx ports and the specified ports do not match" >> "$RAPPORT"
	fi
}

FONCARG () {
	USER=$("$CMDGREP" -m 1 : < "$ARGFILE" | "$CMDCUT" -f 1 -d ':')
	USERPWD=$("$CMDGREP" -m 1 : < "$ARGFILE" | "$CMDCUT" -d ':' -f2-)
	"$CMDSED" -i '1d' "$ARGFILE"
}

#FONCMEDIAINFO () {
#	cd /tmp || exit
#	"$CMDWGET" http://mediaarea.net/download/binary/libzen0/"$LIBZEN0"/"$LIBZEN0NAME"_"$LIBZEN0"-1_amd64."$DEBNUMBER"
#	"$CMDWGET" http://mediaarea.net/download/binary/libmediainfo0/"$LIBMEDIAINFO0"/"$LIBMEDIAINFO0NAME"_"$LIBMEDIAINFO0"-1_amd64."$DEBNUMBER"
#	"$CMDWGET" http://mediaarea.net/download/binary/mediainfo/"$MEDIAINFO"/mediainfo_"$MEDIAINFO"-1_amd64."$DEBNUMBER"
#
#	"$CMDDPKG" -i "$LIBZEN0NAME"_"$LIBZEN0"-1_amd64."$DEBNUMBER"
#	"$CMDDPKG" -i "$LIBMEDIAINFO0NAME"_"$LIBMEDIAINFO0"-1_amd64."$DEBNUMBER"
#	"$CMDDPKG" -i mediainfo_"$MEDIAINFO"-1_amd64."$DEBNUMBER"
#}
