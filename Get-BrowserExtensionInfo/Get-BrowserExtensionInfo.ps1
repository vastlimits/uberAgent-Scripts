<#
  .SYNOPSIS
  uberAgent script to collect information about the installed browser extensions for the current user.

  .DESCRIPTION
  Parses the browser profiles on disk to retrieve information about installed extensions.
#>

#
# Chrome
#
function ProcessChrome
{
   # Get the user data directory. If it doesn't exist, we cannot proceed.
   $userDataPath = GetChromeUserDataPath
   if ($userDataPath -eq $null)
   {
      return
   }

   # Get info on the profiles
   $profiles = GetChromeProfiles $userDataPath

   # Iterate over the profiles to get info on the extensions
   foreach ($profileDir in $profiles.keys)
   {
      $profilePath = $userDataPath + "\" + $profileDir

      # Check if the user profile directory exists
      if (-not (Test-Path $profilePath))
      {
         continue
      }

      # Get extension info
      $extensionInfo = GetExtensionInfoFromProfile $profilePath
   }
}

#
# Get extension information from a profile
#
function GetExtensionInfoFromProfile
{
   Param(
      [Parameter(Mandatory)][string] $profilePath
   )

   # Out variable
   $extensionsMap = @{}

   # Build the path to the secure preferences file
   $securePreferencesPath = $profilePath + "\Secure Preferences"

   # Check if the secure preferences file exists
   if (-not (Test-Path $securePreferencesPath -PathType Leaf))
   {
      return $extensionsMap
   }

   # Read the secure preferences file & convert to JSON
   $securePreferencesJson = Get-Content $securePreferencesPath | ConvertFrom-Json

   # The extensions are children of extensions > settings
   $extensionsJson = $securePreferencesJson.extensions.settings
   $extensionIds   = $extensionsJson.psobject.properties.name

   # Extract properties of each extension
   foreach ($extensionId in $extensionIds)
   {
      #
      # Get properties of the extension
      #

      # Part of Chrome, not removable?
      $installedByDefault = $extensionsJson.$extensionId.was_installed_by_default
      if ($installedByDefault -ne $false)
      {
         # This also gets rid of entries where was_installed_by_default does not exist
         continue
      }

      # Install time
      $installTimeMs = ConvertChromeTimestampToEpochMs $extensionsJson.$extensionId.install_time

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
         name         = $name                                              # Extension name
         version      = $version                                           # Extension version
         fromWebstore = $extensionsJson.$extensionId.from_webstore         # Was the extension installed from the Chrome Web Store?
         state        = $extensionsJson.$extensionId.state                 # Extension state (1 = enabled)
         installTime  = $installTimeMs                                     # Installation timestamp as Unix epoch in ms
      }

      # Add this extension to the list of extensions
      $extensionsMap[$extensionId] = $extensionMap;
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
# Get the Chrome profiles
#
function GetChromeProfiles
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
   $localStateJson = Get-Content $localStatePath | ConvertFrom-Json

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
# Get the Chrome user data directory
#
function GetChromeUserDataPath
{
   # Build the path to the user data directory
   $userDataPath = $env:LOCALAPPDATA + "\Google\Chrome\User Data"

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
# Script start
#
ProcessChrome
