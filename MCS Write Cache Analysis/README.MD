# MCS Write Cache Analysis with uberAgent

## Description

Machine Creation Services (MCS) Storage Optimization (MCSIO) is a great feature to boost the performance by moving storage operations from shared storage to a local cache disk. Sizing the cache correctly is crucial for performance and cost and uberAgent is the perfect tool to help you achieve both.

The folder contains a script and a corresponding Splunk dashboard.

## How to Run `Analyze_Drive`

### Script Execution

- **Context** (per machine or per user): machine
- **Elevation** (admin rights): yes

### Supported Operating Systems

- Should work on:
  - Windows 7 or newer
- Tested on:
  - Windows 11

### Requirements

No specific requirements.

## How to Import `Dashboard.json`

- Create a new dashboard in Splunk's dashboard studio
- Clear the present dashboard's `json` code and paste the content of `Dashboard.json`
- Save the dashboard

### Requirements

- Splunk >= 9.0
