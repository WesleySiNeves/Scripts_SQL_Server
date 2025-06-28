# Módulo 6: Subconsultas e CTEs

## 🎯 Objetivos do Módulo
- Dominar subconsultas em todas as suas formas
- Compreender e aplicar Common Table Expressions (CTEs)
- Trabalhar com CTEs recursivas
- Otimizar consultas complexas
- Resolver problemas hierárquicos

## 📚 Conteúdo Programático

### 6.1 Subconsultas Básicas
- Conceito e sintaxe
- Subconsultas no SELECT
- Subconsultas no WHERE
- Subconsultas no FROM
- Performance e otimização

### 6.2 Subconsultas Correlacionadas
- Diferença entre correlacionadas e não-correlacionadas
- EXISTS e NOT EXISTS
- Casos práticos de uso
- Otimização de subconsultas correlacionadas

### 6.3 Operadores de Subconsulta
- IN e NOT IN
- ANY, ALL, SOME
- Comparações com subconsultas
- Tratamento de valores NULL

### 6.4 Common Table Expressions (CTEs)
- Sintaxe e estrutura básica
- Vantagens sobre subconsultas
- CTEs múltiplas
- Reutilização de código

### 6.5 CTEs Não-Recursivas
- Simplificação de consultas complexas
- CTEs com Window Functions
- Cálculos percentuais
- Análises estatísticas

### 6.6 CTEs Recursivas
- Conceito de recursividade
- Estrutura: Anchor + Recursive Member
- Hierarquias organizacionais
- Geração de sequências
- Navegação em árvores

### 6.7 Casos Avançados
- CTEs com múltiplos níveis
- Combinação de CTEs recursivas e não-recursivas
- Otimização de performance
- Limitações e cuidados

## 📁 Arquivos do Módulo

### Exemplos/
- `01_subconsultas_basicas.sql` - Fundamentos de subconsultas
- `02_subconsultas_correlacionadas.sql` - EXISTS, NOT EXISTS
- `03_operadores_subconsulta.sql` - IN, ANY, ALL
- `04_ctes_nao_recursivas.sql` - CTEs básicas
- `05_ctes_recursivas.sql` - Recursividade e hierarquias
- `06_ctes_avancadas.sql` - Casos complexos

### Exercicios/
- `exercicio_01_subconsultas.sql` - Prática com subconsultas
- `exercicio_02_ctes_basicas.sql` - CTEs fundamentais
- `exercicio_03_recursividade.sql` - Estruturas hierárquicas

### Desafios/
- `desafio_hierarquia_completa.sql` - Sistema organizacional
- `desafio_analise_temporal.sql` - Séries temporais
- `desafio_otimizacao.sql` - Performance avançada

## 🎯 Habilidades Desenvolvidas
- ✅ Criar subconsultas eficientes
- ✅ Implementar CTEs para simplificar código
- ✅ Resolver problemas hierárquicos
- ✅ Otimizar consultas complexas
- ✅ Trabalhar com estruturas recursivas

## 💡 Conceitos Importantes

### Subconsultas vs CTEs
| Aspecto | Subconsultas | CTEs |
|---------|--------------|------|
| Legibilidade | Menor | Maior |
| Reutilização | Não | Sim |
| Recursividade | Não | Sim |
| Performance | Variável | Geralmente melhor |
| Manutenção | Difícil | Fácil |

### Quando Usar Cada Um
- **Subconsultas**: Filtros simples, valores únicos
- **CTEs**: Consultas complexas, múltiplas referências
- **CTEs Recursivas**: Hierarquias, árvores, sequências

## 🔧 Dicas de Performance

### Subconsultas
- Evite subconsultas correlacionadas em grandes volumes
- Use EXISTS ao invés de IN quando possível
- Considere JOINs como alternativa

### CTEs
- CTEs são materializadas apenas uma vez
- Ideais para consultas complexas reutilizadas
- Cuidado com CTEs recursivas em grandes hierarquias

## 🔗 Conexão com Módulos
- **Anterior**: Joins e Relacionamentos
- **Próximo**: Funções Avançadas
- **Relacionado**: Window Functions, Análise de Dados

---
**Tempo Estimado**: 10-12 horas  
**Nível**: Intermediário/Avançado  
**Pré-requisitos**: Módulos 1-5 completos