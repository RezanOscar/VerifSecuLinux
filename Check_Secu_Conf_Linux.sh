#!/bin/bash
##################################################################################################
#                                                                                                #
# Objet : Script de vérification des recommandations de l'ANSI et des principes de secu de base  #
#	  pour un systéme GNU/Linux (Debian/Centos)                                              #
#                                                                                                #
# Version : 1.3                                                                                  #
# Par : Rêzan.O                                                                                  #
#	    Yohan                                                                                #
#                                                                                                #
# Fonctions :                                                                                    #
#	- Affiche des informations de base (RSO et Systeme) sur le SI.                           #
#	- Vérifie la configuration du ssh.                                                       #
#	- Vérifie si les recommendations de l'ANSI sont appliquée.                               #
#	- Vérifie si Fail2ban esr installée.                                                     #
#	- Génére un rapport.                                                                     #
##################################################################################################

##################################################################################################
# Obj : Ajout de la couleur pour les résultats                                                   #
##################################################################################################

# Couleur
normal=$'\e[0m'                           # (works better sometimes)
red=$'\033[1;31m'            			  # bright red text
green=$(tput setaf 2)                     # dim green text
darkblue=$(tput setaf 4)                  # dim blue text
blue="$bold$darkblue"                     # bright blue text

###################################################################################################
# Obj : vérifier que le script est executé par root                                               #
###################################################################################################

res_root=$(id -u)

if [ $res_root -ne 0 ]
 then
  	echo "Ce script doit être executé avec des droits root ou sudo, privilègié sudo."
	echo "Pour cela :
	# sudo bash <nom_du_script>
ou alors
	# su - puis ./<nom_du_script>"
  	exit
fi

###################################################################################################
# Obj : vérifier que le script est executé par bash                                               #
###################################################################################################

if readlink /proc/$$/exe | grep -qs "dash"; then
        echo "Utilisez bash, pas sh..."
		echo "# sudo bash <nom_du_script>"
        exit 1
fi

fonct_uname () {
clear
echo "###################################################################################################"
echo "# Obj : Informations uname									  #"
echo "###################################################################################################"

res_nom=$(uname -a| cut -d" " -f2)
res_ver=$(uname -a| cut -d" " -f3)

echo -e "\rHostname : $res_nom \r"



if [ -f /etc/redhat-release ]
then
	nb=$(grep -c "CentOS" /etc/redhat-release)
	if [ $nb -eq 1 ]
		then 
			cat /etc/redhat-release
		fi
fi

date
echo -e "version $res_ver \n"
}

fonct_disq () {
clear

echo "###########################################################################################"
echo "# Obj : Utilisation de l'espace disque							  #"
echo "###########################################################################################"
echo -e "\nUtilisation de l'espace disque :\n"
df -h

####################################################################################################################
#Obj : Récupération des numéros de série des disques                                                               #
####################################################################################################################

echo -e "\n######################################################################################"
echo      "# Obj : Récupération des numéros de série des disques				     #"
echo -e   "######################################################################################\n"

udevadm info --query=all -n /dev/sd* | grep ID_SERIAL
echo " "
}

fonct_res () {
clear

echo "########################################################################################"
echo "# Obj : Informations réseau                                                            #"
echo "########################################################################################"

echo -e "\nAdressage IP :"
ip a | grep -e '[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}'

echo -e "\nRoute disponible :"
echo " "
ip route show

echo -e "\nLes Routes inutiles doivent etre supprimées, pour cela utiliser la commande <route del -net ...>\n"
}

fonct_ecoute () {

echo -e "\n#############################################################################################"
echo      "# Obj : Process en écoute                                                                   #"
echo      "#############################################################################################"

echo -e "\nProcess en écoute sur le serveur :\n"
ss -ntuap

nb=$(ss -ntuap6 | grep -c tcp )
echo -e "\nVous avez ${red}$nb${normal} ports ouverts en tcp ipv6 qui sont les ports :"
ss -ntap6 | awk '! ($1=$2=$3=$5=$6=$7=$8="")' | sed 's/.*://g' | sed 's/Local//g' | awk '{ORS=" "} {print $1}'
echo " "

nb=$(ss -ntuap6 | grep -c udp )
echo -e "\nVous avez ${red}$nb${normal} ports ouverts en udp ipv6 qui sont les ports :"
ss -nuap6 | awk '! ($1=$2=$3=$5=$6=$7=$8="")' | sed 's/.*://g' | sed 's/Local//g' | awk '{ORS=" "} {print $1}'
echo " "

nb=$(ss -ntuap4 | grep -c tcp )
echo -e "\nVous avez ${red}$nb${normal} ports ouverts en tcp ipv4 qui sont les ports :"
ss -ntap4 | awk '! ($1=$2=$3=$5=$6=$7=$8="")' | sed 's/.*://g' | sed 's/Local//g' | awk '{ORS=" "} {print $1}'
echo " "

nb=$(ss -ntuap4 | grep -c udp )
echo -e "\nVous avez ${red}$nb${normal} ports ouverts en udp ipv4 qui sont les ports :"
ss -nuap4 | awk '! ($1=$2=$3=$5=$6=$7=$8="")' | sed 's/.*://g' | sed 's/Local//g' | awk '{ORS=" "} {print $1}'
echo " "

echo -e "\n#############################################################################################"
echo      "# Obj : Services classiques en ecoute sur un serveur installé par défaut                    #"
echo      "#############################################################################################"

nb=$(ss -nltuap | grep -c :111)
if [ $nb -ne 0 ]
 then   
        echo -e "\nLe service rpc est actif sur ce serveur"
fi

nb=$(ss -nltuap | grep -c :25)
if [ $nb -ne 0 ]
 then   
        echo -e "\nLe service de messagerie est actif sur ce serveur"
fi

nb=$(ss -nltuap | grep -c :5353)
if [ $nb -ne 0 ]
 then   
        echo -e "\nLe service avahi est actif sur ce serveur"
fi

nb=$(ss -nltuap | grep -c :631)
if [ $nb -ne 0 ]
 then   
        echo -e "\nLe service d'impression est actif sur ce serveur"
fi

nb=$(ss -nltuap | grep -c :1900)
if [ $nb -ne 0 ]
 then   
        echo -e "\nLe service de diffusion de contenu est actif sur ce serveur"
fi


echo -e "\n###################################################################################"
echo "# Désactiver les services en écoute qui ne sont pas nécessaire		          #"
echo "###################################################################################"

echo -e "\nPour les services inutiles qui sont en ecoute, 2 choix s'offrent a vous : "
echo "   - Arreter le service <service stop nom_du_service>"
echo "   - Supprimer le service pour cela : "
echo "             + sudo yum purge packet_du_service_a_suprimer (jusqu'a Red Hat 8)"
echo "             + sudo dnf purge packet_du_service_a_suprimer (Remplacement de yum)"
echo "             + sudo apt purge packet_du_service_a_suprimer (Debian)"
echo "             + sudo snapy purge packet_du_service_a_suprimer (Ubuntu)"

echo -e "\nIl est recommandé de suprimer les services inutiles, si les services doivent
etre utilisés dans un futur tres proche sur votre SI vous pouvez juste les arreter\n"

}

fonct_fw () {
clear

echo "###########################################################################"
echo "# Obj : Configuration du Parefeu si Présent				  #"
echo "###########################################################################"

echo -e "\nConfiguration du parefeu local :\n"
iptables -nvL
echo " "

}

fonct_sshd () {
clear

echo "##############################################################################"
echo "# Obj : Vérification des bons usages sshd				     #"
echo "##############################################################################"
echo -e "\nEvaluation non-exhaustive de la configuration du serveur ssh (\"/etc/ssh/sshd_config\") : "

echo -e "\n !!! Toute les modifications se font dans le fichier \"/etc/ssh/sshd_config\" !!!"

if grep -q "StrictHostKeyChecking  ask" /etc/ssh/ssh_config 
     then
echo -e "\nValidation explicite par l’utilisateur de la clé hôte : 		${green}ok${normal}";
    else
echo -e "\nValidation explicite par l’utilisateur de la clé hôte : 		${red}non ${normal}
    => Paramétre à modifier seulement si le poste contrôlé est un poste client.
	Pour cela dans \"/etc/ssh/sshd_config\" modifier ou ajouter <StrictHostKeyChecking ask> ";
fi


if grep -q "StrictModes yes " /etc/ssh/ssh_config 
     then
echo -e "Vérifications des modes et droits : 		\t\t\t${green}ok${normal}";
    else
echo -e "Vérifications des modes et droits : 		\t\t\t${red}non ${normal}
		 Dans \"/etc/ssh/sshd_config\" modifier ou ajouter <StrictModes yes> ";
fi


if grep -q "PermitEmptyPasswords no" /etc/ssh/ssh_config 
     then
echo -e "Interdire les mots de passe vide : 		\t\t\t${green}ok${normal}";
    else
echo -e "Interdire les mots de passe vide :		 \t\t\t${red}non ${normal}
		 Dans \"/etc/ssh/sshd_config\" modifier ou ajouter <PermitEmptyPasswords no>";
fi


if grep -q "MaxAuthTries 2" /etc/ssh/ssh_config 
     then
echo -e "Nombre de tentative d'authentification : 		\t\t${green}ok${normal}";
    else
echo -e "Nombre de tentative d'authentification : 		\t\t${red}non ${normal}
		 Dans \"/etc/ssh/sshd_config\" modifier ou ajouter <MaxAuthTries 2>";
fi


if grep -q "LoginGraceTime 30" /etc/ssh/ssh_config 
     then
echo -e "Limite de la durée d'authentification : 		\t\t${green}ok${normal}";
    else
echo -e "Limite de la durée d'authentification : 		\t\t${red}non ${normal}
		 Dans \"/etc/ssh/sshd_config\" modifier ou ajouter <LoginGraceTime 30>";
fi


if grep -q "PermitRootLogin no" /etc/ssh/ssh_config 
     then
echo -e "Connexion de root interdite : 		\t\t\t\t${green}ok${normal}";
    else
echo -e "Connexion de root interdite : 		\t\t\t\t${red}non ${normal}
		 Dans \"/etc/ssh/sshd_config\" modifier ou ajouter <PermitRootLogin no>";
fi


if grep -q "PrintLastLog yes" /etc/ssh/ssh_config 
     then
echo -e "Affichage de la dernière connexion : 		\t\t\t${green}ok${normal}";
    else
echo -e "Affichage de la dernière connexion : 		\t\t\t${red}non ${normal}
		 Dans \"/etc/ssh/sshd_config\" modifier ou ajouter <PrintLastLog yes>";
fi


if grep -q "AllowUsers" /etc/ssh/ssh_config 
     then
echo -e "Limiter les utilisateurs autorisés : 		\t\t\t${green}ok${normal}";
echo -e "    => Verifier que le paramétre AllowUsers dans /etc/sshd/sshd_config 
		contient biens les utilisateurs pouvant accepter les connexions en SSH
		(ex : AllowUsers user1 user2 )";
    else
echo -e "Limiter les utilisateurs autorisés : 		\t\t\t${red}non ${normal}";
echo -e "    => Si vous souhaitez ajouter une liste de compte local d'utilisateur 
		pouvant accepter les connexions SSH ,rajouter le paramétre AllowUsers 
		dans /etc/sshd/sshd_config (ex : AllowUsers user1 user2 )
		(ex : AllowUsers group1 group2 )"; 
fi

if grep -q "AllowGroups" /etc/ssh/ssh_config 
     then
echo -e "Limiter les groupes autorisés : 		\t\t\t${green}ok${normal}";
echo -e "    => Verifier que le paramétre AllowGroups dans /etc/sshd/sshd_config
		contient biens les groupes pouvant accepter les connexions SSH
		";
    else
echo -e "Limiter les groupes autorisés : 		\t\t\t${red}non ${normal}";
echo -e "    => Si vous souhaitez ajouter une liste de groupe 
		pouvant accepter les connexions SSH ,rajouter le paramétre AllowGroups 
		dans /etc/sshd/sshd_config (ex : AllowUsers group1 group2 )"; 
fi

if grep -q "PermitUserEnvironment no" /etc/ssh/ssh_config 
     then
echo -e "Bloquer la modification de l’environnement : 		\t\t${green}ok${normal}";
    else
echo -e "Bloquer la modification de l’environnement : 		\t\t${red}non ${normal}
		 dans \"/etc/ssh/sshd_config\" modifier ou ajouter <PermitUserEnvironment no>";
fi

if grep -q "\#ListenAddress" /etc/ssh/ssh_config 
     then
echo -e "Spécifier l'addresse local d'ecoute pour le SSH :	\t\t${red}non ${normal}
		 dans \"/etc/ssh/sshd_config\" modifier ou ajouter <ListenAddress> ce champs doit contenir les bons parametres 
			(addresse d ecoute,ipv4 ou ipv6...,port)";
    else
echo -e "Spécifier l'addresse local d'ecoute pour le SSH : 	\t\t${green}ok${normal}
		 Verifier que le champs <ListenAddress> contient les bons parametres 
			(addresse d ecoute,ipv4 ou ipv6...,port)";
fi


if grep -q "AllowTcpForwarding no" /etc/ssh/ssh_config 
     then
echo -e "Désactiver les redirections côté serveur : 		\t\t${green}ok${normal}";
    else
echo -e "Désactiver les redirections côté serveur : 		\t\t${red}non ${normal}
		 dans \"/etc/ssh/sshd_config\" modifier ou ajouter <AllowTcpForwarding no>";
fi


if grep -q "X11Forwarding no" /etc/ssh/ssh_config 
     then
echo -e "Désactivation de la redirection X11 : 		\t\t\t${green}ok${normal}";
    else
echo -e "Désactivation de la redirection X11 : 		\t\t\t${red}non ${normal}
		 dans \"/etc/ssh/sshd_config\" modifier ou ajouter <X11Forwarding no>";
fi
}

fonct_anssi () {
clear

echo -e "\n##########################################################################################"
echo 	  "# Obj : Vérification des recommandations de configuration de l'ANSI                      #"
echo 	  "##########################################################################################"

echo -e "\nRecommandations issues de la note technique NoDAT-NT-28/ANSSI/SDE/NP du 22 fevrier 2019
Version 1.2 du guide"

echo -e "\n${red}Les régle \"Non-évaluée\" sont à charge de l'administrateur, leurs execution dépendent
du systémes qui est evalué.
Par exemple les regles en rapport avec SELinux ne doivent être apliquée que si SELinux est présent dans le SI.${normal} \n"

echo "---------------------------------------------------------------------------------------------"
#R1  Minimisation des services installés
echo -e "\n#R1 Liste des services installés sur le serveur \n"
service --status-all 
echo -e "\nArreter ou Suprimer tous les services non utilisé ou inutile"

echo -e "\nPour les services inutiles qui sont en ecoute, 2 choix s'offrent a vous : "
echo "   - Arreter le service <service stop nom_du_service>"
echo "   - Supprimer le service pour cela : "
echo "             + sudo yum purge packet_du_service_a_suprimer (jusqu'a Red Hat 8)"
echo "             + sudo dnf purge packet_du_service_a_suprimer (Remplacement de yum)"
echo "             + sudo apt purge packet_du_service_a_suprimer (Debian)"
echo "             + sudo snapy purge packet_du_service_a_suprimer (Ubuntu)"
echo "!!! Voir options 3 !!!"
echo " "
echo "---------------------------------------------------------------------------------------------"
#R2  Minimisation de la configuration
echo -e "\n#R2 Minimisation de la configuration : ${blue}Non évaluée${normal}"
echo "Les fonctionnalités configurées au niveau des services démarrés doivent être limitées au strict nécessaire"


echo "----------------------------------------------------------------------------------------"
#R3  Principe de moindre privilège
echo -e "\n#R3 Principe de moindre privilège :${blue} Non évaluée${normal}"
echo -e "Les services et exécutables disponibles sur le système doivent faire l’objet \n d’une analyse afin de connaître les privilèges qui leurs sont associés, \n et doivent ensuite être configurés et intégrés en vue d’en utiliser le strict nécessaire."

echo "----------------------------------------------------------------------------------------"
#R4  Utilisation des fonctionnalités de contrôle d’accès

echo -e "\n#R4 Utilisation des fonctionnalités de contrôle d'accès :${blue} Non évaluée${normal}"
echo -e "Utilisation des fonctionnalités de contrôle d’accès. Il est recommandé d’utiliser \n les fonctionnalités de contrôle d’accès obligatoire (MAC) en plus du traditionnel modèle \n utilisateur Unix (DAC), voire éventuellement \n de les combiner avec des mécanismes de cloisonnement. (EX : MAC loking)"

echo "----------------------------------------------------------------------------------------"
#R5  Principe de défense en profondeur

echo -e "\n#R5 Principe de défense en profondeur :${blue} Non évaluée${normal}"
echo -e "Sous Unix et dérivés, la défense en profondeur doit reposer sur une combinaison de 
barrières qu’il faut garder indépendantes les unes des autres, par exemple : 
	– authentification nécessaire avant d’effectuer des opérations, notamment quand elles sont privilégiées ;
	– journalisation centralisée d’évènements au niveau systèmes et services ;
	– priorité à l’usage de services qui implémentent des mécanismes de cloisonnement 
et ou de séparation de privilèges ;
	– utilisation de mécanismes de prévention d’exploitation."


echo "----------------------------------------------------------------------------------------"
#R6  Cloisonnement des services réseau
echo -e "\n#R6  Cloisonnement des services réseau :${blue} Non évaluée${normal}"
echo -e "Les services réseau doivent autant que possible être hébergés sur des environnements
distincts. Cela évite d’avoir d’autres services potentiellement affectés si l’un d’eux se
retrouve compromis sous le même environnement."

echo "----------------------------------------------------------------------------------------"
#R7  Journalisation de l’activité des services
echo -e "\n#R7  Journalisation de l’activité des services${blue} Non évaluée${normal}"
echo -e "Les activités du système et des services en cours d’exécution doivent être \n journalisées et archivées sur un système externe, non local."

echo "----------------------------------------------------------------------------------------"
#R8  Mises à jour régulières
echo "Verification si les MAJ ont etait faite récemment"

nb=$(uname -a |grep -c "Debian")
if [ $nb -eq 1 ]
then 
	echo -e "\n#R8 Simmulation de mise à jour :"
	apt-get update && apt-get upgrade -s
fi

if [ -f /etc/redhat-release ]
then 
	nb=$(grep -c "CentOS" /etc/redhat-release)
	if [ $nb -eq 1 ]
	then 
		echo -e "\n#R8 Simmulation de mise à jour :"
		yum check-update
	fi
fi


echo "----------------------------------------------------------------------------------------"

#R9  Configuration matérielle
echo -e "\n#R9 Configuration matérielle :${blue} Non évaluée${normal}"
echo -e "Il est conseillé d’appliquer les recommandations de configuration mentionnées dans
la note technique « Recommandations de configuration matérielle de postes clients et
serveurs x86_4»"

echo "----------------------------------------------------------------------------------------"

#R10 Architecture 32 et 64 bits
echo -e "\n#R10 Privilégié une installation 64bits de votre SI"

nb=$(arch | grep -c x86_64)
if [ $nb -ne 1 ]
 then   
        echo -e "\n ${red}Vous devez privilégier une installation 64bits de votre système${normal}"
else 

        echo -e "\n ${green}Vous avez privilégié une installation 64bits de votre système${normal}"
fi

echo "----------------------------------------------------------------------------------------"
#R11 Directive de configuration de l’IOMMU
nb=$(grep -c "iommu=force"  /etc/default/grub)
if [ $nb -eq 0 ]
 then   
        echo -e "\n#R11 ${red}L’activation du service d’IOMMU permet de protéger la mémoire du système${normal}"
	echo -e "Ajoutez la variable iommu=force  dans /etc/default/grub ou  /boot/grub/menu.lst"
 else
        echo -e "\n#R11 ${green}La directive du service d’IOMMU est bien rajouté \n cela permet de protéger la mémoire du système${normal}"
fi

echo "----------------------------------------------------------------------------------------"

echo -e "\n#R12 : Partitionement "
echo -e "Ci-dessous votre partitionement : "
echo " "
df -h
echo -e "\nVous trouverez ci-dessous le partionement type recommandé"
echo -e "\nSi vous ne diposer pas de ressource suffisante pour effectuer ce partionnement, il primordial 
au minimum de crée une partition séparer pour \"/var/log\". \n"
echo "----------------------------------------------------------------------------------------"
echo -e "Partitionnement type${blue} Non évaluée${normal}"
echo -e "#-----------------------------------------------------------------------------------------------------#"
echo -e "# Point de montage |       Options              | Description                                         #"
echo -e "#-----------------------------------------------------------------------------------------------------#"
echo -e "#      /           |     <sans option>          |Partition racine, contient le reste del’arborescence #"
echo -e "#-----------------------------------------------------------------------------------------------------#"
echo -e "#       /boot      | nosuid,nodev,noexec        | Contient le noyau et le chargeur dedémarrage.       #"
echo -e "#                  |       (noauto optionnel)   |  nécessaire une fois le boot terminé                #"
echo -e "#                  |                            |          (sauf mise à jour)                         #"
echo -e "#-----------------------------------------------------------------------------------------------------#"
echo -e "#       /opt       | nosuid,nodev(ro optionnel) | Packages  additionnels  au  système.                #"
echo -e "#                  |                            | Montage en lecture seule si non utilisé             #"
echo -e "#-----------------------------------------------------------------------------------------------------#"
echo -e "#     /tmp         |                            |   Fichiers temporaires. Ne doit contenir            #"
echo -e "#                  |    nosuid,nodev,noexec     | que des éléments non exécutables.                   #"
echo -e "#                  |                            | Nettoyé après redémarrage                           #"
echo -e "#-----------------------------------------------------------------------------------------------------#"
echo -e "#     /srv         |nosuid,nodev                | Contient des fichiers servis par un                 #"
echo -e "#                  |(noexec,ro optionnels)      |  service type web, ftp, etc.                        #"
echo -e "#-----------------------------------------------------------------------------------------------------#"
echo -e "#      /home       |      nosuid,nodev,noexec   |Contient  les HOME utilisateurs.                     #"
echo -e "#                  |                            |Montage  en  lecture  seule  si  non utilisé         #"
echo -e "#-----------------------------------------------------------------------------------------------------#"
echo -e "#     /proc        |       hidepid=1            |Contient des informations sur les processus          #"
echo -e "#                  |                            |et le système                                        #"
echo -e "#-----------------------------------------------------------------------------------------------------#"
echo -e "#      /usr        |      nodev                 |Contient la majorité des utilitaires et              #"
echo -e "#                  |                            |fichiers système                                     #"
echo -e "#-----------------------------------------------------------------------------------------------------#"
echo -e "#       /var       | nosuid,nodev,noexec        |Partition contenant des fichiers variables           #"
echo -e "#                  |                            |pendant  la  vie  du  système                        #"
echo -e "#                  |                            |(mails, fichiers PID, bases de données d’un service) #"
echo -e "#-----------------------------------------------------------------------------------------------------#"
echo -e "#    /var/log      |  nosuid,nodev,noexec       |Contient les logs du système                         #"
echo -e "#-----------------------------------------------------------------------------------------------------#"
echo -e "#    /var/tmp      |  nosuid,nodev,noexec       |Fichiers temporaires conservés après extinction      #"
echo -e "#-----------------------------------------------------------------------------------------------------#"

echo "----------------------------------------------------------------------------------------"

#R13 Restrictions d’accès sur les fichiers System.map


echo -e "\n#R13 Restrictions d’accès sur les fichiers System.map"
a=$(find / -name System.map* | wc -l)
b=1
if [ $a -ne 0 ]
then
        find / -name System.map*
		echo "${green}La restriction d'accés est bien mise en place${normal}"
else
        echo "${red}La restriction d'accés n'est pas mise en place${normal}"
fi

echo "----------------------------------------------------------------------------------------"

echo -e "\n#R14 Installation de paquets réduite au strict nécessaire${blue} Non évaluée${normal}"

echo "----------------------------------------------------------------------------------------"

echo -e "\n#R15 Choix des dépôts de paquets${blue} Non évaluée${normal}"
echo "   => Seuls depot connus et offciels doivent etre utilisés"
cat /etc/apt/sources.list

echo "----------------------------------------------------------------------------------------"

echo -e "\n#R16 Dépôts de paquets durcis${blue} Non évaluée${normal}"
echo "     => Choisir comme depot ceux offrant le durcissement le plus elevé pour les paquets "

echo "----------------------------------------------------------------------------------------"

echo -e "\n#R17 Mot de passe du chargeur de démarrage${blue} Non évaluée${normal}"
echo "     => Un mot de passe  doit etre mis  pour proteger le grub lors du demarage "
echo "       Pour cela, crée un mdp via la commande <grub-mkpassswd-pbkdf2> 
	cela permet d'avoir un mdp obscursit et donc plus de secu, grace à la commande précédemment 
	exécuter cpoier a partir de <grub.pk.....> le mdp dans \"/boot/grub/grub.cfg\"  au debut du fichier 
	avant le mot <#BEGIN>, il faudra d'abord crée le superuser puis lui assosier le mdp copier.
		EX : set superusers = "toto"
		     password_pbkdf2 toto
	 	     mettre_le_mdp_copier

		     EOF       (NE PAS OUBLIER D'ECRIRE <EOF> a la suite CELA PERMET DE CONSERVER 
				LES MODIF EN CAS DE MAJ )

	Enfin faire la commande update-grub"

echo "----------------------------------------------------------------------------------------"

echo -e "\n#R18 Robustesse du mot de passe administrateur${blue} Non évaluée${normal}"
echo "	   => Le mdp Admin doit faire une taille minimum de x caractere avec presence 
		de au moins x chiffre, x caractere special, et x Majuscule, ect ...
		Il doit etre unique pour chaque compte Admin
		Le compte <root> est bien un compte admin (superuser) et doit 
		donc repondre à ces criteres"

echo "----------------------------------------------------------------------------------------"

echo -e "\n#R19 Imputabilité des opérations d’administration${blue} Non évaluée${normal}"
echo "		Chaque Admin dispose de son compte Admin local ou distant pour effectuer ces 
		action d administration, en aucun cas le compte root ne doit etre utilisé pour 
		ce type d'action"

echo "----------------------------------------------------------------------------------------"

echo -e "\n#R20 Installation d’éléments secrets ou de confiance${blue} Non évaluée${normal}"
echo "Tous les éléments secrets doivent être mis en place dès l’installation du système : 
	- mots de passe de comptes et d’administration, certificats d’autorité racines, clés publiques, 
ou encore certificatsde l’hôte (et leur clé privée respective). 

Les secrets par défaut, doivent alors être remplacés pendant, ou juste après, 
la phase d’installation dusystème."

echo -e "\n----------------------------------------------------------------------------------------"

echo -e "#R21 Durcissement et surveillance des services soumis à des flux arbitraires${blue} Non évaluée${normal}"
echo " 		=> Les service exposés et non durcis doivent faire preuve d une attention 
			pariculiére et surveillée"

echo -e "\n----------------------------------------------------------------------------------------"
echo    " "
echo -e "\n#######################################################################################\n"
echo  "${red}Toute les config pour la R22 et la R23 doivent se faire absolument dans le fichier 
	/etc/sysctl sinon elle ne seront pas permanent, ne surtout pas utiliser la 
	commande <sysctl -w> pour faire les modifications.${normal}"
echo    " "
echo -e "\n#######################################################################################"


echo -e "\n#R22 Paramétrage des sysctl réseau"
echo -e "Préconisation : Pas de  routage  entre  les  interfaces"
val=$(sysctl net.ipv4.ip_forward | tail -c2)
a=1
if [ $val = $a ]
 then
        echo -e "${red}Le routage est actif entre vos interfaces, est-ce normal ?${normal}"
	echo "Pour cela modifier le fichier </etc/sysctl.conf> :   net.ipv4.ip_forward=0"
else
        echo "${green}Le routage est désactivé entre vos interfaces${normal}"
fi

echo "----------------------------------------------------------------------------------------"
echo -e "\nFiltrage  par  chemin  inverse"
echo -e "Préconisation : Pas de routage des flux étrangés (all)"
a=0
val=$(sysctl net.ipv4.conf.all.rp_filter | tail -c2)
if [ $val = $a ]
 then
        echo "${red}Le routage des paquets étrangers est activé${normal}"
	echo "Pour cela modifier le fichier </etc/sysctl.conf> :   net.ipv4.conf.all.rp_filter=1"
else
        echo "${green}Le routage des paquets étrangers est désactivé${normal}"
fi

echo "----------------------------------------------------------------------------------------"
echo -e "\nFiltrage  par  chemin  inverse"
echo "Préconisation : Pas de  routage  de flux étrangés (default)"
a=0
val=$(sysctl net.ipv4.conf.default.rp_filter | tail -c2)
if [ $val = $a ]
 then
        echo "${red}Le routage des paquets étrangers est activé${normal}"
	echo "Pour cela modifier le fichier </etc/sysctl.conf> :   
			net.ipv4.conf.default.rp_filter=1"
else
        echo "${green}Le routage des paquets étrangers est désactivé${normal}"
fi

echo "----------------------------------------------------------------------------------------"
echo -e "\nNe pas  envoyer  de  redirections  ICMP"
echo -e "Préconisation : Pas de  redirection ICMP (all)"
a=1
val=$(sysctl net.ipv4.conf.all.send_redirects | tail -c2)
if [ $val = $a ]
 then
        echo -e "${red}La redirection ICMP est activée${normal}"
	echo -e "Pour cela modifier le fichier </etc/sysctl.conf> :   
			net.ipv4.conf.all.send_redirects=0"
else
        echo -e "${green}La redirection ICMP est déactivée${normal}"
fi

echo "----------------------------------------------------------------------------------------"
echo -e "\nNe pas  envoyer  de  redirections  ICMP"
echo -e "Préconisation : Pas de  redirection ICMP (default)"
a=1
val=$(sysctl net.ipv4.conf.default.send_redirects | tail -c2)
if [ $val = $a ]
 then
        echo -e "${red}La redirection ICMP est activée${normal}"
	echo -e "Pour cela modifier le fichier </etc/sysctl.conf> :   
			net.ipv4.conf.default.send_redirects=0"
else
        echo -e "${green}La redirection ICMP est déactivée${normal}"
fi

echo "----------------------------------------------------------------------------------------"
echo -e "\nRefuser  les  paquets  de  source  routing"
echo -e "Préconisation : Refuser  les  paquets  de  source  routing (all)"
a=1
val=$(sysctl net.ipv4.conf.all.accept_source_route | tail -c2)
if [ $val = $a ]
 then
        echo -e "${red}Le source  routing est activé${normal}"
	echo -e "Pour cela modifier le fichier </etc/sysctl.conf> :   
			net.ipv4.conf.all.accept_source_route=0"
else
        echo -e "${green}Le source  routing est déactivé${normal}"
fi

echo "----------------------------------------------------------------------------------------"
echo -e "\nRefuser  les  paquets  de  source  routing"
echo -e "Préconisation : Refuser  les  paquets  de  source  routing (default)"
a=1
val=$(sysctl net.ipv4.conf.default.accept_source_route | tail -c2)
if [ $val = $a ]
 then
        echo -e "${red}Le source  routing est activé${normal}"
	echo -e "Pour cela modifier le fichier </etc/sysctl.conf> :   
			net.ipv4.conf.default.accept_source_route=0"
else
        echo -e "${green}Le source  routing est déactivé${normal}"
fi

echo "----------------------------------------------------------------------------------------"
echo -e "\nNe pas  accepter  les  ICMP de type  accept redirect"
echo -e "Préconisation : Refuser  les  ICMP de type redirect (all)"
a=1
val=$(sysctl net.ipv4.conf.all.accept_redirects | tail -c2)
if [ $val = $a ]
 then
        echo -e "${red}Le serveur accepte les flux de type ICMP redirect${normal}"
	echo -e "Pour cela modifier le fichier </etc/sysctl.conf> :   
			net.ipv4.conf.all.accept_redirects=0"
else
        echo -e "${green}Le serveur n'accepte pas les flux de type ICMP redirect${normal}"
fi

echo "----------------------------------------------------------------------------------------"
echo -e "\nNe pas  accepter  les  ICMP de type  secure redirect"
echo -e "Préconisation : Refuser  les  ICMP de type redirect (all)"
a=1
val=$(sysctl net.ipv4.conf.all.secure_redirects | tail -c2)
if [ $val = $a ]
 then
        echo -e "${red}Le serveur accepte les flux de type ICMP redirect${normal}"
	echo -e "Pour cela modifier le fichier </etc/sysctl.conf> :   
			net.ipv4.conf.all.secure_redirects=0"
else
        echo -e "${green}Le serveur n'accepte pas les flux de type ICMP redirect${normal}"
fi

echo "----------------------------------------------------------------------------------------"
echo -e "\nNe pas  accepter  les  ICMP de type  accept redirect"
echo -e "Préconisation : Refuser  les  ICMP de type redirect (default)"
a=0
val=$(sysctl net.ipv4.conf.default.accept_redirects | tail -c2)
if [ $val = $a ]
 then
        echo -e "${red}Le serveur accepte les flux de type ICMP redirect${normal}"
	echo -e "Pour cela modifier le fichier </etc/sysctl.conf> :   
			net.ipv4.conf.default.accept_redirects=1"
else
        echo -e "${green}Le serveur n'accepte pas les flux de type ICMP redirect${normal}"
fi

echo "----------------------------------------------------------------------------------------"
echo -e "\nNe pas  accepter  les  ICMP de type  accept redirect"
echo -e "Préconisation : Refuser  les  ICMP de type redirect (default)"
a=0
val=$(sysctl net.ipv4.conf.default.secure_redirects | tail -c2)
if [ $val = $a ]
 then
        echo -e "${red}Le serveur accepte les flux de type ICMP redirect${normal}"
	echo -e "Pour cela modifier le fichier </etc/sysctl.conf> :   
			net.ipv4.conf.default.secure_redirects=1"
else
        echo -e "${green}Le serveur n'accepte pas les flux de type ICMP redirect${normal}"
fi

echo "----------------------------------------------------------------------------------------"
echo -e "\nLoguer  les  paquets  ayant  des IPs  anormales"
echo -e "Préconisation : Loguer  les  paquets  ayant  des IPs  anormales (default)"
a=1
val=$(sysctl net.ipv4.conf.all.log_martians | tail -c2)
if [ $val = $a ]
 then
        echo "${green}les paquets sont loggés${normal}"
else
        echo "${red}les paquets  ne sont pas loggé${normal}"
	echo "Pour cela modifier le fichier </etc/sysctl.conf> :   net.ipv4.conf.all.log_martians=1"
fi

echo "----------------------------------------------------------------------------------------"
# RFC  1337
echo -e "\nRFC 1337"
echo -e "Préconisation : TIME-WAIT Assassination Hazards in TCP"
a=1
val=$(sysctl net.ipv4.tcp_rfc1337 | tail -c2)
if [ $val = $a ]
 then
        echo -e "${green}Problème tcp traité${normal}"
else
        echo -e "${red}Problème tcp non-traité${normal}"
	echo -e "Pour cela modifier le fichier </etc/sysctl.conf> :   net.ipv4.tcp_rfc1337=1"
fi

echo "----------------------------------------------------------------------------------------"
# Ignorer  les réponses  non  conformes à la RFC  1122
echo -e "\nIgnorer  les réponses  non  conformes à la RFC 1122"
echo -e "Préconisation : Ignorer  les réponses  non  conformes"
a=1
val=$(sysctl net.ipv4.icmp_ignore_bogus_error_responses | tail -c2)
if [ $val = $a ]
 then
        echo -e "${green}Réponses ignorées${normal}"
else
        echo -e "${red}Réponses ICMP traitées${normal}"
	echo -e "Pour cela modifier le fichier </etc/sysctl.conf> :   
			net.ipv4.icmp_ignore_bogus_error_responses=1"
fi


echo "----------------------------------------------------------------------------------------"
# Augmenter  la plage  pour  les  ports éphémères
echo -e "\nAugmenter  la plage  pour  les  ports éphémères"
a=$(sysctl net.ipv4.ip_local_port_range |cut -f 2)
b=65535
if [ "$a" -ne "$b" ]
then
        echo -e "${red}La plage de ports éphèmères est à augmenter${normal}"
else
        echo -e "${green}La plage de ports éphèmères est conforme${normal}"
fi
echo -e "si besoin :  net.ipv4.ip_local_port_range=\"32768 65535\""


echo "----------------------------------------------------------------------------------------"
# Utiliser  les SYN cookies
echo -e "\nUtiliser  les SYN  cookies"
a=1
val=$(sysctl net.ipv4.tcp_syncookies | tail -c2)
if [ $val = $a ]
 then
        echo -e "${green}SYN cookies utilisés${normal}"
else
        echo -e "${red}SYN cookies ignorés${normal}"
	echo -e "Pour cela modifier le fichier </etc/sysctl.conf> :   net.ipv4.tcp_syncookies=1"
fi


echo "----------------------------------------------------------------------------------------"
echo -e "\nDésactiver  le  support  des "router  solicitations" (all)"
a=1
val=$(sysctl net.ipv6.conf.all.router_solicitations  | tail -c2)
if [ $val = $a ]
 then
        echo -e "${red}Le support est activé${normal}"
	echo -e "Pour cela modifier le fichier </etc/sysctl.conf> :   
			net.ipv6.conf.all.router_solicitations=0"
else
        echo -e "${green}Le support est désactivé${normal}"
fi

echo "----------------------------------------------------------------------------------------"
echo -e "\nDésactiver  le  support  des "router  solicitations" (default)"
a=1
val=$(sysctl net.ipv6.conf.default.router_solicitations | tail -c2)
if [ $val = $a ]
 then
        echo -e "${red}Le support est activé${normal}"
	echo -e "Pour cela modifier le fichier </etc/sysctl.conf> :   
			net.ipv6.conf.default.router_solicitations=0"
else
        echo -e "${green}Le support est désactivé${normal}"
fi

echo "----------------------------------------------------------------------------------------"
echo -e "\nNe pas  accepter  les "routers  preferences" par "router  advertisements"(all)"
a=1
val=$(sysctl net.ipv6.conf.all.accept_ra_rtr_pref | tail -c2)
if [ $val = $a ]
 then
        echo -e "${red}Cette Preference est activé ${normal}"
	echo -e "Pour cela modifier le fichier </etc/sysctl.conf> :   
			net.ipv6.conf.all.accept_ra_rtr_pref=0"
else
        echo -e "${green}Cette Preference est désactivé${normal}"
fi

echo "----------------------------------------------------------------------------------------"
echo -e "\nNe pas  accepter  les "router  preferences" par "router  advertisements"(default)"
a=1
val=$(sysctl net.ipv6.conf.default.accept_ra_rtr_pref | tail -c2)
if [ $val = $a ]
 then
        echo -e "${red}Cette Preference est activé ${normal}"
	echo -e "Pour cela modifier le fichier </etc/sysctl.conf> :   
			net.ipv6.conf.default.accept_ra_rtr_pref=0"
else
        echo -e "${green}Cette Preference est désactivé${normal}"
fi

echo "----------------------------------------------------------------------------------------"
echo -e "\nPas de  configuration  auto  des  prefix  par "router  advertisements"(all)"
a=1
val=$(sysctl net.ipv6.conf.all.accept_ra_pinfo | tail -c2)
if [ $val = $a ]
 then
        echo -e "${red}Cette Preference est activé ${normal}"
	echo -e "Pour cela modifier le fichier </etc/sysctl.conf> :   
			net.ipv6.conf.all.accept_ra_pinfo=0"
else
        echo -e "${green}Cette Preference est désactivé${normal}"
fi

echo "----------------------------------------------------------------------------------------"
echo "Pas de  configuration  auto  des  prefix  par "router  advertisements"(default)"
a=1
val=$(sysctl net.ipv6.conf.default.accept_ra_pinfo | tail -c2)
if [ $val = $a ]
 then
        echo -e "${red}Cette Preference est activé ${normal}"
	echo -e "Pour cela modifier le fichier </etc/sysctl.conf> :   
			net.ipv6.conf.default.accept_ra_pinfo=0"
else
        echo -e "${green}Cette Preference est désactivé${normal}"
fi

echo "----------------------------------------------------------------------------------------"
echo -e "\nPas d’apprentissage  du  routeur  par défaut  par "router  advertisements"(all)"
a=1
val=$(sysctl net.ipv6.conf.all.accept_ra_defrtr | tail -c2)
if [ $val = $a ]
 then
        echo -e "${red}Cette Preference est activé ${normal}"
	echo -e "Pour cela modifier le fichier </etc/sysctl.conf> :   
			net.ipv6.conf.all.accept_ra_defrtr=0"
else
        echo -e "${green}Cette Preference est désactivé${normal}"
fi

echo "----------------------------------------------------------------------------------------"
echo -e "\nPas d’apprentissage  du  routeur  par défaut  par "router  advertisements"(default)"
a=1
val=$(sysctl net.ipv6.conf.default.accept_ra_defrtr | tail -c2)
if [ $val = $a ]
 then
        echo -e "${red}Cette Preference est activé ${normal}"
	echo -e "Pour cela modifier le fichier </etc/sysctl.conf> :   
			net.ipv6.conf.default.accept_ra_defrtr=0"
else
        echo -e "${green}Cette Preference est désactivé${normal}"
fi

echo "----------------------------------------------------------------------------------------"
echo -e "\nPas de  configuration  auto  des  adresses à partir  des "router advertisements"(all)"
a=1
val=$(sysctl net.ipv6.conf.all.autoconf| tail -c2)
if [ $val = $a ]
 then
        echo -e "${red}Cette Preference est activé ${normal}"
	echo -e "Pour cela modifier le fichier </etc/sysctl.conf> :   net.ipv6.conf.all.autoconf=0"
else
        echo -e "${green}Cette Preference est désactivé${normal}"
fi

echo "----------------------------------------------------------------------------------------"
echo -e "\nPas de configuration auto des adresses à partir des "router advertisements"(default)"
a=1
val=$(sysctl net.ipv6.conf.default.autoconf | tail -c2)
if [ $val = $a ]
 then
        echo -e "${red}Cette Preference est activé ${normal}"
	echo -e "Pour cela modifier le fichier </etc/sysctl.conf> :   
			net.ipv6.conf.default.autoconf=0"
else
        echo -e "${green}Cette Preference est désactivé${normal}"
fi
echo "----------------------------------------------------------------------------------------"
echo -e "\nNe pas accepter les ICMP de type redirect (all)"
a=1
val=$(sysctl net.ipv6.conf.all.accept_redirects | tail -c2)
if [ $val = $a ]
 then
        echo -e "${red}Les ICMP redirect sont acceptées${normal}"
	echo -e "Pour cela modifier le fichier </etc/sysctl.conf> :   
			net.ipv6.conf.all.accept_redirects=0"
else
        echo -e "${green}Les ICMP redirect sont refusées${normal}"
fi

echo "----------------------------------------------------------------------------------------"
echo -e "\nNe pas  accepter  les  ICMP de type  redirect (default)"
a=1
val=$(sysctl net.ipv6.conf.default.accept_redirects | tail -c2)
if [ $val = $a ]
 then
        echo -e "${red}Les ICMP redirect sont acceptées${normal}"
	echo -e "Pour cela modifier le fichier </etc/sysctl.conf> :   
			net.ipv6.conf.default.accept_redirects=0"
else
        echo -e "${green}Les ICMP redirect sont refusées${normal}"
fi


echo "----------------------------------------------------------------------------------------"
echo -e "\nRefuser  les  packets  de  source  routing (all)"
a=1
val=$(sysctl net.ipv6.conf.all.accept_source_route | tail -c2)
if [ $val = $a ]
 then
        echo -e "${red}Les packets de source routing sont acceptés${normal}"
	echo -e "Pour cela modifier le fichier </etc/sysctl.conf> :   
			net.ipv6.conf.all.accept_source_route=0"
else
        echo -e "${green}Les packets de source routing sont refusés${normal}"
fi

echo "----------------------------------------------------------------------------------------"
echo -e "\nRefuser  les  packets  de  source  routing(default)"
a=1
val=$(sysctl net.ipv6.conf.default.accept_source_route | tail -c2)
if [ $val = $a ]
 then
        echo -e "${red}Les packets de source routing sont acceptés${normal}"
	echo -e "Pour cela modifier le fichier </etc/sysctl.conf> :   
			net.ipv6.conf.default.accept_source_route=0"
else
        echo -e "${green}Les packets de source routing sont refusés${normal}"
fi

echo "----------------------------------------------------------------------------------------"
echo -e "\nNombre  maximal d’adresses  autoconfigurées par  interface (all)"
a=0
val=$(sysctl net.ipv6.conf.all.max_addresses | tail -c2)
if [ $val = $a ]
 then
        echo -e "${red}Les packets de source routing sont acceptés${normal}"
	echo -e "Pour cela modifier le fichier </etc/sysctl.conf> :   
			net.ipv6.conf.all.max_addresses=1"
else
        echo -e "${green}Les packets de source routing sont refusés${normal}"
fi
echo "----------------------------------------------------------------------------------------"
echo -e "\nNombre  maximal d’adresses  autoconfigurées par  interface (default)"
a=0
val=$(sysctl net.ipv6.conf.default.max_addresses | tail -c2)
if [ $val = $a ]
 then
        echo -e "${red}Les packets de source routing sont acceptés${normal}"
	echo -e "Pour cela modifier le fichier </etc/sysctl.conf> :   
			net.ipv6.conf.default.max_addresses=1"
else
        echo -e "${green}Les packets de source routing sont refusés${normal}"
fi

echo -e "\n#R23 Paramétrage des sysctl système"
echo -e "Désactivation  des  SysReq"
a=1
val=$(sysctl kernel.sysrq | tail -c2)
if [ $val = $a ]
 then
        echo -e "${red}Les requètes systèmes sont activées${normal}"
	echo -e "Pour cela modifier le fichier </etc/sysctl.conf> :   kernel.sysrq=0"
else
        echo -e "${green}Les requètes systèmes sont activées${normal}"
fi


echo "----------------------------------------------------------------------------------------"
echo -e "\nPas de core  dump  des exécutables  setuid"
a=1
val=$(sysctl fs.suid_dumpable | tail -c2)
if [ $val = $a ]
 then
        echo -e "${red}Les core dump sont possibles${normal}"
	echo -e "Pour cela modifier le fichier </etc/sysctl.conf> :   fs.suid_dumpable=0"
else
        echo -e "${green}Les core dump sont désactivés${normal}"
fi

echo "----------------------------------------------------------------------------------------"
echo -e "\nInterdiction de déréférencer des liens (link) vers des fichiers dont l’utilisateur courant n’est pas le propriétaire"
a=0
val=$(sysctl fs.protected_symlinks| tail -c2)
if [ $val = $a ]
 then
        echo -e "${red}Les déréférencements sont possibles${normal}"
	echo -e "Pour cela modifier le fichier </etc/sysctl.conf> :   fs.protected_symlinks=1"
else
        echo -e "${green}Le déréférencement des liens symboliques est désactivé${normal}"
fi
echo "----------------------------------------------------------------------------------------"
echo -e "\nInterdiction de déréférencer des liens (hard) vers des fichiers dont l’utilisateur courant n’est pas le  propriétaire"
a=0
val=$(sysctl fs.protected_hardlinks| tail -c2)
if [ $val = $a ]
 then
        echo -e "${red}Les déréférencements sont possibles${normal}"
	echo -e "Pour cela modifier le fichier </etc/sysctl.conf> :   fs.protected_hardlinks=1"
else
        echo -e "${green}Le déréférencement des liens symboliques est désactivé${normal}"
fi


echo "----------------------------------------------------------------------------------------"
echo -e "\nActivation de l'ASLR"
a=2
val=$(sysctl kernel.randomize_va_space| tail -c2)
if [ $val = $a ]
 then
        echo -e "${green}L'ASLR est activée${normal}"
 else
	echo -e "${red}L'ASLR n'est pas activée${normal}"
	echo -e "Pour cela modifier le fichier </etc/sysctl.conf> :   kernel.randomize_va_space=2"
fi

echo "----------------------------------------------------------------------------------------"
echo -e "\nInterdiction  de  mapper  de la mémoire  dans  les  adresses  basses  "
a=$(sysctl vm.mmap_min_addr |cut -d" " -f 3)
b=65536
if [ "$a" -ne "$b" ]
then
        echo -e "${red}Il est possible de mapper la mémoire dans les adresses basses${normal}"
	echo -e "Pour cela modifier le fichier </etc/sysctl.conf> :   vm.mmap_min_addr=65536"
else
        echo -e "${green}La plage de mémoire adressable est conforme${normal}"
fi
# Espace  de choix  plus  grand  pour  les  valeurs  de PID
echo "----------------------------------------------------------------------------------------"
echo -e "\nEspace  de choix  plus  grand  pour  les  valeurs  de PID"
a=$(sysctl kernel.pid_max |cut -d" " -f 3)
b=65536
if [ "$a" -ne "$b" ]
then
        echo -e "${red}Il'espace de choix pour les valeurs de PID doit être augementé${normal}"
	echo -e "Pour cela modifier le fichier </etc/sysctl.conf> :   kernel.pid_max=65536"
else
        echo -e "${green}L'espace de chois PID est conforme${normal}"
fi
echo "----------------------------------------------------------------------------------------"
echo -e "\nObfuscation  des  adresses mémoire  kernel"
a=1
val=$(sysctl kernel.kptr_restrict | tail -c2)
if [ $val = $a ]
 then
        echo -e "${green}Obfuscation  des  adresses mémoire  kernel activé${normal}"
else
        echo -e "${red}Obfuscation  des  adresses mémoire  kernel désactivé${normal}"
	echo -e "Pour cela modifier le fichier </etc/sysctl.conf> :   kernel.kptr_restrict=1"
fi
echo "----------------------------------------------------------------------------------------"
echo -e "\nRestriction d’accès au  buffer  dmesg"
a=1
val=$(sysctl kernel.dmesg_restrict | tail -c2)
if [ $val = $a ]
 then
        echo -e "${green}Accès au buffer dmesg restreint${normal}"
else
        echo -e "${red}L'accès au buffer dmesg n'est pas restreint${normal}"
	echo -e "Pour cela modifier le fichier </etc/sysctl.conf> :   kernel.dmesg_restrict=1"
fi


# Restreint l’utilisation du sous système perf
echo "----------------------------------------------------------------------------------------"
echo -e "\nRestriction de l’utilisation du sous système perf : paranoid"
a=2
val=$(sysctl kernel.perf_event_paranoid | tail -c2)
if [ $val = $a ]
 then
        echo -e "${green}Accès au sous systeme perf restreint${normal}"
else
        echo -e "${red}L'accès au sous systeme perf n'est pas restreint${normal}"
	echo -e "Pour cela modifier le fichier </etc/sysctl.conf> :   kernel.perf_event_paranoid=2"
fi


echo "----------------------------------------------------------------------------------------"
echo -e "\nRestriction de l’utilisation du sous système perf : max sample rate"
a=2
val=$(sysctl kernel.perf_event_max_sample_rate | tail -c2)
if [ $val = $a ]
 then
        echo -e "${green}Accès au sous systeme perf max sample rate ${normal}"
else
        echo -e "${red}L'accès au sous systeme perf n'est pas restreint${normal}"
	echo -e "Pour cela modifier le fichier </etc/sysctl.conf> :   
			kernel.perf_event_max_sample_rate=2"
fi

echo "----------------------------------------------------------------------------------------"
echo -e "\nRestriction de l’utilisation du sous système perf : cpu time max"
a=1
val=$(sysctl kernel.perf_cpu_time_max_percent | tail -c2)
if [ $val = $a ]
 then
        echo -e "${green}Accès au sous systeme perf max sample rate ${normal}"
else
        echo -e "${red}L'accès au sous systeme perf n'est pas restreint${normal}"
	echo -e "Pour cela modifier le fichier </etc/sysctl.conf> :   
			kernel.perf_cpu_time_max_percent=1"
fi


echo "----------------------------------------------------------------------------------------"
echo -e "\nR24 Désactivation du chargement des modules noyau"
a=1
val=$(sysctl kernel.modules_disabled | tail -c2)
if [ $val = $a ]
 then
        echo -e "${green}Le chargement des modules noyau est désactivé${normal}"
else
        echo -e "${red}Le chargement des modules noyau est activé${normal}"
	echo -e "Pour cela modifier le fichier </etc/sysctl.conf> :   kernel.modules_disabled=1"
fi

echo "----------------------------------------------------------------------------------------"

echo -e "\n#R25 Configuration sysctl du module Yama${blue} Non évaluée${normal}"
echo "Il est recommandé de charger le module de sécu Yama lors du démarrage (par
exemple en passant l’argument security=yama au noyau) et de configurer dans /etc/sysctl
kernel.yama.ptrace_scope à une valeur au moins égale à 1."

echo "----------------------------------------------------------------------------------------"

echo -e "\n#R26 Désactivation des comptes utilisateurs inutilisés${blue} Non évaluée${normal}"
echo "		=> les comptes user  inutilisé doivent etre desactivé pour cela  :
	- On verouille le compte : usermod -L <compte>
	- Desactivation de son shell : usermod -s /bin/false <compte>
	";

echo -e "\n----------------------------------------------------------------------------------------"

echo "#R27 Désactivation des comptes de services${blue} Non évaluée${normal}"
echo "		=> Desactiver les comptes de service inutile"

echo "----------------------------------------------------------------------------------------"

echo -e "\n#R28 Unicité et exclusivité des comptes de services système${blue} Non évaluée${normal}"

echo "----------------------------------------------------------------------------------------"

echo -e "\n#R29 Délai d’expiration de sessions utilisateurs${blue} Non évaluée${normal}"

echo -e "\n----------------------------------------------------------------------------------------"

echo    "#R30 Applications utilisant PAM${blue} Non évaluée${normal}"
echo "Les aplications et les services qui utilise PAM doivent etre réduit au strict minimum"

echo -e "\n----------------------------------------------------------------------------------------"

echo -e "\n#R31 Sécurisation des services réseau d’authentification PAM${blue} Non évaluée${normal}"
echo " 	=> Secu du pam a modifier par raport a l objectif voulue et si utilisation du pam :
		- l'ajout de la ligne < auth	required	pam_wheel.so>
			permet de bloquer l'acces root au menbre du groupe wheel

		- l'utilisation de pam_cracklib dans /etc/pam.d/passwd permet de gerer la 
		complexite des mot de passe
EX : 
Dans cette exemple le mdp est de minimum 14 caractere avec pas de repetion ni sequence monotone
avec 3 classe differente (parmi majuscule,miniscule, chiffres, autres)
			password	required	      pam_cracklib.so minlen=14 minclass=3 
							      decredit=0 ucredit=0 lcredit=0
							      maxrepeat=1 maxsequence=1 gecoscheck 

"
echo -e "\n----------------------------------------------------------------------------------------"
echo -e "\n#R32 Protection des mots de passe stockés${blue} Non évaluée${normal}"
echo "Secu a modifier dans le pam par rapport a l objectif et si utilisation du pam dans:
		# Fichier /etc/pam.d/common -password
			password 	required 	pam_unix.so obscure sha512 rounds =65536
			
		# Fichier /etc/login.defs
			ENCRYPT_METHOD SHA512
			SHA_CRYPT_MIN_ROUNDS 65536 "

echo -e "\n----------------------------------------------------------------------------------------"
echo -e "#R33 Sécurisation des accès aux bases utilisateurs distantes${blue} Non évaluée${normal}"
echo -e "\n----------------------------------------------------------------------------------------"
echo -e "\n#R34 Séparation des comptes système et d’administrateur de l’annuaire${blue} Non évaluée${normal}"
echo -e "\n----------------------------------------------------------------------------------------"
echo -e "\n#R35 Valeur de umask${blue} Non évaluée${normal}"
echo "Le umask système doit être positionné à 0027.
Le umask pour les utilisateurs doit être positionné à 0077."
echo -e "\n----------------------------------------------------------------------------------------"
echo "#R36 Droits d’accès aux fichiers de contenu sensible${blue} Non évaluée${normal}"

echo -e "\n----------------------------------------------------------------------------------------"
echo "#R37 Exécutables avec bits setuid et setgid${blue} Non évaluée${normal}"

echo "----------------------------------------------------------------------------------------"
echo -e "\n#R38 Exécutables setuid root${blue} Non évaluée${normal}"
echo "	Lister l’ensemble des fichiers setuid/setgid
			find / -type f -perm /6000 -ls 2>/dev/null
			
		Retirer les droits setuid ou setgid
			chmod u-s <fichier > # Retire le bit setuid
			chmod g-s <fichier > # Retire le bit setgid"

echo -e "\n----------------------------------------------------------------------------------------"
echo "#R39 Répertoires temporaires dédiés aux comptes${blue} Non évaluée${normal}"
echo -e "\n#R40 Sticky bit et droits d’accès en écriture${blue} Non évaluée${normal}"
echo -e "\n#R41 Sécurisation des accès pour les sockets et pipes nommées${blue} Non évaluée${normal}"
echo -e "\n----------------------------------------------------------------------------------------"
echo -e "\n#R42 Services et daemons résidents en mémoire${blue} Non évaluée${normal}"
echo "Seuls les démons réseau strictement nécessaires au fonctionnement du système et du service qu’ils rendent doivent être résidents et n’être en écoute que sur les interfaces
réseau adéquates.
Les autres démons doivent être désactivés et autant que possible désinstallés.

Liste des processus résidents et ceux en écoute sur le réseau
	# Liste des processus résidents
			ps aux
	# Liste des processus en écoute sur le réseau
			netstat -aelonptu"

echo -e "\n----------------------------------------------------------------------------------------"
echo "#R43 Durcissement et configuration du service syslog${blue} Non évaluée${normal}"
echo "#R44 Cloisonnement du service syslog par chroot${blue} Non évaluée${normal}"
echo "#R45 Cloisonnement du service syslog par container${blue} Non évaluée${normal}"
echo "#R46 Journaux d’activité de service${blue} Non évaluée${normal}"
echo "#R47 Partition dédiée pour les journaux${blue} Non évaluée${normal}"
echo "#R48 Configuration du service local de messagerie${blue} Non évaluée${normal}"
echo "#R49 Alias de messagerie des comptes de service${blue} Non évaluée${normal}"
echo "#R50 Journalisation de l’activité par auditd${blue} Non évaluée${normal}"
echo "#R51 Scellement et intégrité des fichiers${blue} Non évaluée${normal}"
echo "#R52 Protection de la base de données des scellés${blue} Non évaluée${normal}"
echo "#R53 Restriction des accès des services déployés${blue} Non évaluée${normal}"
echo "#R54 Durcissement des composants de virtualisation${blue} Non évaluée${normal}"
echo "#R55 Cage chroot et privilèges d’accès du service cloisonné${blue} Non évaluée${normal}"
echo "#R56 Activation et utilisation de chroot par un service${blue} Non évaluée${normal}"
echo -e "\n----------------------------------------------------------------------------------------"
echo "#R57 Groupe dédié à l’usage de sudo${blue} Non évaluée${normal}"
echo "Un groupe dédié à l’usage de sudo doit être créé. Seuls les utilisateurs membres de ce groupe doivent avoir le droit d’exécuter sudo.
	Groupe sudo dédié
		# ls -al /usr/bin/sudo
			-rwsr -x---. 2 root sudogrp [...] /usr/bin/sudo
"

echo -e "\n----------------------------------------------------------------------------------------"
echo "#R58 Directives de configuration sudo${blue} Non évaluée${normal}"
echo -e "\n----------------------------------------------------------------------------------------"
echo -e "\n#R58 Directives de configuration sudo"
        nb=$(grep -c "noexec" /etc/sudoers)
        if [ $nb -eq 1 ]
        then
        echo "${green}L'execution des subsystem est interdite${normal}"
else
        echo -e "${red}L'execution des subsystem est autorisé${normal}"
	echo "Ajouter les lignes suivants à votre sudoers :"
	echo "         Defaults noexec,requiretty,use_pty,umask=0027"
	echo "         Defaults ignore_dot,env_reset,passwd_timeout=1"
fi
echo -e "\n#R59 Authentification des utilisateurs exécutant sudo"
echo -e "\n#R60 Privilèges des utilisateurs cible pour une commande sudo "
echo -e "\n#R61 Limitation du nombre de commandes nécessitant l’option EXEC"
echo "   => recommandation évaluée dans la R58"
echo -e "\n----------------------------------------------------------------------------------------"

echo -e "\n#R62 Du bon usage de la négation dans une spécification sudo"
        nb=$(grep -c "!/" /etc/sudoers)
        if [ $nb -eq 0 ]
        then
        echo "${green}Pas de négation dans votre fichier sudoers${normal}"
else
        echo -e "${red}L'utilisation des négations est déconseillée${normal}"
	echo "Exemple :"
	echo "        User ALL=ALL, !/bin/sh"
	echo "         un cp de /bin/sh sous un autre nom suffit à le rendre utilisable"
fi

echo -e "\n#R63 Arguments explicites dans les spécifications sudo"
	#pas de * caractère jocker dans le sudoers
        nb=$(grep -c "\*" /etc/sudoers)
        if [ $nb -eq 0 ]
        then
        echo "${green}Pas de /* dans votre fichier sudoers${normal}"
else
        echo -e "${red}L'utilisation des carat est déconseillée${normal}"
	echo "Toutes les commandes du fichier sudoers doivent préciser strictement les arguments autorisés à être utilisés pour un utilisateur donné.
L’usage de ( \* wildcard) dans les règles doit être autant que possible évité. L’absence d’arguments auprès d’une commande doit être spécifiée par la présence d’une chaînevide (\"\")."
fi

echo -e "\n#R64 Du bon usage de sudoedit${blue} Non évaluée${normal}"
echo -e "\n#R65 Activation des profils de sécurité AppArmor${blue} Non évaluée${normal}"

echo -e "\n#R66 Activation de la politique targeted avec SELinux${blue} Non évaluée${normal}"
echo "    => Si aucun autre module de Securité est utilisé autre que SELinux, il faut activer SELinux en mode <enforcing> et utiliser la politique <targeted>."
echo "Pour cela :

1. Vérifier la valeur des variables SELINUX et SELINUXTYPE dans le fichier
	/etc/selinux/config :
		# grep ^SELINUX /etc/selinux/config
			SELINUX=enforcing
			SELINUXTYPE=targeted
			
2. Si la valeur de SELINUX n’est pas enforcing ou si la valeur de SELINUXTYPE n’est pas targeted (ou default), éditer le fichier pour les corriger.

3. Si SELinux n’était pas en mode enforcing, il est nécessaire de vérifier que des labels SELinux sont correctement attribués aux fichiers sur l’ensemble du système. Cette vérification peut être programmée pour être exécutée de façon automatique au prochain démarrage avec la commande : 
		# fixfiles onboot
4. Si la politique utilisée n’était pas la politique targeted, recharger la politique utilisée par le noyau avec la commande : 
		# semodule -R
5. Il peut s’avérer nécessaire de redémarrer le système pour que le changement de politique ou l’activation de SELinux soient correctement pris en compte.

6. Enfin, pour s’assurer que SELinux est actif et avec les bons paramètres :
		# sestatus
			SELinux status: enabled
			Loaded policy name: targeted
			Current mode: enforcing
"

echo -e "\n----------------------------------------------------------------------------------------"
echo -e "\n#R67 Paramétrage des booléens SELinux${blue} Non évaluée${normal}"
echo -e "Si présence de SELinux c'est commande doivent etre executé"
echo -e "     setsebool  -P allow_execheap=off"
echo -e "     setsebool  -P allow_execmem=off"
echo -e "     setsebool  -P allow_execstack=off"
echo -e "     setsebool  -P secure_mode_insmod=off"
echo -e "     setsebool  -P ssh_sysadm_login=off"

echo "----------------------------------------------------------------------------------------"

echo -e "\n#R68 Désinstallation des outils de débogage de politique SELinux${blue} Non évaluée${normal}"
echo -e "     => Pour cela le demon <setroubleshootd> doit être désactivé et paquets <setroubleshoot, setroubleshoot-server, setroubleshoot-plugins> doivent être desinstaller."

echo "----------------------------------------------------------------------------------------"

echo -e "\n #R69 Confinement des utilisateur interactifs non privilégiés"
echo        "Par defaut, les droits user ne sont pas restreint dans la politique targeted,
 mais il est possiblede confiner sélectivement les users n'ayant pas besoins d'effectuer des taches admin"
echo  "     Pour cela : usermod -Z user_u <utilisateur> "
echo " "
}
 
fonct_fail () {
clear
echo "#############################################################################################"
echo "# Obj : vérification de la présence du service fail2ban                                     #"
echo "#############################################################################################"


a=$(service --status-all |grep fail |wc -l)
if [ $a -ne 0 ]
then
	echo "${green}Fail2ban est installé sur le serveur${normal}"
else
        echo "${red}Votre système ne dispose pas de Fail2ban${normal}
Fail2ban est une application qui analyse les logs de divers services (SSH, Apache, FTP…) en cherchant des correspondances par rapport à des motifs définis dans ses filtres. Lorsqu'une correspondance est trouvée une ou plusieurs actions sont exécutées. 
Typiquement, fail2ban cherche des tentatives répétées de connexions infructueuses dans les fichiers journaux et procède à un bannissement en ajoutant une règle au pare-feu iptables ou nftables pour bannir l'adresse IP de la source.
Pour l'installer :
	apt install fail2ban"

fi


}

fonct_rap () {

#date du jour
DATE=`date +"%d-%m-%d_%H-%M"`
NOM=`hostname`
  fonct_uname > Rapport_du_$DATE-$NOM.txt
  fonct_res >> Rapport_du_$DATE-$NOM.txt
  fonct_ecoute >> Rapport_du_$DATE-$NOM.txt
  fonct_fw >> Rapport_du_$DATE-$NOM.txt
  fonct_disq >> Rapport_du_$DATE-$NOM.txt
  fonct_sshd >> Rapport_du_$DATE-$NOM.txt
  fonct_anssi >> Rapport_du_$DATE-$NOM.txt
  fonct_fail >> Rapport_du_$DATE-$NOM.txt

sed -i 's/[^a-zA-Z 0-9`~!@#$%&*()_+\\{}|;'\'':",.\/<>?]//g' Rapport_du_$DATE-$NOM.txt
sed -i 's/1;31m//g' Rapport_du_$DATE-$NOM.txt
sed -i 's/0m//g' Rapport_du_$DATE-$NOM.txt
sed -i 's/H2J3J//g' Rapport_du_$DATE-$NOM.txt
sed -i 's/32m//g' Rapport_du_$DATE-$NOM.txt
sed -i 's/34m//g' Rapport_du_$DATE-$NOM.txt

echo -e "\nNe pas tenir compte si le message <find .... permission refusé> et les erreurs liées un apt update apparaissent"
echo -e "\nLa géneration du rapport est finie vous pouvez quiteer le programme ou choisir une nouvelle option."
echo -e "\nMerci d'avoir utilisé ce programme.\n"
}

####################################################################################################
#                               Menu                                                               #
####################################################################################################

PS3="${blue} Que souhaitez vous faire ( Appuyer sur \"Entée\" pour afficher les opérations possibles ) ? ${normal}"
select choix in \
   "Afficher les informations diverses de la machine" \
   "Afficher les informations réseau"  \
   "Afficher et Verifier les services sur les ports en écoute"  \
   "Afficher les informations sur le parefeu"  \
   "Afficher les informations sur les disques"  \
   "Véririer le paramétrage du serveur SSH"  \
   "Vérifier les critères de l'ANSSI "  \
   "Vérifier fail2ban"\
   "Génèrer un fichier rapport de toutes les options ci-dessus"  \
   "Abandon"
do
   clear
   echo "Vous avez choisi l item $REPLY : $item"
   case $REPLY in
      1) fonct_uname exit ;;
      2) fonct_res exit ;;
      3) fonct_ecoute exit ;;
      4) fonct_fw exit ;;
      5) fonct_disq exit ;;
      6) fonct_sshd exit ;;
      7) fonct_anssi exit ;;
      8) fonct_fail exit ;;
      9) fonct_rap exit ;;
     10) echo "Fin"
         exit 0 ;;
      *) echo "Fonction non implémentée"  ;;
   esac
done
