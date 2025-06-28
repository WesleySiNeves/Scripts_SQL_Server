# Módulo 10: Window Functions

## 🎯 Objetivos do Módulo
- Dominar todas as Window Functions do SQL Server
- Compreender OVER(), PARTITION BY e ORDER BY
- Aplicar Window Frames (ROWS/RANGE)
- Resolver problemas analíticos complexos
- Otimizar consultas com funções de janela

## 📚 Conteúdo Programático

### 10.1 Fundamentos de Window Functions
- Conceito e sintaxe básica
- Cláusula OVER()
- PARTITION BY vs GROUP BY
- ORDER BY em Window Functions
- Diferenças com funções de agregação tradicionais

### 10.2 Funções de Ranking
- ROW_NUMBER()
- RANK() e DENSE_RANK()
- NTILE()
- Casos práticos de ranking

### 10.3 Funções de Agregação com OVER
- SUM(), COUNT(), AVG() com OVER
- MIN() e MAX() com janelas
- Totais acumulados (Running Totals)
- Médias móveis

### 10.4 Funções de Offset
- LAG() e LEAD()
- FIRST_VALUE() e LAST_VALUE()
- Comparações temporais
- Análise de tendências

### 10.5 Window Frames
- ROWS vs RANGE
- UNBOUNDED PRECEDING/FOLLOWING
- CURRENT ROW
- N PRECEDING/FOLLOWING
- Casos práticos com frames

### 10.6 Análises Avançadas
- Percentuais relativos
- Razões contábeis
- Análises de séries temporais
- Cálculos financeiros
- Detecção de padrões

### 10.7 Performance e Otimização
- Índices para Window Functions
- Ordem de execução
- Combinação com CTEs
- Melhores práticas

## 📁 Arquivos do Módulo

### Exemplos/
- `01_fundamentos_over.sql` - Conceitos básicos
- `02_funcoes_ranking.sql` - ROW_NUMBER, RANK, DENSE_RANK
- `03_agregacao_over.sql` - SUM, COUNT, AVG com OVER
- `04_funcoes_offset.sql` - LAG, LEAD, FIRST_VALUE, LAST_VALUE
- `05_window_frames.sql` - ROWS e RANGE
- `06_analises_avancadas.sql` - Casos complexos
- `07_performance_otimizacao.sql` - Otimização

### Exercicios/
- `exercicio_01_ranking.sql` - Prática com ranking
- `exercicio_02_totais_acumulados.sql` - Running totals
- `exercicio_03_analise_temporal.sql` - Séries temporais

### Desafios/
- `desafio_dashboard_vendas.sql` - Dashboard completo
- `desafio_analise_financeira.sql` - Análise financeira
- `desafio_deteccao_padroes.sql` - Padrões de comportamento

## 🎯 Habilidades Desenvolvidas
- ✅ Criar rankings e classificações
- ✅ Calcular totais acumulados
- ✅ Implementar médias móveis
- ✅ Analisar tendências temporais
- ✅ Otimizar consultas analíticas

## 💡 Conceitos Fundamentais

### Estrutura Básica
```sql
SELECT 
    coluna,
    FUNCAO() OVER (
        [PARTITION BY coluna(s)]
        [ORDER BY coluna(s)]
        [ROWS/RANGE frame_specification]
    ) AS resultado
FROM tabela;
```

### Tipos de Window Functions

| Categoria | Funções | Uso Principal |
|-----------|---------|---------------|
| **Ranking** | ROW_NUMBER, RANK, DENSE_RANK, NTILE | Classificações e rankings |
| **Agregação** | SUM, COUNT, AVG, MIN, MAX | Totais e médias com janelas |
| **Offset** | LAG, LEAD, FIRST_VALUE, LAST_VALUE | Comparações entre linhas |
| **Analíticas** | PERCENT_RANK, CUME_DIST, PERCENTILE_CONT | Análises estatísticas |

### Window Frames Mais Usados

| Frame | Descrição | Uso |
|-------|-----------|-----|
| `ROWS UNBOUNDED PRECEDING` | Do início até linha atual | Total acumulado |
| `ROWS BETWEEN 2 PRECEDING AND CURRENT ROW` | 3 linhas (2 anteriores + atual) | Média móvel 3 períodos |
| `RANGE BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW` | Valores iguais incluídos | Total por valor |

## 🔧 Dicas de Performance

### Otimização
- Crie índices nas colunas de PARTITION BY e ORDER BY
- Use Window Functions ao invés de subconsultas correlacionadas
- Combine múltiplas Window Functions com a mesma janela
- Evite ORDER BY desnecessário quando não precisar

### Melhores Práticas
- Documente frames complexos
- Use aliases descritivos
- Teste com volumes reais de dados
- Considere materialização para consultas frequentes

## 🎨 Casos de Uso Comuns

### Business Intelligence
- Rankings de vendas
- Análise de crescimento
- Comparações período a período
- Identificação de outliers

### Análise Financeira
- Totais acumulados
- Médias móveis
- Variações percentuais
- Análise de tendências

### Relatórios Gerenciais
- Top N por categoria
- Participação percentual
- Evolução temporal
- Benchmarking

## 🔗 Conexão com Módulos
- **Anterior**: Estruturas de Controle
- **Próximo**: Análise de Dados
- **Relacionado**: CTEs, Subconsultas, Funções Avançadas

---
**Tempo Estimado**: 12-15 horas  
**Nível**: Avançado  
**Pré-requisitos**: Módulos 1-9 completos