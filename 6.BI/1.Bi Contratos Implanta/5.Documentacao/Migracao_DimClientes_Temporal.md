# Migração da Dimensão DimClientes para Modelo Temporal (SCD Tipo 2)

## Resumo das Alterações

Este documento descreve as alterações realizadas para migrar a dimensão `Shared.DimClientes` de um modelo simples para um modelo temporal com versionamento (SCD Tipo 2).

## Alterações na Estrutura da Tabela

### Antes (Modelo Simples)
```sql
CREATE TABLE [Shared].[DimClientes]
(
    [SkCliente]         SMALLINT         NOT NULL IDENTITY(0, 1),
    [IdCliente]         UNIQUEIDENTIFIER NOT NULL,
    [SkConselhoFederal] SMALLINT         NOT NULL,
    [Nome]              VARCHAR(100)     NOT NULL,
    [Sigla]             VARCHAR(50)      NOT NULL,
    [Estado]            CHAR(2),
    [TipoCliente]       VARCHAR(20),
    [Ativo]             BIT DEFAULT 1,
    [DataCarga]         DATETIME2(2) DEFAULT GETDATE(),
    [DataAtualizacao]   DATETIME2(2) DEFAULT GETDATE()
);
```

### Depois (Modelo Temporal - SCD Tipo 2)
```sql
CREATE TABLE [Shared].[DimClientes]
(
    [SkCliente]         INT              NOT NULL IDENTITY(1, 1),  -- Mudou de SMALLINT para INT
    [IdCliente]         UNIQUEIDENTIFIER NOT NULL,                  -- Chave natural
    [SkConselhoFederal] SMALLINT         NOT NULL,
    [Nome]              VARCHAR(100)     NOT NULL,
    [Sigla]             VARCHAR(50)      NOT NULL,
    [Estado]            CHAR(2),
    [TipoCliente]       VARCHAR(20),
    [Ativo]             BIT DEFAULT 1,
    
    -- Campos de versionamento temporal (SCD Tipo 2)
    [DataInicioVersao]  DATETIME2(2)     NOT NULL DEFAULT GETDATE(),
    [DataFimVersao]     DATETIME2(2)     NULL,                      -- NULL = versão atual
    [VersaoAtual]       BIT              NOT NULL DEFAULT 1,        -- 1 = versão atual, 0 = histórica
    
    -- Auditoria
    [DataCarga]         DATETIME2(2) DEFAULT GETDATE(),
    [DataAtualizacao]   DATETIME2(2) DEFAULT GETDATE()
);
```

## Novos Campos Adicionados

| Campo | Tipo | Descrição |
|-------|------|----------|
| `DataInicioVersao` | DATETIME2(2) | Data de início da validade desta versão do registro |
| `DataFimVersao` | DATETIME2(2) | Data de fim da validade (NULL para versão atual) |
| `VersaoAtual` | BIT | Flag indicando se é a versão atual (1) ou histórica (0) |

## Novos Índices

1. **IX_DimClientes_IdCliente_VersaoAtual**: Para busca eficiente por chave natural e versão atual
2. **IX_DimClientes_Sigla_VersaoAtual**: Para busca por sigla considerando apenas versão atual
3. **IX_DimClientes_Historico**: Para consultas históricas por período

## Alterações na Procedure de Carga

A procedure `Shared.uspLoadDimClientes` foi completamente reescrita para implementar SCD Tipo 2:

### Processo de Carga (5 Etapas)

1. **Identificar Alterações**: Compara dados de origem com versões atuais na dimensão
2. **Fechar Versões Antigas**: Define `DataFimVersao` e `VersaoAtual = 0` para registros alterados
3. **Inserir Novas Versões**: Cria novos registros para dados alterados
4. **Inserir Novos Clientes**: Adiciona clientes que não existem na dimensão
5. **Atualizar Metadados**: Atualiza `DataAtualizacao` para registros inalterados

### Campos Monitorados para Detecção de Mudanças
- `Nome`
- `TipoCliente`
- `SkConselhoFederal`

## Alterações em Views e Procedures

Todos os JOINs com `DimClientes` foram atualizados para incluir a condição `VersaoAtual = 1`:

### Arquivos Alterados:
- `VwGetFatoContratos.sql`
- `1.QueryValidacao.sql`
- `8.uspLoadFato.sql`

### Exemplo de Alteração:
```sql
-- Antes
LEFT JOIN Shared.DimClientes cli ON cli.SkCliente = base.SkCliente

-- Depois
LEFT JOIN Shared.DimClientes cli ON cli.SkCliente = base.SkCliente AND cli.VersaoAtual = 1
```

## Alterações na Tabela Fato

O tipo da chave `SkCliente` foi alterado de `SMALLINT` para `INT` para acomodar o maior volume de registros históricos.

## Benefícios da Implementação

1. **Histórico Completo**: Mantém todas as versões dos dados de clientes
2. **Auditoria**: Rastreabilidade completa de mudanças
3. **Consultas Temporais**: Possibilidade de análises em qualquer ponto no tempo
4. **Integridade**: Preserva a consistência dos dados históricos

## Consultas de Exemplo

### Buscar Versão Atual de um Cliente
```sql
SELECT * 
FROM Shared.DimClientes 
WHERE IdCliente = 'GUID_DO_CLIENTE' 
  AND VersaoAtual = 1;
```

### Buscar Histórico de um Cliente
```sql
SELECT * 
FROM Shared.DimClientes 
WHERE IdCliente = 'GUID_DO_CLIENTE' 
ORDER BY DataInicioVersao;
```

### Buscar Cliente em Data Específica
```sql
SELECT * 
FROM Shared.DimClientes 
WHERE IdCliente = 'GUID_DO_CLIENTE' 
  AND DataInicioVersao <= '2024-01-01'
  AND (DataFimVersao IS NULL OR DataFimVersao > '2024-01-01');
```

## Considerações de Performance

- Índices otimizados para consultas por versão atual
- Compressão de dados habilitada (PAGE)
- Fill factor de 95% para índices não-clusterizados

## Impacto em Relatórios

- Relatórios existentes continuam funcionando normalmente
- Novos relatórios podem aproveitar dados históricos
- Performance mantida através de índices apropriados

---

**Data da Migração**: $(Get-Date -Format "yyyy-MM-dd")
**Responsável**: Sistema de BI - Data Warehouse
**Versão**: 2.0