# Get-ProcessorTemperature: Determine the Current CPU Temperature

This script is part of the uberAgent practice guide [Collecting the Processor Temperature With uberAgent](https://uberagent.com/docs/uberagent/latest/practice-guides/collect-processor-temperature-with-uberagent/).

## Description

This script reads the current CPU temperature from WMI and converts the resulting output to the KV format required by uberAgent custom scripts.

## How to Run This Script

### Script Execution

- **Context** (per machine or per user): machine
- **Elevation** (admin rights): no (yes when switching to the alternative WMI class)

### Supported Operating Systems

- Should work on:
  - Windows 7 or newer
- Tested on:
  - Windows 10 20H2

### Requirements

- PowerShell 3.0
