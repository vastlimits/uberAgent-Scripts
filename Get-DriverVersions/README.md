# Get-DriverVersions: List All Installed Drivers

This script is part of the uberAgent practice guide [Generating Driver Version Inventory Reports](https://uberagent.com/docs/uberagent/latest/practice-guides/generating-driver-version-inventory-reports/).

## Description

This script retrieves a list of all device drivers from WMI, excludes Microsoft drivers, and converts the resulting output to the KV format required by uberAgent custom scripts.

## How to Run This Script

### Script Execution

- **Context** (per machine or per user): machine
- **Elevation** (admin rights): no

### Supported Operating Systems

- Should work on:
  - Windows 7 or newer
- Tested on:
  - Windows 10 20H2

### Requirements

- PowerShell 3.0
