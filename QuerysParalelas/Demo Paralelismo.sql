
/*Sem paralelismo*/
DECLARE @dataInicio DATE = '2018-01-01';
DECLARE @dataTermino DATE = '2018-12-31';


IF ( OBJECT_ID('TEMPDB..#TempDados') IS NOT NULL )
    DROP TABLE #TempDados;	


CREATE TABLE #TempDados
(
    [IdLancamento] UNIQUEIDENTIFIER,
    [Exercicio] INT,
    [Numero] INT,
    [Data] DATETIME,
    [Modificacao] DATETIME,
    [IdPlanoConta] UNIQUEIDENTIFIER,
    [Codigo] VARCHAR(60),
    [Nome] VARCHAR(100),
    [Credito] BIT,
    [NumeroProcesso] VARCHAR(20),
    [Valor] DECIMAL(18, 2),
    [Historico] VARCHAR(MAX)
);

INSERT INTO #TempDados

SELECT L.IdLancamento,
       L.Exercicio,
       L.Numero,
       L.Data,
       L.Modificacao,
       M.IdPlanoConta,
       PC.Codigo,
       PC.Nome,
       M.Credito,
       M.NumeroProcesso,
       M.Valor,
       M.Historico
FROM Contabilidade.Lancamentos AS L
    JOIN Contabilidade.Movimentos AS M
        ON L.IdLancamento = M.IdLancamento
    JOIN Contabilidade.PlanoContas AS PC
        ON M.IdPlanoConta = PC.IdPlanoConta
WHERE CAST(L.Data AS DATE)
BETWEEN @dataInicio AND @dataTermino;


GO

/* ==================================================================
--Data: 10/08/2018 
--Autor :Wesley Neves
--Observação: Com paralelismo
 
-- ==================================================================
*/

DECLARE @dataInicio DATE = '2018-01-01';
DECLARE @dataTermino DATE = '2018-12-31';


IF ( OBJECT_ID('TEMPDB..#TempDados') IS NOT NULL )
    DROP TABLE #TempDados;	


CREATE TABLE #TempDados
(
    [IdLancamento] UNIQUEIDENTIFIER,
    [Exercicio] INT,
    [Numero] INT,
    [Data] DATETIME,
    [Modificacao] DATETIME,
    [IdPlanoConta] UNIQUEIDENTIFIER,
    [Codigo] VARCHAR(60),
    [Nome] VARCHAR(100),
    [Credito] BIT,
    [NumeroProcesso] VARCHAR(20),
    [Valor] DECIMAL(18, 2),
    [Historico] VARCHAR(MAX)
);

INSERT INTO #TempDados


SELECT L.IdLancamento,
       L.Exercicio,
       L.Numero,
       L.Data,
       L.Modificacao,
       M.IdPlanoConta,
       PC.Codigo,
       PC.Nome,
       M.Credito,
       M.NumeroProcesso,
       M.Valor,
       M.Historico
FROM Contabilidade.Lancamentos AS L
    JOIN Contabilidade.Movimentos AS M
        ON L.IdLancamento = M.IdLancamento
    JOIN Contabilidade.PlanoContas AS PC
        ON M.IdPlanoConta = PC.IdPlanoConta
WHERE CAST(L.Data AS DATE)
BETWEEN @dataInicio AND @dataTermino
OPTION ( QUERYTRACEON 8649)


/* ==================================================================
--Data: 25/09/2018 
--Autor :Wesley Neves
--Observação:  Entretando geralmente inserts geram bloqueios é pode ser um gargalo
 
-- ==================================================================
*/

GO


DECLARE @dataInicio DATE = '2018-01-01';
DECLARE @dataTermino DATE = '2018-12-31';

/* ==================================================================
--Data: 25/09/2018 
--Autor :Wesley Neves
--Observação:  Sem paralelismo
 
-- ==================================================================
*/




SELECT L.IdLancamento,
       L.Exercicio,
       L.Numero,
       L.Data,
       L.Modificacao,
       M.IdPlanoConta,
       PC.Codigo,
       PC.Nome,
       M.Credito,
       M.NumeroProcesso,
       M.Valor,
       M.Historico
FROM Contabilidade.Lancamentos AS L
    JOIN Contabilidade.Movimentos AS M
        ON L.IdLancamento = M.IdLancamento
    JOIN Contabilidade.PlanoContas AS PC
        ON M.IdPlanoConta = PC.IdPlanoConta
WHERE CAST(L.Data AS DATE)
BETWEEN @dataInicio AND @dataTermino


GO

DECLARE @dataInicio DATE = '2018-01-01';
DECLARE @dataTermino DATE = '2018-12-31';
/* ==================================================================
--Data: 25/09/2018 
--Autor :Wesley Neves
--Observação: Com paralelismo
 
-- ==================================================================
*/




SELECT L.IdLancamento,
       L.Exercicio,
       L.Numero,
       L.Data,
       L.Modificacao,
       M.IdPlanoConta,
       PC.Codigo,
       PC.Nome,
       M.Credito,
       M.NumeroProcesso,
       M.Valor,
       M.Historico
FROM Contabilidade.Lancamentos AS L
    JOIN Contabilidade.Movimentos AS M
        ON L.IdLancamento = M.IdLancamento
    JOIN Contabilidade.PlanoContas AS PC
        ON M.IdPlanoConta = PC.IdPlanoConta
WHERE CAST(L.Data AS DATE)
BETWEEN @dataInicio AND @dataTermino
OPTION ( QUERYTRACEON 8649)