# 📋 Guia de Migração dos Arquivos Existentes

## 🎯 Objetivo

Este guia mapeia como organizar os arquivos existentes na nova estrutura do curso, mantendo a lógica pedagógica e melhorando a organização.

## 📂 Mapeamento de Migração

### 📁 **1.Basic** → Múltiplos Módulos

#### **1.Basic/1.Joins/** → **05_Joins_Relacionamentos/Exemplos/**
```
✅ diferenca do Lef Join com where.sql → 06_diferenca_left_join_where.sql
```

#### **1.Basic/2.Where/** → **02_Consultas_Basicas/Exemplos/**
```
📄 1.OperadorLikeSomenteNumeros.sql → 03_like_patterns.sql (integrar)
📄 2.Achar Nomes Com Acento.sql → 02_where_operadores.sql (integrar)
📄 3.Fazendo Joins com Multiplos Likes.sql → 05_Joins_Relacionamentos/Exemplos/
📄 3.Fazendo Multiplos Likes.sql → 02_where_operadores.sql (integrar)
📄 Like somente numeros.sql → 03_like_patterns.sql (integrar)
```

#### **1.Basic/3.Datas/** → **03_Funcoes_Operadores/Exemplos/**
```
📄 1.Convert de milisegundos para segundos.sql → 03_funcoes_data.sql
📄 2.CalculoComTime.sql → 03_funcoes_data.sql
📄 3.DivideUmMesEmSemanas.sql → 03_funcoes_data.sql
📄 ConvertDateTimeDiferentesFormatos.sql → 03_funcoes_data.sql
```

#### **1.Basic/97.Tratamento Erros/** → **09_Estruturas_Controle/Exemplos/**
```
📁 1.RaiseError/ → 04_tratamento_erros.sql
📁 2.THROW/ → 04_tratamento_erros.sql
```

#### **1.Basic/98.Funcoes SQL/** → **03_Funcoes_Operadores/Exemplos/**
```
📁 1.Funcoes String/ → 01_funcoes_string.sql
📁 2.Isnull Coalesce/ → 02_funcoes_logicas.sql
📁 3.Funcoes Bytes/ → 04_funcoes_sistema.sql
📄 Demostracao Format.sql → 01_funcoes_string.sql
```

#### **1.Basic/OperacoesConjuntos/** → **04_Agrupamento_Ordenacao/Exemplos/**
```
📄 SemiJoinsComExecpt.sql → 05_operacoes_conjuntos.sql
```

#### **1.Basic/OrdenacaoDados/** → **04_Agrupamento_Ordenacao/Exemplos/**
```
📄 1.OrdenaçãoDadosFeth.sql → 02_ordenacao_avancada.sql
📄 2.OrdenaçãoDadosRowNumber.sql → 02_ordenacao_avancada.sql
📄 3.OrdenaçãoDadosWITH.sql → 02_ordenacao_avancada.sql
```

### 📁 **2.Advanced** → Múltiplos Módulos

#### **2.Advanced/87.CalculosFinanceiros/** → **11_Analise_Dados/Exemplos/**
```
📄 1.Calcular Lucro.sql → 04_calculos_financeiros.sql
```

#### **2.Advanced/88.TrabalhandoCollates/** → **14_Administracao_Avancada/Exemplos/**
```
📄 1.BuscaTodasColunasComCollate.sql → 03_configuracao_servidor.sql
📄 2.Alterar Collate Banco.sql → 03_configuracao_servidor.sql
📄 3.Tabela com varios idiomas.sql → 03_configuracao_servidor.sql
📄 4.AlterarCollateServidorComando.sql → 03_configuracao_servidor.sql
```

#### **2.Advanced/91.CTEs/** → **06_Subconsultas_CTEs/Exemplos/**
```
✅ 1.CTENaoRecursivaSimples.sql → 04_ctes_nao_recursivas.sql (integrado)
📄 2.CTENaoRecursivaMaiores10EmpenhosPorPessoa.sql → 04_ctes_nao_recursivas.sql
📄 3.CTENaoRecursivaMaiores10EmpenhosPorPessoa.sql → 04_ctes_nao_recursivas.sql
📄 3.CTERecursivaContasAgenda.sql → 05_ctes_recursivas.sql
✅ 4.CTE Com Porcentagem sobre o valor Total.sql → 04_ctes_nao_recursivas.sql (integrado)
✅ 5.CTE Sum Over.sql → 04_ctes_nao_recursivas.sql (integrado)
📄 6.Porcentagem Relativa do preco atual com o proximo preço.sql → 10_Window_Functions/
📄 7.CTE Recursiva Alfabeto ASCII.sql → 05_ctes_recursivas.sql
```

#### **2.Advanced/92.CTESRecursivas/** → **06_Subconsultas_CTEs/Exemplos/**
```
📄 1.GeraGranTotaisNosPais.sql → 05_ctes_recursivas.sql
📄 2.GeraSequencialCEPV1.sql → 05_ctes_recursivas.sql
📄 3.GeraSequencialCEPV2.sql → 05_ctes_recursivas.sql
📄 4.CTERecursividadeChar.sql → 05_ctes_recursivas.sql
📄 5.GeraNumerosRecursivos.sql → 05_ctes_recursivas.sql
📄 6.CTERecursividadeCargosGerentes.sql → 05_ctes_recursivas.sql
📄 7.RecursividadeCaracteres.sql → 05_ctes_recursivas.sql
```

#### **2.Advanced/93.XMLQuerys/** → **12_XML_JSON/Exemplos/**
```
📄 BuscaConteudoEmCampoXML.sql → 01_manipulacao_xml.sql
📄 EncodeDeCode.sql → 01_manipulacao_xml.sql
📄 Recuperar Conteudo XML 2.sql → 01_manipulacao_xml.sql
📄 Recuperar Conteudo Xml.sql → 01_manipulacao_xml.sql
```

#### **2.Advanced/94.WindowsFunctions/** → **10_Window_Functions/Exemplos/**
```
✅ 1.Batida Ponto (Firt e Last Value).sql → 04_funcoes_offset.sql (integrado)
📄 1.Run Totais.sql → 03_agregacao_over.sql
📄 2.Run Totais.sql → 03_agregacao_over.sql
✅ 2.Ultimas 3 vendas(PRECEDING AND CURRENT ROW).sql → 04_funcoes_offset.sql (integrado)
📄 3.Percentual Relativo.sql → 06_analises_avancadas.sql
📄 3.Percentual do Valor Sobre o Total.sql → 06_analises_avancadas.sql
📄 4.Agregats Function Por cento.sql → 03_agregacao_over.sql
📄 5.RazaoContabil.sql → 06_analises_avancadas.sql
✅ 6.Porcentagem Relativa do preco atual com o proximo preço.sql → 04_funcoes_offset.sql (integrado)
📄 6.Windows Frame with CTE.sql → 05_window_frames.sql
📄 7.Windows Funcition e Windows Frame.sql → 05_window_frames.sql
```

#### **2.Advanced/95.OUTPUT/** → **08_Manipulacao_Dados/Exemplos/**
```
📄 1.Delete com OUTPUT.sql → 04_output_clause.sql
📄 2.Insert Com OUTPUT.sql → 04_output_clause.sql
📄 3.Merge Com OUTPUT com Filter.sql → 04_output_clause.sql
📄 4.Merge Com OUTPUT.sql → 04_output_clause.sql
📄 5.Update com OUTPUT.sql → 04_output_clause.sql
📄 6.DELETE UPDATE COM OUTPUT.sql → 04_output_clause.sql
```

#### **2.Advanced/96.Pivot/** → **11_Analise_Dados/Exemplos/**
```
📄 1.PivotBatidaPontoHorarioSaida.sql → 02_pivot_unpivot.sql
📄 2.PivotComDoisAgrupamentos.sql → 02_pivot_unpivot.sql
📄 3.PivotComMediaCalculada.sql → 02_pivot_unpivot.sql
📄 5.PivotDinamicoComTempTable.sql → 02_pivot_unpivot.sql
📄 6.Pivot Projetos.sql → 02_pivot_unpivot.sql
📄 7.ExemploPivotSimples.sql → 02_pivot_unpivot.sql
📄 8.ExemploPivotSimples.sql → 02_pivot_unpivot.sql
📄 9.PivotSimplesEmpresas.sql → 02_pivot_unpivot.sql
📄 10.PivotComSoma_Media_Maior-Menor.sql → 02_pivot_unpivot.sql
📄 11.PivotAvancadoComMediaETotalJunto.sql → 02_pivot_unpivot.sql
📄 12.PivotTotalVendidoAnual.sql → 02_pivot_unpivot.sql
📄 13.TotalPagamentoMensal.sql → 02_pivot_unpivot.sql
```

#### **2.Advanced/99.Agrupadores Complexos/** → **04_Agrupamento_Ordenacao/Exemplos/**
```
📄 1.Exemplo Rollup X Cube X Grouping Sets.sql → 04_agrupadores_complexos.sql
📄 2.Demo Agrupadores.sql → 04_agrupadores_complexos.sql
📄 3.Demo Agrupamentos Cube.sql → 04_agrupadores_complexos.sql
📄 4.Exemplo Rollup.sql → 04_agrupadores_complexos.sql
📄 5.Grouping.sql → 04_agrupadores_complexos.sql
📄 6.Grupping Sets.sql → 04_agrupadores_complexos.sql
```

### 📁 **3.DDL** → **14_Administracao_Avancada**

```
📄 2.RenomearCamposTabelas.sql → 02_ddl_avancado.sql
📁 99.TransferirTabelasEntreSchemas/ → 02_ddl_avancado.sql
```

### 📁 **3.Topicos Avancados** → Múltiplos Módulos

#### **Tópicos de Performance** → **13_Performance_Otimizacao/**
```
📁 1.TraceFlags/ → 05_monitoramento_avancado.sql
📁 2.InMemory/ → 04_otimizacao_memoria.sql
📁 2.Trace Side events/ → 05_monitoramento_avancado.sql
📁 86.Analyzing Database Structures/ → 03_analise_estruturas.sql
📁 89.DataBaseCompression/ → 04_otimizacao_memoria.sql
📁 Locks/ → 06_concorrencia_locks.sql
```

#### **Tópicos de Administração** → **14_Administracao_Avancada/**
```
📁 85.JSON/ → 12_XML_JSON/Exemplos/02_manipulacao_json.sql
📁 87.TabelasParticionadas/ → 01_estruturas_avancadas.sql
📁 9.BaseLines/ → 07_baselines_monitoramento.sql
```

## 🔄 Processo de Migração

### Etapa 1: Backup
```bash
# Criar backup da estrutura atual
copy "1.Programação em SQL\1.TSQL" "1.Programação em SQL\1.TSQL_BACKUP"
```

### Etapa 2: Criação da Nova Estrutura
1. ✅ Criar pastas dos módulos principais
2. ✅ Criar READMEs com teoria
3. 🔄 Migrar arquivos conforme mapeamento
4. 🔄 Adaptar scripts para nova estrutura
5. 🔄 Criar exercícios e desafios

### Etapa 3: Validação
1. Testar todos os scripts migrados
2. Verificar referências entre arquivos
3. Atualizar documentação
4. Criar índice geral

## 📊 Status da Migração

### Progresso Geral
- **Arquivos migrados**: 8 de ~85 arquivos identificados
- **Progresso**: 9,4%
- **Módulos com conteúdo**: 5 de 16 módulos
- **Última atualização**: 2024-01-15

### Status por Módulo

| Módulo | Status | Arquivos Migrados | Total Estimado |
|--------|--------|-------------------|----------------|
| 01_Fundamentos_SQL | ✅ Criado | README.md | 1 |
| 02_Consultas_Basicas | 🔄 Em progresso | README.md, 01_select_basico.sql, 02_clausula_where.sql, 03_like_patterns.sql | 8 |
| 03_Funcoes_Operadores | 🔄 Em progresso | README.md, 01_funcoes_string.sql, 02_funcoes_conversao_null.sql, 03_funcoes_data.sql, 04_tratamento_erros.sql, 05_operacoes_conjuntos.sql | 15 |
| 04_Agrupamento_Ordenacao | ⏳ Pendente | - | 8 |
| 05_Joins_Relacionamentos | ✅ Criado | README.md, 01_inner_join.sql | 12 |
| 06_Subconsultas_CTEs | ✅ Criado | README.md, 01_ctes_basicas.sql | 10 |
| 07_Funcoes_Agregacao | ⏳ Pendente | - | 6 |
| 08_Manipulacao_Dados | ⏳ Pendente | - | 8 |
| 09_Estruturas_Controle | ⏳ Pendente | - | 5 |
| 10_Window_Functions | ✅ Criado | README.md, 01_funcoes_offset.sql | 8 |
| 11_Procedures_Functions | ⏳ Pendente | - | 12 |
| 12_Triggers_Events | ⏳ Pendente | - | 6 |
| 13_Indices_Performance | ⏳ Pendente | - | 10 |
| 14_Transacoes_Locks | ⏳ Pendente | - | 8 |
| 15_XML_JSON | ⏳ Pendente | - | 4 |
| 16_Recursos_Avancados | ⏳ Pendente | - | 6 |

## 🎯 Próximas Ações

### Prioridade Imediata
1. **Completar Módulo 02** - Migrar arquivos WHERE e LIKE
2. **Completar Módulo 05** - Migrar arquivos de Joins
3. **Criar Módulo 03** - Funções e operadores

### Prioridade Alta
4. **Migrar CTEs** - Completar módulo 06
5. **Migrar Window Functions** - Completar módulo 10
6. **Criar Módulo 04** - Agrupamento e ordenação

### Automação Sugerida
- Script PowerShell para migração automática
- Validação de sintaxe SQL
- Geração automática de índices
- Verificação de links quebrados

---

**Última Atualização**: 2024  
**Responsável**: Assistente AI  
**Status**: Em Progresso