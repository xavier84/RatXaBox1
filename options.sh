#!/bin/bash

INCLUDES="./includes"
. "$INCLUDES"/variables.sh
. "$INCLUDES"/langues.sh
. "$INCLUDES"/functions.sh

clear
. "$INCLUDES"/logo.sh

#variable NGINXCONFDRAT
if [ ! -f "$NGINXCONFDRAT"/sickrage.conf ]; then
	NGINXCONFDRAT="$NGINXCONFD"
fi


# choix de streaming
	echo "" ; set "234" ; FONCTXT "$1" ; echo -e "${CBLUE}$TXT1${CEND}"
	set "236" "810" ; FONCTXT "$1" "$2" ; echo -e "${CYELLOW}$TXT1${CEND} ${CGREEN}$TXT2${CEND}" #plex
	set "238" "812" ; FONCTXT "$1" "$2" ; echo -e "${CYELLOW}$TXT1${CEND} ${CGREEN}$TXT2${CEND}" #emby
	set "240" "814" ; FONCTXT "$1" "$2" ; echo -e "${CYELLOW}$TXT1${CEND} ${CGREEN}$TXT2${CEND}" #openvpn
	set "242" "820" ; FONCTXT "$1" "$2" ; echo -e "${CYELLOW}$TXT1${CEND} ${CGREEN}$TXT2${CEND}" #filebot
	set "818" "258" ; FONCTXT "$1" "$2" ; echo -e "${CYELLOW}$TXT1${CEND} ${CGREEN}$TXT2${CEND}" #sortir
	set "260" ; FONCTXT "$1" ; echo -n -e "${CBLUE}$TXT1 ${CEND}"
	read -r CHOIXS


#plex ou emby
	case $CHOIXS  in
		1)
			apt-get install apt-transport-https -y
			echo "deb https://downloads.plex.tv/repo/deb/ public main" > /etc/apt/sources.list.d/plexmediaserver.list
			wget -q https://downloads.plex.tv/plex-keys/PlexSign.key -O - | apt-key add -
			aptitude update && aptitude install -y plexmediaserver && service plexmediaserver start
			#ajout icon de plex
			git clone https://github.com/xavier84/linkplex /var/www/rutorrent/plugins/linkplex
			chown -R "$WDATA" /var/www/rutorrent/plugins/linkplex
		;;

		2)
			aptitude install -y  mono-xsp4
			wget http://download.opensuse.org/repositories/home:emby/Debian_8.0/Release.key
			apt-key add - < Release.key
			apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 3FA7E0328081BFF6A14DA29AA6A19B38D3D831EF
			#ajout depot
			echo "deb http://download.mono-project.com/repo/debian wheezy main" | tee /etc/apt/sources.list.d/mono-xamarin.list
			echo "deb http://download.mono-project.com/repo/debian wheezy-apache24-compat main" | tee -a /etc/apt/sources.list.d/mono-xamarin.list
			echo "deb http://download.mono-project.com/repo/debian wheezy-libjpeg62-compat main" | tee -a /etc/apt/sources.list.d/mono-xamarin.list
			echo 'deb http://download.opensuse.org/repositories/home:/emby/Debian_8.0/ /' >> /etc/apt/sources.list.d/emby-server.list
			aptitude update
			aptitude install -y mono-complete
			aptitude install -y emby-server
			#ajout icon de emby
			git clone https://github.com/xavier84/linkemby /var/www/rutorrent/plugins/linkemby
			chown -R "$WDATA" /var/www/rutorrent/plugins/linkemby
		;;


		3)
			wget https://raw.githubusercontent.com/xavier84/Script-xavier/master/openvpn/openvpn-install.sh
			chmod +x openvpn-install.sh && ./openvpn-install.sh
		;;

		4)
			wget https://raw.githubusercontent.com/xavier84/Script-xavier/master/filebot/filebot.sh
			chmod +x filebot.sh && ./filebot.sh
		;;

		5)
			read -p "$(echo -e ${CGREEN}Choix de l\'utilisateur : ${CEND})" USER
			curl -s https://syncthing.net/release-key.txt | apt-key add -
			echo "deb http://apt.syncthing.net/ syncthing release" | tee /etc/apt/sources.list.d/syncthing.list
			apt-get update
			apt-get install syncthing

			cp -f "$FILES"/syncthing/syncthing@.service /etc/systemd/system/syncthing@"$USER".service
			mkdir -p /home/"$USER"/.config/syncthing
			chown -R "$USER":"$USER" /home/"$USER"/.config
			chmod -R 700 /home/"$USER"/.config
			systemctl enable syncthing@"$USER".service
			systemctl start syncthing@"$USER".service
			sleep 3
			sed -i -e 's/127.0.0.1/0.0.0.0/g' /home/"$USER"/.config/syncthing/config.xml
			sed -i -e '2,20d' /home/"$USER"/.config/syncthing/config.xml
			systemctl restart syncthing@"$USER".service
			cp -f "$BONOBOX"/files/syncthing/syncthing.vhost "$NGINXCONFDRAT"/syncthing.conf
			FONCSERVICE restart nginx
			salut
		;;

		0)
			echo ""
		;;

		*)
			echo "" ; set "292" ; FONCTXT "$1" ; echo -e "${CRED}$TXT1${CEND}"
		;;
	esac