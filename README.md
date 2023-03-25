# Powershell-Scripts-and-Modules
Powershell 7 Scripts


1.) Ping-InParallel: Powershell Module that will ping a list of IP addresses from a txt file. Default path for ip address txt file is C:\temp\ip_addresses.txt. Use parameter **-IPListLocation** to change to the path of your choice. Results will output to terminal by default. Use the second parameter **-LogOutput** to define a log output file path to export the results in CSV. 

2.) VMWare/vRealizeOperations/Get-ServicesOnVMAndMonitorThemInVROPS.ps1: This script is intended to be ran on a Virtual Machine (Windows OS only) that is currently hosted on an ESXi host. The ESXi host of said Virtual Machine must be part of a vCenter, and additionally a vRealize Operations Cloud Proxy appliance must have deployed a Telegraf agent via the Web UI to this Virtual Machine already.

The script will beform the following:
- Ask for your username, password and the auth source (enter your vRealize Operations username and password here)
- The script will then find it's own Virtual Machine object resource ID on the Virtual Machine that the script is running on. It will match based on the property value: summary|smbiosUUID and compare that with the current serial number in the Windows Server OS 
-- I.E. Does summary|smbiosUUID equal wmic bios get serialNumber? Yes? Ok, return VM object resource ID.
- The script will then gather all the Windows Services that are set to Automatic (not delayed) on the current Windows VM it is on
- Finally, the script will then post to vROps, creating all the custom services under the Windows OS object but by using the Virtual Machine Object resource ID to do so. (See "/api/applications/agents/{id}/services" it only wants the Virtual Machine object resource ID, not the Windows OS ID)
