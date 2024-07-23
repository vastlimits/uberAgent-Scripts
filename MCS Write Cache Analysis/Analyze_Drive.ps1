#region functions
function Send-ToSplunk {
   param (
      $Item,
      $Size
   )
   $Output = @{
      'Item' = "`"$Item`""
      'SizeMB' = "$Size"
   }
   Write-Output $($Output.Keys.ForEach({"$_=$($Output.$_)"}) -join ' ')
}
#endregion functions

#region variables
# add the drives you want to check
$Drives = @("D:\","E:\")

# exclude files and folders which should not be monitored
$Exclude = @('System Volume Information', '$RECYCLE.BIN')

#endregion variables

#region main

foreach ($Drive in $Drives)
{

    try {Push-Location $Drive -ErrorAction Stop}
    catch {continue}

    $items = Get-ChildItem -Force
    foreach ($item in $items)
    {
       if ($item.name -in $Exclude) {continue}
       $null = $Size
       if ($item.PSIsContainer)
       {
          $Size = [math]::Round((Get-ChildItem -Path $item.FullName -Recurse -Force -erroraction silentlycontinue | Measure-Object -Property Length -Sum -erroraction silentlycontinue).Sum / 1MB,0)

       }
       else
       {
          $Size = [math]::Round(($item | Measure-Object -Property Length -Sum).Sum / 1MB,0)

       }
       if ($null -ne $Size)
       {
           Send-ToSplunk -Item $item.FullName -Size $Size
       }
    }

    Pop-Location
}
#endregion main
