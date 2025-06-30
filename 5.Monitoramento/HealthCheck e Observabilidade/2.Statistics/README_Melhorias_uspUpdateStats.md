# Melhorias Implementadas na Procedure HealthCheck.uspUpdateStats

## 📋 Resumo das Alterações

A procedure `HealthCheck.uspUpdateStats` foi completamente reformulada com foco em **segurança**, **performance** e **controle operacional**. As principais melhorias incluem validação de horário comercial, sistema de priorização inteligente, controle avançado de execução e relatórios detalhados.

---

## 🚀 Principais Funcionalidades Implementadas

### 1. **Validação de Horário Comercial**
- **Bloqueio automático** entre 8h e 18h
- **Parâmetro @ForcarExecucao** para situações de emergência
- **Validação contínua** durante execução longa
- **Interrupção automática** se horário comercial for atingido

### 2. **Sistema de Priorização Inteligente**
- **Score de prioridade** baseado em múltiplos fatores:
  - 70% peso para percentual de modificações
  - 30% peso para idade da estatística
- **Classificação automática**: CRÍTICA, ALTA, MÉDIA, BAIXA
- **Ordenação otimizada** por prioridade calculada

### 3. **Controle Avançado de Performance**
- **Paralelismo configurável** (MAXDOP)
- **Amostragem personalizável** (percentual ou padrão SQL Server)
- **Timeout por comando** para evitar bloqueios longos
- **Logs detalhados opcionais** para troubleshooting

### 4. **Validação Robusta de Parâmetros**
- **Verificação de intervalos válidos** para todos os parâmetros
- **Mensagens de erro descritivas** com orientações
- **Prevenção de configurações inválidas**

### 5. **Relatórios Aprimorados**
- **Métricas de performance** (tempo médio, taxa de sucesso)
- **Informações de duração** por estatística
- **Percentuais de sucesso/erro**
- **Alertas de execução em horário comercial**

---

## 📊 Novos Parâmetros

| Parâmetro | Tipo | Padrão | Descrição |
|-----------|------|--------|----------|
| `@ForcarExecucao` | BIT | 0 | Força execução mesmo em horário comercial |
| `@MaxParallelism` | TINYINT | 1 | Grau máximo de paralelismo (1-64) |
| `@SamplePercent` | TINYINT | NULL | Percentual de amostragem (1-100 ou NULL) |
| `@TimeoutSegundos` | INT | 300 | Timeout em segundos para cada comando |
| `@LogDetalhado` | BIT | 0 | Exibe logs detalhados de execução |

---

## 🔧 Melhorias Técnicas Implementadas

### **1. Estrutura de Dados Otimizada**
```sql
-- Nova coluna para score de prioridade
[priority_score] DECIMAL(10,4)

-- Precisão aumentada para evitar overflow
[modification_percent] DECIMAL(10,4)
```

### **2. Algoritmo de Priorização**
```sql
-- Cálculo do score de prioridade
SET priority_score = 
    (modification_percent * 0.7) +     -- 70% peso para modificações
    (CASE WHEN days_since_update > 30   -- 30% peso para idade
     THEN (days_since_update / 10.0) 
     ELSE 0 END * 0.3);
```

### **3. Validação de Horário Comercial**
```sql
-- Validação inicial
DECLARE @HoraAtual TIME = CAST(GETDATE() AS TIME);
DECLARE @HorarioComercial BIT = CASE 
    WHEN @HoraAtual >= '08:00:00' AND @HoraAtual < '18:00:00' THEN 1 
    ELSE 0 
END;

-- Validação contínua no cursor
IF @HorarioComercial = 1 AND @ForcarExecucao = 0
BEGIN
    PRINT 'INTERROMPIDO: Horário comercial atingido';
    BREAK;
END;
```

### **4. Controle de Timeout**
```sql
-- Configuração de timeout por comando
DECLARE @TimeoutCommand NVARCHAR(MAX) = 
    CONCAT('SET LOCK_TIMEOUT ', @TimeoutSegundos * 1000, '; ', @sql);
EXEC sp_executesql @TimeoutCommand;
```

### **5. Scripts Otimizados**
```sql
-- Geração de scripts com MAXDOP e amostragem
CASE 
    WHEN @SamplePercent IS NOT NULL 
    THEN CONCAT('UPDATE STATISTICS [...] WITH SAMPLE ', @SamplePercent, 
                ' PERCENT, MAXDOP = ', @MaxParallelism, ';')
    ELSE CONCAT('UPDATE STATISTICS [...] WITH SAMPLE, MAXDOP = ', 
                @MaxParallelism, ';')
END
```

---

## 📈 Benefícios das Melhorias

### **Segurança Operacional**
- ✅ Prevenção de execução em horário de pico
- ✅ Controle de impacto na performance
- ✅ Validação robusta de parâmetros
- ✅ Timeouts para evitar bloqueios

### **Eficiência**
- ✅ Priorização inteligente das estatísticas
- ✅ Controle de paralelismo
- ✅ Amostragem configurável
- ✅ Interrupção automática quando necessário

### **Monitoramento**
- ✅ Logs detalhados opcionais
- ✅ Métricas de performance
- ✅ Relatórios com percentuais
- ✅ Tempo médio por estatística

### **Flexibilidade**
- ✅ Múltiplos cenários de uso
- ✅ Configurações personalizáveis
- ✅ Modo de emergência
- ✅ Simulação antes da execução

---

## 🎯 Cenários de Uso Recomendados

### **Manutenção Regular (Fora do Horário Comercial)**
```sql
EXEC [HealthCheck].[uspUpdateStats]
    @ExecutarAtualizacao = 1,
    @ModificationThreshold = 0.10,
    @DaysSinceLastUpdate = 7,
    @MaxParallelism = 4,
    @SamplePercent = NULL;
```

### **Emergência (Horário Comercial)**
```sql
EXEC [HealthCheck].[uspUpdateStats]
    @ExecutarAtualizacao = 1,
    @ForcarExecucao = 1,
    @MaxParallelism = 1,
    @SamplePercent = 25,
    @TimeoutSegundos = 180;
```

### **Análise/Troubleshooting**
```sql
EXEC [HealthCheck].[uspUpdateStats]
    @ExecutarAtualizacao = 0,
    @ModificationThreshold = 0.01,
    @LogDetalhado = 1;
```

---

## ⚠️ Considerações Importantes

### **Horário Comercial**
- A execução é **bloqueada automaticamente** entre 8h-18h
- Use `@ForcarExecucao = 1` **apenas em emergências**
- **Monitore o impacto** na performance quando forçar execução
- A procedure pode ser **interrompida automaticamente** se o horário comercial for atingido durante execução longa

### **Performance**
- **Paralelismo alto** (MAXDOP > 4) deve ser usado apenas fora do horário comercial
- **Amostragem baixa** (< 25%) reduz precisão mas acelera execução
- **Timeout muito baixo** (< 60s) pode causar falhas em tabelas grandes

### **Monitoramento**
- Use `@LogDetalhado = 1` para **troubleshooting**
- **Monitore os relatórios** de taxa de sucesso/erro
- **Acompanhe o tempo médio** por estatística para otimizar configurações

---

## 🔍 Logs e Relatórios

### **Informações de Início**
```
=========================================
ANÁLISE DE ESTATÍSTICAS DESATUALIZADAS
=========================================
Horário de início: 15/12/2024 14:30:25
Threshold de modificações: 10%
Dias desde última atualização: 30
Modo de execução: EXECUÇÃO REAL
Paralelismo máximo: 4
Amostragem: PADRÃO SQL SERVER
Timeout por comando: 300 segundos
Horário comercial: SIM (8h-18h)
Forçar execução: SIM
=========================================
```

### **Relatório Final**
```
=========================================
RELATÓRIO FINAL
=========================================
Estatísticas encontradas: 25
Estatísticas processadas: 25
Sucessos: 23 (92.0%)
Erros: 2 (8.0%)
Tempo total: 180 segundos (3.0 minutos)
Tempo médio por estatística: 7.20 segundos
=========================================
```

### **Classificação de Prioridade**
| Score | Classificação | Descrição |
|-------|---------------|----------|
| ≥ 50 | CRÍTICA | Requer atenção imediata |
| 20-49 | ALTA | Deve ser processada em breve |
| 10-19 | MÉDIA | Pode aguardar próxima manutenção |
| < 10 | BAIXA | Não urgente |

---

## 📝 Histórico de Versões

| Versão | Data | Descrição |
|--------|------|----------|
| 5.0 | 2024 | Implementação completa com controle de horário comercial e funcionalidades avançadas |
| 4.0 | 2024 | Versão simplificada |
| 3.x | 2024 | Versões anteriores com funcionalidades complexas |

---

## 👨‍💻 Autor

**Wesley Silva**  
Versão: 5.0 - Enhanced with Business Hours Control & Advanced Features  
Data: 2024

---

*Esta documentação cobre todas as melhorias implementadas na procedure HealthCheck.uspUpdateStats. Para exemplos práticos de uso, consulte o arquivo `Exemplo_Uso_uspUpdateStats.sql`.*