
    $RootOUs = @(
        "Workstations",
        "Servers",
        "People",
        "Groups",
        "Resources"
    )
    $SubOUs = @(
        @{name="Admins";path="OU=People,$DomainRoot"},
        @{name="Security";path="OU=Groups,$DomainRoot"},
        @{name="Application";path="OU=Groups,$DomainRoot"},
        @{name="File Share";path="OU=Groups,$DomainRoot"},
        @{name="RBAC";path="OU=Groups,$DomainRoot"}
    )
    $Users = @(
        @{name = "LSullivan";first = "Liam";Last = "Sullivan";displayname = "Liam Sullivan"},
        @{name = "EWilson";first = "Emma";Last = "Wilson";displayname = "Emma Wilson"},
        @{name = "JCarter";first = "John";Last = "Carter";displayname = "John Carter"},
        @{name = "MDavis";first = "Mary";Last = "Davis";displayname = "Mary Davis"},
        @{name = "DMiller";first = "David";Last = "Miller";displayname = "David Miller"},
        @{name = "EThorne";first = "Evelyn";Last = "Thorne";displayname = "Evelyn Thorne"},
        @{name = "CBeaumont";first = "Charlotte";Last = "Beaumont";displayname = "Charlie Beaumont"},
        @{name = "NGreene";first = "Noah";Last = "Greene";displayname = "Noah Greene"},
        @{name = "OWalker";first = "Olivia";Last = "Walker";displayname = "Olivia Walker"},
        @{name = "LEvans";first = "Lucas";Last = "Evans";displayname = "Lucas Evans"}
    )
    $AdminUsers = @(
        @{name = "LEvans-ADM";first = "Lucas";Last = "Evans";displayname = "(Admin) Luke Evans"},
        @{name = "LEvans-DA";first = "Lucas";Last = "Evans";displayname = "(DA) Luke Evans"},
        @{name = "CBeaumont-ADM";first = "Charlotte";Last = "Beaumont";displayname = "(Admin) Charlie Beaumont"},
        @{name = "NGreene-ADM";first = "Noah";Last = "Greene";displayname = "(Admin) Noah Greene"},
        @{name = "NGreene-DA";first = "Noah";Last = "Greene";displayname = "(DA) Noah Greene"}
    )
    $Groups = @(
        @{name = "SEC-ServerAdmins";OU = "OU=Security,OU=Groups,$DomainRoot";description = "Users with Admin permissions on Servers";members = ($AdminUsers | Where-Object {$_.name -like "*-ADM"}).name},
        @{name = "SEC-RODCDelegatedAdmins";OU = "OU=Security,OU=Groups,$DomainRoot";description = "Users with Delegated Admin Permissions on RODCs";members = @()},
        @{name = "FS-DFS-IT-RW";OU = "OU=File Share,OU=Groups,$DomainRoot";description = "Read/Write on \\$DomainName\IT$";members = @()},
        @{name = "APP-BackupUtil-User";OU = "OU=Application,OU=Groups,$DomainRoot";description = "Login to BackupUtil";members = @()},
        @{name = "APP-BackupUtil-Admin";OU = "OU=Application,OU=Groups,$DomainRoot";description = "Admin rights in BackupUtil";members = @()}
    )
    [array]$DomainAdmins = ($AdminUsers | Where-Object {$_.name -like "*-DA"}).name
    $DomainAdmins += $Admincreds.UserName

        ForEach ($RootOU in $RootOUs)
        {
            xADOrganizationalUnit ($RootOU).Replace(" ","")
            {
                Name                            = $RootOU
                Path                            = $DomainRoot
                ProtectedFromAccidentalDeletion = $true
                Ensure                          = "Present"
                Credential                      = $DomainCreds
                DependsOn                       = @("[xWaitForADDomain]DscForestWait")
            }
        }
        
        ForEach ($SubOU in $SubOUs)
        {
            xADOrganizationalUnit ($SubOU.name).Replace(" ","")
            {
                Name                            = $SubOU.name
                Path                            = $SubOU.path
                ProtectedFromAccidentalDeletion = $true
                Ensure                          = "Present"
                Credential                      = $DomainCreds
                DependsOn                       = @("[xWaitForADDomain]DscForestWait","[xADOrganizationalUnit]$($RootOUs[-1])")
            }
        }
        
        ForEach ($User in $Users)
        {
            xADUser $User.name
            {
                DomainName                    = $DomainName
                Ensure                        = "Present"
                DomainAdministratorCredential = $DomainCreds
                DependsOn                     = "[xADOrganizationalUnit]People"
                UserName                      = $User.name
                Path                          = "OU=People,$DomainRoot"
                Password                      = $Admincreds
                DisplayName                   = $User.displayname
                GivenName                     = $User.first
                Surname                       = $User.last
            }
        }

        ForEach ($AdminUser in $AdminUsers)
        {
            xADUser $AdminUser.name
            {
                DomainName                    = $DomainName
                Ensure                        = "Present"
                DomainAdministratorCredential = $DomainCreds
                DependsOn                     = "[xADOrganizationalUnit]Admins"
                UserName                      = $AdminUser.name
                Path                          = "OU=Admins,OU=People,$DomainRoot"
                Password                      = $Admincreds
                DisplayName                   = $AdminUser.displayname
                GivenName                     = $AdminUser.first
                Surname                       = $AdminUser.last
            }
        }

        xADUser AdminUser
        {
            DomainName                    = $DomainName
            Ensure                        = "Present"
            DomainAdministratorCredential = $DomainCreds
            DependsOn                     = "[xADOrganizationalUnit]Admins"
            UserName                      = "$($Admincreds.UserName)"
            Path                          = "OU=Admins,OU=People,$DomainRoot"
        }

        ForEach ($Group in $Groups)
        {
            xADGroup $Group.name
            {
                Ensure      = "Present"
                Credential  = $DomainCreds
                DependsOn   = @("[xWaitForADDomain]DscForestWait","[xADUser]$($AdminUsers[-1].name)")
                GroupName   = $Group.name
                Path        = $Group.OU
                Description = $Group.description
                Members     = $Group.members
            }
        }

        xADGroup DomainAdmins
        {
            Ensure      = "Present"
            Credential  = $DomainCreds
            DependsOn   = @("[xWaitForADDomain]DscForestWait","[xADUser]$($AdminUsers[-1].name)")
            GroupName   = "Domain Admins"
            Members     = $DomainAdmins
        }
