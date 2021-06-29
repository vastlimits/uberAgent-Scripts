<#
  .SYNOPSIS
  uberAgent script to collect information about signal quality and security of WiFi networks (DE).

  .DESCRIPTION
  Retrieves detailed information about the current WiFi connection, including signal strength, receive and transmit rates, and authentication type.

  This version of the script works on German versions of Windows.
#>

$interface = @(netsh wlan show interface)
$hash = $null

# We only support machines with one interface for now. The following line also makes sure that the scripts only proceed if a WiFi interface is found at all.
If ($interface -match 'Es ist 1 Schnittstelle auf dem System vorhanden')
{
    # The following builds a hash table from the netsh output
    foreach($item in $interface)
    {
        if($item.Contains(':'))
        {
            $hash += @{            
                $item.Replace(" ","").split('{:}')[0] = $item.Replace(" ","").split('{:}')[1]
            } 
        }
    }
    
    # Only connected interfaces are interesting
    If ($hash.Status -eq 'Verbunden')
    {
        # Get the WiFi band by looking at the used channel
        If ([int]$hash.Kanal -gt 33)
        {
            $Band = '5'
        }
        Else
        {
            $Band = '2.4'
        }

        # Build the output hash
        $Output = @{
           'Signal' = $hash.Signal -replace '%',''
           'Type' = $hash.Funktyp
           'Receiverate' = $hash.'Empfangsrate(MBit/s)'
           'Transmitrate' = $hash.'Übertragungsrate(MBit/s)'
           'Band' = $Band
           'SSID' = "`"$($hash.SSID)`""
           'Authentication' = $hash.Authentifizierung
           'Cipher' = $hash.Verschlüsselung
        }
        
        # Finally, write the hash to stdout. The output will be picked up by uberAgent.
        Write-Output $($Output.Keys.ForEach({"$_=$($Output.$_)"}) -join ' ')
    
    }
    Else
    {
        Throw "Interface $($hash.Name) not connected. Exiting..."
    }
}
Else
{
    Throw 'Zero or more than one interface on machine. Exiting...'
}