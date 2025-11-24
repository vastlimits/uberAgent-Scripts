# Get-TpmtoolAsKv: Collect TPM Status Information

This script is part of the uberAgent practice guide [Creating a TPM Status Inventory Report](https://docs.citrix.com/en-us/uberagent/current-release/practice-guides/creating-a-tpm-status-inventory-report).

## Description

This script runs the command `tpmtool.exe getdeviceinformation` and converts the output to the KV format required by uberAgent custom scripts.

## How to Run This Script

### Script Execution

- **Context** (per machine or per user): machine
- **Elevation** (admin rights): no

### Supported Operating Systems

- Should work on:
  - Windows 8 or newer
  - Windows Server 2012 or newer
- Tested on:
  - Windows 10 2004
  - Windows 10 20H2

### Requirements

- `tpmtool.exe` ([Microsoft documentation](https://docs.microsoft.com/en-us/windows-server/administration/windows-commands/tpmtool))
