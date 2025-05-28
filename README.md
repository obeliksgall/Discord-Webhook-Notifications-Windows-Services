# Discord-Webhook-Notifications-Windows-Services

**REMEMBER TO ENTER YOUR WEBHOOK ADDRESS AT THE BEGINNING OF THE SCRIPT - $webhookUrl = "" **

A PowerShell script that can be run as a Windows service via nssm.
Used to send notifications to the Discord webhook if a Windows service is stopped or started.

![Zrzut ekranu 2025-05-28 233339](https://github.com/user-attachments/assets/49bd14d0-033b-4cfb-af81-4141746d8f77)

The services section is - on the left the name of the service, on the right its displayed name:
$services = @{

    "W32Time" = "Usluga czasu systemu Windows"
    
    "Spooler" = "Bufor wydruku"
    
    "wuauserv" = "Usluga Windows Update"
    
}


The time at which the service is checked can be found at the end of the script (default 60 seconds):
Start-Sleep -Seconds 60
