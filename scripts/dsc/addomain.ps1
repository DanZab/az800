configuration setup-domain 
{ 
    param 
    ( 
        [Parameter(Mandatory)]
        [String]$DomainName,
        #Replace DomainDN reference or set variable
        [Parameter(Mandatory=$false)]
        [String]$ConfigScript,

        [Parameter(Mandatory=$false)]
        [String]$GPOzip="https://raw.githubusercontent.com/DanZab/az800/main/scripts/dsc/gpo.zip",

        [Parameter(Mandatory)]
        [System.Management.Automation.PSCredential]$Admincreds,

        [Int]$RetryCount = 20,
        [Int]$RetryIntervalSec = 30
    ) 
    
    Import-DscResource -ModuleName xActiveDirectory, xStorage, xNetworking, PSDesiredStateConfiguration, xPendingReboot
    [System.Management.Automation.PSCredential ]$DomainCreds = New-Object System.Management.Automation.PSCredential ("${DomainName}\$($Admincreds.UserName)", $Admincreds.Password)
    $Interface = Get-NetAdapter | Where Name -Like "Ethernet*" | Select-Object -First 1
    $InterfaceAlias = $($Interface.Name)
    $DNs = $DomainName.Split(".") | ForEach-Object {"DC=$($_)"}
    $DomainRoot = $DNs -join ","

    Node localhost
    {
        LocalConfigurationManager {
            RebootNodeIfNeeded = $true
        }

        WindowsFeature DNS { 
            Ensure = "Present" 
            Name   = "DNS"		
        }

        Script GuestAgent
        {
            SetScript  = {
                Set-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Services\WindowsAzureGuestAgent' -Name DependOnService -Type MultiString -Value DNS
                Write-Verbose -Verbose "GuestAgent depends on DNS"
            }
            GetScript  = { @{} }
            TestScript = { $false }
            DependsOn  = "[WindowsFeature]DNS"
        }
        
        Script EnableDNSDiags {
            SetScript  = { 
                Set-DnsServerDiagnostics -All $true
                Write-Verbose -Verbose "Enabling DNS client diagnostics" 
            }
            GetScript  = { @{} }
            TestScript = { $false }
            DependsOn  = "[WindowsFeature]DNS"
        }

        WindowsFeature DnsTools {
            Ensure    = "Present"
            Name      = "RSAT-DNS-Server"
            DependsOn = "[WindowsFeature]DNS"
        }

        xDnsServerAddress DnsServerAddress 
        { 
            Address        = '127.0.0.1' 
            InterfaceAlias = $InterfaceAlias
            AddressFamily  = 'IPv4'
            DependsOn      = "[WindowsFeature]DNS"
        }

        WindowsFeature ADDSInstall { 
            Ensure    = "Present" 
            Name      = "AD-Domain-Services"
            DependsOn = "[WindowsFeature]DNS" 
        } 

        WindowsFeature ADDSTools {
            Ensure    = "Present"
            Name      = "RSAT-ADDS-Tools"
            DependsOn = "[WindowsFeature]ADDSInstall"
        }

        WindowsFeature ADAdminCenter {
            Ensure    = "Present"
            Name      = "RSAT-AD-AdminCenter"
            DependsOn = "[WindowsFeature]ADDSInstall"
        }
         
        xADDomain FirstDS 
        {
            DomainName                    = $DomainName
            DomainAdministratorCredential = $DomainCreds
            SafemodeAdministratorPassword = $DomainCreds
            DatabasePath                  = "C:\NTDS"
            LogPath                       = "C:\NTDS"
            SysvolPath                    = "C:\SYSVOL"
            DependsOn                     = @("[WindowsFeature]ADDSInstall")
        }

        xWaitForADDomain DscForestWait
        {
            DomainName           = $DomainName
            DomainUserCredential = $DomainCreds
            RetryCount           = "3"
            RetryIntervalSec     = "300"
            DependsOn            = "[xADDomain]FirstDS"
        }

        Script Config
        {
            SetScript  = {
                Invoke-WebRequest "$using:ConfigScript" -UseBasicParsing -Outfile "C:\Temp\ad.ps1"
                C:\Temp\ad.ps1 -DomainCreds $DomainCreds -DomainRoot $DomainRoot
            }
            GetScript  = { @{} }
            TestScript = { $false }
            DependsOn  = @("[xWaitForADDomain]DscForestWait")
        }
        
        Script GPOs
        {
            SetScript  = {
                $Path = "C:\Temp\GPO"
                New-Item -Path $Path -ItemType Directory -Force
                Invoke-WebRequest "$using:GPOzip" -UseBasicParsing -Outfile "C:\Temp\gpo.zip"
                Expand-Archive -LiteralPath "C:\Temp\gpo.zip" -DestinationPath $Path -Force

                $GPOs = @(
                    @{
                        Name = "Server-Admins"
                        OU = "OU=Servers,$DomainDN"
                    },
                    @{
                        Name = "Domain-RDP"
                        OU = "$DomainDN"
                    },
                    @{
                        Name = "Domain-Firewall"
                        OU = "$DomainDN"
                    }
                )
                ForEach ($GPO in $GPOs) {
                    New-GPO -Name $GPO.Name
                    Import-GPO -Path $Path -BackupGpoName $GPO.Name -TargetName $GPO.Name
                    New-GPLink -Name $GPO.Name -Target $GPO.OU
                }
            }
            GetScript  = { @{} }
            TestScript = { $false }
            DependsOn  = @("[xWaitForADDomain]DscForestWait","[xADOrganizationalUnit]$($RootOUs[-1])")
        }
    }
}