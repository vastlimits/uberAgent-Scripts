<#
  .SYNOPSIS
  uberAgent script to list all applied machine GPOs.

  .DESCRIPTION
  Creates a resultant set of policy (RSOP) for the computer via gpresult.exe, extracts the GPO names and converts the resulting output to the KV format required by uberAgent custom scripts.
#>

# We need a temporary XML file to store the data
$OutputFile = "C:\Windows\Temp\TempGPOExport.xml"

# If the file exists delete it
If (Test-Path $OutputFile)
{
   Remove-Item $OutputFile -Force
}

# Run gpresult and store the result in the temporary xml file
gpresult.exe /Scope Computer /X $OutputFile /F

# Read the xml file
[xml]$XML = Get-Content $OutputFile

# Get the names of all GPOs
$GPOs = ($XML.Rsop.ComputerResults.GPO).Name | Sort-Object

# Remove the temporary file
Remove-Item $OutputFile -Force

# Join all GPOs to a long string
$GPOs = $GPOs -join ';'

# Write the output. uberAgent will pick this up.
Write-Output "MachineGPOs=`"$GPOs`""