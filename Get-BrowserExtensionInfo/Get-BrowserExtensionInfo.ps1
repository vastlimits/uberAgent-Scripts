<#
  .SYNOPSIS
  uberAgent script to collect information about the installed browser extensions for the current user.

  .DESCRIPTION
  Parses the browser profiles on disk to retrieve information about installed extensions.
#>

#
# Global variables and types
#
enum Browser
{
   Chrome
   Edge
   Firefox
}

#
# Process a browser
#
function ProcessBrowser
{
   Param(
      [Parameter(Mandatory)][Browser] $browser
   )
   
   if ($browser -eq [Browser]::Chrome -or $browser -eq [Browser]::Edge)
   {
      # Chromium-based browsers

      # Get the user data directory. If it doesn't exist, we cannot proceed.
      $userDataPath = GetChromiumUserDataPath $browser
      if ($userDataPath -eq $null)
      {
         return
      }

      # Get user info about the profiles
      $profiles = GetProfilesChromium $userDataPath

      # Iterate over the profiles to get info on the extensions
      foreach ($profileDir in $profiles.keys)
      {
         $profilePath = $userDataPath + "\" + $profileDir

         # Check if the user profile directory exists
         if (-not (Test-Path $profilePath))
         {
            continue
         }

         # Get extension info...
         $extensionInfo = GetExtensionInfoFromProfileChromium $profilePath

         # ...and write it to stdout
         PrintExtensionInfo "$browser" $profileDir $profiles $extensionInfo
      }
   }
   elseif ($browser -eq [Browser]::Firefox)
   {
      # Firefox

      # Get the profiles' parent directory
      $profilesPath = GetFirefoxProfilesPath

      # Process each profile
      foreach ($profileDirObject in Get-ChildItem -Path $profilesPath -Directory)
      {
         # Get user info
         $profiles = GetProfileUserInfoFirefox $profileDirObject.Name $profileDirObject.FullName

         # Get extension info...
         $extensionInfo = GetExtensionInfoFromProfileFirefox $profileDirObject.FullName

         # ...and write it to stdout
         PrintExtensionInfo "$browser" $profileDirObject.Name $profiles $extensionInfo
      }
   }
   else
   {
      Write-Error "Invalid browser: $browser"
      return
   }
}

#
# Print collected extension info
#
function PrintExtensionInfo
{
   Param(
      [Parameter(Mandatory)][string] $browserName,
      [Parameter(Mandatory)][string] $profileDir,
      [Parameter(Mandatory)][hashtable] $profiles,
      [Parameter(Mandatory)][hashtable] $extensionInfo
   )

   # Field names
   $osUserNameField                    = "OsUser"
   $browserNameField                   = "Browser"
   $profileDirField                    = "ProfileDir"
   $profileNameField                   = "ProfileName"
   $profileGaiaNameField               = "ProfileGaiaName"
   $profileUserNameField               = "ProfileUserName"
   $extensionIdField                   = "ExtensionId"
   $extensionNameField                 = "ExtensionName"
   $extensionVersionField              = "ExtensionVersion"
   $extensionFromWebstoreField         = "ExtensionFromWebstore"
   $extensionInstalledByDefaultField   = "ExtensionInstalledByDefault"
   $extensionStateField                = "ExtensionState"
   $extensionInstallTimeField          = "ExtensionInstallTime"

   # Field data
   $userName         = GetUsername
   $profileName      = $profiles[$profileDir].profileName
   $profileGaiaName  = $profiles[$profileDir].gaiaName
   $profileUserName  = $profiles[$profileDir].userName

   # Process each extension
   foreach ($extensionId in $extensionInfo.keys)
   {
      $extensionName                = $extensionInfo[$extensionId].name
      $extensionVersion             = $extensionInfo[$extensionId].version
      $extensionFromWebstore        = $extensionInfo[$extensionId].fromWebstore
      $extensionInstalledByDefault  = $extensionInfo[$extensionId].installedByDefault
      $extensionState               = $extensionInfo[$extensionId].state
      $extensionInstallTime         = $extensionInfo[$extensionId].installTime

      $output = "$osUserNameField=`"$userName`" $browserNameField=`"$browserName`" $profileDirField=`"$profileDir`" $profileNameField=`"$profileName`" $profileGaiaNameField=`"$profileGaiaName`" $profileUserNameField=`"$profileUserName`" " + `
                "$extensionIdField=`"$extensionId`" $extensionNameField=`"$extensionName`" $extensionVersionField=`"$extensionVersion`" $extensionFromWebstoreField=`"$extensionFromWebstore`" $extensionStateField=`"$extensionState`" " + `
                "$extensionInstallTimeField=`"$extensionInstallTime`" $extensionInstalledByDefaultField=`"$extensionInstalledByDefault`""

      Write-Output $output
   }
}

#
# Get the username. Format:
#    1) Domain user: DOMAIN\USER
#    2) Local user:  USER
#
function GetUsername
{
   $computer = $Env:COMPUTERNAME
   $domain   = $Env:USERDOMAIN

   if ($domain -ne $computer)
   {
      return $domain + "\" + $env:USERNAME
   }
   else
   {
      return $env:USERNAME
   }
}

#
# Get extension JSON settings from a Chromium profile's (secure) preferences
#
function GetExtensionJsonFromPreferencesChromium
{
   Param(
      [Parameter(Mandatory)][string] $preferencesFile
   )

   # Check if the secure preferences file exists
   if (-not (Test-Path $preferencesFile -PathType Leaf))
   {
      return
   }

   # Read the preferences file & convert to JSON
   $preferencesJson = Get-Content -Path $preferencesFile -Encoding UTF8 | ConvertFrom-Json

   # The extensions are children of extensions > settings
   return $preferencesJson.extensions.settings
}

#
# Get extension JSON settings from a Firefox profile's preferences
#
function GetExtensionJsonFromPreferencesFirefox
{
   Param(
      [Parameter(Mandatory)][string] $preferencesFile
   )

   # Check if the secure preferences file exists
   if (-not (Test-Path $preferencesFile -PathType Leaf))
   {
      return
   }

   # Read the preferences file & convert to JSON
   $preferencesJson = Get-Content -Path $preferencesFile -Encoding UTF8 | ConvertFrom-Json

   # The extensions are children of extensions > settings
   return $preferencesJson.addons
}

#
# Get extension information from a Chromium-based profile
#
function GetExtensionInfoFromProfileChromium
{
   Param(
      [Parameter(Mandatory)][string] $profilePath
   )

   # Out variable
   $extensionsMap = @{}

   # Try to get extension info from secure preferences
   $extensionsJson = GetExtensionJsonFromPreferencesChromium ($profilePath + "\Secure Preferences")
   if ($extensionsJson -eq $null)
   {
      # Try regular preferences instead
      $extensionsJson = GetExtensionJsonFromPreferencesChromium ($profilePath + "\Preferences")
      if ($extensionsJson -eq $null)
      {
         return $extensionsMap
      }
   }

   # The extensions are children of extensions > settings
   $extensionIds   = $extensionsJson.psobject.properties.name

   # Extract properties of each extension
   foreach ($extensionId in $extensionIds)
   {
      # Ignore extensions installed by default (that also don't show up in the extensions UI)
      # $installedByDefault = $extensionsJson.$extensionId.was_installed_by_default
      # if ($installedByDefault -eq $true)
      # {
      #    continue
      # }

      # Ignore extensions located outside the user data directory (e.g., extensions that ship with the browser)
      # Location values seen:
      #    1: Profile (user data)
      #    5: Install directory (program files)
      #   10: Profile (user data) [not sure about the difference to 1]
      $location = $extensionsJson.$extensionId.location
      if ($location -eq 5)
      {
         continue
      }

      # Ignore extensions whose directory does not exist
      $extensionPath = $profilePath + "\Extensions\" + $extensionId
      if (-not (Test-Path $extensionPath))
      {
         continue
      }

      # Last install time
      $updateTimeMs = ConvertChromeTimestampToEpochMs $extensionsJson.$extensionId.install_time

      # Manifest
      $manifestJson = $extensionsJson.$extensionId.manifest
      if ($manifestJson -eq $null)
      {
         # Ignore entries without a manifest
         continue
      }
      $name    = $manifestJson.name
      $version = $manifestJson.version

      # Build a hashtable with the properties of this extension
      $extensionMap  =
      @{
         name                 = $name                                                  # Extension name
         version              = $version                                               # Extension version
         fromWebstore         = $extensionsJson.$extensionId.from_webstore             # Was the extension installed from the Chrome Web Store?
         installedByDefault   = $extensionsJson.$extensionId.was_installed_by_default  # Was the extension installed by default?
         state                = $extensionsJson.$extensionId.state                     # Extension state (1 = enabled)
         installTime          = $updateTimeMs                                          # Timestamp of the last installation (= update) as Unix epoch in ms
      }

      # Add this extension to the list of extensions
      $extensionsMap[$extensionId] = $extensionMap;
   }

   # Return the list of extensions
   return $extensionsMap
}

#
# Get extension information from a Firefox profile
#
function GetExtensionInfoFromProfileFirefox
{
   Param(
      [Parameter(Mandatory)][string] $profilePath
   )

   # Out variable
   $extensionsMap = @{}

   # Try to get extension info from extensions.json
   $extensionsJson = GetExtensionJsonFromPreferencesFirefox ($profilePath + "\extensions.json")
   if ($extensionsJson -eq $null)
   {
      return $extensionsMap
   }

   # Extract properties of each extension
   foreach ($extensionJson in $extensionsJson)
   {
      # Ignore addons outside the profile
      if ($extensionJson.location -ne "app-profile")
      {
         continue
      }
      # Ignore addons that are not extensions
      if ($extensionJson.type -ne "extension")
      {
         continue
      }

      # State (enabled/disabled)
      $state = "0"
      if ($extensionJson.active -eq $true)
      {
         $state = "1"
      }

      # Default locale
      $defaultLocale = $extensionJson.defaultLocale
      if ($defaultLocale -eq $null)
      {
         # Ignore entries without a manifest
         continue
      }
      $name = $defaultLocale.name

      # Installation source: Firefox Addons?
      # sourceURI must be https://addons.cdn.mozilla.net or https://addons.mozilla.org
      $fromFirefoxAddons = $false
      if ($extensionJson.sourceURI -match "^http(s)?://addons\.(cdn\.)?mozilla\.")
      {
         $fromFirefoxAddons = $true
      }

      # Build a hashtable with the properties of this extension
      $extensionMap  =
      @{
         name                 = $name                       # Extension name
         version              = $extensionJson.version      # Extension version
         fromWebstore         = $fromFirefoxAddons          # Was the extension installed from Firefox Addons?
         state                = $state                      # Extension state (1 = enabled)
         installTime          = $extensionJson.updateDate   # Last update timestamp as Unix epoch in ms
      }

      # Add this extension to the list of extensions
      $extensionsMap[$extensionJson.id] = $extensionMap;
   }

   # Return the list of extensions
   return $extensionsMap
}

#
# Convert a Chrome timestamp to Unix epoch milliseconds
#
#    Chrome time format: Windows FILETIME / 10 (microsecond intervals since 1601-01-01)
#
function ConvertChromeTimestampToEpochMs
{
   Param(
      [Parameter()][long] $chromeTimestamp
   )

   if ($chromeTimestamp -eq $null)
   {
      return
   }

   $filetime = $chromeTimestamp * 10
   $datetime = [datetime]::FromFileTime($filetime)
   return ([DateTimeOffset]$datetime).ToUnixTimeMilliseconds()
}

#
# Chrome: get the profiles (along with user info)
#
function GetProfilesChromium
{
   Param(
      [Parameter(Mandatory)][string] $userDataPath
   )

   # Out variable
   $profilesMap = @{}

   # Build the path to the local state file
   $localStatePath = $userDataPath + "\Local State"

   # Check if the local state file exists
   if (-not (Test-Path $localStatePath -PathType Leaf))
   {
      return $profilesMap
   }

   # Read the local state file & convert to JSON
   $localStateJson = Get-Content -Path $localStatePath -Encoding UTF8 | ConvertFrom-Json

   # The profiles are children of profile > info_cache
   $infoCacheJson = $localStateJson.profile.info_cache
   $profileDirs   = $infoCacheJson.psobject.properties.name

   # Extract properties of each profile
   foreach ($profileDir in $profileDirs)
   {
      # Build a hashtable with the properties of this profile
      $profileMap  =
      @{
         profileName = $infoCacheJson.$profileDir.name        # Name of the browser profile, e.g.: Person 1
         gaiaName    = $infoCacheJson.$profileDir.gaia_name   # Name of the profile's user, e.g.: John Doe
         userName    = $infoCacheJson.$profileDir.user_name   # Email of the profile's user, e.g.: john@domain.com
      }

      # Add this profile to the list of profiles
      $profilesMap[$profileDir] = $profileMap;
   }

   # Return the list of profiles
   return $profilesMap
}

#
# Firefox: get user info for a profile
#
function GetProfileUserInfoFirefox
{
   Param(
      [Parameter(Mandatory)][string] $profileDir,
      [Parameter(Mandatory)][string] $profilePath
   )

   # Out variables
   $userEmail = ""
   $profilesMap = @{}

   # Extract the profile name from the profile directory (everything after the first dot)
   $profileName = ""
   if ($profileDir -match "[^\.]+\.(.+)")
   {
      $profileName = $Matches[1]
   }

   # Build the path to the file signedInUser.json
   $signedInUserPath = $profilePath + "\signedInUser.json"

   # Check if the signedInUser.json file exists
   if (Test-Path $signedInUserPath -PathType Leaf)
   {
      # Read the signedInUser.json file & convert to JSON
      $signedInUserJson = Get-Content -Path $signedInUserPath -Encoding UTF8 | ConvertFrom-Json

      # User Info is in accountData
      $accountData = $signedInUserJson.accountData
      if ($accountData -ne $null)
      {
         $userEmail = $accountData.email
      }
   }

   # Build a hashtable with the properties of this profile
   $profileMap  =
   @{
      userName    = $userEmail         # Email of the profile's user, e.g.: john@domain.com
      profileName = $profileName       # Name of the browser profile, e.g.: Person 1
   }

   # Add this profile to the list of profiles
   $profilesMap[$profileDir] = $profileMap;

   # Return the list of profiles
   return $profilesMap
}

#
# Get the Chrome user data directory
#
function GetChromiumUserDataPath
{
   Param(
      [Parameter(Mandatory)][Browser] $browser
   )

   $userDataPath = ""
   
   # Build the path to the user data directory
   if ($browser -eq [Browser]::Chrome)
   {
      $userDataPath = $env:LOCALAPPDATA + "\Google\Chrome\User Data"
   }
   elseif ($browser -eq [Browser]::Edge)
   {
      $userDataPath = $env:LOCALAPPDATA + "\Microsoft\Edge\User Data"
   }
   else
   {
      Write-Error "Invalid browser: $browser"
      return
   }

   # Check if the Chrome data directory exists
   if (Test-Path $userDataPath)
   {
      return $userDataPath
   }
   else
   {
      return
   }
}

#
# Get the Firefox profiles directory
#
function GetFirefoxProfilesPath
{
   $profilesPath = ""
   
   # Build the path to the profiles directory
   $profilesPath = $env:APPDATA + "\Mozilla\Firefox\Profiles"

   # Check if the profiles directory exists
   if (Test-Path $profilesPath)
   {
      return $profilesPath
   }
   else
   {
      return
   }
}

#
# Script start
#
ProcessBrowser Chrome
ProcessBrowser Edge
ProcessBrowser Firefox
