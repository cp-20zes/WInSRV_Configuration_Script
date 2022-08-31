# Script d'installation complet Windows Server 2019 fait le 29.08.2022 en pratique

workflow Installation_WinSRV {
    
    Write-Host "Installation automatique de Windows Server"

    # Adresse IP statique --> OK
    [string]$choixIP = Read-Host -Prompt "Voulez-vous attribuer une adresse IP fixe ? (Y/n)"
    if ($choixIP -eq '' -or $choixIP -eq 'y' -or $choixIP -eq 'Y') {
        Get-NetIPInterface
        [int]$choixInterface = Read-Host -Prompt "`nQuelle interface voulez-vous ?"
        [string]$adresseIP = Read-Host -Prompt "Entrez l'adresse IP"
        [int]$prefix = Read-Host -Prompt "Entrez le préfix CIDR"
        [string]$gateway = Read-Host -Prompt "Entrez la passerelle par défaut"
        New-NetIPAddress -InterfaceIndex $choixInterface -IPAddress $adresseIP -PrefixLength $prefix -DefaultGateway $gateway

        [string]$mainDNS = Read-Host -Prompt "Entrez l'adresse DNS préférée"
        [string]$secondDNS = Read-Host -Prompt "Entrez l'adresse DNS secondaire"
        Set-DnsClientServerAddress -InterfaceIndex $choixInterface -ServerAddresses ($mainDNS, $secondDNS)
    } else {
        Write-Host "OK... Pas de changements"
    }

    Write-Host "`n-------------------------------------`n"

    # Installation de l'Active Directory --> ~Ok
    [string]$choixDC = Read-Host -Prompt "Voulez-vous mettre en place un contrôleur de domaine ? (Y/n)"
    if ($choixDC -eq '' -or $choixDC -eq 'y' -or $choixDC -eq 'Y') {

        $avecToolsDC = Read-Host -Prompt "Voulez-vous les outils de managements ? (Y/n)"

        if ($avecToolsDC -eq '' -or $avecToolsDC -eq 'y' -or $avecToolsDC -eq 'Y') {
            Add-WindowsFeature AD-Domain-Services -IncludeManagementTools
        } else {
            Add-WindowsFeature AD-Domain-Services
        }

    } else {
        Write-Host "OK... Pas de changements"
    }

    Write-Host "`n-------------------------------------`n"

    # Création d'une nouvelle fôret --> OK mais script continue pas après restart
    [string]$choixDC2 = Read-Host -Prompt "Voulez-vous créer une nouvelle fôret ? (Y/n)"
    if ($choixDC2 -eq '' -or $choixDC2 -eq 'y' -or $choixDC2 -eq 'Y') {

        [string]$nomDeDomaine = Read-Host -Prompt "`nEntrez le nom de domaine"
        Install-ADDSForest -DomainName $nomDeDomaine -InstallDNS

    }

    Restart-Computer -Wait -Force

    # DNS
    [string]$choixDNS = Read-Host -Prompt "Voulez-vous configurer le DNS ? (Y/n)"
    if ($choixDNS -eq '' -or $choixDNS -eq 'y' -or $choixDNS -eq 'Y') {
        
        [string]$networkID = Read-Host -Prompt "Entrez l'adresse de la zone inverse (x.x.x.0/x)"
        Add-DnsServerPrimaryZone -NetworkId $networkID -ReplicationScope Domain

        Write-Host "`nCréation du PTR Record`n"

        Get-DnsServerZone
        [string]$dnsServerZone = Read-Host -Prompt "Quelle zone DNS voulez-vous choisir ?"

        Get-DnsServerResourceRecord -ZoneName $dnsServerZone
        [string]$record = Read-Host -Prompt "`nQuelle record voulez-vous choisir ? (NS)"

        [string]$name = Read-Host -Prompt "`nEntrez le nom (peut être le dernier octet de l'IP)"
        [string]$zoneName = Read-Host -Prompt "`nEntrez le le nom de la zone ex. 5.168.192.in-addr-arpa"

        add-DnsServerResourceRecordPtr -Name $name -ZoneName $zoneName -PtrDomainName $record

    } else {
        Write-Host "OK... Pas de changements"
    }

    Write-Host "`n-------------------------------------`n"

    # DHCP
    [string]$choixDHCP = Read-Host -Prompt "Voulez-vous configurer le DHCP ? (Y/n)"
    if ($choixDHCP -eq '' -or $choixDHCP -eq 'y' -or $choixDHCP -eq 'Y') {
        
        $avecToolsDHCP = Read-Host -Prompt "Voulez-vous les outils de managements ? (Y/n)"
        if ($avecToolsDHCP -eq '' -or $avecToolsDHCP -eq 'y' -or $avecToolsDHCP -eq 'Y') {
            Add-WindowsFeature DHCP -IncludeManagementTools
        } else {
            Add-WindowsFeature DHCP
        }
        
        [string]$scopeName = Read-Host -Prompt "Entrez le nom de la scope"
        [ipaddress]$startRange = Read-Host -Prompt "Entrez le début de la plage"
        [ipaddress]$endRange = Read-Host -Prompt "Entrez la fin de la plage"
        [ipaddress]$subnetmask = Read-Host -Prompt "Entrez le masque"
        [ipaddress]$dnsServerAddr = Read-Host -Prompt "Entrez l'adresse du DNS"
        [ipaddress]$routerAddr = Read-Host -Prompt "Entrez l'adresse du routeur"

        Add-DhcpServerv4Scope -Name $scopeName -StartRange $startRange -EndRange $endRange -SubnetMask $subnetmask
        Set-DhcpServerv4OptionValue -DnsServer $dnsServerAddr -Router $routerAddr

    } else {
        Write-Host "OK... Pas de changements"
    }
    
}

