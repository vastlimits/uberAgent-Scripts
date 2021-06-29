<#
  .SYNOPSIS
  uberAgent script to determine the current CPU temperature.

  .DESCRIPTION
  Reads the current CPU temperature from WMI and converts the resulting output to the KV format required by uberAgent custom scripts.

  If the default WMI class does not yield satisfactory resulty, try switching to the alternative data source by commenting out the relevant lines.

  Most machines have multiple thermal zones. Test with your PCs and enter the name of the appropriate thermal zone in the variable $thermalZone.
  To retrieve a list of all thermal zones run either of the following:
  - Get-CimInstance -ClassName Win32_PerfFormattedData_Counters_ThermalZoneInformation
  - Get-CimInstance -ClassName MSAcpi_ThermalZoneTemperature -Namespace "root/wmi"
#>

# Thermal zone (wildcard string)
$thermalZone = "*tz00*"

# Default: get the CPU temperature from the WMI class Win32_PerfFormattedData_Counters_ThermalZoneInformation
$temp = Get-CimInstance -ClassName Win32_PerfFormattedData_Counters_ThermalZoneInformation | Where-Object -Property Name -like $thermalZone
$TempKelvin     = $temp.Temperature

# Alternative: get the CPU temperature from the WMI class MSAcpi_ThermalZoneTemperature
# Note: requires elevation (admin rights)
# $temp = Get-CimInstance -ClassName MSAcpi_ThermalZoneTemperature -Namespace "root/wmi" | Where-Object -Property InstanceName -like $thermalZone
# $TempKelvin     = $temp.Temperature / 10

$TempKelvin     = $temp.Temperature
$TempCelsius    = $TempKelvin - 273.15
$TempFahrenheit = (9/5) * $TempCelsius + 32

$Output = @{
   # delete rows which are not needed
   'TempCelsius' = [math]::Round($TempCelsius)
   'TempFahrenheit' = [math]::Round($TempFahrenheit)
   'TempKelvin' = [math]::Round($TempKelvin)
}
Write-Output $($Output.Keys.ForEach({"$_=$($Output.$_)"}) -join ' ')
