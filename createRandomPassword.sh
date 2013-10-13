#!/bin/bash


# génération d'un mot de passe aléatoire
# http://www.cyberciti.biz/faq/linux-random-password-generator/
function createRandomPassword(){
	# $1 => longueur
	local LONG=$1
	[ "$LONG" == "" ] && LONG=8
	PASSWORD=`tr -dc A-Za-z0-9_ < /dev/urandom | head -c ${LONG}`
	PASSWORD="aA1$PASSWORD" #pour passer les contraintes programmées dans MON zimbra (a supprimer ou adapter)
}
