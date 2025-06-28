-- =====================================================
-- CURSO SQL SERVER - MÓDULO 02: CONSULTAS BÁSICAS
-- Arquivo: 03_like_patterns.sql
-- Tópico: Padrões Avançados com LIKE
-- =====================================================

-- ÍNDICE:
-- 1. LIKE com Números
-- 2. LIKE com Acentos
-- 3. LIKE com Múltiplos Padrões
-- 4. Exercícios Práticos

-- =====================================================
-- 1. OPERADOR LIKE SOMENTE COM NÚMEROS
-- =====================================================

-- Exemplo 1: Buscar códigos que começam com números
SELECT BM.IdBemMovel,
       BM.Codigo
FROM Patrimonio.BensMoveis AS BM
WHERE BM.Codigo LIKE '[0-9]%';

-- Exemplo 2: Buscar códigos que NÃO começam com números
SELECT BM.IdBemMovel,
       BM.Codigo
FROM Patrimonio.BensMoveis AS BM
WHERE BM.Codigo NOT LIKE '[0-9]%';

-- Exemplo 3: Códigos que são totalmente numéricos
SELECT BM.IdBemMovel,
       BM.Codigo
FROM Patrimonio.BensMoveis AS BM
WHERE BM.Codigo LIKE '[0-9][0-9][0-9][0-9][0-9]';

-- Exemplo 4: Códigos com formato específico (3 números + 2 letras)
SELECT BM.IdBemMovel,
       BM.Codigo
FROM Patrimonio.BensMoveis AS BM
WHERE BM.Codigo LIKE '[0-9][0-9][0-9][A-Z][A-Z]';

-- =====================================================
-- 2. BUSCAR NOMES COM ACENTOS
-- =====================================================

-- Exemplo 1: Buscar nomes com acentos específicos
SELECT P.IdPessoa,
       P.NomeRazaoSocial
FROM Cadastro.Pessoas AS P
WHERE P.NomeRazaoSocial COLLATE SQL_Latin1_General_CP1_CI_AS LIKE '%[áéíóúàèìòùâêîôûãõç]%';

-- Exemplo 2: Buscar nomes com acentos (versão mais completa)
SELECT P.IdPessoa,
       P.NomeRazaoSocial
FROM Cadastro.Pessoas AS P
WHERE P.NomeRazaoSocial COLLATE SQL_Latin1_General_CP1_CI_AS 
      LIKE '%[áàâãäéèêëíìîïóòôõöúùûüçñ]%';

-- Exemplo 3: Buscar nomes SEM acentos
SELECT P.IdPessoa,
       P.NomeRazaoSocial
FROM Cadastro.Pessoas AS P
WHERE P.NomeRazaoSocial COLLATE SQL_Latin1_General_CP1_CI_AS 
      NOT LIKE '%[áàâãäéèêëíìîïóòôõöúùûüçñ]%';

-- =====================================================
-- 3. MÚLTIPLOS PADRÕES LIKE
-- =====================================================

-- Exemplo 1: Múltiplas condições LIKE com OR
SELECT P.IdPessoa,
       P.NomeRazaoSocial
FROM Cadastro.Pessoas AS P
WHERE P.NomeRazaoSocial LIKE 'João%'
   OR P.NomeRazaoSocial LIKE 'Maria%'
   OR P.NomeRazaoSocial LIKE 'José%';

-- Exemplo 2: Múltiplas condições LIKE com AND
SELECT P.IdPessoa,
       P.NomeRazaoSocial
FROM Cadastro.Pessoas AS P
WHERE P.NomeRazaoSocial LIKE '%Silva%'
  AND P.NomeRazaoSocial LIKE '%Santos%';

-- Exemplo 3: Padrões complexos combinados
SELECT P.IdPessoa,
       P.NomeRazaoSocial,
       P.Email
FROM Cadastro.Pessoas AS P
WHERE (P.NomeRazaoSocial LIKE '%Silva%' OR P.NomeRazaoSocial LIKE '%Santos%')
  AND P.Email LIKE '%@gmail.com';

-- =====================================================
-- 4. PADRÕES AVANÇADOS
-- =====================================================

-- Exemplo 1: CEP com formato específico
SELECT E.IdEndereco,
       E.CEP
FROM Cadastro.Enderecos AS E
WHERE E.CEP LIKE '[0-9][0-9][0-9][0-9][0-9]-[0-9][0-9][0-9]';

-- Exemplo 2: Telefone com DDD específico
SELECT P.IdPessoa,
       P.Telefone
FROM Cadastro.Pessoas AS P
WHERE P.Telefone LIKE '(11)%'
   OR P.Telefone LIKE '(21)%'
   OR P.Telefone LIKE '(31)%';

-- Exemplo 3: Email com domínios específicos
SELECT P.IdPessoa,
       P.Email
FROM Cadastro.Pessoas AS P
WHERE P.Email LIKE '%@gmail.com'
   OR P.Email LIKE '%@hotmail.com'
   OR P.Email LIKE '%@yahoo.com.br';

-- =====================================================
-- 5. EXERCÍCIOS PRÁTICOS
-- =====================================================

/*
EXERCÍCIO 1:
Crie uma consulta que busque todos os produtos cujo código:
- Comece com 'P'
- Tenha exatamente 6 caracteres
- Termine com um número

EXERCÍCIO 2:
Busque todos os clientes cujo nome:
- Contenha 'Silva' OU 'Santos'
- E tenha pelo menos um acento

EXERCÍCIO 3:
Encontre todos os telefones que:
- Tenham DDD de São Paulo (11) ou Rio de Janeiro (21)
- E sejam celulares (9 dígitos após o DDD)

EXERCÍCIO 4:
Busque todos os emails que:
- Sejam de domínios corporativos (.com.br)
- E não sejam de provedores gratuitos (gmail, hotmail, yahoo)

EXERCÍCIO 5:
Crie uma consulta que encontre códigos de barras que:
- Tenham exatamente 13 dígitos
- Comecem com 789 (código do Brasil)
*/

-- =====================================================
-- SOLUÇÕES DOS EXERCÍCIOS
-- =====================================================

-- SOLUÇÃO 1:
/*
SELECT *
FROM Produtos
WHERE Codigo LIKE 'P____[0-9]';
*/

-- SOLUÇÃO 2:
/*
SELECT *
FROM Clientes
WHERE (Nome LIKE '%Silva%' OR Nome LIKE '%Santos%')
  AND Nome COLLATE SQL_Latin1_General_CP1_CI_AS LIKE '%[áàâãäéèêëíìîïóòôõöúùûüçñ]%';
*/

-- SOLUÇÃO 3:
/*
SELECT *
FROM Clientes
WHERE (Telefone LIKE '(11)9[0-9][0-9][0-9][0-9]-[0-9][0-9][0-9][0-9]'
    OR Telefone LIKE '(21)9[0-9][0-9][0-9][0-9]-[0-9][0-9][0-9][0-9]');
*/

-- SOLUÇÃO 4:
/*
SELECT *
FROM Clientes
WHERE Email LIKE '%.com.br'
  AND Email NOT LIKE '%@gmail.%'
  AND Email NOT LIKE '%@hotmail.%'
  AND Email NOT LIKE '%@yahoo.%';
*/

-- SOLUÇÃO 5:
/*
SELECT *
FROM Produtos
WHERE CodigoBarras LIKE '789[0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]';
*/