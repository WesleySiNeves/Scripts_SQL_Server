# 📊 Módulo 03: Funções e Operadores

## 🎯 Objetivos do Módulo

Ao final deste módulo, você será capaz de:
- Dominar as principais funções de string do SQL Server
- Trabalhar eficientemente com funções de data e hora
- Utilizar funções matemáticas e de conversão
- Aplicar funções lógicas e condicionais
- Compreender operadores avançados
- Otimizar consultas usando funções apropriadas

## 📚 Conteúdo Programático

### 1. Funções de String
- `LEN`, `LEFT`, `RIGHT`, `SUBSTRING`
- `UPPER`, `LOWER`, `LTRIM`, `RTRIM`, `TRIM`
- `REPLACE`, `STUFF`, `REVERSE`
- `CHARINDEX`, `PATINDEX`
- `CONCAT`, `CONCAT_WS`
- `FORMAT` para formatação de strings
- Funções de manipulação de caracteres

### 2. Funções de Data e Hora
- `GETDATE`, `GETUTCDATE`, `SYSDATETIME`
- `DATEADD`, `DATEDIFF`, `DATEPART`
- `YEAR`, `MONTH`, `DAY`, `DATETRUNC`
- `CONVERT` e `CAST` para datas
- Formatação de datas com `FORMAT`
- Cálculos temporais complexos
- Conversão de milissegundos
- Trabalho com fusos horários

### 3. Funções Matemáticas
- `ABS`, `CEILING`, `FLOOR`, `ROUND`
- `POWER`, `SQRT`, `LOG`, `EXP`
- `SIN`, `COS`, `TAN` (trigonométricas)
- `RAND`, `PI`
- Funções estatísticas básicas

### 4. Funções de Conversão
- `CAST` vs `CONVERT`
- `TRY_CAST`, `TRY_CONVERT`
- `PARSE`, `TRY_PARSE`
- Conversões implícitas vs explícitas
- Tratamento de erros de conversão

### 5. Funções Lógicas e Condicionais
- `ISNULL`, `COALESCE`
- `NULLIF`, `IIF`
- `CASE WHEN` (expressões condicionais)
- `CHOOSE`
- Funções de validação

### 6. Funções de Sistema
- `@@VERSION`, `@@SERVERNAME`
- `USER_NAME`, `SUSER_NAME`
- `DB_NAME`, `OBJECT_NAME`
- Funções de metadados
- Funções de informação do sistema

## 📁 Estrutura de Arquivos

```
03_Funcoes_Operadores/
├── README.md
├── Exemplos/
│   ├── 01_funcoes_string.sql
│   ├── 02_funcoes_logicas.sql
│   ├── 03_funcoes_data.sql
│   ├── 04_funcoes_matematicas.sql
│   ├── 05_funcoes_conversao.sql
│   └── 06_funcoes_sistema.sql
├── Exercicios/
│   ├── 01_exercicios_string.sql
│   ├── 02_exercicios_data.sql
│   └── 03_exercicios_conversao.sql
└── Desafios/
    ├── 01_desafio_formatacao.sql
    └── 02_desafio_calculos.sql
```

## 🛠️ Habilidades Desenvolvidas

- **Manipulação de Texto**: Limpeza, formatação e transformação de strings
- **Cálculos Temporais**: Operações complexas com datas e horas
- **Conversões Seguras**: Tratamento adequado de tipos de dados
- **Lógica Condicional**: Implementação de regras de negócio
- **Otimização**: Escolha das funções mais eficientes
- **Tratamento de Erros**: Prevenção de falhas em conversões

## 💡 Conceitos Importantes

### Determinismo de Funções
- **Determinísticas**: Sempre retornam o mesmo resultado (ex: `LEN`, `UPPER`)
- **Não-determinísticas**: Podem retornar resultados diferentes (ex: `GETDATE`, `RAND`)
- Impacto em índices computados e views indexadas

### Performance
- Funções em WHERE podem impedir uso de índices
- Alternativas para otimização
- Uso de funções em SELECT vs WHERE

### Tratamento de NULL
- Comportamento das funções com valores NULL
- Uso de `ISNULL` vs `COALESCE`
- Propagação de NULL em expressões

## 🔗 Conexão com Outros Módulos

**Pré-requisitos:**
- [Módulo 01: Fundamentos SQL](../01_Fundamentos_SQL/)
- [Módulo 02: Consultas Básicas](../02_Consultas_Basicas/)

**Próximos módulos:**
- [Módulo 04: Agrupamento e Ordenação](../04_Agrupamento_Ordenacao/)
- [Módulo 05: Joins e Relacionamentos](../05_Joins_Relacionamentos/)

## 📝 Dicas de Estudo

1. **Pratique Regularmente**: Teste cada função com diferentes tipos de dados
2. **Combine Funções**: Aprenda a usar múltiplas funções em uma expressão
3. **Performance**: Sempre considere o impacto na performance
4. **Documentação**: Consulte a documentação oficial para detalhes
5. **Casos Reais**: Aplique em cenários do seu dia a dia

## ⚡ Melhores Práticas

- Use `TRY_CONVERT` em vez de `CONVERT` quando houver risco de erro
- Prefira `COALESCE` a `ISNULL` para múltiplos valores
- Evite funções em cláusulas WHERE para melhor performance
- Use `FORMAT` com moderação (pode ser lento)
- Sempre trate valores NULL adequadamente

---

**Tempo Estimado**: 8-10 horas  
**Nível**: Básico a Intermediário  
**Pré-requisitos**: Conhecimento básico de SQL