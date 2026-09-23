$ErrorActionPreference = "Stop"


function Stop-Instalacao {
    param([string]$Mensagem)

    Write-Host ""
    Write-Host "============================================================" -ForegroundColor Red
    Write-Host " INSTALACAO INTERROMPIDA" -ForegroundColor Red
    Write-Host "============================================================" -ForegroundColor Red
    Write-Host ""
    Write-Host $Mensagem -ForegroundColor Red
    Write-Host ""

    Read-Host "Pressione ENTER para sair"
    exit 1
}

function Test-PrinterDriverInstalled {
    param([string]$DriverName)

    try {
        $Driver = Get-PrinterDriver -Name $DriverName -ErrorAction SilentlyContinue

        if ($null -ne $Driver) {
            return $true
        }

        return $false
    }
    catch {
        return $false
    }
}


function Install-DriverFromInf {
    param(
        [string]$Fabricante,
        [string]$DriverFolder,
        [string]$DriverName
    )

    Write-Host ""
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host " INSTALACAO DO DRIVER VIA INF" -ForegroundColor Cyan
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host ""

    Write-Host "Fabricante : $Fabricante"
    Write-Host "Driver     : $DriverName"
    Write-Host ""

    $FabricanteUpper = $Fabricante.ToUpper()
    $InfName = $null

    if ($FabricanteUpper -eq "RICOH") {

        if ($DriverFolder -match "SP377") {
            $InfName = "RXE6E.INF"
        }
        elseif ($DriverFolder -match "M320F") {
            $InfName = "GXE6T.INF"
        }
    }
    elseif ($FabricanteUpper -eq "BROTHER") {

        if ($DriverFolder -match "DCP-L2540DW") {
            $InfName = "BRPRM13A.INF"
        }
    }

    if ([string]::IsNullOrWhiteSpace($InfName)) {

        Write-Host "[*] Modelo nao identificado automaticamente." -ForegroundColor Yellow
        Write-Host "[*] Procurando arquivo INF..." -ForegroundColor Cyan
        Write-Host ""

        $InfFiles = @(Get-ChildItem -LiteralPath $DriverFolder -Filter "*.inf" -Recurse -File -ErrorAction SilentlyContinue)

        if ($InfFiles.Count -eq 1) {

            $InfName = $InfFiles[0].Name

            Write-Host "[OK] INF encontrado automaticamente." -ForegroundColor Green
        }
        elseif ($InfFiles.Count -gt 1) {

            Write-Host "[ERRO] Foram encontrados varios arquivos INF." -ForegroundColor Red

            foreach ($InfFile in $InfFiles) {
                Write-Host "    $($InfFile.Name)" -ForegroundColor DarkGray
            }

            return $false
        }
        else {

            Write-Host "[ERRO] Nenhum arquivo INF encontrado." -ForegroundColor Red

            return $false
        }
    }

    $InfPath = Join-Path $DriverFolder $InfName

    if (-not (Test-Path -LiteralPath $InfPath)) {

        $InfSearch = @(Get-ChildItem -LiteralPath $DriverFolder -Filter $InfName -Recurse -File -ErrorAction SilentlyContinue)

        if ($InfSearch.Count -gt 0) {
            $InfPath = $InfSearch[0].FullName
        }
    }

    if (-not (Test-Path -LiteralPath $InfPath)) {

        Write-Host ""
        Write-Host "[ERRO] O INF esperado nao foi encontrado." -ForegroundColor Red

        return $false
    }

    Write-Host "[OK] Arquivo INF localizado." -ForegroundColor Green
    Write-Host ""

    $PnpUtilPath = Join-Path $env:WINDIR "System32\pnputil.exe"

    if (-not (Test-Path -LiteralPath $PnpUtilPath)) {

        Write-Host ""
        Write-Host "[ERRO] PnPUtil nao encontrado." -ForegroundColor Red

        return $false
    }

    Write-Host "[*] Adicionando pacote ao Driver Store..." -ForegroundColor Cyan
    Write-Host ""

    try {

        $PnpOutput = @(
            & $PnpUtilPath "/add-driver" $InfPath "/subdirs" "/install" 2>&1
        )

        $PnpExitCode = $LASTEXITCODE

        Write-Host ""
        Write-Host "[*] Codigo PnPUtil: $PnpExitCode" -ForegroundColor Cyan

        if ($PnpExitCode -ne 0) {

            Write-Host ""
            Write-Host "[ERRO] O PnPUtil retornou um codigo de erro." -ForegroundColor Red

            return $false
        }

        Write-Host "[OK] Pacote adicionado ao Driver Store." -ForegroundColor Green
    }
    catch {

        Write-Host ""
        Write-Host "[ERRO] Falha ao executar PnPUtil." -ForegroundColor Red
        Write-Host "       $($_.Exception.Message)" -ForegroundColor Red

        return $false
    }

    Write-Host ""
    Write-Host "[*] Verificando se o Windows registrou o driver..." -ForegroundColor Cyan

    $StartTime = Get-Date

    while (((Get-Date) - $StartTime).TotalSeconds -lt 30) {

        if (Test-PrinterDriverInstalled -DriverName $DriverName) {

            Write-Host "[OK] Driver registrado no Windows." -ForegroundColor Green
            Write-Host "    $DriverName" -ForegroundColor DarkGray

            return $true
        }

        Start-Sleep -Seconds 2
    }

    Write-Host ""
    Write-Host "[*] Driver ainda nao apareceu." -ForegroundColor Yellow
    Write-Host "[*] Tentando registrar com Add-PrinterDriver..." -ForegroundColor Cyan
    Write-Host ""

    try {

        Add-PrinterDriver -Name $DriverName -ErrorAction Stop

        Write-Host "[OK] Driver registrado com sucesso." -ForegroundColor Green

        return $true
    }
    catch {

        Write-Host ""
        Write-Host "[AVISO] Add-PrinterDriver retornou erro:" -ForegroundColor Yellow
        Write-Host "        $($_.Exception.Message)" -ForegroundColor Yellow
    }

    Start-Sleep -Seconds 3

    if (Test-PrinterDriverInstalled -DriverName $DriverName) {

        Write-Host "[OK] Driver encontrado no Windows." -ForegroundColor Green
        Write-Host "    $DriverName"

        return $true
    }

    Write-Host ""
    Write-Host "[ERRO] O driver nao foi registrado." -ForegroundColor Red
    Write-Host "       $DriverName" -ForegroundColor Red

    return $false
}

function Wait-ForPrinterDriver {
    param(
        [string]$DriverName,
        [int]$TimeoutSeconds
    )

    Write-Host ""
    Write-Host "[*] Aguardando o Windows registrar o driver..." -ForegroundColor Cyan

    $StartTime = Get-Date

    while (((Get-Date) - $StartTime).TotalSeconds -lt $TimeoutSeconds) {

        if (Test-PrinterDriverInstalled -DriverName $DriverName) {

            Write-Host "[OK] Driver encontrado:" -ForegroundColor Green
            Write-Host "     $DriverName"

            return $true
        }

        Start-Sleep -Seconds 2
    }

    Write-Host ""
    Write-Host "[ERRO] O driver nao apareceu no Windows dentro do tempo esperado." -ForegroundColor Red
    Write-Host "       $DriverName" -ForegroundColor Red

    return $false
}

function Set-PrinterPortRaw9100 {
    param(
        [string]$PortName,
        [string]$PrinterHostAddress
    )

    try {

        $PrnPortScript = Get-ChildItem `
            -Path (Join-Path $env:WINDIR "System32\Printing_Admin_Scripts") `
            -Filter "prnport.vbs" `
            -Recurse `
            -File `
            -ErrorAction SilentlyContinue |
            Select-Object -First 1

        if (-not $PrnPortScript) {
            throw "O prnport.vbs nao foi encontrado no Windows."
        }

        $CscriptPath = Join-Path $env:WINDIR "System32\cscript.exe"

        if (-not (Test-Path -LiteralPath $CscriptPath)) {
            throw "O cscript.exe nao foi encontrado."
        }

        $PortExists = Get-PrinterPort -Name $PortName -ErrorAction SilentlyContinue

        if ($PortExists) {
            $PrnArgs = @(
                "//NoLogo",
                $PrnPortScript.FullName,
                "-t",
                "-r", $PortName,
                "-h", $PrinterHostAddress,
                "-o", "raw",
                "-n", "9100",
                "-md"
            )
        }
        else {
            $PrnArgs = @(
                "//NoLogo",
                $PrnPortScript.FullName,
                "-a",
                "-r", $PortName,
                "-h", $PrinterHostAddress,
                "-o", "raw",
                "-n", "9100",
                "-md"
            )
        }

        & $CscriptPath @PrnArgs 2>&1 | Out-Null
        $ExitCode = $LASTEXITCODE

        if ($ExitCode -ne 0) {
            throw "prnport.vbs retornou codigo $ExitCode."
        }

        return $true
    }
    catch {

        Write-Host ""
        Write-Host "[ERRO] Falha ao configurar RAW + 9100." -ForegroundColor Red
        Write-Host "       $($_.Exception.Message)" -ForegroundColor Red

        return $false
    }
}

$CurrentIdentity = [Security.Principal.WindowsIdentity]::GetCurrent()
$Principal = New-Object Security.Principal.WindowsPrincipal($CurrentIdentity)

if (-not $Principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {

    Write-Host ""
    Write-Host "[*] Este script precisa ser executado como administrador." -ForegroundColor Yellow
    Write-Host "[*] Solicitando UAC..." -ForegroundColor Yellow
    Write-Host ""

    try {

        $PowerShellArguments = "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`""

        Start-Process -FilePath "powershell.exe" -ArgumentList $PowerShellArguments -Verb RunAs -ErrorAction Stop

        exit
    }
    catch {

        Write-Host ""
        Write-Host "[ERRO] Nao foi possivel abrir como administrador." -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor Red
        Write-Host ""

        Read-Host "Pressione ENTER para sair"

        exit 1
    }
}

try {

    $ScriptPath = $PSScriptRoot
    $CsvPath = Join-Path $ScriptPath "impressoras.csv"
    $DriversPath = Join-Path $ScriptPath "Drivers"

 
    Clear-Host

    Write-Host ""
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host " AUTOMACAO DE INSTALACAO DE IMPRESSORAS" -ForegroundColor Cyan
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host ""


    if (-not (Test-Path -LiteralPath $CsvPath)) {
        Stop-Instalacao "Arquivo CSV nao encontrado."
    }

    if (-not (Test-Path -LiteralPath $DriversPath)) {
        Stop-Instalacao "Pasta Drivers nao encontrada."
    }

    try {
        $Impressoras = @(Import-Csv -LiteralPath $CsvPath -Delimiter ";" -ErrorAction Stop)
    }
    catch {
        Stop-Instalacao "Nao foi possivel carregar o CSV.`nErro: $($_.Exception.Message)"
    }

    if ($Impressoras.Count -eq 0) {
        Stop-Instalacao "O CSV nao possui nenhuma impressora."
    }


    Write-Host "Impressoras disponiveis:" -ForegroundColor Cyan
    Write-Host ""

    for ($i = 0; $i -lt $Impressoras.Count; $i++) {

        $Item = $Impressoras[$i]
        Write-Host "[$($i + 1)] $($Item.Depto) - $($Item.Fabricante) $($Item.Modelo)"
    }

    Write-Host ""

    $NumeroSelecionado = 0
    $OpcaoValida = $false

    do {

        $Opcao = Read-Host "Selecione a impressora"
        $NumeroSelecionado = 0

        if ([int]::TryParse($Opcao, [ref]$NumeroSelecionado)) {

            if (($NumeroSelecionado -ge 1) -and ($NumeroSelecionado -le $Impressoras.Count)) {
                $OpcaoValida = $true
            }
            else {
                Write-Host "[ERRO] Numero fora da lista." -ForegroundColor Red
            }
        }
        else {
            Write-Host "[ERRO] Digite somente o numero da impressora." -ForegroundColor Red
        }

    } while (-not $OpcaoValida)

    $Alvo = $Impressoras[$NumeroSelecionado - 1]

    $NomeImpressora = "$($Alvo.Depto) - $($Alvo.Fabricante) $($Alvo.Modelo)"
    $NomePorta = "IP_$($Alvo.IP)"
    $CaminhoDriverCompleto = Join-Path $DriversPath $Alvo.DriverFolder

    if ([string]::IsNullOrWhiteSpace($Alvo.Depto)) {
        Stop-Instalacao "O campo Depto esta vazio no CSV."
    }

    if ([string]::IsNullOrWhiteSpace($Alvo.Fabricante)) {
        Stop-Instalacao "O campo Fabricante esta vazio no CSV."
    }

    if ([string]::IsNullOrWhiteSpace($Alvo.Modelo)) {
        Stop-Instalacao "O campo Modelo esta vazio no CSV."
    }

    if ([string]::IsNullOrWhiteSpace($Alvo.IP)) {
        Stop-Instalacao "O campo IP esta vazio no CSV."
    }

    if ([string]::IsNullOrWhiteSpace($Alvo.DriverName)) {
        Stop-Instalacao "O campo DriverName esta vazio no CSV."
    }

    if ([string]::IsNullOrWhiteSpace($Alvo.DriverFolder)) {
        Stop-Instalacao "O campo DriverFolder esta vazio no CSV."
    }

    Write-Host ""
    Write-Host "============================================================" -ForegroundColor Green
    Write-Host " IMPRESSORA SELECIONADA" -ForegroundColor Green
    Write-Host "============================================================" -ForegroundColor Green
    Write-Host ""

    Write-Host "Departamento : $($Alvo.Depto)"
    Write-Host "Fabricante   : $($Alvo.Fabricante)"
    Write-Host "Modelo       : $($Alvo.Modelo)"
    Write-Host "Driver       : $($Alvo.DriverName)"
    Write-Host "Pasta Driver : [OCULTA]"
    Write-Host ""

    Write-Host "[OK] Pasta do driver encontrada." -ForegroundColor Green


    Write-Host ""
    Write-Host "[*] Verificando conectividade..." -NoNewline

    try {

        $PingResult = Test-Connection -ComputerName $Alvo.IP -Count 1 -Quiet -ErrorAction SilentlyContinue

        if ($PingResult) {
            Write-Host " [OK]" -ForegroundColor Green
        }
        else {
            Write-Host " [SEM RESPOSTA]" -ForegroundColor Yellow
            Write-Host "[AVISO] Ping sem resposta. Continuando instalacao..." -ForegroundColor Yellow
        }
    }
    catch {
        Write-Host " [ERRO]" -ForegroundColor Yellow
        Write-Host "[AVISO] Falha no ping. Continuando instalacao..." -ForegroundColor Yellow
    }

    Write-Host ""
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host " DRIVER" -ForegroundColor Cyan
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host ""

    if (Test-PrinterDriverInstalled -DriverName $Alvo.DriverName) {

        Write-Host "[OK] Driver ja instalado:" -ForegroundColor Green
        Write-Host "     $($Alvo.DriverName)"
    }
    else {

        Write-Host "[*] Driver nao encontrado. Instalando pacote..." -ForegroundColor Yellow

        $DriverInstalled = Install-DriverFromInf `
            -Fabricante $Alvo.Fabricante `
            -DriverFolder $CaminhoDriverCompleto `
            -DriverName $Alvo.DriverName

        if (-not $DriverInstalled) {
            Stop-Instalacao "Nao foi possivel instalar o driver via INF.`nFabricante: $($Alvo.Fabricante)`nModelo: $($Alvo.Modelo)`nDriver: $($Alvo.DriverName)"
        }

        if (-not (Wait-ForPrinterDriver -DriverName $Alvo.DriverName -TimeoutSeconds 60)) {
            Stop-Instalacao "O Windows nao registrou o driver:`n$($Alvo.DriverName)"
        }
    }


    Write-Host ""
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host " PORTA TCP/IP" -ForegroundColor Cyan
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host ""

    $PortaExistente = Get-PrinterPort -Name $NomePorta -ErrorAction SilentlyContinue

    if ($PortaExistente) {
        Write-Host "[OK] Porta TCP/IP ja existe." -ForegroundColor Green
    }
    else {

        Write-Host "[*] Criando porta TCP/IP..." -NoNewline

        try {
            Add-PrinterPort -Name $NomePorta -PrinterHostAddress $Alvo.IP -ErrorAction Stop
            Write-Host " [OK]" -ForegroundColor Green
        }
        catch {

            Write-Host " [FALHA]" -ForegroundColor Red
            Write-Host "[ERRO] $($_.Exception.Message)" -ForegroundColor Red
            Stop-Instalacao "Nao foi possivel criar a porta TCP/IP."
        }
    }


    Write-Host ""
    Write-Host "[*] Configurando RAW + TCP 9100..." -NoNewline

    if (Set-PrinterPortRaw9100 -PortName $NomePorta -PrinterHostAddress $Alvo.IP) {
        Write-Host " [OK]" -ForegroundColor Green
    }
    else {
        Stop-Instalacao "Falha ao configurar RAW + 9100."
    }


    Write-Host ""
    Write-Host "[*] Verificando configuracao da porta..." -ForegroundColor Cyan

    try {

        $WmiPortCheck = Get-WmiObject -Class Win32_TCPIPPrinterPort -Filter "Name='$NomePorta'" -ErrorAction Stop

        if ($WmiPortCheck) {
            Write-Host "[OK] Porta encontrada." -ForegroundColor Green
            Write-Host "    Protocolo : $($WmiPortCheck.Protocol)"
            Write-Host "    Porta     : $($WmiPortCheck.PortNumber)"
            Write-Host "    SNMP      : $($WmiPortCheck.SNMPEnabled)"
        }
    }
    catch {
        Write-Host "[AVISO] Nao foi possivel validar a porta via WMI." -ForegroundColor Yellow
    }

    Write-Host ""
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host " FILA DA IMPRESSORA" -ForegroundColor Cyan
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host ""

    $PrinterExistente = Get-Printer -Name $NomeImpressora -ErrorAction SilentlyContinue

    if ($PrinterExistente) {

        Write-Host "[*] Impressora ja existe. Atualizando..." -ForegroundColor Yellow

        try {
            Set-Printer -Name $NomeImpressora -PortName $NomePorta -DriverName $Alvo.DriverName -ErrorAction Stop
            Write-Host "[OK] Fila atualizada." -ForegroundColor Green
        }
        catch {
            Stop-Instalacao "Falha ao atualizar a fila.`n$($_.Exception.Message)"
        }
    }
    else {

        Write-Host "[*] Criando fila da impressora..." -NoNewline

        try {
            Add-Printer -Name $NomeImpressora -DriverName $Alvo.DriverName -PortName $NomePorta -ErrorAction Stop
            Write-Host " [OK]" -ForegroundColor Green
        }
        catch {

            Write-Host " [FALHA]" -ForegroundColor Red
            Write-Host "[ERRO] $($_.Exception.Message)" -ForegroundColor Red
            Stop-Instalacao "Nao foi possivel criar a fila."
        }
    }

    Write-Host ""
    Write-Host "[*] Configurando papel A4..." -NoNewline

    try {
        Set-PrintConfiguration -PrinterName $NomeImpressora -PaperSize A4 -ErrorAction Stop
        Write-Host " [OK]" -ForegroundColor Green
    }
    catch {
        Write-Host " [FALHA]" -ForegroundColor Red
        Write-Host "[AVISO] $($_.Exception.Message)" -ForegroundColor Yellow
    }


    Write-Host ""
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host " VERIFICACAO FINAL" -ForegroundColor Cyan
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host ""

    $PrinterFinal = Get-Printer -Name $NomeImpressora -ErrorAction SilentlyContinue
    $DriverFinal = Get-PrinterDriver -Name $Alvo.DriverName -ErrorAction SilentlyContinue
    $PortFinal = Get-PrinterPort -Name $NomePorta -ErrorAction SilentlyContinue

    if ($PrinterFinal) {
        Write-Host "[OK] Impressora instalada:" -ForegroundColor Green
        Write-Host "     $NomeImpressora"
    }
    else {
        Write-Host "[FALHA] Impressora nao encontrada." -ForegroundColor Red
    }

    if ($DriverFinal) {
        Write-Host "[OK] Driver instalado:" -ForegroundColor Green
        Write-Host "     $($DriverFinal.Name)"
    }
    else {
        Write-Host "[FALHA] Driver nao encontrado." -ForegroundColor Red
    }

    if ($PortFinal) {
        Write-Host "[OK] Porta TCP/IP configurada." -ForegroundColor Green
    }
    else {
        Write-Host "[FALHA] Porta nao encontrada." -ForegroundColor Red
    }

    try {

        $WmiPortFinal = Get-WmiObject -Class Win32_TCPIPPrinterPort -Filter "Name='$NomePorta'" -ErrorAction SilentlyContinue

        if ($WmiPortFinal) {
            Write-Host ""
            Write-Host "Configuracao TCP/IP:" -ForegroundColor Cyan
            Write-Host "    Protocolo : $($WmiPortFinal.Protocol)"
            Write-Host "    Porta     : $($WmiPortFinal.PortNumber)"
            Write-Host "    SNMP      : $($WmiPortFinal.SNMPEnabled)"
        }
    }
    catch {
    }

    Write-Host ""
    Write-Host "============================================================" -ForegroundColor Green
    Write-Host " INSTALACAO CONCLUIDA" -ForegroundColor Green
    Write-Host "============================================================" -ForegroundColor Green
    Write-Host ""
    Write-Host "Impressora : $NomeImpressora"
    Write-Host "Driver     : $($Alvo.DriverName)"
    Write-Host "Porta TCP/IP configurada."
    Write-Host ""

    Read-Host "Pressione ENTER para sair"
}
catch {

    Write-Host ""
    Write-Host "============================================================" -ForegroundColor Red
    Write-Host " ERRO INESPERADO" -ForegroundColor Red
    Write-Host "============================================================" -ForegroundColor Red
    Write-Host ""
    Write-Host "Mensagem:" -ForegroundColor Yellow
    Write-Host $_.Exception.Message -ForegroundColor Red
    Write-Host ""
    Write-Host "Linha aproximada: $($_.InvocationInfo.ScriptLineNumber)" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Comando:" -ForegroundColor Yellow
    Write-Host $_.InvocationInfo.Line -ForegroundColor DarkGray
    Write-Host ""

    Read-Host "Pressione ENTER para fechar"
}
