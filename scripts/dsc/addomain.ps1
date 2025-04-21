configuration addomain 
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
            RetryCount           = "20"
            RetryIntervalSec     = "30"
            DependsOn            = "[xADDomain]FirstDS"
        }

        Script Config
        {
            SetScript  = {
                Invoke-WebRequest "$using:ConfigScript" -UseBasicParsing -Outfile "C:\Temp\ad.ps1"
                C:\Temp\ad.ps1 -DomainCreds $DomainCreds -DomainRoot $DomainRoot -DefaultUsername $Admincreds.UserName -DomainName $DomainName
            }
            GetScript  = { @{} }
            TestScript = { $false }
            DependsOn  = @("[xWaitForADDomain]DscForestWait")
        }
    }       
}