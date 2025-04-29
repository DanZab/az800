configuration add-features 
{ 
    param 
    ( 
        [Parameter(Mandatory)]
        [array]$Features
    ) 

    Node localhost
    {
        LocalConfigurationManager {
            RebootNodeIfNeeded = $true
        }

        ForEach ($Feature in $Features)
        {
            WindowsFeature Features { 
                Ensure = "Present" 
                Name   = $Feature
                IncludeAllSubFeature = $true
            }
        }
    }
}