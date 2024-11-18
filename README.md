# Salesforce Data Export Script

## Description
This project is a `Bash` script designed to automate the process of exporting data from all or specified Salesforce objects using the Salesforce CLI (`sf`) and `jq` for JSON parsing. 

## What It Does
- Retrieves a list of all standard and custom Salesforce objects or allows you to specify objects manually.
- Describes each object and identifies fields to exclude compound fields.
- Exports data from Salesforce objects in CSV format using bulk query mode.
- Saves the exported data in a specified directory (`./exports`).

## Prerequisites
- **Salesforce CLI (`sf`)**: Ensure you have the Salesforce CLI installed and authenticated.
- **`jq`**: A lightweight and powerful command-line JSON processor. Install it using:
  - macOS: `brew install jq`
  - Linux: `sudo apt-get install jq`

## Usage
### Basic Syntax
```bash
./sf-export.sh <username or alias> [sObject1 sObject2 ...]
