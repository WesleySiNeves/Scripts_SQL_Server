# Implementação de Try-Catch no Sistema HealthCheck

## Resumo das Melhorias

Este documento descreve as melhorias implementadas no sistema de HealthCheck para captura e notificação de erros de execução.

## Modificações Realizadas

### 1. Procedure SQL - HealthCheck.uspAutoHealthCheck

#### Melhorias Implementadas:
- **Bloco Try-Catch Completo**: Envolveu toda a lógica da procedure em um bloco try-catch
- **Captura Detalhada de Erros**: Coleta informações completas sobre erros (mensagem, severidade, estado, linha, procedure)
- **Log de Auditoria**: Tentativa de inserir erros na tabela `HealthCheck.LogsExecucao` se existir
- **Retorno Estruturado**: Retorna informações estruturadas do erro para o PowerShell
- **Re-lançamento de Erro**: Usa `RAISERROR` para garantir que o PowerShell capture a falha

#### Estrutura do Tratamento de Erro:
```sql
BEGIN TRY
    -- Código principal da procedure
END TRY
BEGIN CATCH
    -- Captura informações do erro
    -- Log para auditoria
    -- Retorna dados estruturados
    -- Re-lança o erro
END CATCH
```

#### Informações Capturadas:
- **Procedure**: Nome da procedure onde ocorreu o erro
- **Linha**: Número da linha do erro
- **Mensagem**: Descrição detalhada do erro
- **Severidade**: Nível de severidade do erro
- **Estado**: Estado do erro
- **Data/Hora**: Timestamp do erro

### 2. Script PowerShell - AutoExecute.ps1

#### Melhorias na Função Execute-HealthCheck:
- **Timeout Aumentado**: QueryTimeout aumentado para 600 segundos
- **ErrorAction Stop**: Garante que erros SQL sejam capturados
- **Verificação de Resultado**: Analisa o resultado retornado pela procedure SQL
- **Detecção de Erro SQL**: Identifica quando a procedure retorna status "ERRO"
- **Tratamento Detalhado**: Captura diferentes tipos de erro (SQL Server, timeout, conexão)
- **Logging Aprimorado**: Logs mais detalhados para troubleshooting

#### Melhorias na Função PostToTeams:
- **Tipos de Notificação**: Suporte a diferentes tipos (Erro, Erro SQL, Erro Crítico, Aviso)
- **Cores Diferenciadas**: Cores específicas para cada tipo de erro
- **Ícones Personalizados**: Ícones visuais para diferentes tipos de erro
- **Formatação Melhorada**: Mensagens formatadas com HTML para melhor legibilidade
- **Emojis e Símbolos**: Interface mais amigável com emojis
- **Informações Adicionais**: Campos extras como "Tipo de Erro" e "Ação Requerida"

## Fluxo de Tratamento de Erros

### 1. Erro na Procedure SQL
```
Erro na Procedure → Try-Catch SQL → Log de Auditoria → Retorno Estruturado → RAISERROR
```

### 2. Captura no PowerShell
```
Invoke-Sqlcmd → Verificação de Status → Análise de Erro → Notificação Teams → Log PowerShell
```

### 3. Tipos de Erro Detectados

#### Erros SQL (Capturados pela Procedure):
- Erros de lógica de negócio
- Problemas de integridade de dados
- Falhas em procedures chamadas
- Problemas de permissão

#### Erros de Infraestrutura (Capturados pelo PowerShell):
- Problemas de conexão
- Timeouts de execução
- Falhas de autenticação
- Problemas de rede

## Configuração de Notificações

### Cores por Tipo de Erro:
- **Erro**: `#FF0000` (Vermelho)
- **Erro SQL**: `#FF6600` (Laranja)
- **Erro Crítico**: `#8B0000` (Vermelho Escuro)
- **Aviso**: `#FFA500` (Laranja Claro)

### Ícones por Tipo:
- **Erro SQL**: Ícone de erro de banco de dados
- **Erro Crítico**: Ícone de erro geral
- **Padrão**: Ícone do Azure Automation

## Benefícios da Implementação

1. **Detecção Proativa**: Identificação imediata de problemas
2. **Notificação Automática**: Alertas em tempo real via Teams
3. **Troubleshooting Facilitado**: Informações detalhadas para diagnóstico
4. **Auditoria Completa**: Logs estruturados para análise posterior
5. **Monitoramento Contínuo**: Acompanhamento da saúde do sistema
6. **Escalabilidade**: Sistema preparado para múltiplos bancos

## Recomendações de Uso

### Para Administradores:
1. Monitore as notificações do Teams regularmente
2. Investigue erros SQL imediatamente
3. Mantenha logs de auditoria organizados
4. Configure alertas adicionais se necessário

### Para Desenvolvedores:
1. Use as informações de linha e procedure para debug
2. Analise padrões de erro para melhorias
3. Implemente correções baseadas nos logs
4. Teste mudanças em ambiente controlado

### Para Operações:
1. Configure monitoramento de infraestrutura
2. Estabeleça SLAs baseados nas notificações
3. Documente procedimentos de resposta a incidentes
4. Mantenha contatos de escalação atualizados

## Próximos Passos

1. **Criar Tabela de Logs**: Implementar `HealthCheck.LogsExecucao` se não existir
2. **Dashboard de Monitoramento**: Criar visualizações dos logs de erro
3. **Alertas Avançados**: Implementar alertas baseados em padrões
4. **Métricas de SLA**: Estabelecer métricas de disponibilidade
5. **Automação de Correção**: Implementar correções automáticas para erros comuns

## Estrutura da Tabela de Logs (Sugerida)

```sql
CREATE TABLE HealthCheck.LogsExecucao (
    Id BIGINT IDENTITY(1,1) PRIMARY KEY,
    Procedure NVARCHAR(128) NOT NULL,
    DataExecucao DATETIME2 NOT NULL DEFAULT GETDATE(),
    Status NVARCHAR(20) NOT NULL, -- 'SUCESSO', 'ERRO', 'AVISO'
    Mensagem NVARCHAR(MAX),
    Severidade INT,
    Estado INT,
    Linha INT,
    DuracaoMS INT,
    Servidor NVARCHAR(128) DEFAULT @@SERVERNAME,
    Banco NVARCHAR(128) DEFAULT DB_NAME(),
    Usuario NVARCHAR(128) DEFAULT SUSER_NAME()
);
```

---

**Data da Implementação**: $(Get-Date -Format 'dd/MM/yyyy')
**Versão**: 1.0
**Autor**: Sistema de HealthCheck Automatizado