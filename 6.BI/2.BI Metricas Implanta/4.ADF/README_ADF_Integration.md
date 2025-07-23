# Azure Data Factory - Integração BI Métricas

## Visão Geral

Este diretório contém os arquivos necessários para integrar o pipeline de BI Métricas com o Azure Data Factory (ADF), permitindo a execução automatizada do carregamento de dimensões e fatos após o término do ForEach de servidores.

## Arquivos Incluídos

### 1. `uspExecutarCarregamentoCompleto.sql`
**Procedure principal para execução no ADF**
- Encapsula a execução sequencial das procedures de dimensões e fatos
- Inclui logging detalhado e tratamento de erros
- Retorna códigos de status para monitoramento no ADF
- Calcula tempos de execução para cada etapa

### 2. `ExecutarCarregamentoDimensoesFatos.sql`
**Script SQL alternativo**
- Script direto para execução via atividade SQL no ADF
- Mesma funcionalidade da procedure, mas em formato de script
- Útil para ambientes que preferem scripts a procedures

### 3. `ADF_Pipeline_Config.json`
**Configuração do Pipeline ADF**
- Template JSON para criação do pipeline no ADF
- Define a sequência: ForEach → Carregamento BI
- Inclui configurações de timeout, retry e dependências

## Estratégia de Implementação

### Fluxo do Pipeline

```
┌─────────────────┐    ┌──────────────────────────┐    ┌─────────────────────┐
│   ForEach       │    │   Aguarda Conclusão     │    │   Carregamento      │
│   Servidores    │───▶│   (dependsOn)            │───▶│   Dimensões + Fatos │
│                 │    │                          │    │                     │
└─────────────────┘    └──────────────────────────┘    └─────────────────────┘
```

### Ordem de Execução

1. **ForEach Servidores** - Processa todos os servidores em paralelo
2. **Aguarda Conclusão** - Espera todos os servidores terminarem
3. **Carrega Dimensões** - Executa `uspLoadDimClientes` (SCD Tipo 2)
4. **Carrega Fatos** - Executa `uspLoadFatoMetricasClientes` (Snapshot Temporal)

## Configuração no Azure Data Factory

### Passo 1: Criar Linked Service

```json
{
  "name": "LinkedService_SQLServer_BI",
  "type": "SqlServer",
  "typeProperties": {
    "connectionString": "Server=SEU_SERVIDOR;Database=SEU_BANCO;Integrated Security=true;",
    "encryptedCredential": "..."
  }
}
```

### Passo 2: Configurar Atividade Stored Procedure

**Configurações Recomendadas:**
- **Nome**: `Executar_Carregamento_Dimensoes_Fatos`
- **Tipo**: `SqlServerStoredProcedure`
- **Procedure**: `[dbo].[uspExecutarCarregamentoCompleto]`
- **Timeout**: `01:00:00` (1 hora)
- **Retry**: `2` tentativas
- **Retry Interval**: `30` segundos

### Passo 3: Configurar Dependências

```json
"dependsOn": [
  {
    "activity": "ForEach_Servidores",
    "dependencyConditions": ["Succeeded"]
  }
]
```

## Monitoramento e Logs

### Logs no SQL Server

A procedure `uspExecutarCarregamentoCompleto` gera logs detalhados:

```
=========================================
INÍCIO DO CARREGAMENTO COMPLETO BI MÉTRICAS
Data/Hora: 2024-01-15 10:30:00
=========================================

1. CARREGANDO DIMENSÃO CLIENTES...
✓ Dimensão Clientes carregada com sucesso!
  Tempo de execução: 45 segundos

2. CARREGANDO TABELA FATO MÉTRICAS...
✓ Tabela Fato Métricas carregada com sucesso!
  Tempo de execução: 120 segundos

=========================================
✓ CARREGAMENTO CONCLUÍDO COM SUCESSO!
=========================================
Resumo da Execução:
• Dimensão Clientes: 45s
• Fato Métricas: 120s
• Tempo Total: 165s
Data/Hora Final: 2024-01-15 10:32:45
=========================================
```

### Monitoramento no ADF

- **Status da Atividade**: Sucesso/Falha
- **Duração**: Tempo total de execução
- **Logs de Saída**: Mensagens da procedure
- **Códigos de Retorno**: 0 (Sucesso) / 1 (Erro)

## Tratamento de Erros

### Estratégias Implementadas

1. **Rollback Automático**: Em caso de erro, todas as transações são desfeitas
2. **Logs Detalhados**: Captura procedure, linha, severidade e mensagem
3. **Re-propagação**: Erros são enviados para o ADF com contexto
4. **Retry no ADF**: Configurado para 2 tentativas com intervalo de 30s

### Exemplo de Log de Erro

```
=========================================
❌ ERRO NO CARREGAMENTO BI MÉTRICAS
=========================================
Detalhes do Erro:
• Procedure: uspLoadDimClientes
• Linha: 85
• Severidade: 16
• Estado: 1
• Tempo até erro: 30s
• Data/Hora do Erro: 2024-01-15 10:30:30

Mensagem do Erro:
Violation of PRIMARY KEY constraint...
=========================================
```

## Alternativas de Implementação

### Opção 1: Stored Procedure (Recomendada)
- Usa `uspExecutarCarregamentoCompleto`
- Melhor controle de transações
- Logs mais detalhados
- Códigos de retorno padronizados

### Opção 2: Script SQL
- Usa `ExecutarCarregamentoDimensoesFatos.sql`
- Execução via atividade SQL Script
- Mais simples, menos controle

### Opção 3: Atividades Separadas
- Uma atividade para cada procedure
- Maior granularidade de controle
- Mais complexo de configurar

## Benefícios da Integração

### Operacionais
- **Automação Completa**: Sem intervenção manual
- **Sequenciamento Garantido**: Dimensões antes de fatos
- **Monitoramento Centralizado**: Tudo no ADF
- **Retry Automático**: Recuperação de falhas temporárias

### Técnicos
- **Transações Atômicas**: Rollback em caso de erro
- **Logs Estruturados**: Facilita troubleshooting
- **Performance Otimizada**: Execução sequencial eficiente
- **Escalabilidade**: Suporta crescimento do volume de dados

## Próximos Passos

1. **Implementar**: Executar os scripts SQL no banco de dados
2. **Configurar**: Criar o pipeline no ADF usando o template JSON
3. **Testar**: Executar um ciclo completo de teste
4. **Monitorar**: Acompanhar execuções e ajustar timeouts se necessário
5. **Documentar**: Registrar configurações específicas do ambiente

## Suporte e Manutenção

- **Logs**: Verificar sempre os logs do SQL Server para detalhes
- **Performance**: Monitorar tempos de execução e otimizar se necessário
- **Alertas**: Configurar notificações no ADF para falhas
- **Backup**: Manter backup das configurações do pipeline

---

**Nota**: Este README assume familiaridade básica com Azure Data Factory. Para dúvidas específicas sobre configuração do ADF, consulte a documentação oficial da Microsoft.