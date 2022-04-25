<#
  .SYNOPSIS
  Find and optionally start services that are set to automatic startup, but are currently in a stopped state.
#>


# Exclude irrelevant services from monitoring
$ExcludedServices = "uberagentsvc|edgeupdate|gpupdate|gpsvc|sppsvc|gupdate" # add more services as you which divided by a pipe --> | 

Get-Service | Where-Object { "$($_.Name)" -notmatch $ExcludedServices } | ForEach-Object -Process {
   # Get all services with start type 'automatic' and without a trigger. More info: https://mikefrobbins.com/2015/12/24/use-powershell-to-determine-services-with-a-starttype-of-automatic-or-manual-with-trigger-start/
   If (($_.StartType -eq 'Automatic') -and (-NOT (Test-Path -Path "HKLM:\SYSTEM\CurrentControlSet\Services\$($_.Name)\TriggerInfo\"))) {
      # Include only stopped services
      If ($_.Status -eq 'Stopped') {
         # Start-Service -Name "$($_.Name)" | Out-Null # Uncomment the line to automatically start the service
         Write-Output "Name=`"$($_.Name)`" DisplayName=`"$($_.DisplayName)`""
      }
   }
}
