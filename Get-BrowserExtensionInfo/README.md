# Get-BrowserExtensionInfo: Collect Information About the Installed Browser Extensions

This script is part of the uberAgent practice guide [Building a Browser Extension Inventory Report](https://uberagent.com/docs/uberagent/latest/practice-guides/building-a-browser-extension-inventory-report/).

## Description

This script is intended to be executed per user session. For each supported browser (see below), it determines the profile directories and extracts information about installed browser extensions from each profile.

## Splunk App

The subdirectory `Splunk app` contains a Splunk app that visualizes the data collected by the script. Copy the entire contents of the `Splunk app` directory to the `apps` directory of your Splunk search head(s).

## How to Run This Script

### Script Execution

- **Context** (per machine or per user): user
- **Elevation** (admin rights): no

### Supported Operating Systems

- Should work on:
  - Windows 7 or newer
- Tested on:
  - Windows 10 20H2

### Supported Browsers

- Google Chrome
- Microsoft Edge

### Requirements

No specific requirements.
