<#
  .SYNOPSIS
  uberAgent script to query the event log for events with a specific event ID.

  .DESCRIPTION
  Queries an event log channel for events with a specific ID in the past n milliseconds. It is intended to be run periodically every n milliseconds.
#>

PARAM
(
    [Parameter(Mandatory = $true)]
    [System.Int32]$EventID,
    
    [Parameter(Mandatory = $true)]
    [System.String]$EventLog,
    
    [Parameter(Mandatory = $true)]
    [System.Int32]$IntervalMS
)

$IntervalMS = -$IntervalMS

$StartTime=$(get-date).AddMilliseconds($IntervalMS)

$Filter= @{
    LogName="$EventLog"
    StartTime=$StartTime
    Id=$EventID
}

$Events = Get-WinEvent -FilterHashtable $Filter -ErrorAction SilentlyContinue

if (@($Events).Count -gt 0)
{
    foreach ($Event in $Events)
    {
        [Hashtable]$Output = @{
            'ProviderName' = "`"$($Event.ProviderName)`""
            'Id' = $Event.id
            'LevelDisplayName' = $Event.LevelDisplayName
            'LogName' = $Event.LogName
            'Message' = "`"$($Event.Message)`""
            'TimeCreated' = "`"$($Event.TimeCreated)`""
            'TaskDisplayName' = "`"$($Event.TaskDisplayName)`""
        }
        Write-Output $($Output.keys.foreach({"$_=$($Output.$_)"}) -join ' ')
        
    }
}