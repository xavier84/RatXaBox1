#!/bin/bash

INCLUDES="/tmp/ratxabox/includes"
. "$INCLUDES"/variables.sh
. "$INCLUDES"/langues.sh
. "$INCLUDES"/functions.sh

clear
. "$INCLUDES"/logo.sh

# choix de streaming
	echo "" ; set "234" ; FONCTXT "$1" ; echo -e "${CBLUE}$TXT1${CEND}"
	set "236" "810" ; FONCTXT "$1" "$2" ; echo -e "${CYELLOW}$TXT1${CEND} ${CGREEN}$TXT2${CEND}" #plex 1
	set "238" "812" ; FONCTXT "$1" "$2" ; echo -e "${CYELLOW}$TXT1${CEND} ${CGREEN}$TXT2${CEND}" #emby 2
	set "240" "814" ; FONCTXT "$1" "$2" ; echo -e "${CYELLOW}$TXT1${CEND} ${CGREEN}$TXT2${CEND}" #openvpn 3
	set "242" "820" ; FONCTXT "$1" "$2" ; echo -e "${CYELLOW}$TXT1${CEND} ${CGREEN}$TXT2${CEND}" #filebot 4
	set "244" "822" ; FONCTXT "$1" "$2" ; echo -e "${CYELLOW}$TXT1${CEND} ${CGREEN}$TXT2${CEND}" #SyncThing 5
	set "246" "824" ; FONCTXT "$1" "$2" ; echo -e "${CYELLOW}$TXT1${CEND} ${CGREEN}$TXT2${CEND}" #sickrage 6
	set "294" "826" ; FONCTXT "$1" "$2" ; echo -e "${CYELLOW}$TXT1${CEND} ${CGREEN}$TXT2${CEND}" #couchpotato 7
	set "830" "828" ; FONCTXT "$1" "$2" ; echo -e "${CYELLOW}$TXT1${CEND} ${CGREEN}$TXT2${CEND}" #medusa 8
	set "818" "258" ; FONCTXT "$1" "$2" ; echo -e "${CYELLOW}$TXT1${CEND} ${CGREEN}$TXT2${CEND}" #sortir 0
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
			if [ ! -d "$RUPLUGINS"/linkplex ];then
				git clone https://github.com/xavier84/linkplex "$RUPLUGINS"/linkplex
				chown -R "$WDATA" "$RUPLUGINS"/linkplex

			fi
		;;

		2)
			#ajout depot
			echo "deb http://download.mono-project.com/repo/debian wheezy-apache24-compat main" | tee -a /etc/apt/sources.list.d/mono-xamarin.list
			echo "deb http://download.mono-project.com/repo/debian wheezy-libjpeg62-compat main" | tee -a /etc/apt/sources.list.d/mono-xamarin.list

			if [[ $VERSION =~ 7. ]]; then
				echo "deb http://download.mono-project.com/repo/debian wheezy main" > /etc/apt/sources.list.d/mono-official.list
				echo 'deb http://download.opensuse.org/repositories/home:/emby/Debian_7.0/ /' > /etc/apt/sources.list.d/emby-server.list
				wget -nv http://download.opensuse.org/repositories/home:emby/Debian_7.0/Release.key -O Release.key
				apt-key add - < Release.key
				apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 3FA7E0328081BFF6A14DA29AA6A19B38D3D831EF
			elif [[ $VERSION =~ 8. ]]; then
				echo "deb http://download.mono-project.com/repo/debian jessie main" > /etc/apt/sources.list.d/mono-official.list
				echo 'deb http://download.opensuse.org/repositories/home:/emby/Debian_8.0/ /' > /etc/apt/sources.list.d/emby-server.list
				wget http://download.opensuse.org/repositories/home:emby/Debian_8.0/Release.key -O Release.key
				apt-key add - < Release.key
				apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 3FA7E0328081BFF6A14DA29AA6A19B38D3D831EF
			fi

			aptitude update
			aptitude install -y  mono-xsp4 mono-complete emby-server
			#ajout icon de emby
			if [ ! -d "$RUPLUGINS"/linkemby ];then
				git clone https://github.com/xavier84/linkemby "$RUPLUGINS"/linkemby
				chown -R "$WDATA" "$RUPLUGINS"/linkemby
			fi
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
			set "184" ; FONCTXT "$1" ; echo -e "${CGREEN}$TXT1 ${CEND}"
			read -r USER
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
		;;

		6)
			set "184" ; FONCTXT "$1" ; echo -e "${CGREEN}$TXT1 ${CEND}"
			read -r USER
			if [ ! -d "$SICKRAGE" ];then
				apt-get install -y git-core python python-cheetah
				git clone https://github.com/SickRage/SickRage "$SICKRAGE"
				chown -R "$USER":"$USER" "$SICKRAGE"
				chmod -R 755 "$SICKRAGE"
				#compteur
				PORT=20001
				echo "$PORT" >> "$SICKRAGE"/histo.log
			fi
			# calcul port sickrage
			FONCPORT "$SICKRAGE" 20001
			#compteur
			echo "$PORT" >> "$SICKRAGE"/histo.log
			#config
			cp -f "$BONOBOX"/files/sickrage/sickrage.init /etc/init.d/sickrage-"$USER"
			chmod +x /etc/init.d/sickrage-"$USER"
			sed -i -e 's/xataz/'$USER'/g' /etc/init.d/sickrage-"$USER"
			sed -i -e 's/SR_USER=/SR_USER='$USER'/g' /etc/init.d/sickrage-"$USER"
			/etc/init.d/sickrage-"$USER" start && sleep 5 && /etc/init.d/sickrage-"$USER" stop
			sleep 1
			sed -i -e 's/web_root = ""/web_root = \/sickrage/g' "$SICKRAGE"/data/"$USER"/config.ini
			sed -i -e 's/web_port = 8081/web_port = '$PORT'/g' "$SICKRAGE"/data/"$USER"/config.ini
			sed -i -e 's/torrent_dir = ""/torrent_dir = \/home\/'$USER'\/watch\//g' "$SICKRAGE"/data/"$USER"/config.ini
			sed -i -e 's/web_host = 0.0.0.0/web_host = 127.0.0.1/g' "$SICKRAGE"/data/"$USER"/config.ini
			FONCSCRIPT "$USER" sickrage
			FONCSERVICE start sickrage-"$USER"

			if [ ! -f "$NGINXCONFDRAT"/sickrage.conf ]; then
				cp -f "$BONOBOX"/files/sickrage/sickrage.vhost "$NGINXCONFDRAT"/sickrage.conf
			else
				sed -i '$d' "$NGINXCONFDRAT"/sickrage.conf
				cat <<- EOF >> "$NGINXCONFDRAT"/sickrage.conf
				                if (\$remote_user = "@USER@") {
				                        proxy_pass http://127.0.0.1:@PORT@;
				                        break;
		    		           }
		    		  }
				EOF
			fi

			sed -i "s|@USER@|$USER|g;" "$NGINXCONFDRAT"/sickrage.conf
			sed -i "s|@PORT@|$PORT|g;" "$NGINXCONFDRAT"/sickrage.conf
			FONCSERVICE restart nginx


		;;

		7)
			set "184" ; FONCTXT "$1" ; echo -e "${CGREEN}$TXT1 ${CEND}"
			read -r USER
			if [ ! -d "$COUCHPOTATO" ];then
				apt-get install -y git-core python python-cheetah
				git clone https://github.com/CouchPotato/CouchPotatoServer.git "$COUCHPOTATO"
				chown -R "$USER":"$USER" "$COUCHPOTATO"
				chmod -R 755 "$COUCHPOTATO"
				#compteur
				PORT=5051
				echo "$PORT" >> "$COUCHPOTATO"/histo.log
			fi
			# calcul port sickrage
			FONCPORT "$COUCHPOTATO" 5051
			#compteur
			echo "$PORT" >> "$COUCHPOTATO"/histo.log
			#config couch
			cp -f "$BONOBOX"/files/couchpotato/ubuntu /etc/init.d/couchpotato-"$USER"
			sed -i -e 's/CONFIG=\/etc\/default\/couchpotato/#CONFIG=\/etc\/default\/couchpotato/g' /etc/init.d/couchpotato-"$USER"
			sed -i -e 's/# Provides:          couchpotato/# Provides:          '$USER'/g' /etc/init.d/couchpotato-"$USER"
			sed -i -e 's/CP_USER:=couchpotato/CP_USER:='$USER'/g' /etc/init.d/couchpotato-"$USER"
			sed -i -e 's/CP_DATA:=\/var\/opt\/couchpotato/CP_DATA:=\/opt\/couchpotato\/data\/'$USER'/g' /etc/init.d/couchpotato-"$USER"
			sed -i -e 's/CP_PIDFILE:=\/var\/run\/couchpotato\/couchpotato.pid/CP_PIDFILE:=\/opt\/couchpotato\/data\/'$USER'\/couchpotato.pid/g' /etc/init.d/couchpotato-"$USER"
			chmod +x /etc/init.d/couchpotato-"$USER"
			FONCSCRIPT "$USER" couchpotato
			/etc/init.d/couchpotato-"$USER" start && sleep 5 && /etc/init.d/couchpotato-"$USER" stop
			sleep 1
			#config de user couch
			chmod -Rf 755  "$COUCHPOTATO"/data/
			cp -f "$BONOBOX"/files/couchpotato/settings.conf "$COUCHPOTATO"/data/"$USER"/settings.conf
			sed -i "s|@USER@|$USER|g;" "$COUCHPOTATO"/data/"$USER"/settings.conf
			sed -i "s|@PORT@|$PORT|g;" "$COUCHPOTATO"/data/"$USER"/settings.conf
			FONCSCRIPT "$USER" couchpotato
			FONCSERVICE start couchpotato-"$USER"

			if [ ! -f "$NGINXCONFDRAT"/couchpotato.conf ]; then
				cp -f "$BONOBOX"/files/couchpotato/couchpotato.vhost "$NGINXCONFDRAT"/couchpotato.conf
			else
				#config nginx couchpotato
				sed -i '$d' "$NGINXCONFDRAT"/couchpotato.conf
				cat <<- EOF >> "$NGINXCONFDRAT"/couchpotato.conf
				                if (\$remote_user = "@USER@") {
			                        proxy_pass http://127.0.0.1:@PORT@;
			                        break;
				               }
				      }
				EOF
			fi

			sed -i "s|@USER@|$USER|g;" "$NGINXCONFDRAT"/couchpotato.conf
			sed -i "s|@PORT@|$PORT|g;" "$NGINXCONFDRAT"/couchpotato.conf
			FONCSERVICE restart nginx
		;;

		8)
			set "184" ; FONCTXT "$1" ; echo -e "${CGREEN}$TXT1 ${CEND}"
			read -r USER
			if [ ! -d "$MEDUSA" ];then
				apt-get install -y git-core python python-cheetah
				git clone git://github.com/pymedusa/Medusa.git "$MEDUSA"
				chown -R "$USER":"$USER" "$MEDUSA"
				chmod -R 755 "$MEDUSA"
				#compteur
				PORT=5051
				echo "$PORT" >> "$MEDUSA"/histo.log
			fi
			# calcul port medusa
			FONCPORT "$MEDUSA" 20100
			#compteur
			echo "$PORT" >> "$MEDUSA"/histo.log
			#config
			cp -f "$BONOBOX"/files/medusa/medusa.init /etc/init.d/medusa-"$USER"
			chmod +x /etc/init.d/medusa-"$USER"
			sed -i -e 's/xataz/'$USER'/g' /etc/init.d/medusa-"$USER"
			sed -i -e 's/MD_USER=/MD_USER='$USER'/g' /etc/init.d/medusa-"$USER"
			/etc/init.d/medusa-"$USER" start && sleep 5 && /etc/init.d/medusa-"$USER" stop
			sleep 1
			sed -i -e 's/web_root = ""/web_root = \/medusa/g' "$MEDUSA"/data/"$USER"/config.ini
			sed -i -e 's/web_port = 8081/web_port = '$PORT'/g' "$MEDUSA"/data/"$USER"/config.ini
			sed -i -e 's/torrent_dir = ""/torrent_dir = \/home\/'$USER'\/watch\//g' "$MEDUSA"/data/"$USER"/config.ini
			sed -i -e 's/web_host = 0.0.0.0/web_host = 127.0.0.1/g' "$MEDUSA"/data/"$USER"/config.ini
			FONCSCRIPT "$USER" medusa
			FONCSERVICE start medusa-"$USER"

			if [ ! -f "$NGINXCONFDRAT"/medusa.conf ]; then
				cp -f "$BONOBOX"/files/medusa/medusa.vhost "$NGINXCONFDRAT"/medusa.conf
			else
				sed -i '$d' "$NGINXCONFDRAT"/medusa.conf
				cat <<- EOF >> "$NGINXCONFDRAT"/medusa.conf
				                if (\$remote_user = "@USER@") {
				                        proxy_pass http://127.0.0.1:@PORT@;
				                        break;
		    		           }
		    		  }
				EOF
			fi

			sed -i "s|@USER@|$USER|g;" "$NGINXCONFDRAT"/medusa.conf
			sed -i "s|@PORT@|$PORT|g;" "$NGINXCONFDRAT"/medusa.conf
			FONCSERVICE restart nginx
		;;

		0)
			clear
		;;

		*)
			echo "" ; set "292" ; FONCTXT "$1" ; echo -e "${CRED}$TXT1${CEND}"
		;;
	esac