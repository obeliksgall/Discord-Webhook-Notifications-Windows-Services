# Lista monitorowanych uslug i ich opisowe nazwy
$services = @{
    "W32Time" = "Usluga czasu systemu Windows"
    "Spooler" = "Bufor wydruku"
    "wuauserv" = "Usluga Windows Update"
}
$sentAlerts = @{}
$webhookUrl = ""
$computerName = $env:COMPUTERNAME
$serviceStatus = @{}  # Hash table do sledzenia poprzednich statusów uslug

function Send-DiscordNotification($service, $serviceFriendlyName, $statusType) {
    $currentTime = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $alertColor = if ($statusType -eq "uruchomiona") { 65280 } else { 16711680 }  # Zielony dla uruchomionej, czerwony dla zatrzymanej
    $alertTitle = if ($statusType -eq "uruchomiona") { "Usluga uruchomiona: $serviceFriendlyName" } else { "Usluga zatrzymana: $serviceFriendlyName" }
	$data = Get-Date -Format "yyyy-MM-dd HH:mm:ss" # Get current date and time

    $Body = @{
        "username" = "System Monitor - $computerName - $data"
        "content" = ""  # Discord wymaga tego pola, nawet jesli puste
        "tts" = $false
        "embeds" = @(
            @{
                "color" = $alertColor
                "title" = $alertTitle
                "fields" = @(
                    @{ "name" = "Data i godzina"; "value" = "$currentTime"; "inline" = $false },
                    @{ "name" = "Nazwa komputera"; "value" = "$computerName"; "inline" = $false },
                    @{ "name" = "Nazwa uslugi"; "value" = "$serviceFriendlyName ($service)"; "inline" = $false }
                )
                "footer" = @{
                    "text" = "Dzisiaj: $currentTime`nSystem Monitor`nWyslano z: $computerName"
                }
            }
        )
    }

    # Konwersja JSON do UTF-8 (zapobiega bledom Discord 50109)
    $BodyJson = $Body | ConvertTo-Json -Depth 10
    $BodyBytes = [System.Text.Encoding]::UTF8.GetBytes($BodyJson)

    try {
        Invoke-RestMethod -Uri $webhookUrl -Method 'Post' -Body $BodyBytes -ContentType 'application/json'
        Write-Host "Powiadomienie wyslane do Discord o usludze: $serviceFriendlyName ($service) - Status: $statusType"
    } catch {
        Write-Host "Blad wysylania powiadomienia do Discord: $_"
    }

    $sentAlerts[$service] = $true
}

while ($true) {
    foreach ($service in $services.Keys) {
        $status = Get-Service -Name $service -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Status
        $friendlyName = $services[$service]

        # Jesli usluga jest ZATRZYMANA i wczesniej byla dzialajaca -> wysylamy alert
        if ($status -ne "Running") {
            if (-not $sentAlerts.ContainsKey($service)) {
                Send-DiscordNotification $service $friendlyName "zatrzymana"
                Write-Host "Wysylam powiadomienie o usludze $friendlyName ($service) - ZATRZYMANA"
            }
            $serviceStatus[$service] = "Stopped"
        } 
        # Jesli usluga jest URUCHOMIONA i wczesniej byla zatrzymana -> wysylamy alert o przywróceniu
        elseif ($status -eq "Running" -and $serviceStatus[$service] -eq "Stopped") {
            Send-DiscordNotification $service $friendlyName "uruchomiona"
            Write-Host "Wysylam powiadomienie o usludze $friendlyName ($service) - PONOWNIE URUCHOMIONA"
            $sentAlerts.Remove($service)
            $serviceStatus[$service] = "Running"
        } 
        else {
            Write-Host "Brak zmian w statusie uslugi: $friendlyName ($service)"
        }
    }
    Start-Sleep -Seconds 60
}