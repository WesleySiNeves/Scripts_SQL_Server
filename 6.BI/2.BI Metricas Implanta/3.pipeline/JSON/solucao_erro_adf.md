# Solução para Erro no Azure Data Factory

## Erro Encontrado
```
The expression 'length(activity('Recuperar Bancos por Servidor').output.value)' cannot be evaluated because property 'value' doesn't exist, available properties are 'durationInQueue'.
```

## Análise do Problema

O erro indica que a atividade `Recuperar Bancos por Servidor` não está retornando a propriedade `value` esperada. Isso geralmente acontece quando:

1. **A atividade falhou** - Quando uma atividade falha, ela não retorna a propriedade `value`
2. **Configuração incorreta do Lookup** - A atividade Lookup não está configurada corretamente
3. **Query não retorna dados** - A consulta SQL não está retornando resultados
4. **Timeout ou erro de conexão** - Problemas de conectividade com o banco de dados

## Soluções Propostas

### 1. Verificar se a Atividade foi Bem-Sucedida

Antes de usar `output.value`, sempre verifique se a atividade foi executada com sucesso:

```json
{
  "name": "Verificar Se Retornou Dados",
  "type": "IfCondition",
  "dependsOn": [
    {
      "activity": "Recuperar Bancos por Servidor",
      "dependencyConditions": ["Succeeded"]
    }
  ],
  "typeProperties": {
    "expression": {
      "value": "@and(contains(activity('Recuperar Bancos por Servidor').output, 'value'), greater(length(activity('Recuperar Bancos por Servidor').output.value), 0))",
      "type": "Expression"
    }
  }
}
```

### 2. Configuração Correta do Lookup

Certifique-se de que a atividade Lookup está configurada corretamente:

```json
{
  "name": "Recuperar Bancos por Servidor",
  "type": "Lookup",
  "typeProperties": {
    "source": {
      "type": "AzureSqlSource",
      "sqlReaderQuery": "SELECT CodSistema, Nome FROM Sistema.Sistemas WHERE Ativo = 1",
      "queryTimeout": "02:00:00"
    },
    "dataset": {
      "referenceName": "AzureSqlTable_Source",
      "type": "DatasetReference"
    },
    "firstRowOnly": false
  }
}
```

**IMPORTANTE**: `"firstRowOnly": false` é essencial para retornar múltiplas linhas no array `value`.

### 3. Expressão Segura para Verificar Dados

Use esta expressão mais robusta:

```json
{
  "value": "@if(and(contains(activity('Recuperar Bancos por Servidor').output, 'value'), greater(length(activity('Recuperar Bancos por Servidor').output.value), 0)), length(activity('Recuperar Bancos por Servidor').output.value), 0)",
  "type": "Expression"
}
```

### 4. Tratamento de Erro com Try-Catch

Implemente um tratamento de erro mais robusto:

```json
{
  "name": "Try Recuperar Bancos",
  "type": "IfCondition",
  "typeProperties": {
    "expression": {
      "value": "@equals(activity('Recuperar Bancos por Servidor').output.count, 0)",
      "type": "Expression"
    },
    "ifTrueActivities": [
      {
        "name": "Log Sem Dados",
        "type": "Wait",
        "typeProperties": {
          "waitTimeInSeconds": 1
        }
      }
    ],
    "ifFalseActivities": [
      {
        "name": "Processar Dados",
        "type": "ForEach",
        "typeProperties": {
          "items": {
            "value": "@activity('Recuperar Bancos por Servidor').output.value",
            "type": "Expression"
          }
        }
      }
    ]
  }
}
```

## Verificações Adicionais

### 1. Verificar a Query SQL

Teste a query diretamente no SQL Server Management Studio:

```sql
-- Teste esta query para garantir que retorna dados
SELECT CodSistema, Nome 
FROM Sistema.Sistemas 
WHERE Ativo = 1;
```

### 2. Verificar Permissões

Certifique-se de que o usuário do ADF tem permissões para:
- Conectar ao banco de dados
- Executar a query
- Acessar as tabelas necessárias

### 3. Verificar Connection String

Verifique se a connection string está correta e se o banco está acessível.

## Exemplo de Pipeline Completo

Veja o arquivo `pipeline_debug_solution.json` para um exemplo completo de como implementar essas soluções.

## Debugging

Para debugar o problema:

1. **Execute a atividade isoladamente** - Teste apenas o Lookup
2. **Verifique os logs** - Analise os logs detalhados no ADF
3. **Use atividade de Wait** - Adicione uma atividade Wait para pausar e verificar os outputs
4. **Teste a query manualmente** - Execute a query diretamente no banco

## Monitoramento

Adicione logging para monitorar:

```json
{
  "name": "Log Output",
  "type": "SetVariable",
  "typeProperties": {
    "variableName": "LogMessage",
    "value": {
      "value": "@concat('Atividade executada. Count: ', string(activity('Recuperar Bancos por Servidor').output.count), ' - Tem Value: ', string(contains(activity('Recuperar Bancos por Servidor').output, 'value')))",
      "type": "Expression"
    }
  }
}
```

Esta solução deve resolver o erro e tornar o pipeline mais robusto contra falhas similares.