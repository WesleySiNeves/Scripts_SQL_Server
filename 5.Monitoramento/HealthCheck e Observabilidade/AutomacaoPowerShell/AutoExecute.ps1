# Script de Automação para execução do HealthCheck em todos os bancos Azure SQL
# Executa a procedure HealthCheck.uspAutoHealthCheck com @Efetivar = 1
# Notifica apenas em caso de falha

try
{
    Write-Output "Iniciando login no Azure..."
    Connect-AzAccount -Identity
    Write-Output "Login realizado com sucesso"
}
catch {
    Write-Error -Message $_.Exception
    throw $_.Exception
}

# Função para enviar notificações ao Teams apenas em caso de falha
function PostToTeams($mensagem, $tipoNotificacao = "Erro")
{
    try {
        # URL do recurso de automação
        $ThisResourceURL = 'https://portal.azure.com/#@implantainformatica.com.br/resource/subscriptions/b98b628c-0499-4165-bdb4-34c81b728ca4/resourceGroups/RgPrd/providers/Microsoft.Automation/automationAccounts/implanta-automation/runbooks/AutoExecute/overview'

        # Webhook configurado no grupo do Teams
        $ChannelURL = 'https://implantainformatica.webhook.office.com/webhookb2/3ce68492-0462-4986-84c5-c0af088d6258@5627b2ec-37e2-42df-bac4-43add425101c/IncomingWebhook/0e019c9fbbfa4263921ae21a2a02f6b2/bbc50a8c-92ec-4225-ae2c-87927f2047d0'

        # Define a cor e ícone baseado no tipo de notificação
        $corNotificacao = switch ($tipoNotificacao) {
            "Erro" { "FF0000" }
            "Erro SQL" { "FF6600" }
            "Erro Crítico" { "8B0000" }
            "Aviso" { "FFA500" }
            default { "FF0000" }
        }
        
        $iconeNotificacao = switch ($tipoNotificacao) {
            "Erro SQL" { "https://img.icons8.com/color/48/000000/database-error.png" }
            "Erro Crítico" { "https://img.icons8.com/color/48/000000/error.png" }
            default { "https://azure.microsoft.com/svghandler/automation/" }
        }
        
        # Formata a mensagem para melhor legibilidade
        $mensagemFormatada = $mensagem -replace "`n", "<br/>" -replace "`r", ""
        
        $Body = ConvertTo-Json -Depth 4 @{
            title = 'HealthCheck Automation - Falha Detectada'
            text = 'HealthCheck Automation Error Notification'
            themeColor = $corNotificacao
            sections = @(
                @{
                    activityTitle = "🚨 $tipoNotificacao - HealthCheck.uspAutoHealthCheck"
                    activitySubtitle = $mensagemFormatada
                    activityImage = $iconeNotificacao
                    facts = @(
                        @{
                            name = '⏰ Timestamp'
                            value = (Get-Date -Format 'dd/MM/yyyy HH:mm:ss')
                        },
                        @{
                            name = '📋 Runbook'
                            value = 'AutoExecute.ps1'
                        },
                        @{
                            name = '🔧 Tipo de Erro'
                            value = $tipoNotificacao
                        },
                        @{
                            name = '🎯 Ação Requerida'
                            value = 'Verificar logs e corrigir problema'
                        }
                    )
                    markdown = $true
                }
            )
            potentialAction = @(
                @{
                    '@context' = 'http://schema.org'
                    '@type' = 'ViewAction'
                    name = '🔗 Gerenciar Automação'
                    target = @($ThisResourceURL)
                }
            )
        }

        $Utf8Encoding = [System.Text.Encoding]::UTF8
        $BodyBytes = $Utf8Encoding.GetBytes($Body)
        $Headers = @{ "Content-Type" = "application/json; charset=utf-8"}

        Invoke-RestMethod -Method Post -Uri $ChannelURL -Headers $Headers -Body $BodyBytes
        Write-Output "✅ Notificação enviada ao Teams: $tipoNotificacao"
    }
    catch {
        Write-Host "❌ Erro ao enviar notificação ao Teams: $($_.Exception.Message)"
    }
}

# Função para executar HealthCheck em um banco específico
function Execute-HealthCheck($serverInstance, $databaseName, $username, $password)
{
    try {
        Write-Output "Executando HealthCheck no banco: $databaseName (Servidor: $serverInstance)"
        
        # Executa a procedure HealthCheck.uspAutoHealthCheck com @Efetivar = 1
        $SQLOutput = Invoke-Sqlcmd -ServerInstance $serverInstance `
                                  -Username $username `
                                  -Password $password `
                                  -Database $databaseName `
                                  -Query "EXEC HealthCheck.uspAutoHealthCheck @Efetivar = 1" `
                                  -QueryTimeout 600 `
                                  -ConnectionTimeout 60 `
                                  -ErrorAction Stop `
                                  -Verbose
        
        # Verifica se houve erro retornado pela procedure SQL
        if ($SQLOutput -and $SQLOutput.Status -eq "ERRO") {
            $sqlErrorMessage = "Erro SQL na procedure HealthCheck.uspAutoHealthCheck:`n" +
                              "Banco: $databaseName`n" +
                              "Servidor: $serverInstance`n" +
                              "Procedure: $($SQLOutput.Procedure)`n" +
                              "Linha: $($SQLOutput.Linha)`n" +
                              "Mensagem: $($SQLOutput.Mensagem)`n" +
                              "Severidade: $($SQLOutput.Severidade)`n" +
                              "Data/Hora: $($SQLOutput.DataHoraErro)"
            
            Write-Error $sqlErrorMessage
            PostToTeams -mensagem $sqlErrorMessage -tipoNotificacao "Erro SQL"
            return $false
        }
        
        Write-Output "HealthCheck executado com sucesso no banco: $databaseName"
        
        # Log dos resultados se disponível
        if ($SQLOutput -and $SQLOutput.Count -gt 0) {
            Write-Output "Procedures executadas: $($SQLOutput.Count)"
        }
        
        return $true
    }
    catch {
        # Captura erros de conexão, timeout ou outros erros do PowerShell/SQL
        $errorDetails = @()
        $errorDetails += "Banco: $databaseName"
        $errorDetails += "Servidor: $serverInstance"
        $errorDetails += "Erro: $($_.Exception.Message)"
        
        # Adiciona detalhes específicos se disponível
        if ($_.Exception.InnerException) {
            $errorDetails += "Erro Interno: $($_.Exception.InnerException.Message)"
        }
        
        # Verifica se é erro de SQL Server
        if ($_.Exception.Message -match "SQL Server") {
            $errorDetails += "Tipo: Erro de SQL Server"
        }
        elseif ($_.Exception.Message -match "timeout") {
            $errorDetails += "Tipo: Timeout de execução"
        }
        elseif ($_.Exception.Message -match "connection") {
            $errorDetails += "Tipo: Erro de conexão"
        }
        
        $errorMessage = "Erro ao executar HealthCheck:`n" + ($errorDetails -join "`n")
        Write-Error $errorMessage
        
        # Envia notificação de falha
        PostToTeams -mensagem $errorMessage -tipoNotificacao "Erro"
        return $false
    }
}


# Bloco principal de execução com try-catch-finally
try 
{
    Write-Output 'Processo de HealthCheck iniciado'
    
    # Variáveis de controle
    $totalBancos = 0
    $bancosProcessados = 0
    $bancosComErro = 0
    $errosDetalhados = @()
    
    # Configuração da subscrição principal
    $subscriptionId = 'b98b628c-0499-4165-bdb4-34c81b728ca4'
    Set-AzContext $subscriptionId
    
    # Obtém variáveis de automação
    $variaveis = Get-AzAutomationVariable -ResourceGroupName 'RgPrd' -AutomationAccountName 'implanta-automation'
    
    # Obtém credenciais para conexão SQL (assumindo que estão nas variáveis de automação)
    $SecretValueUserName = ($variaveis | Where-Object { $_.Name -eq 'SqlUsername' }).Value
    $SecurePassword = ($variaveis | Where-Object { $_.Name -eq 'SqlPassword' }).Value
    
    if ([string]::IsNullOrEmpty($SecretValueUserName) -or [string]::IsNullOrEmpty($SecurePassword)) {
        throw "Credenciais SQL não encontradas nas variáveis de automação"
    }
    
    Write-Output "Credenciais obtidas com sucesso"
    
    # ========== PROCESSAMENTO SUBSCRIÇÃO PRINCIPAL (PRODUÇÃO) ==========
    Write-Output "Processando subscrição principal (Produção)..."
    
    $resourceGroupPrd = $variaveis | Where-Object { $_.Name -eq 'PRDResourceGroup' }
    if ($resourceGroupPrd) {
        $SqlServersPrd = Get-AzSqlServer -ResourceGroupName $resourceGroupPrd.Value
        
        foreach($sqlserver in $SqlServersPrd) {
            Write-Output "Processando servidor: $($sqlserver.ServerName)"
            
            try {
                $databases = Get-AzSqlDatabase -ResourceGroupName $resourceGroupPrd.Value -ServerName $sqlserver.ServerName
                
                foreach($database in $databases) {
                    # Processa apenas bancos que terminam com 'implanta.net.br' e não são bancos de sistema
                    if ($database.DatabaseName -like "*implanta.net.br" -and 
                        $database.DatabaseName -notmatch "master|model|msdb|tempdb") {
                        
                        $totalBancos++
                        $serverInstance = "$($sqlserver.ServerName).database.windows.net"
                        
                        # Executa HealthCheck no banco com try-catch individual
                        try {
                            $resultado = Execute-HealthCheck -serverInstance $serverInstance `
                                                            -databaseName $database.DatabaseName `
                                                            -username $SecretValueUserName `
                                                            -password $SecurePassword
                            
                            if ($resultado) {
                                $bancosProcessados++
                                Write-Output "✅ HealthCheck executado com sucesso: $($database.DatabaseName)"
                            } else {
                                $bancosComErro++
                                $errorDetail = "❌ Falha no HealthCheck - Banco: $($database.DatabaseName) (Servidor: $serverInstance)"
                                $errosDetalhados += $errorDetail
                                Write-Warning $errorDetail
                            }
                        }
                        catch {
                            $bancosComErro++
                            $errorDetail = "💥 Erro crítico no HealthCheck - Banco: $($database.DatabaseName) (Servidor: $serverInstance) - Erro: $($_.Exception.Message)"
                            $errosDetalhados += $errorDetail
                            Write-Error $errorDetail
                        }
                    }
                }
            }
            catch {
                $errorMsg = "Erro ao processar servidor $($sqlserver.ServerName): $($_.Exception.Message)"
                Write-Error $errorMsg
                $errosDetalhados += $errorMsg
            }
        }
    }
    
    # ========== PROCESSAMENTO SUBSCRIÇÃO SECUNDÁRIA ==========
    Write-Output "Processando subscrição secundária..."
    
    $subscriptionSubProd = $variaveis | Where-Object { $_.Name -eq 'SubscriptionSubPrd' }
    if ($subscriptionSubProd) {
        Set-AzContext $subscriptionSubProd.Value
        
        $SqlServersSubProd = Get-AzSqlServer
        
        foreach($sqlserver in $SqlServersSubProd) {
            Write-Output "Processando servidor: $($sqlserver.ServerName)"
            
            try {
                $databases = Get-AzSqlDatabase -ResourceGroupName $sqlserver.ResourceGroupName -ServerName $sqlserver.ServerName
                
                foreach($database in $databases) {
                    # Processa apenas bancos que terminam com 'implanta.net.br' e não são bancos de sistema
                    if ($database.DatabaseName -like "*implanta.net.br" -and 
                        $database.DatabaseName -notmatch "master|model|msdb|tempdb") {
                        
                        $totalBancos++
                        $serverInstance = "$($sqlserver.ServerName).database.windows.net"
                        
                        # Executa HealthCheck no banco com try-catch individual
                        try {
                            $resultado = Execute-HealthCheck -serverInstance $serverInstance `
                                                            -databaseName $database.DatabaseName `
                                                            -username $SecretValueUserName `
                                                            -password $SecurePassword
                            
                            if ($resultado) {
                                $bancosProcessados++
                                Write-Output "✅ HealthCheck executado com sucesso: $($database.DatabaseName)"
                            } else {
                                $bancosComErro++
                                $errorDetail = "❌ Falha no HealthCheck - Banco: $($database.DatabaseName) (Servidor: $serverInstance)"
                                $errosDetalhados += $errorDetail
                                Write-Warning $errorDetail
                            }
                        }
                        catch {
                            $bancosComErro++
                            $errorDetail = "💥 Erro crítico no HealthCheck - Banco: $($database.DatabaseName) (Servidor: $serverInstance) - Erro: $($_.Exception.Message)"
                            $errosDetalhados += $errorDetail
                            Write-Error $errorDetail
                        }
                    }
                }
            }
            catch {
                $errorMsg = "Erro ao processar servidor $($sqlserver.ServerName): $($_.Exception.Message)"
                Write-Error $errorMsg
                $errosDetalhados += $errorMsg
            }
        }
    }
    
    # ========== RELATÓRIO FINAL ==========
    $relatorio = @"
Relatório de Execução do HealthCheck:
- Total de bancos encontrados: $totalBancos
- Bancos processados com sucesso: $bancosProcessados
- Bancos com erro: $bancosComErro
"@
    
    Write-Output $relatorio
    
    # Envia notificação apenas se houver erros
    if ($bancosComErro -gt 0) {
        $mensagemErro = $relatorio + "`n`nDetalhes dos erros:`n" + ($errosDetalhados -join "`n")
        PostToTeams -mensagem $mensagemErro -tipoNotificacao "Erro"
    }
    
    Write-Output 'Processo de HealthCheck concluído com sucesso'
}
catch 
{
    # Captura erros gerais do processo
    $errorMessage = "Erro crítico durante a execução do HealthCheck: $($_.Exception.Message)"
    Write-Error $errorMessage
    
    # Envia notificação de erro crítico
    PostToTeams -mensagem $errorMessage -tipoNotificacao "Erro Crítico"
    
    throw $_.Exception
}
finally 
{
    # Bloco finally - sempre executado
    Write-Output "Finalizando processo de HealthCheck..."
    
    # Limpa variáveis sensíveis
    if ($SecretValueUserName) { Remove-Variable -Name SecretValueUserName -ErrorAction SilentlyContinue }
    if ($SecurePassword) { Remove-Variable -Name SecurePassword -ErrorAction SilentlyContinue }
    
    # Log final
    $timestampFinal = Get-Date -Format 'dd/MM/yyyy HH:mm:ss'
    Write-Output "Processo finalizado em: $timestampFinal"
}