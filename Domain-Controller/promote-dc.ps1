Install-WindowsFeature -name AD-Domain-Services -IncludeManagementTools

# make sure success is true [?] and exit code is Success...
# next step promote box to DC

# first check pre req's
# secure string password is passed as argument to script
# if status is success from test we can proceed with AD isntall
Test-ADDSForestInstallation -DomainName itingredients.com -InstallDns -SafeModeAdministratorPassword $password

# -Confirm:$false to answer 'yes'
Install-ADDSForest -DomainName itingredients.com -InstallDNS -Confirm:$false -SafeModeAdministratorPassword $password