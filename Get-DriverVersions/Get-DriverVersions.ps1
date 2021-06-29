<#
  .SYNOPSIS
  uberAgent script to list all installed drivers.

  .DESCRIPTION
  Retrieves a list of all device drivers from WMI, excludes Microsoft drivers, and converts the resulting output to the KV format required by uberAgent custom scripts.
#>

$Output = @{}
$DriverPackages = $null

$DriverPackages = Get-WmiObject Win32_PnPSignedDriver | select devicename, driverversion, driverprovidername | where-object {$PSItem.driverprovidername -notlike "" -and $PSItem.driverprovidername -notlike "*Microsoft*"}

Foreach ($DriverPackage in $DriverPackages)
{
    # Do some formatting for Intel drivers as the vendor name is not consistent
    If ($DriverPackage.driverprovidername -like "*Intel*")
    {
        $DriverPackage.driverprovidername = "Intel"
    }
    $Output = @{
       'DeviceName' = "`"$($DriverPackage.devicename)`""
       'DriverVersion' = $DriverPackage.driverversion
       'DriverVendor' = "`"$($DriverPackage.driverprovidername)`""
    }
    Write-Output $($Output.Keys.ForEach({"$_=$($Output.$_)"}) -join ' ')
}