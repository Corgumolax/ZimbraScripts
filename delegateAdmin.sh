#!/bin/bash

# Create delegated administrator on Zimbra 8.x FOSS Edition
# Credits to barrydegraaff: https://gist.github.com/barrydegraaff/d1549d7e3f1951067da2
# Warning: MUST be use as ZIMBRA user and DOMAIN variable MUST be set
# Delegated admin can create/modify accounts, alias, distribution lists and resources

# Domain of concern to be changed
DOMAIN='domain.tld'

# Ensure script is running under zimbra user
WHO=`whoami`
if [ $WHO != "zimbra" ]
then
   echo
   echo "Execute this scipt as user zimbra (\"su - zimbra\")"
   echo
   exit 1
fi

echo
echo
echo "Zimbra Delegate Admin control"
echo "*************************************************"
echo "Utility to grant/revoke delegated administrators"
echo
echo "Please choose R for revoke or G for grant (RG) or any other key to abort."
read -p "RG: " rg

if [ "$rg" == 'R' ]
then
   echo "Please enter the user name (example: foo.bar@example.com) you wish to revoke delegated domain admin rights from."
   read -p "username: " username
   # Remove delegation
   zmprov ma $username zimbraIsDelegatedAdminAccount FALSE

   # Add/Create delegation
elif [ "$rg" == 'G' ]
then
   echo "Please enter the user name (example: foo.bar@example.com) you wish to grant delegated domain admin rights."
   read -p "username: " username

   # assigning admin views
   echo "Assigning admin wiews"
   zmprov ma $username zimbraIsDelegatedAdminAccount TRUE
   zmprov ma $username +zimbraAdminConsoleUIComponents accountListView
   zmprov ma $username +zimbraAdminConsoleUIComponents DLListView
   zmprov ma $username +zimbraAdminConsoleUIComponents aliasListView

   # grant rights
   echo "Granting Rights"
   # Alias Managment
   zmprov grr domain $DOMAIN usr $username +deleteAlias
   zmprov grr domain $DOMAIN usr $username +listAlias
   zmprov grr domain $DOMAIN usr $username createAlias
   zmprov grr domain $DOMAIN usr $username listAlias
   zmprov grr domain $DOMAIN usr $username addAccountAlias
   # Account Managment
   zmprov grr domain $DOMAIN usr $username +listAccount
   zmprov grr domain $DOMAIN usr $username +renameAccount
   zmprov grr domain $DOMAIN usr $username +setAccountPassword
   zmprov grr domain $DOMAIN usr $username +listDomain
   zmprov grr domain $DOMAIN usr $username +createAccount
   zmprov grr domain $DOMAIN usr $username +getAccountInfo
   zmprov grr domain $DOMAIN usr $username +getAccountMembership
   zmprov grr domain $DOMAIN usr $username +setAccountPassword
   zmprov grr domain $DOMAIN usr $username +removeAccountAlias   
   
   zmprov grr domain $DOMAIN usr $username set.account.zimbraAccountStatus
   zmprov grr domain $DOMAIN usr $username set.account.sn
   zmprov grr domain $DOMAIN usr $username set.account.givenName
   zmprov grr domain $DOMAIN usr $username set.account.displayName
   zmprov grr domain $DOMAIN usr $username set.account.zimbraPasswordMustChange

   # Distribution List Managment
   zmprov grr domain $DOMAIN usr $username +createDistributionList
   zmprov grr domain $DOMAIN usr $username +addDistributionListMember
   zmprov grr domain $DOMAIN usr $username +removeDistributionListMember
   zmprov grr domain $DOMAIN usr $username +getDistributionListMembership
   zmprov grr domain $DOMAIN usr $username +getDistributionList
   zmprov grr domain $DOMAIN usr $username +modifyDistributionList
   zmprov grr domain $DOMAIN usr $username +listDistributionList

   # Resource Managment
   zmprov grr domain $DOMAIN usr $username +createCalendarResource
   zmprov grr domain $DOMAIN usr $username +listCalendarResource
   zmprov grr domain $DOMAIN usr $username +getCalendarResource
   zmprov grr domain $DOMAIN usr $username +getCalendarResourceInfo
   zmprov grr domain $DOMAIN usr $username +modifyCalendarResource

else
   echo "Invalid option, abort"
   exit 0
fi

exit 0

   
