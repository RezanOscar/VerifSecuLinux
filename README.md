# VerifSecuLinux
L'objectif de ce code est de tester la configuration de serveur ou poste Linux de type Debian et Centos.

Ce code s'appuie sur les recommandations de l'ANSSI ainsi que des principes de secu de Base.

Le code va tester votre config, puis vous donnez des solution de remediation si cela est jugé non conforme.
Chaque solution est expliqué pour des systéme Debian ou Centos.

Le code est ameliorable, proposer vos modfication ou ajout, ce code est partie d'un base deja faite par "yohannahoy" sur github

9 options vous sont présenter :

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


