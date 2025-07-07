<#
.SYNOPSIS
    Script para validar o status HTTP das páginas dos CRPs
.DESCRIPTION
    Lê uma lista de URLs e verifica se cada uma retorna código HTTP 200
    Gera relatório com status de cada URL e estatísticas finais
.AUTHOR
    Wesley
.DATE
    $(Get-Date -Format 'dd/MM/yyyy')
#>

# =============================================
# CONFIGURAÇÕES INICIAIS
# =============================================

# Definir encoding para caracteres especiais
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

# Lista de URLs para validar
$urls = @(
    "cfp-br.implanta.net.br/siscont/sistema/status.aspx",
    "crp-al.implanta.net.br/siscont/sistema/status.aspx",
    "crp-am.implanta.net.br/siscont/sistema/status.aspx",
    "crp-ba.implanta.net.br/siscont/sistema/status.aspx",
    "crp-ce.implanta.net.br/siscont/sistema/status.aspx",
    "crp-df.implanta.net.br/siscont/sistema/status.aspx",
    "crp-es.implanta.net.br/siscont/sistema/status.aspx",
    "crp-go.implanta.net.br/siscont/sistema/status.aspx",
    "crp-ma.implanta.net.br/siscont/sistema/status.aspx",
    "crp-mg.implanta.net.br/siscont/sistema/status.aspx",
    "crp-ms.implanta.net.br/siscont/sistema/status.aspx",
    "crp-mt.implanta.net.br/siscont/sistema/status.aspx",
    "crp-pa.implanta.net.br/siscont/sistema/status.aspx",
    "crp-pb.implanta.net.br/siscont/sistema/status.aspx",
    "crp-pe.implanta.net.br/siscont/sistema/status.aspx",
    "crp-pi.implanta.net.br/siscont/sistema/status.aspx",
    "crp-pr.implanta.net.br/siscont/sistema/status.aspx",
    "crp-rj.implanta.net.br/siscont/sistema/status.aspx",
    "crp-rn.implanta.net.br/siscont/sistema/status.aspx",
    "crp-ro.implanta.net.br/siscont/sistema/status.aspx",
    "crp-rs.implanta.net.br/siscont/sistema/status.aspx",
    "crp-sc.implanta.net.br/siscont/sistema/status.aspx",
    "crp-se.implanta.net.br/siscont/sistema/status.aspx",
    "crp-sp.implanta.net.br/siscont/sistema/status.aspx",
    "crp-to.implanta.net.br/siscont/sistema/status.aspx"
)

# Configurações de timeout e retry
$timeoutSeconds = 30
$maxRetries = 2

# =============================================
# FUNÇÕES AUXILIARES
# =============================================

function Test-UrlStatus {
    param(
        [string]$Url,
        [int]$TimeoutSeconds = 30,
        [int]$MaxRetries = 2
    )
    
    # Adicionar https:// se não estiver presente
    if (-not $Url.StartsWith("http")) {
        $fullUrl = "https://$Url"
    } else {
        $fullUrl = $Url
    }
    
    $attempt = 0
    
    do {
        $attempt++
        try {
            Write-Host "Testando: $fullUrl (Tentativa $attempt)" -ForegroundColor Yellow
            
            # Fazer requisição HTTP
            $response = Invoke-WebRequest -Uri $fullUrl -TimeoutSec $TimeoutSeconds -UseBasicParsing -ErrorAction Stop
            
            # Retornar resultado de sucesso
            return @{
                Url = $Url
                FullUrl = $fullUrl
                StatusCode = $response.StatusCode
                StatusDescription = $response.StatusDescription
                Success = ($response.StatusCode -eq 200)
                ResponseTime = $null
                Error = $null
                Attempt = $attempt
            }
        }
        catch {
            $errorMessage = $_.Exception.Message
            
            # Se não é a última tentativa, aguardar antes de tentar novamente
            if ($attempt -lt $MaxRetries) {
                Write-Host "Erro na tentativa $attempt. Aguardando 3 segundos..." -ForegroundColor Red
                Start-Sleep -Seconds 3
            }
        }
    } while ($attempt -lt $MaxRetries)
    
    # Se chegou aqui, todas as tentativas falharam
    return @{
        Url = $Url
        FullUrl = $fullUrl
        StatusCode = $null
        StatusDescription = "Falha na conexão"
        Success = $false
        ResponseTime = $null
        Error = $errorMessage
        Attempt = $attempt
    }
}

function Write-ColoredStatus {
    param(
        [string]$Message,
        [bool]$Success
    )
    
    if ($Success) {
        Write-Host $Message -ForegroundColor Green
    } else {
        Write-Host $Message -ForegroundColor Red
    }
}

# =============================================
# EXECUÇÃO PRINCIPAL
# =============================================

Write-Host "=" * 60 -ForegroundColor Cyan
Write-Host "VALIDAÇÃO DE STATUS DAS PÁGINAS CRP" -ForegroundColor Cyan
Write-Host "=" * 60 -ForegroundColor Cyan
Write-Host "Início: $(Get-Date -Format 'dd/MM/yyyy HH:mm:ss')" -ForegroundColor Cyan
Write-Host "Total de URLs: $($urls.Count)" -ForegroundColor Cyan
Write-Host ""

# Array para armazenar resultados
$results = @()
$startTime = Get-Date

# Processar cada URL
foreach ($url in $urls) {
    $result = Test-UrlStatus -Url $url -TimeoutSeconds $timeoutSeconds -MaxRetries $maxRetries
    $results += $result
    
    # Exibir resultado imediato
    $statusMessage = "[$($result.Url)] - Status: $($result.StatusCode) - $($result.StatusDescription)"
    Write-ColoredStatus -Message $statusMessage -Success $result.Success
    
    if (-not $result.Success -and $result.Error) {
        Write-Host "   Erro: $($result.Error)" -ForegroundColor Red
    }
    
    Write-Host ""
}

$endTime = Get-Date
$totalTime = $endTime - $startTime

# =============================================
# RELATÓRIO FINAL
# =============================================

Write-Host "=" * 60 -ForegroundColor Cyan
Write-Host "RELATÓRIO FINAL" -ForegroundColor Cyan
Write-Host "=" * 60 -ForegroundColor Cyan

# Estatísticas
$successCount = ($results | Where-Object { $_.Success }).Count
$failureCount = ($results | Where-Object { -not $_.Success }).Count
$successPercentage = [math]::Round(($successCount / $results.Count) * 100, 2)

Write-Host "Tempo total de execução: $($totalTime.ToString('mm\:ss'))" -ForegroundColor Cyan
Write-Host "Total de URLs testadas: $($results.Count)" -ForegroundColor Cyan
Write-Host "Sucessos: $successCount ($successPercentage%)" -ForegroundColor Green
Write-Host "Falhas: $failureCount" -ForegroundColor Red
Write-Host ""

# Listar URLs com falha
if ($failureCount -gt 0) {
    Write-Host "URLs COM FALHA:" -ForegroundColor Red
    Write-Host "-" * 40 -ForegroundColor Red
    
    $failures = $results | Where-Object { -not $_.Success }
    foreach ($failure in $failures) {
        Write-Host "• $($failure.Url)" -ForegroundColor Red
        if ($failure.Error) {
            Write-Host "  Erro: $($failure.Error)" -ForegroundColor Red
        }
    }
    Write-Host ""
}

# Listar URLs com sucesso
if ($successCount -gt 0) {
    Write-Host "URLs COM SUCESSO:" -ForegroundColor Green
    Write-Host "-" * 40 -ForegroundColor Green
    
    $successes = $results | Where-Object { $_.Success }
    foreach ($success in $successes) {
        Write-Host "• $($success.Url) (Status: $($success.StatusCode))" -ForegroundColor Green
    }
    Write-Host ""
}

# =============================================
# EXPORTAR RESULTADOS (OPCIONAL)
# =============================================

# Criar relatório CSV
$csvPath = "$PSScriptRoot\StatusReport_$(Get-Date -Format 'yyyyMMdd_HHmmss').csv"
$results | Select-Object Url, FullUrl, StatusCode, StatusDescription, Success, Error, Attempt | 
    Export-Csv -Path $csvPath -NoTypeInformation -Encoding UTF8

Write-Host "Relatório CSV salvo em: $csvPath" -ForegroundColor Cyan

# =============================================
# FINALIZAÇÃO
# =============================================

Write-Host "=" * 60 -ForegroundColor Cyan
Write-Host "VALIDAÇÃO CONCLUÍDA" -ForegroundColor Cyan
Write-Host "Fim: $(Get-Date -Format 'dd/MM/yyyy HH:mm:ss')" -ForegroundColor Cyan
Write-Host "=" * 60 -ForegroundColor Cyan

# Retornar código de saída baseado no resultado
if ($failureCount -eq 0) {
    Write-Host "✅ Todas as URLs estão funcionando corretamente!" -ForegroundColor Green
    exit 0
} else {
    Write-Host "❌ $failureCount URL(s) apresentaram falha!" -ForegroundColor Red
    exit 1
}