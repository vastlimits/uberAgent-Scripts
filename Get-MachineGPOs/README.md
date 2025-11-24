# Get-MachineGPOs: List All Applied Machine GPOs

This script is part of the uberAgent practice guide [Documenting Applied Computer GPOs](https://docs.citrix.com/en-us/uberagent/current-release/practice-guides/documenting-applied-computer-gpos).

## Description

This script creates a resultant set of policy (RSOP) for the computer via gpresult.exe, extracts the GPO names and converts the resulting output to the KV format required by uberAgent custom scripts.

## How to Run This Script

### Script Execution

- **Context** (per machine or per user): machine
- **Elevation** (admin rights): yes

### Supported Operating Systems

- Should work on:
  - Windows 7 or newer
- Tested on:
  - Windows 10 20H2

### Requirements

- `gpresult.exe`
