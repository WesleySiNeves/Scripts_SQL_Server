# 📊 Procedure uspLoadDimMetricas - Versão Melhorada

## 🎯 Visão Geral

A procedure `uspLoadDimMetricas` foi completamente reescrita para implementar um **SCD Tipo 2 (Slowly Changing Dimension)** robusto e eficiente para a dimensão de métricas do Data Warehouse.

## 🚀 Principais Melhorias Implementadas

### ✅ 1. **SCD Tipo 2 Completo**
- **Inserção de novas métricas**: Métricas que não existem são inseridas automaticamente
- **Versionamento automático**: Mudanças no `TipoRetorno` geram novas versões
- **Histórico preservado**: Todas as versões anteriores são mantidas para auditoria
- **Controle temporal**: Campos `DataInicioVersao`, `DataFimVersao` e `VersaoAtual`

### ✅ 2. **Categorização Inteligente**
```sql
-- Categorização automática baseada no nome da métrica
CASE 
    WHEN NomeMetrica LIKE '%Performance%' OR NomeMetrica LIKE '%Tempo%' THEN 'Performance'
    WHEN NomeMetrica LIKE '%Erro%' OR NomeMetrica LIKE '%Falha%' THEN 'Qualidade'
    WHEN NomeMetrica LIKE '%Usuario%' OR NomeMetrica LIKE '%Login%' THEN 'Acesso'
    WHEN NomeMetrica LIKE '%Backup%' OR NomeMetrica LIKE '%Manutencao%' THEN 'Infraestrutura'
    WHEN NomeMetrica LIKE '%Relatorio%' OR NomeMetrica LIKE '%Dashboard%' THEN 'Relatórios'
    ELSE 'Geral'
END
```

### ✅ 3. **Descrições Automáticas**
```sql
-- Descrição baseada no tipo de retorno
CASE 
    WHEN TipoRetorno = 'BIT' THEN 'Métrica booleana: ' + NomeMetrica
    WHEN TipoRetorno IN ('INT', 'DECIMAL', 'NUMERIC') THEN 'Métrica numérica: ' + NomeMetrica
    WHEN TipoRetorno = 'DATETIME' THEN 'Métrica temporal: ' + NomeMetrica
    ELSE 'Métrica textual: ' + NomeMetrica
END
```

### ✅ 4. **Gestão de Ciclo de Vida**
- **Ativação automática**: Novas métricas são marcadas como ativas
- **Desativação inteligente**: Métricas que não aparecem mais no staging são desativadas
- **Preservação de histórico**: Métricas desativadas mantêm seu histórico

### ✅ 5. **Tratamento Robusto de Erros**
- **Transações**: Rollback automático em caso de erro
- **Logging detalhado**: Informações completas sobre execução e erros
- **Re-throw**: Propagação de erros para sistemas de monitoramento

### ✅ 6. **Auditoria Completa**
- **Contadores**: Registros inseridos e atualizados
- **Timestamps**: Controle preciso de datas
- **Log estruturado**: Informações formatadas para análise

## 📋 Estrutura da Procedure

### **Etapa 1: Inserção de Novas Métricas**
```sql
-- Identifica métricas que não existem na dimensão
-- Insere com categorização e descrição automáticas
-- Marca como versão atual e ativa
```

### **Etapa 2: Versionamento (SCD Tipo 2)**
```sql
-- 2.1: Fecha versões antigas (DataFimVersao + VersaoAtual = 0)
-- 2.2: Insere novas versões para métricas modificadas
-- Detecta mudanças no TipoRetorno
```

### **Etapa 3: Gestão de Métricas Inativas**
```sql
-- Desativa métricas que não aparecem mais no staging
-- Preserva histórico para auditoria
```

## 🔧 Como Usar

### **Execução Simples**
```sql
EXEC [DM_MetricasClientes].[uspLoadDimMetricas];
```

### **Monitoramento da Execução**
```sql
-- A procedure gera logs automáticos:
=== CARGA DimMetricas CONCLUÍDA ===
Data/Hora: 2024-01-15 14:30:25
Métricas Inseridas (Novas): 5
Métricas Atualizadas (SCD): 2
======================================
```

## 🧪 Scripts de Teste e Validação

### **1. TesteUspLoadDimMetricas.sql**
- **Testes automatizados** para todas as funcionalidades
- **Cenários de teste**: Inserção, atualização, desativação
- **Validação de resultados** com queries específicas
- **Limpeza automática** dos dados de teste

### **2. ValidacaoSCD_DimMetricas.sql**
- **Validações de integridade** do SCD Tipo 2
- **Relatórios de monitoramento** detalhados
- **Alertas automáticos** para inconsistências
- **Comandos de manutenção** prontos para uso

## 📊 Campos de Controle SCD

| Campo | Tipo | Descrição |
|-------|------|----------|
| `DataInicioVersao` | DATETIME2(2) | Início da validade da versão |
| `DataFimVersao` | DATETIME2(2) | Fim da validade (NULL = atual) |
| `VersaoAtual` | BIT | Flag da versão ativa (1 = atual, 0 = histórica) |
| `DataCarga` | DATETIME2(2) | Data de criação do registro |
| `DataAtualizacao` | DATETIME2(2) | Data da última modificação |

## 🔍 Queries de Análise

### **Versões Atuais**
```sql
SELECT * 
FROM [DM_MetricasClientes].[DimMetricas] 
WHERE [VersaoAtual] = 1;
```

### **Histórico de uma Métrica**
```sql
SELECT * 
FROM [DM_MetricasClientes].[DimMetricas] 
WHERE [NomeMetrica] = 'SuaMetrica'
ORDER BY [DataInicioVersao];
```

### **Métricas Válidas em Data Específica**
```sql
DECLARE @DataConsulta DATETIME2(2) = '2024-01-15';
SELECT * 
FROM [DM_MetricasClientes].[DimMetricas]
WHERE [DataInicioVersao] <= @DataConsulta
  AND ([DataFimVersao] IS NULL OR [DataFimVersao] > @DataConsulta);
```

## ⚠️ Pontos de Atenção

### **1. Critério de Mudança**
- Atualmente detecta mudanças apenas no campo `TipoRetorno`
- Para detectar outras mudanças, adicione condições na seção de UPDATE

### **2. Performance**
- Procedure otimizada para grandes volumes
- Usa transações para garantir consistência
- Recomenda-se execução em horários de baixa demanda

### **3. Monitoramento**
- Execute `ValidacaoSCD_DimMetricas.sql` regularmente
- Monitore logs de execução
- Configure alertas para inconsistências

## 🔄 Integração com ETL

### **Ordem de Execução Recomendada**
```sql
-- 1. Carregar staging
EXEC [Staging].[uspLoadMetricasSCD] @DadosADF;

-- 2. Carregar dimensões
EXEC [DM_MetricasClientes].[uspLoadDimTipoRetorno];
EXEC [DM_MetricasClientes].[uspLoadDimMetricas];  -- ← Nova versão

-- 3. Carregar fato
EXEC [DM_MetricasClientes].[uspLoadFatoMetricasClientes];
```

## 📈 Benefícios da Implementação

### **✅ Rastreabilidade Completa**
- Histórico completo de todas as mudanças
- Auditoria temporal precisa
- Capacidade de "voltar no tempo"

### **✅ Automação Inteligente**
- Categorização automática de métricas
- Descrições geradas automaticamente
- Gestão automática do ciclo de vida

### **✅ Robustez Operacional**
- Tratamento de erros robusto
- Logging detalhado
- Validações de integridade

### **✅ Facilidade de Manutenção**
- Código bem documentado
- Scripts de teste incluídos
- Queries de monitoramento prontas

## 🚀 Próximos Passos

1. **Teste em ambiente de desenvolvimento**
   ```sql
   -- Execute o script de teste
   EXEC [TesteUspLoadDimMetricas.sql]
   ```

2. **Validação de integridade**
   ```sql
   -- Execute as validações
   EXEC [ValidacaoSCD_DimMetricas.sql]
   ```

3. **Deploy em produção**
   - Backup da procedure atual
   - Deploy da nova versão
   - Monitoramento pós-deploy

4. **Configuração de monitoramento**
   - Agendar execução das validações
   - Configurar alertas automáticos
   - Documentar procedimentos operacionais

---

**📝 Nota**: Esta implementação segue as melhores práticas de Data Warehousing e está otimizada para ambientes Azure SQL Database com compressão de dados habilitada.

**🔗 Arquivos Relacionados**:
- `2.uspLoadDimMetricas.sql` - Procedure principal
- `TesteUspLoadDimMetricas.sql` - Scripts de teste
- `ValidacaoSCD_DimMetricas.sql` - Validações e monitoramento
- `README_Procedures.md` - Documentação geral do projeto