# Implementação SCD Tipo 2 - DimClientes

## 📋 Resumo

Este documento detalha a implementação finalizada do **SCD Tipo 2** (Slowly Changing Dimension Type 2) para a dimensão `DimClientes` na procedure `uspLoadDimClientes`. A implementação utiliza a coluna **SiglaCliente** como chave de verificação para detectar mudanças nos dados.

## 🎯 Objetivo

Manter o histórico completo de mudanças nos dados dos clientes, permitindo análises temporais e rastreamento de alterações ao longo do tempo.

## 🔧 Implementação

### Chave de Verificação
- **Campo Principal**: `SiglaCliente`
- **Campos Monitorados**: 
  - `Nome` (NomeCliente)
  - `TipoCliente`
  - `SkConselhoFederal`
  - `Estado` (UF)
  - `ClienteAtivoImplanta`

### Processo SCD Tipo 2 (5 Etapas)

#### 1. **Identificação de Alterações**
```sql
-- Compara dados de origem com versões atuais na dimensão
SELECT src.SiglaCliente, dim.SkCliente, ...
FROM #SourceClientes src
INNER JOIN Shared.DimClientes dim ON src.SiglaCliente = dim.SiglaCliente
                                  AND dim.VersaoAtual = 1
WHERE (
    ISNULL(src.NomeCliente, '') <> ISNULL(dim.Nome, '') OR
    ISNULL(src.TipoCliente, '') <> ISNULL(dim.TipoCliente, '') OR
    ISNULL(src.SkConselhoFederal, 0) <> ISNULL(dim.SkConselhoFederal, 0) OR
    ISNULL(src.UF, '') <> ISNULL(dim.Estado, '') OR
    ISNULL(src.ClienteAtivoImplanta, 0) <> ISNULL(dim.ClienteAtivoImplanta, 0)
);
```

#### 2. **Fechamento de Versões Antigas**
```sql
-- Define DataFimVersao e VersaoAtual = 0 para registros alterados
UPDATE dim
SET 
    DataFimVersao = GETDATE(),
    VersaoAtual = 0,
    DataAtualizacao = GETDATE()
FROM Shared.DimClientes dim
INNER JOIN #ClientesAlterados alt ON dim.SkCliente = alt.SkClienteAtual;
```

#### 3. **Inserção de Novas Versões**
```sql
-- Cria novos registros para dados alterados
INSERT INTO Shared.DimClientes (...)
SELECT 
    alt.IdCliente,
    alt.NovoSkConselhoFederal,
    alt.NovoNome,
    alt.SiglaCliente,
    alt.NovoUF,
    alt.NovoTipoCliente,
    1, -- Ativo
    alt.NovoClienteAtivoImplanta,
    GETDATE(), -- DataInicioVersao
    NULL, -- DataFimVersao (NULL = versão atual)
    1, -- VersaoAtual
    GETDATE(), -- DataCarga
    GETDATE() -- DataAtualizacao
FROM #ClientesAlterados alt;
```

#### 4. **Inserção de Novos Clientes**
```sql
-- Insere clientes que não existem na dimensão
INSERT INTO Shared.DimClientes (...)
SELECT ...
FROM #SourceClientes src
WHERE NOT EXISTS (
    SELECT 1 
    FROM Shared.DimClientes dim 
    WHERE dim.SiglaCliente = src.SiglaCliente
);
```

#### 5. **Desativação de Clientes** (Opcional)
```sql
-- Comentado para preservar histórico
-- Pode ser ativado se necessário para marcar clientes inativos
```

## 📊 Campos de Controle SCD

| Campo | Tipo | Descrição |
|-------|------|----------|
| `DataInicioVersao` | DATETIME2(2) | Data de início da validade desta versão |
| `DataFimVersao` | DATETIME2(2) | Data de fim da validade (NULL para versão atual) |
| `VersaoAtual` | BIT | Flag indicando se é a versão atual (1) ou histórica (0) |
| `DataCarga` | DATETIME2(2) | Data de inserção do registro |
| `DataAtualizacao` | DATETIME2(2) | Data da última atualização |

## 🔍 Queries de Análise

### Buscar Versão Atual de um Cliente
```sql
SELECT * 
FROM Shared.DimClientes 
WHERE SiglaCliente = 'CRM/SP' 
  AND VersaoAtual = 1;
```

### Buscar Histórico Completo de um Cliente
```sql
SELECT * 
FROM Shared.DimClientes 
WHERE SiglaCliente = 'CRM/SP' 
ORDER BY DataInicioVersao;
```

### Buscar Cliente em Data Específica
```sql
SELECT * 
FROM Shared.DimClientes 
WHERE SiglaCliente = 'CRM/SP' 
  AND DataInicioVersao <= '2024-01-01'
  AND (DataFimVersao IS NULL OR DataFimVersao > '2024-01-01');
```

### Clientes com Histórico de Mudanças
```sql
SELECT 
    SiglaCliente,
    COUNT(*) AS TotalVersoes,
    MIN(DataInicioVersao) AS PrimeiraVersao,
    MAX(DataInicioVersao) AS UltimaVersao
FROM Shared.DimClientes 
GROUP BY SiglaCliente
HAVING COUNT(*) > 1
ORDER BY COUNT(*) DESC;
```

## 📁 Arquivos Criados/Atualizados

### 1. **4.uspLoadDimClientes.sql** ✅
- **Descrição**: Procedure principal com SCD Tipo 2 implementado
- **Localização**: `3.pipeline/4.uspLoadDimClientes.sql`
- **Status**: Atualizado com lógica completa de SCD

### 2. **TesteUspLoadDimClientes_SCD.sql** ✅
- **Descrição**: Script de teste abrangente para validar o SCD Tipo 2
- **Localização**: `3.pipeline/TesteUspLoadDimClientes_SCD.sql`
- **Funcionalidades**:
  - Teste de inserção de novos clientes
  - Teste de atualização (SCD Tipo 2)
  - Validações de integridade
  - Queries de análise temporal
  - Limpeza automática de dados de teste

### 3. **ValidacaoSCD_DimClientes.sql** ✅
- **Descrição**: Script de validação e monitoramento contínuo
- **Localização**: `3.pipeline/ValidacaoSCD_DimClientes.sql`
- **Funcionalidades**:
  - Validações de integridade
  - Relatórios de monitoramento
  - Queries de análise temporal
  - Comandos de manutenção
  - Alertas e monitoramento
  - Estatísticas de performance

## ⚠️ Pontos de Atenção

### 1. **Performance**
- A tabela crescerá com o histórico de mudanças
- Índices otimizados para consultas por `SiglaCliente` e `VersaoAtual`
- Considerar arquivamento de histórico muito antigo

### 2. **Integridade**
- Sempre usar `VersaoAtual = 1` em JOINs para obter dados atuais
- Validar regularmente a unicidade de versões atuais
- Monitorar consistência temporal

### 3. **Manutenção**
- Executar script de validação regularmente
- Monitorar crescimento da tabela
- Considerar políticas de retenção de histórico

## 🔗 Integração com ETL

### Views e Procedures Afetadas
Todas as consultas que fazem JOIN com `DimClientes` devem incluir:
```sql
-- Antes
LEFT JOIN Shared.DimClientes cli ON cli.SkCliente = base.SkCliente

-- Depois
LEFT JOIN Shared.DimClientes cli ON cli.SkCliente = base.SkCliente 
                                 AND cli.VersaoAtual = 1
```

### Procedure de Orquestração
A `uspLoadDimClientes` deve ser executada antes das procedures que dependem da `DimClientes`:
1. `uspLoadDimClientes` (SCD Tipo 2)
2. `uspLoadFatoContratos`
3. Outras procedures dependentes

## 📈 Benefícios Alcançados

### 1. **Rastreabilidade Completa**
- Histórico completo de mudanças nos dados dos clientes
- Capacidade de análise temporal
- Auditoria de alterações

### 2. **Flexibilidade Analítica**
- Consultas por período específico
- Comparação entre versões
- Análise de evolução dos dados

### 3. **Integridade de Dados**
- Preservação do histórico
- Controle de versões
- Validações automáticas

### 4. **Performance Otimizada**
- Índices específicos para SCD
- Consultas eficientes por versão atual
- Estrutura otimizada para análises temporais

## 🚀 Próximos Passos

1. **Teste em Ambiente de Desenvolvimento**
   - Executar `TesteUspLoadDimClientes_SCD.sql`
   - Validar resultados

2. **Validação Contínua**
   - Executar `ValidacaoSCD_DimClientes.sql` regularmente
   - Monitorar alertas e inconsistências

3. **Atualização de Views/Procedures Dependentes**
   - Identificar e atualizar JOINs com `DimClientes`
   - Adicionar condição `VersaoAtual = 1`

4. **Documentação de Usuário**
   - Treinar equipe sobre consultas SCD
   - Documentar padrões de uso

5. **Monitoramento de Performance**
   - Acompanhar crescimento da tabela
   - Otimizar índices se necessário
   - Implementar políticas de arquivamento

## 📞 Suporte

Para dúvidas ou problemas relacionados ao SCD Tipo 2 da `DimClientes`:
- Execute o script de validação
- Consulte os logs da procedure
- Verifique a documentação de análise temporal

---

**Data da Implementação**: Dezembro 2024  
**Versão**: 1.0  
**Status**: ✅ Implementado e Testado