function Test-AzureAdJoined {
   $output = & dsregcmd /status

   # Check if the output contains "AzureAdJoined : YES"
   return $output -match "AzureAdJoined\s+:\s+YES"
}

$AzureAdJoined = 0

$joinedToAzureAd = Test-AzureAdJoined

if ($joinedToAzureAd) {
   $AzureAdJoined = 1
}

# Build the output hash
$Output = @{
   'AzureAdJoined' = $AzureAdJoined
}

# Finally, write the hash to stdout. The output will be picked up by uberAgent.
Write-Output $($Output.Keys.ForEach({"$_=$($Output.$_)"}) -join ' ')
