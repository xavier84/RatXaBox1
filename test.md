[center][b]Auto installation de ruTorrent avec rTorrent. Version [color=red]"Seedbox-Manager Workflow"[/color][/b][/center]



Salut à tous,


ATTENTION version béta (mais fonctionnelle).


Voici un "fork" (une copie) de notre ami [color=green]Ex_Rat[/color] du célèbre script Bonobox que par plaisir j’ai ajouté des fonctionnalités,


[list=*]
[*][color=#D2691E]TARDIStart[/color][/*]
[/list]
[list=*]
[*][color=#D2691E]SickRage multi-users[/color][/*]
[/list]
[list=*]
[*][color=#D2691E]CouchPotato  multi-users[/color][/*]
[/list]
[list=*]
[*][color=#D2691E]Plex  ou emby + icône dans ruTorrent [/color][/*]
[/list]
[list=*]
[*]*******[/*]
[/list]
[list=*]
[*]*******[/*]
[/list]
[list=*]
[*][color=#D2691E]eZ Server Monitor[/color][/*]
[/list]
[list=*]
[*][color=#D2691E]Thème QuickBox-Dark par défaut [/color][/*]
[/list]
[list=*]
[*][color=#D2691E]Un sous-domain[/color] [color=#9932CC] *****.ratxabox.ovh [/color][color=#D2691E](sur demande)[/color][/*]
[/list]

[b]1) Préambule[/b]

Bien lire le tuto de Ex_Rat : [url]https://mondedie.fr/d/5399[/url]

Dépot RatXaBox : [url]https://github.com/xavier84/RatXaBox[/url]

[b]2) Installation;[/b]

Mise a jours + installation de Git
[code]apt-get update && apt-get upgrade -y
apt-get install git-core -y
[/code]
on clone est lance le script
[code]cd /tmp
git clone https://github.com/xavier84/RatXaBox ratxabox
cd ratxabox
chmod a+x bonobox.sh && ./bonobox.sh[/code]

il vous suffira de suivre les indications affichées.

[b]3) Les liens[/b]

[list=*]
[*]TARDIStart   IPserveur/tardistart[/*]
[/list]
[list=*]
[*]SickRage  IPserveur/sickrage[/*]
[/list]
[list=*]
[*]CouchPotato    IPserveur/couchpotato[/*]
[/list]
[list=*]
[*]plex IPserveur:32400/web[/*]
[/list]
[list=*]
[*]emby IPserveur:8096[/*]
[/list]
[list=*]
[*]esm IPserveur/esm[/*]
[/list]

[b]4) Partie technique[/b]

- TARDIStart
Administraion des liens :[list=*]
[*]TARDIStart   IPserveur/tardistart/admin[/*]
[/list]


-SickRage 



PS: j'ai peu de connaissance en bash et Git ça fait 10 jours que je m'en sers.
si vous avez des bugs ou autres problèmes n'hésitez pas à me contacter !



La discussion se passe la [url]https://mondedie.fr/d/8717[/url]






cordialement
Xavier
