# 
########################################################
# DOC d'utilisation du script Check_Secu_Conf_Linux.SH #
########################################################

1) Transfert du script vers la machine cible.

2) Vérification des droits d'éxécution.

Voici la commande pour ajouter les droits :
	chmod u+x [nom_du_script]

3) Lancer le script en tant que Administrateur avec sudo

	sudo ./nom_du_script

Si vous ne disposer de aucun compte d'administration autre que "root" le script devra être
lancer avec "root" pour cela :
	su -
	./nom_du_script

4) Choisir les options voulues de 1 jusqu'a 10.

5) L'options 9 permet de générer le rapport celui-ci sera génere dans le repertoire d'execution du script.
Vous pouvez l'ouvrir avec n'importe quelle editeur sur "linux", et sur "Windows" avec wordpad ou nottepad.
Le rapport sera sous la forme Rapport_du_[date]_[nom-machine]

########################################################
# INFOS                                                #
########################################################

L'objectif de ce code est de tester la configuration de serveur ou poste Linux de type Debian et Centos.

Ce code s'appuie sur les recommandations de l'ANSSI ainsi que des principes de sécurité de Base.

Le code va tester votre config, puis vous donnez des solutions de remediation si cela est jugé non conforme. Chaque solution est expliquée pour le système Debian ou Centos.

Le code est ameliorable, proposer vos modfication ou ajout.

10 options vous présentez :

	1) Informations diverses sur le serveur

	2) Information réseau
		- Information et Recommandations RSO (ip, route, ...)

	3) Information sur les ports en écoute
		- Information et Recommandations sur les ports ouvert

	4) Afficher les informations sur le parefeu
		- Etat du Pare-Feu que pour Iptables

	5) Afficher les informations sur les disques
		- Etat des disques
		- Partionement
		- numeros de serie de vos disque

	6) Véririer le paramétrage du serveur SSH
		- Par rapport au fichier /etc/ssh/sshd_config
		- Recommandationsde secu

	7) Vérifier les critères de l'ANSSI 
		- 69 Regles sont vérifier + Recommendation pour mettre en place ces regles
		- Voir fichier pdf "configuration_linux-fr-v1.2.pdf" pour les regles

	8) Vérifier fail2ban

	9) Génèrer un fichier rapport de toutes les options ci-dessus
		- Le rapport une concatenation de toute les options précedente dans un fichier txt
		- Vous trouverez un exemple de Rapport "Rapport_du_03-12-03_09-56-dedale.txt"
		- Chaque rapport est editer de la facons suivante : "Rapport_du_$(Date+heure)_$(Nom_de_la_machine).txt

	10) Abandonner 
