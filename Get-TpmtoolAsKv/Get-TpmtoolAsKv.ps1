<#
  .SYNOPSIS
  uberAgent script to collect TPM status information.

  .DESCRIPTION
  Runs the command "tpmtool.exe getdeviceinformation" and converts the output to the KV format required by uberAgent custom scripts.
#>

# Run tpmtool
$tpmtoolOutput = @(tpmtool getdeviceinformation)

# We'll store the output fields here
$output = @{}

foreach ($line in $tpmtoolOutput)
{
   # Ignore empty lines
   if (!$line) { continue }

   # Remove the leading dash
   $line = $line -replace "^-", ""

   # Split at the colon
   $kv = $line.Split(":")

   if ($kv.Count -ne 2) { continue }

   # Remove the leading space in the value
   $kv[1] = $kv[1] -replace "^\s+", ""

   # Ignore certain fields
   if ($kv[0] -like "*spec version*" -or $kv[0] -like "*errata date*") { continue }

   # Remove spaces in the key name
   $kv[0] = $kv[0] -replace "\s+", ""

   # Add the field to the output hashtable
   $output.Add($kv[0], "`"$($kv[1])`"")
}

# Write the KV output to the console so uberAgent can pick it up
Write-Output $($output.Keys.ForEach({"$_=$($output.$_)"}) -join ' ')