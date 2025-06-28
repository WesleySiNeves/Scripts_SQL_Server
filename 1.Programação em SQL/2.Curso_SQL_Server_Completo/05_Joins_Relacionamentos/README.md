# Módulo 5: Joins e Relacionamentos

## 🎯 Objetivos do Módulo
- Compreender relacionamentos entre tabelas
- Dominar todos os tipos de JOIN
- Aplicar joins em consultas complexas
- Otimizar performance de joins
- Resolver problemas práticos com múltiplas tabelas

## 📚 Conteúdo Programático

### 5.1 Fundamentos de Relacionamentos
- Chaves primárias e estrangeiras
- Tipos de relacionamentos (1:1, 1:N, N:N)
- Integridade referencial
- Normalização básica

### 5.2 INNER JOIN
- Conceito e sintaxe
- JOIN com múltiplas condições
- Performance e índices
- Casos práticos

### 5.3 LEFT JOIN (LEFT OUTER JOIN)
- Diferença entre INNER e LEFT JOIN
- Identificação de registros órfãos
- LEFT JOIN vs WHERE
- Casos de uso práticos

### 5.4 RIGHT JOIN (RIGHT OUTER JOIN)
- Conceito e aplicação
- Quando usar RIGHT JOIN
- Equivalência com LEFT JOIN

### 5.5 FULL OUTER JOIN
- União completa de tabelas
- Identificação de dados não relacionados
- Análise de integridade de dados

### 5.6 CROSS JOIN
- Produto cartesiano
- Casos de uso específicos
- Cuidados com performance

### 5.7 SELF JOIN
- Relacionamentos hierárquicos
- Comparações dentro da mesma tabela
- Estruturas organizacionais

### 5.8 Joins Complexos
- Múltiplos joins em uma consulta
- Joins com subconsultas
- Joins com funções de agregação
- Otimização de consultas complexas

## 📁 Arquivos do Módulo

### Exemplos/
- `01_inner_join.sql` - INNER JOIN fundamentais
- `02_left_join.sql` - LEFT JOIN e casos práticos
- `03_right_full_join.sql` - RIGHT e FULL OUTER JOIN
- `04_cross_self_join.sql` - CROSS e SELF JOIN
- `05_joins_multiplos.sql` - Joins complexos
- `06_diferenca_left_join_where.sql` - Comparação LEFT JOIN vs WHERE

### Exercicios/
- `exercicio_01_relacionamentos.sql` - Análise de relacionamentos
- `exercicio_02_joins_basicos.sql` - Prática com joins básicos
- `exercicio_03_joins_complexos.sql` - Consultas avançadas

### Desafios/
- `desafio_analise_vendas.sql` - Sistema de vendas completo
- `desafio_hierarquia_funcionarios.sql` - Estrutura organizacional
- `desafio_integridade_dados.sql` - Análise de integridade

## 🎯 Habilidades Desenvolvidas
- ✅ Relacionar dados de múltiplas tabelas
- ✅ Escolher o tipo correto de JOIN
- ✅ Otimizar consultas com joins
- ✅ Resolver problemas de integridade
- ✅ Criar consultas complexas eficientes

## 💡 Dicas Importantes

### Performance
- Sempre use índices nas colunas de JOIN
- Prefira INNER JOIN quando possível
- Evite CROSS JOIN em tabelas grandes
- Use aliases para melhor legibilidade

### Boas Práticas
- Sempre especifique as condições de JOIN
- Use nomes descritivos para aliases
- Documente consultas complexas
- Teste com dados reais

## 🔗 Conexão com Módulos
- **Anterior**: Agrupamento e Ordenação
- **Próximo**: Subconsultas e CTEs
- **Relacionado**: Window Functions, Análise de Dados

---
**Tempo Estimado**: 8-10 horas  
**Nível**: Intermediário  
**Pré-requisitos**: Módulos 1-4 completos