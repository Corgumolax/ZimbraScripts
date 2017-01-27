#!/bin/bash

# Script de création d'un utilisateur zimbra

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
	cat << _EOF
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
			Les entrée ssont séparées par ','. Vide par défaut.
	--domain	Domaine du nouveau compte. ${RED}Obligatoire${NORMAL} 
	--password	Mot de passe. Si le paramètre est absent le script génère un mot
			de passe aléatoire de 8 caractères alphanumériques
	--telephone	Numéro de ligne directe.
	--portable  	Numéro de telephone portable
	--company	Nom du site de travail
	--title		Titre de la personne
	--adresse	Adresse postale
	--code-postal	Code postal
	--town		ville
	
_EOF
	exit 0
}


#Test des paramètres nécessaires
function checkParameters(){
	# test présence des paramètres obligatoires
	if [ -z "$FIRST_NAME" ]; then
		printf "Prenom (${RED}Obligatoire${NORMAL}): "
		read FIRST_NAME
		if [ -z "$FIRST_NAME" ]; then
			exit $E_ERREUR_OPTION
		fi
	fi

	if [ -z "$LAST_NAME" ]; then
		printf "Nom (${RED}Obligatoire${NORMAL}): "
		read LAST_NAME
		if [ -z "$LAST_NAME" ]; then
			exit $E_ERREUR_OPTION
		fi
	fi
	
	if [ -z "$DOMAIN" ]; then
		printf "Domaine (${RED}Obligatoire${NORMAL}): "
		read DOMAIN
		if [ -z "$DOMAIN" ]; then
			exit $E_ERREUR_OPTION
		fi
	fi

	if [ -z "$DESC" ]; then
		printf "Description (${GREEN}Facultatif${NORMAL}): "
		read DESC
	fi

	if [ -z "$MEMBER_OF" ]; then
		printf "Membre de (${GREEN}Facultatif${NORMAL})\nSeparees par une ',': "
		read MEMBER_OF
	fi

	if [ -z "$TEL" ]; then
		printf "Telephone principal (${GREEN}Facultatif${NORMAL}): "
		read TEL
	fi

	if [ -z "$PORTABLE" ]; then
		printf "Telephone portable (${GREEN}Facultatif${NORMAL}): "
		read PORTABLE
	fi

	if [ -z "$SITE" ]; then
		printf "Site (${GREEN}Facultatif${NORMAL}): "
		read SITE
	fi

	if [ -z "$TITLE" ]; then
		printf "Titre (${GREEN}Facultatif${NORMAL}): "
		read TITLE
	fi

	if [ -z "$ADDRESS" ]; then
		printf "ADRESSE (${GREEN}Facultatif${NORMAL}): "
		read ADDRESS
	fi

	if [ -z "$CP" ]; then
		printf "Code Postal (${GREEN}Facultatif${NORMAL}): "
		read CP
	fi

	if [ -z "$TOWN" ]; then
		printf "Ville (${GREEN}Facultatif${NORMAL}): "
		read TOWN
	fi

}

function printParam(){
	printf "Prenom:\t ${FIRST_NAME}\n"
	printf "Nom:\t ${LAST_NAME}\n"
	printf "Domaine:\t ${DOMAIN}\n"
	printf "Desc:\t ${DESC}\n"
	printf "Tel Princ.:\t ${TEL}\n"
	printf "Tel Port.:\t ${PORTABLE}\n"
	printf "Site:\t ${SITE}\n"
	printf "Titre:\t ${TITLE}\n"
	printf "Adresse:\t ${ADDRESS}\n"
	printf "CP:\t ${CP}\n"
	printf "Ville:\t ${TOWN}\n"
	printf "Membre de:\t $MEMBER_OF\n"
}

function createAccount(){

	# Création de l'identifiant prenom.nom et conversion en minuscule
	ID=`echo "$FIRST_NAME.$LAST_NAME" | tr '[:upper:]' '[:lower:]'`

	# Génération de l'email
	EMAIL="$ID@$DOMAIN"

	# Génération du mot de passs si nécessaire
	if [ -z "$PASSWORD" ]; then
		createRandomPassword
	fi
	
	# Génération des options
	OPTLINE="givenName $FIRST_NAME sn $LAST_NAME cn $EMAIL displayName '$FIRST_NAME $LAST_NAME'"
	if [ -n "$DESC" ]; then
		OPTLINE="$OPTLINE description '$DESC'"
	fi

	if [ -n "$TEL" ]; then
		OPTLINE="$OPTLINE telephoneNumber '$TEL'"
	fi

	if [ -n "$PORTABLE" ]; then
		OPTLINE="$OPTLINE mobile '$PORTABLE'"
	fi
	if [ -n "$SITE" ]; then
		OPTLINE="$OPTLINE company '$SITE'"
	fi
	if [ -n "$TITLE" ]; then
		OPTLINE="$OPTLINE title '$TITLE'"
	fi
	if [ -n "$ADDRESS" ]; then
		OPTLINE="$OPTLINE street '$ADDRESS'"
	fi
	if [ -n "$CP" ]; then
		OPTLINE="$OPTLINE postalCode '$CP'"
	fi
	if [ -n "$TOWN" ]; then
		OPTLINE="$OPTLINE l '$TOWN'"
	fi
	# Création du compte sur zimbra
	echo $OPTLINE
	su - zimbra -c "zmprov ca $EMAIL $PASSWORD $OPTLINE" > /dev/null
	if [ $? != 0 ]; then
		printf "Erreur lors de la création du compte"
		exit $E_ERREUR_CREATE
	fi
	# On force l'utilisateur à  changer son mot de passe
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
	printf "______________________________"
	printParam
}


#=============================================================================
# Point d'entrée du script
#=============================================================================

# traitements des options
OPTS=$( getopt -o h --long help,prenom:,nom:,description:,memberof:,domain:,password:,telephone:,portable:,company:,title:,adresse:,code-postal:,town: -- "$@" )
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
		--domain) DOMAIN=$2; shift 2 ;;
		--password) PASSWORD=$2; shift 2 ;;
		--telephone)TEL=$2; shift 2;;
		--portable)  PORTABLE=$2; shift 2;;
		--company)	SITE=$2; shift 2;;
		--title) TITLE=$2; shift 2;;
		--adresse)ADDRESS=$2; shift 2;;
		--code-postal) CP=$2; shift 2;;
		--town) TOWN=$2; shift 2;;
		-h|--help) usage; shift;;
		--) shift; break;;
		*) echo "Error"; exit 1;;
	esac
done

# Test que le script est lance en root
if [ $EUID -ne 0 ]; then
  printf "%40s\n" "Le script doit être lancé en tant que root: ${RED}#sudo $0${NORMAL}"
  exit $E_ERREUR_NO_ROOT
fi

checkParameters

createAccount
