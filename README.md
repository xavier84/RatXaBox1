# Script d'installation ruTorrent / Nginx

![logo](https://raw.github.com/xavier84/RatXaBox/master/files/ratxabox.png)

* Multi-utilisateurs & Multilingue automatique en fonction de l'installation du serveur
* Français, English, German, Pусский,  Español, Português
* Nécessite Debian 7/8/9 (64 bits) & un serveur fraîchement installé

* Inclus VsFTPd (ftp & ftps sur le port 21), Fail2ban (avec conf nginx, ftp & ssh)
* Seedbox-Manager, Auteurs: Magicalex, Hydrog3n et Backtoback

Tiré du tutoriel de Magicalex pour mondedie.fr disponible ici:

[Installer ruTorrent sur Debian {nginx & php-fpm}](http://mondedie.fr/viewtopic.php?id=5302)

[Aide, support & plus si affinités à la même adresse !](http://mondedie.fr/)

**Auteur :** Ex_Rat
**Modifié par :** Xavier

Merci Aliochka & Meister pour les conf de munin et VsFTPd

à Albaret pour le coup de main sur la gestion d'users, LetsGo67 pour ses rectifs et

Jedediah pour avoir joué avec le html/css du thème

Aux traducteurs: Sophie, Spectre, Hardware, Zarev, SirGato, MiguelSam, Hierra

## Installation:
Multilingue automatique
```
apt-get update && apt-get upgrade -y
apt-get install git-core -y

cd /tmp
git clone https://github.com/xavier84/RatXaBox ratxabox
cd ratxabox
chmod a+x bonobox.sh && ./bonobox.sh
```


**Vous pouvez aussi forcer la langue de votre choix:**
```
# Français
chmod a+x bonobox.sh && ./bonobox.sh --fr

# English
chmod a+x bonobox.sh && ./bonobox.sh --en

# Pусский  ( "д/H" или "y/n" )
chmod a+x bonobox.sh && ./bonobox.sh --ru

# German
chmod a+x bonobox.sh && ./bonobox.sh --de

# Español
chmod a+x bonobox.sh && ./bonobox.sh --es

# Português
chmod a+x bonobox.sh && ./bonobox.sh --pt

# Português do Brasil
chmod a+x bonobox.sh && ./bonobox.sh --ptbr
```

Pour gérer vos utilisateurs ultérieurement, il vous suffit de relancer le script

![gestion](https://raw.github.com/xavier84/RatXaBox/master/files/gestion.png)

### Disclaimer
Ce script est proposé à des fins d'expérimentation uniquement, le téléchargement d’oeuvre copyrightées est illégal.

Merci de vous conformer à la législation en vigueur en fonction de vos pays respectifs en faisant vos tests sur des fichiers libres de droits.

### License
This work is licensed under a [Creative Commons Attribution-NonCommercial-ShareAlike 4.0 International License](http://creativecommons.org/licenses/by-nc-sa/4.0/)

