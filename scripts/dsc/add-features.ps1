configuration add-features 
{ 
    param 
    ( 
        [Parameter(Mandatory)]
        [String]$Features
    ) 

    $FeatureArray = $Features -Split ","
    Node localhost
    {
        LocalConfigurationManager {
            RebootNodeIfNeeded = $true
        }

        ForEach ($Feature in $FeatureArray)
        {
            WindowsFeature Features { 
                Ensure = "Present" 
                Name   = $Feature
                IncludeAllSubFeature = $true
            }
        }
    }
}