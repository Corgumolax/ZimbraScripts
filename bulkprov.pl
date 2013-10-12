#!/usr/bin/perl
 
# Lookup the valid COS (Class of Service) ID in the interface or like this
my $cosid = `su - zimbra -c 'zmprov gc Default |grep zimbraId:'`;
$cosid =~ s/zimbraId:\s*|\s*$//g;
  
while (<>) {
       chomp;
 
       # CHANGE ME: To the actual fields you use in your CSV file
       my ($email, $password, $first, $last) = split(/\,/, $_, 4);
         
       my ($uid, $domain) = split(/@/, $email, 2);
 
       print qq{ca $uid\@$domain $password\n};
       print qq{ma $uid\@$domain zimbraCOSid "$cosid"\n};
       print qq{ma $uid\@$domain givenName "$first"\n};
       print qq{ma $uid\@$domain sn "$last"\n};
       print qq{ma $uid\@$domain cn "$uid"\n};
       print qq{ma $uid\@$domain displayName "$first $last"\n};
       print qq{ma $uid\@$domain zimbraPasswordMustChange TRUE\n};
       print qq{\n};
}