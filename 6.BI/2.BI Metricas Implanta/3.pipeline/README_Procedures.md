# Procedures de Carga - Data Warehouse Métricas

## Visão Geral

Este diretório contém as procedures de carga (ETL) para o Data Warehouse de Métricas de Clientes, implementadas usando a estratégia MERGE para sincronização eficiente dos dados.

## Arquivos Criados

### 1. uspLoadDimMetricas.sql
**Descrição:** Procedure para carga da dimensão DimMetricas com SCD Tipo 2
- **Schema:** `DM_MetricasClientes`
- **Tipo:** SCD Tipo 2 (Slowly Changing Dimension)
- **Fonte:** `Staging.MetricasClientes`
- **Funcionalidades:**
  - Identifica registros novos e modificados
  - Fecha versões antigas automaticamente
  - Insere novas versões mantendo histórico
  - Categoriza métricas automaticamente por tipo

### 2. uspLoadDimTipoRetorno.sql
**Descrição:** Procedure para carga da dimensão DimTipoRetorno (dimensão simples)
- **Schema:** `DM_MetricasClientes`
- **Tipo:** Dimensão simples (sem versionamento)
- **Fonte:** `Staging.MetricasClientes`
- **Funcionalidades:**
  - Sincronização usando MERGE
  - Desativação automática de tipos não utilizados
  - Descrições automáticas por tipo de dados

### 3. uspLoadFatoMetricasClientes.sql
**Descrição:** Procedure para carga da tabela fato principal
- **Schema:** `DM_MetricasClientes`
- **Fonte:** `Staging.MetricasClientes`
- **Funcionalidades:**
  - Joins com dimensões compartilhadas (DimClientes, DimProdutos)
  - Conversão automática de tipos de dados
  - Suporte a snapshots temporais
  - Tratamento de valores nulos e inválidos

### 4. uspOrquestracaoETL.sql
**Descrição:** Procedure principal de orquestração do processo ETL
- **Schema:** `DM_MetricasClientes`
- **Funcionalidades:**
  - Execução sequencial de todas as procedures
  - Controle de transações
  - Log detalhado de execução
  - Limpeza opcional do staging
  - Tratamento de erros robusto

### 5. uspInicializarDimensoes.sql
**Descrição:** Procedure para inicialização das dimensões com dados padrão
- **Schema:** `DM_MetricasClientes`
- **Funcionalidades:**
  - Popula tipos de retorno padrão
  - Insere métricas de exemplo
  - Valida dimensões compartilhadas
  - Útil para configuração inicial e testes

## Dependências

### Dimensões Compartilhadas (Projeto de Contratos)
As seguintes dimensões são compartilhadas com o projeto `1.Bi Contratos Implanta`:

- **Shared.DimClientes** - Dimensão de clientes (SCD Tipo 2)
- **Shared.DimProdutos** - Dimensão de produtos/sistemas (SCD Tipo 2)
- **Shared.DimTempo** - Dimensão temporal
- **Shared.DimConselhosFederais** - Dimensão de conselhos federais
- **Shared.DimCategorias** - Dimensão de categorias
- **Shared.DimGeografia** - Dimensão geográfica

### Tabelas de Staging
- **Staging.MetricasClientes** - Tabela de staging principal

## Ordem de Execução

### Execução Manual (Passo a Passo)
```sql
-- 1. Inicializar dimensões (apenas primeira vez)
EXEC [DM_MetricasClientes].[uspInicializarDimensoes];

-- 2. Carregar dimensão de tipos de retorno
EXEC [DM_MetricasClientes].[uspLoadDimTipoRetorno];

-- 3. Carregar dimensão de métricas
EXEC [DM_MetricasClientes].[uspLoadDimMetricas];

-- 4. Carregar tabela fato
EXEC [DM_MetricasClientes].[uspLoadFatoMetricasClientes];
```

### Execução Automatizada (Recomendada)
```sql
-- Execução completa com data atual
EXEC [DM_MetricasClientes].[uspOrquestracaoETL];

-- Execução com snapshot específico
EXEC [DM_MetricasClientes].[uspOrquestracaoETL] 
    @DataSnapshot = '2024-01-15';

-- Execução sem limpeza do staging
EXEC [DM_MetricasClientes].[uspOrquestracaoETL] 
    @ExecutarLimpezaStaging = 0;
```

## Características Técnicas

### Estratégia MERGE
- **Vantagens:**
  - Operação atômica (INSERT/UPDATE/DELETE em uma única operação)
  - Melhor performance para sincronização
  - Reduz bloqueios e fragmentação
  - Controle preciso de mudanças

### SCD Tipo 2 (DimMetricas)
- **Campos de Controle:**
  - `DataInicioVersao`: Data de início da versão
  - `DataFimVersao`: Data de fim da versão (NULL = atual)
  - `VersaoAtual`: Flag indicando versão ativa (1 = atual, 0 = histórica)

### Tratamento de Tipos de Dados
A procedure da tabela fato converte automaticamente os valores conforme o tipo:
- **VARCHAR/CHAR/TEXT** → `ValorTexto`
- **INT/DECIMAL/FLOAT** → `ValorNumerico`
- **DATETIME/DATE** → `ValorData`
- **BIT** → `ValorBooleano`

### Auditoria e Rastreabilidade
- Todas as tabelas possuem campos de auditoria:
  - `DataCarga`: Data de inserção do registro
  - `DataAtualizacao`: Data da última modificação
- A tabela fato mantém versões das dimensões para auditoria histórica

## Monitoramento e Logs

### Logs de Execução
A procedure de orquestração gera logs detalhados:
- Horário de início e fim
- Tempo total de execução
- Quantidade de registros processados
- Mensagens de erro detalhadas

### Validações Implementadas
- Verificação de dados no staging
- Validação de dimensões compartilhadas
- Tratamento de valores nulos e inválidos
- Controle de transações com rollback automático

## Configuração de Permissões

Todas as procedures concedem permissão para o role `db_executor`:
```sql
GRANT EXECUTE ON [Schema].[ProcedureName] TO [db_executor];
```

## Manutenção e Otimização

### Limpeza do Staging
- A orquestração remove automaticamente registros com mais de 7 dias
- Pode ser desabilitada com `@ExecutarLimpezaStaging = 0`

### Índices Recomendados
Os índices já estão definidos no arquivo `bancoDados.sql`:
- Índices clustered nas chaves primárias
- Índices não-clustered para consultas frequentes
- Índices de cobertura para performance

### Compressão de Dados
Todas as tabelas utilizam `DATA_COMPRESSION = PAGE` para otimização de espaço.

## Troubleshooting

### Problemas Comuns

1. **Erro: Dimensões compartilhadas não encontradas**
   - Verificar se o projeto de contratos foi executado
   - Executar `uspInicializarDimensoes` para validar

2. **Erro: Staging vazio**
   - Normal na primeira execução
   - Verificar processo de carga do staging

3. **Erro: Conversão de tipos**
   - Verificar qualidade dos dados no staging
   - Validar mapeamento de tipos na procedure da fato

4. **Performance lenta**
   - Verificar estatísticas das tabelas
   - Analisar planos de execução
   - Considerar particionamento para grandes volumes

### Comandos Úteis para Diagnóstico

```sql
-- Verificar status das dimensões
SELECT 'DimClientes' as Dimensao, COUNT(*) as Total, 
       SUM(CASE WHEN VersaoAtual = 1 THEN 1 ELSE 0 END) as Atuais
FROM [Shared].[DimClientes]
UNION ALL
SELECT 'DimProdutos', COUNT(*), 
       SUM(CASE WHEN VersaoAtual = 1 THEN 1 ELSE 0 END)
FROM [Shared].[DimProdutos]
UNION ALL
SELECT 'DimMetricas', COUNT(*), 
       SUM(CASE WHEN VersaoAtual = 1 THEN 1 ELSE 0 END)
FROM [DM_MetricasClientes].[DimMetricas];

-- Verificar dados no staging
SELECT COUNT(*) as TotalStaging, 
       COUNT(DISTINCT Cliente) as ClientesUnicos,
       COUNT(DISTINCT NomeMetrica) as MetricasUnicas
FROM [Staging].[MetricasClientes];

-- Verificar última execução da fato
SELECT TOP 10 DataSnapshot, COUNT(*) as Registros
FROM [DM_MetricasClientes].[FatoMetricasClientes]
GROUP BY DataSnapshot
ORDER BY DataSnapshot DESC;
```