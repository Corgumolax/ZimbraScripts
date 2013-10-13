#!/bin/bash

# Script de cr�ation d'un utilisateur zimbra

# Ajout des fichiers bash nécéssaires
source colors.sh
source createRandomPassword.sh


#===================================
# Constantes
#===================================
# Codes de retour
E_ERREUR_OPTION=65
E_ERREUR_CREATE=66
E_ERREUR_USER=126

# Couleur
source colors.sh

#===================================
# Variables
#===================================

FIRST_NAME=""
LAST_NAME=""
PASSWORD=""
DESC=""
MEMBER_OF=""
DOMAIN=""
#=============================================================================
# Fonctions
#=============================================================================

#affichage de l'aide
function usage() {
	cat << EOF
	Script de création d'un compte Zimbra
	Doit être lancé en tant qu'utilisateur root:
		#${RED}sudo $0 [Options]${NORMAL}
       	
	=========================
	Options disponibles:
	
	-h, --help	Aide: Affiche ce message
	--prenom	Prénom du compte ${RED}Obligatoire${NORMAL}
	--nom		Nom du compte ${RED}Obligatoire${NORMAL}
	--description	Ligne de description du compte. Vide par défaut.
	--memberof	Listes des listes de diffusion auxquelles appartient le compte. 
			Les entrées sont séparées paes ','. Vide par défaut.
	--domain	Domaine du nouveau compte. ${RED}Obligatoire${NORMAL} 
	--password	Mot de passe. Si le paramètre est absent le script génère un mot
			de passe aléatoire de 8 caractères alphanumériques.
EOF
	exit 0
}


function createAccount(){
	# test présence des paramètres obligatoires
	if [ -z "$FIRST_NAME" ]; then
		printf "Le prénom doit être renseigné(paramètre --prenom)\n"
		exit $E_ERREUR_OPTION
	fi

	if [ -z "$LAST_NAME" ]; then
		printf "Le nom doit être renseigné(paramètre --nom)\n"
		exit $E_ERREUR_OPTION
	fi
	
	if [ -z "$DOMAIN" ]; then
		printf "Le domaine doit être renseigné (paramètre --domain)\n"
		exit $E_ERREUR_OPTION
	fi

	# Création de l'identifiant prenom.nom et conversion en minuscule
	ID=`echo "$FIRST_NAME.$LAST_NAME" | tr '[:upper:]' '[:lower:]'`

	# Génération de l'email
	EMAIL="$ID@$DOMAIN"

	# Génération du mot de passs di nécessaire
	if [ -z "$PASSWORD" ]; then
		createRandomPassword
	fi
	
	# Génération des options
	OPTLINE="givenName $FIRST_NAME sn $LAST_NAME cn $EMAIL displayName '$FIRST_NAME $LAST_NAME'"
	if [ -n "$DESC" ]; then
		OPTLINE="$OPTLINE description '$DESC'"
	fi
	# Création du compte sur zimbra
	echo $OPTLINE
	su - zimbra -c "zmprov ca $EMAIL $PASSWORD $OPTLINE" > /dev/null
	if [ $? != 0 ]; then
		printf "Erreur lors de la création du compte"
		exit $E_ERREUR_CREATE
	fi
	# On force l'utilisateur à changer son mot de passe
	su - zimbra -c "zmprov ma $EMAIL zimbraPasswordMustChange TRUE" > /dev/null
	if [ $? != 0 ]; then
		exit $E_ERREUR_CREATE
	fi
	
	if [ -n "$MEMBER_OF" ]; then
		LISTS=$(echo $MEMBER_OF | tr "," "\n")
		for LIST in $LISTS
		do
			su - zimbra -c "zmprov adlm $LIST $EMAIL"	
			if [ $? != 0 ]; then
				printf "Impossible d'ajouter l'utilisateur à la liste $LIST"
				exit $E_ERREUR_CREATE
			fi
		done
	fi	

	printf "Compte créé:\t $EMAIL\n"
	printf "Mot de passe:\t $PASSWORD\n"
	printf "Membre de:\t $MEMBER_OF\n"
}


#=============================================================================
# Point d'entré du script
#=============================================================================

# Test que le script est lance en root
if [ $EUID -ne 0 ]; then
  printf "%40s\n" "Le script doit être lancé en tant que root: ${RED}#sudo $0${NORMAL}"
  exit $E_ERREUR_NO_ROOT
fi

# traitements des options
OPTS=$( getopt -o h --long help,prenom:,nom:,description:,memberof:,domain:,password: -- "$@" )
if [ $? != 0 ]; then
  exit 1
fi

eval set -- "$OPTS"
while true ; do
	case "$1" in
		--prenom)FIRST_NAME=$2 ; shift 2 ;;
		--nom) LAST_NAME=$2 ; shift 2 ;;
		--description) DESC=$2 ; shift 2 ;;
		--memberof) MEMBER_OF=$2 ; shift 2 ;;
		--domaine) DOMAIN=$2; shift 2 ;;
		--password) PASSWORD=$2; shift 2 ;;
		-h|--help) usage; shift;;
		--) shift; break;;
		*) echo "Error"; exit 1;;
	esac
done

createAccount
