# Migração DimProdutos para Modelo Temporal (SCD Tipo 2)

## Resumo
Este documento detalha a migração da dimensão `Shared.DimProdutos` de um modelo simples para um modelo temporal utilizando Slowly Changing Dimensions (SCD) Tipo 2, permitindo o versionamento e rastreamento histórico de mudanças nos produtos.

## Alterações na Estrutura da Tabela

### Antes (Modelo Simples)
```sql
CREATE TABLE [Shared].[DimProdutos]
(
    [SkProduto]         TINYINT IDENTITY(1,1) NOT NULL,
    [IdProduto]         UNIQUEIDENTIFIER,
    [DescricaoImplanta] VARCHAR(250),
    [DescricaoCigam]    VARCHAR(250),
    [Area]              VARCHAR(50),
    [Ativo]             BIT,
    [DataCarga]         DATETIME2(2),
    [DataAtualizacao]   DATETIME2(2)
);
```

### Depois (Modelo Temporal SCD Tipo 2)
```sql
CREATE TABLE [Shared].[DimProdutos]
(
    [SkProduto]         INT IDENTITY(1,1) NOT NULL,  -- Alterado de TINYINT para INT
    [IdProduto]         UNIQUEIDENTIFIER,
    [DescricaoImplanta] VARCHAR(250),
    [DescricaoCigam]    VARCHAR(250),
    [Area]              VARCHAR(50),
    [Ativo]             BIT,
    [DataInicioVersao]  DATETIME2(2) NOT NULL,       -- Novo campo
    [DataFimVersao]     DATETIME2(2) NULL,           -- Novo campo
    [VersaoAtual]       BIT NOT NULL,                -- Novo campo
    [DataCarga]         DATETIME2(2),
    [DataAtualizacao]   DATETIME2(2)
);
```

### Principais Mudanças
1. **Tipo da Chave Primária**: `SkProduto` alterado de `TINYINT` para `INT` para suportar mais versões
2. **Campos de Versionamento**:
   - `DataInicioVersao`: Data de início da versão do registro
   - `DataFimVersao`: Data de fim da versão (NULL para versão atual)
   - `VersaoAtual`: Flag indicando se é a versão atual (1) ou histórica (0)

## Novos Índices

```sql
-- Índice para busca por chave natural e versão atual
CREATE NONCLUSTERED INDEX [IX_DimProdutos_IdProduto_VersaoAtual]
ON [Shared].[DimProdutos] ([IdProduto], [VersaoAtual])
WITH (DATA_COMPRESSION = PAGE, FILLFACTOR = 95);

-- Índice único para garantir apenas uma versão atual por produto
CREATE UNIQUE NONCLUSTERED INDEX IX_DimProdutos_IdProduto_VersaoAtual_Unique
ON [Shared].[DimProdutos] ([IdProduto], [VersaoAtual])
WHERE [VersaoAtual] = 1
WITH (DATA_COMPRESSION = PAGE, FILLFACTOR = 95);

-- Índice para consultas históricas
CREATE NONCLUSTERED INDEX IX_DimProdutos_Historico
ON [Shared].[DimProdutos] (DataInicioVersao, DataFimVersao)
WITH (DATA_COMPRESSION = PAGE, FILLFACTOR = 95);

-- Índice para busca por descrição na versão atual
CREATE NONCLUSTERED INDEX IX_DimProdutos_Descricao_VersaoAtual
ON [Shared].[DimProdutos] ([DescricaoCigam], [VersaoAtual])
WITH (DATA_COMPRESSION = PAGE, FILLFACTOR = 95);
```

## Alterações na Procedure de Carga

### Nova Implementação: `Shared.uspLoadDimProdutos`

A procedure foi completamente reescrita para implementar o processo SCD Tipo 2:

#### Etapas do Processo de Carga:
1. **Carregamento de Dados**: Extração dos produtos do staging
2. **Mapeamento**: Correlação entre descrições CIGAM e Implanta
3. **Enriquecimento**: Adição de informações dos sistemas
4. **Tratamento de Não Categorizados**: Criação de produtos para itens não mapeados
5. **Identificação de Mudanças**: Detecção de alterações nos campos monitorados
6. **Fechamento de Versões**: Encerramento de versões antigas
7. **Criação de Novas Versões**: Inserção de novas versões para registros alterados
8. **Inserção de Novos Produtos**: Adição de produtos completamente novos
9. **Atualização de Metadados**: Atualização da data de atualização

#### Campos Monitorados para Mudanças:
- `DescricaoImplanta`
- `Area`
- `Ativo`

#### Tratamento de Erros:
A procedure inclui blocos `TRY/CATCH` para captura e tratamento de erros.

## Alterações em Views e Procedures

### Arquivos Atualizados:
1. **VwGetFatoContratos.sql**: Adicionada condição `AND prod.VersaoAtual = 1`
2. **1.QueryValidacao.sql**: Adicionada condição `AND prod.VersaoAtual = 1`
3. **8.uspLoadFato.sql**: Adicionada condição `AND prod.VersaoAtual = 1`

### Exemplo de Alteração:
```sql
-- Antes
LEFT JOIN Shared.DimProdutos prod ON prod.SkProduto = base.SkProduto

-- Depois
LEFT JOIN Shared.DimProdutos prod ON prod.SkProduto = base.SkProduto AND prod.VersaoAtual = 1
```

## Alterações na Tabela Fato

O tipo da chave `SkProduto` na tabela fato foi alterado de `TINYINT` para `INT` para compatibilidade:

```sql
-- Tabela: Shared.FatoContratosProdutos
[SkProduto] INT NOT NULL,  -- Alterado de TINYINT para INT
```

## Benefícios da Implementação

1. **Rastreamento Histórico**: Capacidade de consultar o estado dos produtos em qualquer ponto no tempo
2. **Auditoria**: Registro completo de todas as mudanças nos produtos
3. **Análises Temporais**: Possibilidade de análises de tendências e evolução dos produtos
4. **Integridade Referencial**: Manutenção da consistência dos dados históricos
5. **Performance**: Índices otimizados para consultas atuais e históricas

## Consultas de Exemplo

### Buscar Versão Atual de um Produto:
```sql
SELECT *
FROM Shared.DimProdutos
WHERE IdProduto = 'GUID_DO_PRODUTO'
  AND VersaoAtual = 1;
```

### Buscar Histórico de um Produto:
```sql
SELECT *
FROM Shared.DimProdutos
WHERE IdProduto = 'GUID_DO_PRODUTO'
ORDER BY DataInicioVersao;
```

### Buscar Produtos Ativos em uma Data Específica:
```sql
SELECT *
FROM Shared.DimProdutos
WHERE DataInicioVersao <= '2024-01-01'
  AND (DataFimVersao IS NULL OR DataFimVersao > '2024-01-01');
```

## Considerações de Migração

1. **Backup**: Realizar backup completo antes da migração
2. **Dados Existentes**: Os dados atuais serão migrados como versão inicial (VersaoAtual = 1)
3. **Aplicações**: Verificar se aplicações externas precisam ser atualizadas
4. **Performance**: Monitorar performance após a implementação
5. **Espaço em Disco**: O modelo temporal pode aumentar o uso de espaço

## Data da Implementação
**Data**: 2024-12-19  
**Responsável**: Sistema de BI - Contratos  
**Status**: Implementado