

CREATE OR ALTER PROCEDURE [Despesa].[uspDIRFTeste]

    @Exercicio INTEGER,
    @MesInicio INT,
    @MesFim INT,
    @IdPessoa UNIQUEIDENTIFIER,
    @somenteFavorecidosComRamoDeTributo BIT
AS





--/* ==================================================================
--	Observação: Declaração de variaveis
-- ================================================================== */

--DECLARE @MesInicio INT = 1;
--DECLARE @MesFim INT = 12;
--DECLARE @Exercicio INT = 2018;
--DECLARE @somenteFavorecidosComRamoDeTributo BIT = 0;
--DECLARE  @IdPessoa UNIQUEIDENTIFIER = NULL;

----DECLARE @IdPessoa UNIQUEIDENTIFIER = '4E02A96E-6354-4D11-942C-2103011A5559'; --








SET NOCOUNT ON;

DECLARE @IdsPlanoContas NVARCHAR(MAX),
        @delimiter NVARCHAR(5) = ',',
        @textXML XML,
        @PrefixosContasDIRF NVARCHAR(MAX),
        @ConsideraEstorno INT = 2018,
        @ConsiderarEstornoPagamentoDIRF BIT;



DECLARE @IdTributoImune UNIQUEIDENTIFIER,
@IdtributoIsento UNIQUEIDENTIFIER,
@NomeTributoImune varchar(MAX),
@TributoIsento varchar (MAX),
@CodigoImune varchar(MAX),
@CodigoIsento varchar (MAX);





SET @IdsPlanoContas =
(
    SELECT REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(C.Valor, ']', ''), '[', ''), '"', ''), CHAR(13), ''), CHAR(10), '')
    FROM Sistema.Configuracoes AS C
    WHERE C.Configuracao = 'ListaIdsPlanosContasDiariasAjudaCustos'
          AND C.Ano = @Exercicio
);


SET @PrefixosContasDIRF =
(
    SELECT RTRIM(C.Valor)
    FROM Sistema.Configuracoes AS C
    WHERE C.Configuracao = 'PrefixosContasBancoTransitoriasDIRF'
);




SET @ConsiderarEstornoPagamentoDIRF =
(
    SELECT CAST(C.Valor AS BIT)
    FROM Sistema.Configuracoes AS C
    WHERE C.Configuracao = 'ConsiderarEstornoPagamentoDIRF'
          AND C.Ano = @Exercicio
);

SET @ConsiderarEstornoPagamentoDIRF = ISNULL(@ConsiderarEstornoPagamentoDIRF, CAST(1 AS BIT));



SELECT @IdsPlanoContas = REPLACE(REPLACE(@IdsPlanoContas, CHAR(13), ''), CHAR(10), '');



SELECT @textXML = CAST('<d>' + REPLACE(@IdsPlanoContas, @delimiter, '</d><d>') + '</d>' AS XML);


DECLARE @ValorParaPagamentosAutonomos DECIMAL(18, 2) = 6000;



DECLARE  @IdCodigoTributoIsentoPF UNIQUEIDENTIFIER,
		 @NomeTributoIsentoPF varchar(MAX),
         @CodigoTributoIsentoPF varchar(MAX);




SELECT @IdCodigoTributoIsentoPF = T.IdTributo,
       @NomeTributoIsentoPF = T.Nome,
       @CodigoTributoIsentoPF = T.Codigo
FROM Despesa.Tributos AS T
WHERE T.Codigo = '0588'
      AND T.Ativo = 1;



SELECT @IdTributoImune = T.IdTributo,
       @NomeTributoImune = T.Nome,
       @CodigoImune = T.Codigo
FROM Despesa.Tributos AS T
WHERE T.Nome = 'RIMUM - Rendimentos Imunes'
      AND T.UsoInterno = 1
      AND T.Ativo = 1;
SELECT @IdtributoIsento = T.IdTributo,
       @TributoIsento = T.Nome,
       @CodigoIsento = T.Codigo
FROM Despesa.Tributos AS T
WHERE T.Nome = 'RISEN - Rendimentos Isentos'
      AND T.UsoInterno = 1
      AND T.Ativo = 1;


	  

/* ==================================================================
--Observação: Tabelas Auxiliares 
-- ==================================================================*/


IF (OBJECT_ID('TEMPDB..#RegrasDirf') IS NOT NULL)
    DROP TABLE #RegrasDirf;

CREATE TABLE #RegrasDirf
(
    IdRegra SMALLINT NOT NULL IDENTITY(1, 1),
    Descricao VARCHAR(200)
);


IF ( OBJECT_ID('TEMPDB..#TabelaTotalEstornoNoAno') IS NOT NULL )
    DROP TABLE #TabelaTotalEstornoNoAno;	

CREATE TABLE #TabelaTotalEstornoNoAno
    (
       IdPagamento UNIQUEIDENTIFIER NOT NULL ,
      Numero INT NOT NULL ,
	  Exercicio INT,
      TotalEstornado NUMERIC(18, 2) NOT NULL 
      
    );


IF OBJECT_ID('TEMPDB..#IdsContasDiariaAjudaCustos') IS NOT NULL
    DROP TABLE #IdsContasDiariaAjudaCustos;

CREATE TABLE #IdsContasDiariaAjudaCustos (Prefixo UNIQUEIDENTIFIER NOT NULL);


IF OBJECT_ID('TEMPDB..#TabelaAuxiliarNomeTributosBaseCalculo') IS NOT NULL
    DROP TABLE #TabelaAuxiliarNomeTributosBaseCalculo;

CREATE TABLE #TabelaAuxiliarNomeTributosBaseCalculo (NomeTributo VARCHAR(20));

INSERT INTO #TabelaAuxiliarNomeTributosBaseCalculo (NomeTributo ) VALUES ('IRPF'), ('IRPJ');


IF OBJECT_ID('TEMPDB..#TableTributosRetidosFonte') IS NOT NULL
    DROP TABLE #TableTributosRetidosFonte;

CREATE TABLE #TableTributosRetidosFonte (NomeTributo VARCHAR(20));


INSERT INTO #TableTributosRetidosFonte ( NomeTributo ) VALUES ('INSS retido na fonte');

IF OBJECT_ID('TEMPDB..#PlanoContasExercicio') IS NOT NULL
    DROP TABLE #PlanoContasExercicio;

CREATE TABLE #PlanoContasExercicio
(
    IdPlanoConta UNIQUEIDENTIFIER NOT NULL PRIMARY KEY,
    Codigo VARCHAR(60) NOT NULL
);


IF OBJECT_ID('TEMPDB..#PessoasDirf') IS NOT NULL
    DROP TABLE #PessoasDirf;

CREATE TABLE #PessoasDirf
(
    IdPessoa UNIQUEIDENTIFIER NOT NULL PRIMARY KEY ,
    CPFCNPJ VARCHAR(60) NOT NULL,
    NomeRazaoSocial VARCHAR(MAX) NOT NULL,
    TipoPessoaFisica BIT NOT NULL,
    Imune BIT NOT NULL DEFAULT (0),
    Isento BIT NOT NULL DEFAULT (0),
	HasTributacao BIT DEFAULT(0),
	HasPagamentoTipoAutonomoMaiorQueSeisMill BIT DEFAULT(0),
	HasPagamentoTipoAluguelMaiorQueSeisMill BIT DEFAULT(0),
	HasPagamentoTipoRoyaltesQueSeisMill BIT DEFAULT(0),
	HasAjudaDeCusto BIT DEFAULT(0),
	HasDeducao BIT DEFAULT(0)
);

/*Para Autônomo*/




IF ( OBJECT_ID('TEMPDB..#TabelaAuxiliarPrimeiroTributoBaseCalculo') IS NOT NULL )
    DROP TABLE #TabelaAuxiliarPrimeiroTributoBaseCalculo;	


CREATE TABLE #TabelaAuxiliarPrimeiroTributoBaseCalculo
(
    [IdPessoa] UNIQUEIDENTIFIER PRIMARY KEY,
    [IdTributo] UNIQUEIDENTIFIER,
    [Codigo] VARCHAR(10),
    [NomeTributo] VARCHAR(30)
);




/* ==================================================================
--Observação: Tabelas de base para calculos intermediarios
-- ==================================================================*/




IF OBJECT_ID('TEMPDB..#TabelaBaseCalculo') IS NOT NULL
    DROP TABLE #TabelaBaseCalculo;

CREATE TABLE #TabelaBaseCalculo
(
    [KeyValue] UNIQUEIDENTIFIER ,
    TipoDespesa VARCHAR(15),
    [IdPessoa] UNIQUEIDENTIFIER,
    [Codigo] VARCHAR(10),
    [Nome] VARCHAR(30),
    [IdTributo] UNIQUEIDENTIFIER,
    [Mes] INT,
    [ValorConsiderado] DECIMAL(18, 2),
);


CREATE NONCLUSTERED INDEX #IdxTabelaBaseCalculo ON #TabelaBaseCalculo([KeyValue],[IdPessoa]) INCLUDE(Mes,ValorConsiderado)

IF OBJECT_ID('TEMPDB..#TabelaBaseDeducao') IS NOT NULL
    DROP TABLE #TabelaBaseDeducao;


CREATE TABLE #TabelaBaseDeducao
(
    [KeyValue] UNIQUEIDENTIFIER PRIMARY KEY,
    TipoDespesa CHAR(3),
    [IdPessoa] UNIQUEIDENTIFIER,
	[IdTributo] UNIQUEIDENTIFIER,
    [CodigoTributo] VARCHAR(10),
    [Nome] VARCHAR(30),
    [Mes] INT,
    [ValorDeducao] DECIMAL(18, 2)
);

CREATE NONCLUSTERED INDEX #IdxTabelaBaseDeducao ON #TabelaBaseDeducao([KeyValue],[IdPessoa]) INCLUDE(Mes,ValorDeducao)

IF OBJECT_ID('TEMPDB..#TabelaBaseTributacao') IS NOT NULL
    DROP TABLE #TabelaBaseTributacao;


CREATE TABLE #TabelaBaseTributacao
(
    [KeyValue] UNIQUEIDENTIFIER ,
    TipoDespesa CHAR(3),
    [IdPessoa] UNIQUEIDENTIFIER,
	[IdTributo] UNIQUEIDENTIFIER,
    [Codigo] VARCHAR(10),
    [Nome] VARCHAR(30),
    [Mes] INT,
    [ValorTributo] DECIMAL(18, 2)
);

CREATE NONCLUSTERED INDEX #IdxTabelaBaseTributacao ON #TabelaBaseTributacao([KeyValue],[IdPessoa]) INCLUDE(Mes,ValorTributo)

IF OBJECT_ID('TEMPDB..#TabelaBaseAjudaCustoDiarias') IS NOT NULL
    DROP TABLE #TabelaBaseAjudaCustoDiarias;


CREATE TABLE #TabelaBaseAjudaCustoDiarias
(
    [KeyValue] UNIQUEIDENTIFIER ,
    TipoDespesa CHAR(3),
    [IdPessoa] UNIQUEIDENTIFIER,
	[IdTributo] UNIQUEIDENTIFIER,
	[Codigo] VARCHAR(10),
    [Nome] VARCHAR(30),
    [Mes] INT,
    [ValorDiaria] DECIMAL(18, 2),
	--HasPagamentoMaiorQueSeisMil BIT DEFAULT(0),
	HasTributacao_IRPF_IRPJ BIT DEFAULT(0),
	PagamentoContabilizadoNaBaseCalculo BIT  DEFAULT(0)
);


CREATE NONCLUSTERED INDEX #IdxTabelaBaseAjudaCustoDiarias ON #TabelaBaseAjudaCustoDiarias([KeyValue],[IdPessoa]) INCLUDE(Mes,ValorDiaria)




IF OBJECT_ID('TEMPDB..#TabelaBasePagamentosAluguelAutonomoAlugueisRoyates') IS NOT NULL
    DROP TABLE #TabelaBasePagamentosAluguelAutonomoAlugueisRoyates;


CREATE TABLE #TabelaBasePagamentosAluguelAutonomoAlugueisRoyates
(
    Codigo VARCHAR(60) NOT NULL,
    NomeTributo VARCHAR(100) NOT NULL,
    [IdTributo] UNIQUEIDENTIFIER,
    [IdPessoa] UNIQUEIDENTIFIER NOT NULL,
    [IdPagamento] UNIQUEIDENTIFIER NOT NULL,
    [CPFCNPJ] VARCHAR(60) NOT NULL,
    [NomeRazaoSocial] VARCHAR(MAX) NOT NULL,
    [TipoPessoaFisica] BIT NOT NULL,
    [ValorAplicado] NUMERIC(18, 2) NOT NULL,
    [Tipo] INT NOT NULL,
    [Mes] INT,
    [Imune] BIT NOT NULL,
    [Isento] BIT NOT NULL,
	PagamentoFoiContabilizadoNaBaseDeCalculo BIT DEFAULT(0),
	PagamentoTributado_IRPF_IRPJ BIT DEFAULT(0),
	PagamentoReferenteADiarias BIT DEFAULT(0),
	PagamentoReferenteAjudaCusto BIT DEFAULT(0)
);



IF OBJECT_ID('TEMPDB..#TabelaBasePagamentosGeralNaoSeAplica') IS NOT NULL
    DROP TABLE #TabelaBasePagamentosGeralNaoSeAplica;


CREATE TABLE #TabelaBasePagamentosGeralNaoSeAplica
(
    [IdPessoa] UNIQUEIDENTIFIER,
    [IdPagamento] UNIQUEIDENTIFIER,
	Codigo VARCHAR(60)  NULL,
    NomeTributo VARCHAR(100)  NULL,
    [IdTributo] UNIQUEIDENTIFIER,
    [CPFCNPJ] VARCHAR(60),
    [NomeRazaoSocial] VARCHAR(MAX),
    [TipoPessoaFisica] BIT,
    [ValorConsiderado] DECIMAL(19, 2),
    [Tipo] INT,
    [Mes] INT,
    [Imune] BIT,
    [Isento] BIT,
	PagamentoTributado_IRPF_IRPJ BIT DEFAULT(0),
	PagamentoReferenteAjudaCusto BIT DEFAULT(0),
	PagamentoFoiContabilizadoNaBaseDeCalculo BIT DEFAULT(0),
);


/* ==================================================================
--Observação: Tabelas Resultado e Pivots
-- ================================================================== */

IF (OBJECT_ID('TEMPDB..#Dirf') IS NOT NULL)
    DROP TABLE #Dirf;

CREATE TABLE #Dirf
(
    [IdPessoa] UNIQUEIDENTIFIER,
    [CPFCNPJ] VARCHAR(60),
    [NomeRazaoSocial] VARCHAR(MAX),
    [TipoPessoaFisica] BIT,
    [IdTributo] UNIQUEIDENTIFIER,
    [Codigo] VARCHAR(60),
    [NomeTributo] VARCHAR(100),
    [BaseCalc01] DECIMAL(18, 2),
    [Trib01] DECIMAL(18, 2),
    [Deducoes01] DECIMAL(18, 2),
    [AjudaCusto01] DECIMAL(18, 2),
    [BaseCalc02] DECIMAL(18, 2),
    [Trib02] DECIMAL(18, 2),
    [Deducoes02] DECIMAL(18, 2),
    [AjudaCusto02] DECIMAL(18, 2),
    [BaseCalc03] DECIMAL(18, 2),
    [Trib03] DECIMAL(18, 2),
    [Deducoes03] DECIMAL(18, 2),
    [AjudaCusto03] DECIMAL(18, 2),
    [BaseCalc04] DECIMAL(18, 2),
    [Trib04] DECIMAL(18, 2),
    [Deducoes04] DECIMAL(18, 2),
    [AjudaCusto04] DECIMAL(18, 2),
    [BaseCalc05] DECIMAL(18, 2),
    [Trib05] DECIMAL(18, 2),
    [Deducoes05] DECIMAL(18, 2),
    [AjudaCusto05] DECIMAL(18, 2),
    [BaseCalc06] DECIMAL(18, 2),
    [Trib06] DECIMAL(18, 2),
    [Deducoes06] DECIMAL(18, 2),
    [AjudaCusto06] DECIMAL(18, 2),
    [BaseCalc07] DECIMAL(18, 2),
    [Trib07] DECIMAL(18, 2),
    [Deducoes07] DECIMAL(18, 2),
    [AjudaCusto07] DECIMAL(18, 2),
    [BaseCalc08] DECIMAL(18, 2),
    [Trib08] DECIMAL(18, 2),
    [Deducoes08] DECIMAL(18, 2),
    [AjudaCusto08] DECIMAL(18, 2),
    [BaseCalc09] DECIMAL(18, 2),
    [Trib09] DECIMAL(18, 2),
    [Deducoes09] DECIMAL(18, 2),
    [AjudaCusto09] DECIMAL(18, 2),
    [BaseCalc10] DECIMAL(18, 2),
    [Trib10] DECIMAL(18, 2),
    [Deducoes10] DECIMAL(18, 2),
    [AjudaCusto10] DECIMAL(18, 2),
    [BaseCalc11] DECIMAL(18, 2),
    [Trib11] DECIMAL(18, 2),
    [Deducoes11] DECIMAL(18, 2),
    [AjudaCusto11] DECIMAL(18, 2),
    [BaseCalc12] DECIMAL(18, 2),
    [Trib12] DECIMAL(18, 2),
    [Deducoes12] DECIMAL(18, 2),
    [AjudaCusto12] DECIMAL(18, 2),
    [Imune] BIT,
    [Isento] BIT
);


IF OBJECT_ID('TEMPDB..#TabelaPivotBaseCalculo') IS NOT NULL
    DROP TABLE #TabelaPivotBaseCalculo;

CREATE TABLE #TabelaPivotBaseCalculo
(
    IdPessoa UNIQUEIDENTIFIER NOT NULL,
    Codigo VARCHAR(60) NOT NULL,
    NomeTributo VARCHAR(100) NOT NULL,
    IdTributo UNIQUEIDENTIFIER NOT NULL,
    BaseCalc01 DECIMAL(18, 2),
    BaseCalc02 DECIMAL(18, 2),
    BaseCalc03 DECIMAL(18, 2),
    BaseCalc04 DECIMAL(18, 2),
    BaseCalc05 DECIMAL(18, 2),
    BaseCalc06 DECIMAL(18, 2),
    BaseCalc07 DECIMAL(18, 2),
    BaseCalc08 DECIMAL(18, 2),
    BaseCalc09 DECIMAL(18, 2),
    BaseCalc10 DECIMAL(18, 2),
    BaseCalc11 DECIMAL(18, 2),
    BaseCalc12 DECIMAL(18, 2),
);

IF OBJECT_ID('TEMPDB..#TabelaPivotDeducoes') IS NOT NULL
    DROP TABLE #TabelaPivotDeducoes;

CREATE TABLE #TabelaPivotDeducoes
(
    IdPessoa UNIQUEIDENTIFIER NOT NULL,
    Codigo VARCHAR(60) NOT NULL,
    NomeTributo VARCHAR(100) NOT NULL,
    IdTributo UNIQUEIDENTIFIER NOT NULL,
    Deducoes01 DECIMAL(18, 2),
    Deducoes02 DECIMAL(18, 2),
    Deducoes03 DECIMAL(18, 2),
    Deducoes04 DECIMAL(18, 2),
    Deducoes05 DECIMAL(18, 2),
    Deducoes06 DECIMAL(18, 2),
    Deducoes07 DECIMAL(18, 2),
    Deducoes08 DECIMAL(18, 2),
    Deducoes09 DECIMAL(18, 2),
    Deducoes10 DECIMAL(18, 2),
    Deducoes11 DECIMAL(18, 2),
    Deducoes12 DECIMAL(18, 2),
);

IF OBJECT_ID('TEMPDB..#TabelaPivotTributos') IS NOT NULL
    DROP TABLE #TabelaPivotTributos;

CREATE TABLE #TabelaPivotTributos
(
    IdPessoa UNIQUEIDENTIFIER NULL,
    Codigo VARCHAR(60) NULL,
    NomeTributo VARCHAR(100) NULL,
    IdTributo UNIQUEIDENTIFIER NULL,
    Trib01 DECIMAL(18, 2),
    Trib02 DECIMAL(18, 2),
    Trib03 DECIMAL(18, 2),
    Trib04 DECIMAL(18, 2),
    Trib05 DECIMAL(18, 2),
    Trib06 DECIMAL(18, 2),
    Trib07 DECIMAL(18, 2),
    Trib08 DECIMAL(18, 2),
    Trib09 DECIMAL(18, 2),
    Trib10 DECIMAL(18, 2),
    Trib11 DECIMAL(18, 2),
    Trib12 DECIMAL(18, 2),
);

IF OBJECT_ID('TEMPDB..#TabelaPivotDiariasEAjudaCusto') IS NOT NULL
    DROP TABLE #TabelaPivotDiariasEAjudaCusto;

CREATE TABLE #TabelaPivotDiariasEAjudaCusto
(
    IdPessoa UNIQUEIDENTIFIER NULL,
	CodigoTributo VARCHAR(60) NULL,
	Nometributo VARCHAR(200),
	IdTributo UNIQUEIDENTIFIER ,
    AjudaCusto01 DECIMAL(18, 2),
    AjudaCusto02 DECIMAL(18, 2),
    AjudaCusto03 DECIMAL(18, 2),
    AjudaCusto04 DECIMAL(18, 2),
    AjudaCusto05 DECIMAL(18, 2),
    AjudaCusto06 DECIMAL(18, 2),
    AjudaCusto07 DECIMAL(18, 2),
    AjudaCusto08 DECIMAL(18, 2),
    AjudaCusto09 DECIMAL(18, 2),
    AjudaCusto10 DECIMAL(18, 2),
    AjudaCusto11 DECIMAL(18, 2),
    AjudaCusto12 DECIMAL(18, 2),
);






/* ==================================================================
--Observação: Insert em tabelas temporárias
-- ================================================================== */



IF LEN(@IdsPlanoContas) > 0
BEGIN

    INSERT INTO #IdsContasDiariaAjudaCustos
    SELECT T.SPLIT.value('.', 'nvarchar(max)') AS DATA
    FROM @textXML.nodes('/d')T(SPLIT);

END;



INSERT INTO #PlanoContasExercicio
SELECT UPCS.IdPlanoConta,
       UPCS.Codigo
FROM Contabilidade.ufnPlanoContaSintetica(@Exercicio) AS UPCS
WHERE UPCS.Analitica = 1
      AND EXISTS
(
    SELECT 1
    FROM Sistema.fnSplitValues(@PrefixosContasDIRF, ';') ufn
    WHERE UPCS.Codigo LIKE ufn.Conteudo + '%'
);




IF (@somenteFavorecidosComRamoDeTributo = 1)
BEGIN
    /* Foi retirado o JOIN por um existe , pois em casos em que o favorecido do tributo está associado a diversas contas
		 o reultado fica duplicado*/
    INSERT INTO #PessoasDirf
    (
        IdPessoa,
        CPFCNPJ,
        NomeRazaoSocial,
        TipoPessoaFisica,
        Imune,
        Isento
    )
   
    SELECT P.IdPessoa,
           ISNULL(   P.CPFCNPJ,
                     CASE
                         WHEN P.TipoPessoaFisica = 1 THEN
                             '000.000.000-00'
                         ELSE
                             '00.000.000/0000-00'
                     END
                 ),
           P.NomeRazaoSocial,
           P.TipoPessoaFisica,
           Imune = CASE
                       WHEN PJ.IdPessoaJuridica IS NOT NULL
                            AND PJ.FlagsBitwisePessoaJuridica = 16 THEN
                           1
                       ELSE
                           0
                   END,
           Isento = CASE
                        WHEN PJ.IdPessoaJuridica IS NOT NULL
                             AND PJ.FlagsBitwisePessoaJuridica = 32 THEN
                            1
                        ELSE
                            0
                    END
    FROM Cadastro.Pessoas AS P
        LEFT JOIN Cadastro.PessoasFisicas AS PF
            ON PF.IdPessoa = P.IdPessoa
        LEFT JOIN Cadastro.PessoasJuridicas AS PJ
            ON PJ.IdPessoa = P.IdPessoa
    WHERE EXISTS
    (
        SELECT 1 FROM Despesa.TributosPessoas AS TP WHERE TP.IdPessoa = P.IdPessoa
    )
          AND P.IdPessoa = ISNULL(@IdPessoa, P.IdPessoa);

END;
ELSE
BEGIN
    INSERT INTO #PessoasDirf
    (
        IdPessoa,
        CPFCNPJ,
        NomeRazaoSocial,
        TipoPessoaFisica,
        Imune,
        Isento
    )
    
    SELECT P.IdPessoa,
           ISNULL(   P.CPFCNPJ,
                     CASE
                         WHEN P.TipoPessoaFisica = 1 THEN
                             '000.000.000-00'
                         ELSE
                             '00.000.000/0000-00'
                     END
                 ),
           P.NomeRazaoSocial,
           P.TipoPessoaFisica,
           Imune = CASE
                       WHEN PJ.IdPessoaJuridica IS NOT NULL
                            AND PJ.FlagsBitwisePessoaJuridica = 16 THEN
                           1
                       ELSE
                           0
                   END,
           Isento = CASE
                        WHEN PJ.IdPessoaJuridica IS NOT NULL
                             AND PJ.FlagsBitwisePessoaJuridica = 32 THEN
                            1
                        ELSE
                            0
                    END
    FROM Cadastro.Pessoas AS P
        LEFT JOIN Cadastro.PessoasFisicas AS PF
            ON PF.IdPessoa = P.IdPessoa
        LEFT JOIN Cadastro.PessoasJuridicas AS PJ
            ON PJ.IdPessoa = P.IdPessoa
    WHERE P.IdPessoa = ISNULL(@IdPessoa, P.IdPessoa);
END;



/* ==================================================================
--Observação: Inicio das CTEs
-- ==================================================================*/


WITH EstornosAplicaveis
AS (SELECT IdPagamento =
           (
               SELECT P2.IdPagamento
               FROM Despesa.Pagamentos AS P2
               WHERE P2.Numero = p.Numero
                     AND YEAR(P2.DataPagamento) = YEAR(p.DataPagamento)
                     AND P2.Estorno = 0
           ),
           P.Numero AS Numero,
           YEAR(P.DataPagamento) AS Exercicio,
           TotalEstornadoPorMes = ABS(SUM(P.Valor))
    FROM Despesa.Pagamentos AS P
    WHERE YEAR(P.DataPagamento) = @Exercicio
          AND P.Estorno = 1
          AND P.ConsiderarDirf = 1
    GROUP BY YEAR(P.DataPagamento),
             P.Numero
   )
INSERT INTO #TabelaTotalEstornoNoAno
SELECT *
FROM EstornosAplicaveis EA;






/* ==================================================================
--Observação: Recupera os dados base para a basede calculo não faz o agrupamento ainda
-- ==================================================================
*/
;
WITH DadosBaseCalculo
AS (SELECT p.IdPagamento AS KeyValue,
           'PG' AS TipoDespesa,
           TR.IdPessoa,
           T.Codigo,
           T.Nome,
           T.IdTributo,
           Mes = MONTH(p.DataPagamento),
           ValorConsiderado = CAST((TR.BaseCalculo
                                    - IIF(@ConsiderarEstornoPagamentoDIRF = 0,
                                          0,
                                          ROUND(TR.BaseCalculo * (ISNULL(TEA.TotalEstornado, 0) / p.Valor), 2))
                                   ) AS DECIMAL(18, 2)) 
    FROM Despesa.TributosRetidos TR
        INNER JOIN Despesa.Tributos T
            ON T.IdTributo = TR.IdTributo
        INNER JOIN Despesa.TributosNaturezas TN
            ON TN.IdTributoNatureza = T.IdTributoNatureza
        INNER JOIN Despesa.TributosRetidosPagamentos TRP
            ON TRP.IdTributoRetido = TR.IdTributoRetido
        INNER JOIN Despesa.Pagamentos p
            ON p.IdPagamento = TRP.IdPagamento
        INNER JOIN Despesa.SaidasFinanceiras SF
            ON SF.IdSaidaFinanceira = p.IdSaidaFinanceira
        INNER JOIN #PlanoContasExercicio AS PCE
            ON PCE.IdPlanoConta = SF.IdPlanoConta
        JOIN #PessoasDirf AS P2
            ON P2.IdPessoa = TR.IdPessoa
        LEFT JOIN
        (
            SELECT TEA2.IdPagamento,
                   TEA2.TotalEstornado
            FROM #TabelaTotalEstornoNoAno AS TEA2
        ) AS TEA
            ON TRP.IdPagamento = TEA.IdPagamento
    WHERE TR.BaseCalculo >= 0
          AND YEAR(p.DataPagamento) = @Exercicio
          AND MONTH(p.DataPagamento)
          BETWEEN @MesInicio AND @MesFim
          AND TN.Nome IN (
                             SELECT TTBC.NomeTributo
                             FROM #TabelaAuxiliarNomeTributosBaseCalculo AS TTBC
                         )
          AND p.Estorno = 0
          AND T.Codigo IS NOT NULL
          AND (
                  P2.Imune = 0
                  AND P2.Isento = 0
              )
          AND (
                  (
                      @somenteFavorecidosComRamoDeTributo = 0
                      AND TR.IdPessoa = ISNULL(@IdPessoa, TR.IdPessoa)
                  )
                  OR (
                         @somenteFavorecidosComRamoDeTributo = 1
                         AND EXISTS
    (
        SELECT 1 FROM #PessoasDirf AS p WHERE p.IdPessoa = TR.IdPessoa
    )
                     )
              )
    UNION ALL
    SELECT MF.IdMovimentoFinanceiro AS KeyValue,
           'MF' AS TipoDespesa,
           TR.IdPessoa,
           T.Codigo,
           T.Nome,
           T.IdTributo,
           Mes = MONTH(MF.Data),
           ValorConsiderado = TR.BaseCalculo
    FROM Despesa.TributosRetidos TR
        INNER JOIN Despesa.Tributos T
            ON T.IdTributo = TR.IdTributo
        INNER JOIN Despesa.TributosNaturezas TN
            ON TN.IdTributoNatureza = T.IdTributoNatureza
        INNER JOIN Despesa.TributosRetidosMovimentosFinanceiros TMF
            ON TMF.IdTributoRetido = TR.IdTributoRetido
        INNER JOIN Despesa.MovimentosFinanceiros MF
            ON MF.IdMovimentoFinanceiro = TMF.IdMovimentoFinanceiro
        INNER JOIN Despesa.SaidasFinanceiras AS SF
            ON SF.IdSaidaFinanceira = MF.IdSaidaFinanceira
        INNER JOIN #PlanoContasExercicio AS PCE
            ON PCE.IdPlanoConta = SF.IdPlanoConta
        JOIN #PessoasDirf AS PD
            ON PD.IdPessoa = TR.IdPessoa
    WHERE TR.BaseCalculo >= 0
          AND T.Codigo IS NOT NULL
          AND (
                  PD.Imune = 0
                  AND PD.Isento = 0
              )
          AND YEAR(MF.Data) = @Exercicio
          AND MONTH(MF.Data)
          BETWEEN @MesInicio AND @MesFim
          AND TN.Nome IN (
                             SELECT TTBC.NomeTributo
                             FROM #TabelaAuxiliarNomeTributosBaseCalculo AS TTBC
                         )
          AND (
                  (
                      @somenteFavorecidosComRamoDeTributo = 0
                      AND TR.IdPessoa = ISNULL(@IdPessoa, TR.IdPessoa)
                  )
                  OR (
                         @somenteFavorecidosComRamoDeTributo = 1
                         AND EXISTS
    (
        SELECT 1 FROM #PessoasDirf AS p WHERE p.IdPessoa = TR.IdPessoa
    )
                     )
              )
   )
INSERT INTO #TabelaBaseCalculo
(
    KeyValue,
    TipoDespesa,
    IdPessoa,
    Codigo,
    Nome,
    IdTributo,
    Mes,
    ValorConsiderado
)
SELECT R.KeyValue,
       R.TipoDespesa,
       R.IdPessoa,
       R.Codigo,
       R.Nome,
       R.IdTributo,
       R.Mes,
       R.ValorConsiderado
       
FROM DadosBaseCalculo R;





/* ==================================================================
--Observação: Recupera os dados base para a parte de tributação (não faz o agrupamento ainda)
-- ==================================================================
*/
;WITH DadosBaseTributos
AS (SELECT p.IdPagamento AS KeyValue,
           'PG' AS TipoDespesa,
           TR.IdPessoa,
           T.Codigo,
           T.Nome,
           T.IdTributo,
           Mes = MONTH(p.DataPagamento),
           ValorTributo = TR.ValorTributo
    FROM Despesa.TributosRetidos TR
        INNER JOIN Despesa.Tributos T
            ON T.IdTributo = TR.IdTributo
        INNER JOIN Despesa.TributosNaturezas TN
            ON TN.IdTributoNatureza = T.IdTributoNatureza
        INNER JOIN Despesa.TributosRetidosPagamentos TRP
            ON TRP.IdTributoRetido = TR.IdTributoRetido
        INNER JOIN Despesa.Pagamentos p
            ON p.IdPagamento = TRP.IdPagamento
        INNER JOIN Despesa.SaidasFinanceiras SFP
            ON SFP.IdSaidaFinanceira = p.IdSaidaFinanceira
        INNER JOIN #PlanoContasExercicio AS PCE
            ON PCE.IdPlanoConta = SFP.IdPlanoConta
        JOIN #PessoasDirf AS PD
            ON PD.IdPessoa = TR.IdPessoa
        LEFT JOIN
        (
            SELECT PEstorno.Numero,
                   Exercicio = YEAR(PEstorno.DataPagamento),
                   SUM(PEstorno.Valor) AS Valor,
                   PEstorno.ConsiderarDirf
            FROM Despesa.Pagamentos AS PEstorno
            WHERE YEAR(PEstorno.DataPagamento) = 2018
                  AND PEstorno.Estorno = 1
                  AND PEstorno.ConsiderarDirf = 1
            GROUP BY YEAR(PEstorno.DataPagamento),
                     PEstorno.Numero,
                     PEstorno.ConsiderarDirf
        ) Estornos
            ON p.Numero = Estornos.Numero
               AND Estornos.Exercicio = YEAR(p.DataPagamento)
    WHERE (
              Estornos.Numero IS NULL
              OR (
                     Estornos.Numero IS NOT NULL
                     AND Estornos.ConsiderarDirf = 0
                 )
              OR (
                     Estornos.Numero IS NOT NULL
                     AND Estornos.ConsiderarDirf = 1
                     AND TR.Estornado = 0
                 )
          )
          AND TR.ValorTributo >= 0
          AND T.Codigo IS NOT NULL
          AND (
                  PD.Imune = 0
                  AND PD.Isento = 0
              )
          AND YEAR(p.DataPagamento) = @Exercicio
          AND MONTH(p.DataPagamento)
          BETWEEN @MesInicio AND @MesFim
          AND p.Estorno = 0
          AND TN.Nome IN (
                             SELECT TTBC.NomeTributo
                             FROM #TabelaAuxiliarNomeTributosBaseCalculo AS TTBC
                         )
          AND (
                  (
                      @somenteFavorecidosComRamoDeTributo = 0
                      AND TR.IdPessoa = ISNULL(@IdPessoa, TR.IdPessoa)
                  )
                  OR (
                         @somenteFavorecidosComRamoDeTributo = 1
                         AND EXISTS
    (
        SELECT 1 FROM #PessoasDirf AS p WHERE p.IdPessoa = TR.IdPessoa
    )
                     )
              )
    UNION ALL
    SELECT MF.IdMovimentoFinanceiro AS KeyValue,
           'MF' AS TipoDespesa,
           TR.IdPessoa,
           T.Codigo,
           T.Nome,
           T.IdTributo,
           Mes = MONTH(MF.Data),
           TotalTributo = TR.ValorTributo
    FROM Despesa.TributosRetidos TR
        INNER JOIN Despesa.Tributos T
            ON T.IdTributo = TR.IdTributo
        INNER JOIN Despesa.TributosNaturezas TN
            ON TN.IdTributoNatureza = T.IdTributoNatureza
        INNER JOIN Despesa.TributosRetidosMovimentosFinanceiros TMF
            ON TMF.IdTributoRetido = TR.IdTributoRetido
        INNER JOIN Despesa.MovimentosFinanceiros MF
            ON MF.IdMovimentoFinanceiro = TMF.IdMovimentoFinanceiro
        INNER JOIN Despesa.SaidasFinanceiras SFM
            ON SFM.IdSaidaFinanceira = MF.IdSaidaFinanceira
        INNER JOIN #PlanoContasExercicio AS PCE
            ON PCE.IdPlanoConta = SFM.IdPlanoConta
        JOIN #PessoasDirf AS P2
            ON P2.IdPessoa = TR.IdPessoa
    WHERE TR.ValorTributo >= 0
          AND MONTH(MF.Data)
          BETWEEN @MesInicio AND @MesFim
          AND YEAR(MF.Data) = @Exercicio
          AND T.Codigo IS NOT NULL
          AND (
                  P2.Imune = 0
                  AND P2.Isento = 0
              )
          AND TN.Nome IN (
                             SELECT TTBC.NomeTributo
                             FROM #TabelaAuxiliarNomeTributosBaseCalculo AS TTBC
                         )
          AND (
                  (
                      @somenteFavorecidosComRamoDeTributo = 0
                      AND TR.IdPessoa = ISNULL(@IdPessoa, TR.IdPessoa)
                  )
                  OR (
                         @somenteFavorecidosComRamoDeTributo = 1
                         AND EXISTS
    (
        SELECT 1 FROM #PessoasDirf AS p WHERE p.IdPessoa = TR.IdPessoa
    )
                     )
              )
   )

  

INSERT INTO #TabelaBaseTributacao
(
    KeyValue,
    TipoDespesa,
    IdPessoa,
    IdTributo,
    Codigo,
    Nome,
    Mes,
    ValorTributo
)

SELECT R.KeyValue,
       R.TipoDespesa,
       R.IdPessoa,
	   R.IdTributo,
       R.Codigo,
       R.Nome,
       R.Mes,
       R.ValorTributo
FROM DadosBaseTributos R;





/* ==================================================================
--Observação: Recupera os dados base para a parte de Ajuda de Custo e Diarias (não faz o agrupamento ainda)
-- ==================================================================
*/
WITH DadosBaseAjudaCustoDiarias
AS (

	SELECT P.IdPagamento AS KeyValue,
		   'PG' AS TipoDespesa,
		   SF.IdPessoa,
		   MONTH(P.DataPagamento) AS Mes,
		   ValorDiaria = (P.Valor - CASE
										WHEN @ConsiderarEstornoPagamentoDIRF = 1 THEN
											P.ValorEstornado
										ELSE
											0
									END
						 )
	FROM Despesa.Pagamentos AS P
		JOIN Despesa.SaidasFinanceiras AS SF
			ON SF.IdSaidaFinanceira = P.IdSaidaFinanceira
		JOIN Despesa.Liquidacoes AS L
			ON L.IdLiquidacao = P.IdLiquidacao
		JOIN Despesa.Empenhos AS E
			ON E.IdEmpenho = L.IdEmpenho
		JOIN #IdsContasDiariaAjudaCustos AS ICDAC
			ON ICDAC.Prefixo = E.IdPlanoConta
		JOIN #PessoasDirf AS P2
			ON P2.IdPessoa = SF.IdPessoa
	WHERE SF.IdPessoa = ISNULL(@IdPessoa, SF.IdPessoa)
		  AND YEAR(P.DataPagamento) = @Exercicio
		  AND MONTH(P.DataPagamento)
		  BETWEEN @MesInicio AND @MesFim
		  AND P.Estorno = 0
		  AND (
				  P2.Imune = 0
				  AND P2.Isento = 0
			  )
   )
INSERT INTO #TabelaBaseAjudaCustoDiarias
(
    KeyValue,
    TipoDespesa,
    IdPessoa,
    Codigo,
    Nome,
    IdTributo,
    Mes,
    ValorDiaria
)

SELECT B.KeyValue,
       B.TipoDespesa,
       B.IdPessoa,
	   @CodigoTributoIsentoPF,
	   @NomeTributoIsentoPF,
	   @IdCodigoTributoIsentoPF,
       B.Mes,
       B.ValorDiaria
FROM DadosBaseAjudaCustoDiarias B






/* ==================================================================
--Observação: Recupera os dados base para a parte de Deduçoes (não faz o agrupamento ainda)
-- ==================================================================
*/




/*Para buscar os pagamentos com os tipos Autônomo = 1, Aluguel = 2 ou Royalties = 3 
 que totalizam valor superior a $6.000,00 e incluí-los nos tributos respectivos */
DECLARE @IdTributo_0588 UNIQUEIDENTIFIER,
        @IdTributo_3208 UNIQUEIDENTIFIER,
        @ConsideraTipoPagamento BIT;

--Busca o cadastro do tributo respectivo
SELECT @IdTributo_0588 = Tributos.IdTributo
FROM Despesa.Tributos
WHERE Tributos.Codigo = '0588';
/*Para Autônomo*/

SELECT @IdTributo_3208 = Tributos.IdTributo
FROM Despesa.Tributos
WHERE Tributos.Codigo = '3208';
/*Para Royaltes e Aluguel*/





INSERT INTO #TabelaBasePagamentosAluguelAutonomoAlugueisRoyates
(
    Codigo,
    NomeTributo,
    IdTributo,
    IdPessoa,
    IdPagamento,
    CPFCNPJ,
    NomeRazaoSocial,
    TipoPessoaFisica,
    ValorAplicado,
    Tipo,
    Mes,
    Imune,
    Isento
)
SELECT Codigo = CASE
                    WHEN P.Tipo = 1 THEN
                        '0588'
                    ELSE
                        '3208'
                END,
       NomeTributo = CASE
                         WHEN P.Tipo = 1 THEN
                             'Autônomo'
                         WHEN P.Tipo = 2 THEN
                             'Aluguel'
                         ELSE
                             'Royalties'
                     END,
       IdTributo = CASE
                       WHEN P.Tipo IN ( 1, 2 ) THEN
                           @IdTributo_0588
                       ELSE
                           @IdTributo_3208
                   END,
       SF.IdPessoa,
       P.IdPagamento,
       P2.CPFCNPJ,
       P2.NomeRazaoSocial,
       P2.TipoPessoaFisica,
       ValorAplicado = (P.Valor - CASE
                                      WHEN @ConsiderarEstornoPagamentoDIRF = 1 THEN
                                          P.ValorEstornado
                                      ELSE
                                          0
                                  END
                       ),
       P.Tipo,
       Mes = MONTH(P.DataPagamento),
       P2.Imune,
       P2.Isento
FROM Despesa.Pagamentos AS P
    JOIN Despesa.SaidasFinanceiras SF
        ON SF.IdSaidaFinanceira = P.IdSaidaFinanceira
    JOIN #PlanoContasExercicio AS PCE
        ON PCE.IdPlanoConta = SF.IdPlanoConta
    JOIN #PessoasDirf AS P2
        ON P2.IdPessoa = SF.IdPessoa
WHERE MONTH(ISNULL(P.DataPagamento, 0))
      BETWEEN @MesInicio AND @MesFim
      AND YEAR(ISNULL(P.DataPagamento, 0)) = @Exercicio
      AND P.Tipo IN ( 1, 2, 3 )
      AND P.Estorno = 0
      AND SF.IdPessoa = ISNULL(@IdPessoa, SF.IdPessoa);





INSERT INTO #TabelaBasePagamentosGeralNaoSeAplica
(
    IdPessoa,
    IdPagamento,
    CPFCNPJ,
    NomeRazaoSocial,
    TipoPessoaFisica,
    ValorConsiderado,
    Tipo,
    Mes,
    Imune,
    Isento
)

SELECT P2.IdPessoa,
       P.IdPagamento AS KeyValue,
       P2.CPFCNPJ,
       P2.NomeRazaoSocial,
       P2.TipoPessoaFisica,
       ValorConsiderado = CASE
                              WHEN @Exercicio >= @ConsideraEstorno THEN
                                  ISNULL((P.Valor - P.ValorEstornado), 0)
                              ELSE
                                  ISNULL((P.Valor), 0)
                          END,
       P.Tipo,
       Mes = MONTH(P.DataPagamento),
       P2.Imune,
       P2.Isento
FROM Despesa.Pagamentos AS P
    JOIN Despesa.SaidasFinanceiras SF ON SF.IdSaidaFinanceira = P.IdSaidaFinanceira
    JOIN #PlanoContasExercicio AS PCE ON PCE.IdPlanoConta = SF.IdPlanoConta
    LEFT JOIN #TabelaBaseCalculo AS TBC ON TBC.KeyValue = P.IdPagamento
    JOIN #PessoasDirf AS P2 ON P2.IdPessoa = SF.IdPessoa
WHERE TBC.KeyValue IS NULL
      AND YEAR(P.DataPagamento) = @Exercicio
      AND MONTH(P.DataPagamento)
      BETWEEN @MesInicio AND @MesFim
      AND P.Tipo = 0
      AND P.Estorno = 0
      AND SF.IdPessoa = ISNULL(@IdPessoa, SF.IdPessoa)
      AND NOT EXISTS
(
    SELECT *
    FROM Despesa.Pagamentos AS P3
        JOIN Despesa.Liquidacoes AS L
            ON L.IdLiquidacao = P3.IdLiquidacao
        JOIN Despesa.Empenhos AS E
            ON E.IdEmpenho = L.IdEmpenho
        JOIN #IdsContasDiariaAjudaCustos AS ICDAC
            ON ICDAC.Prefixo = E.IdPlanoConta
    WHERE P3.IdPagamento = P.IdPagamento
)
UNION ALL
SELECT SF.IdPessoa,
       MF.IdMovimentoFinanceiro AS KeyValue,
       PD.CPFCNPJ,
       PD.NomeRazaoSocial,
       PD.TipoPessoaFisica,
       MF.Valor,
       0 AS Tipo,
       Mes = MONTH(MF.Data),
       PD.Imune,
       PD.Isento
FROM Despesa.MovimentosFinanceiros AS MF
    JOIN Despesa.SaidasFinanceiras AS SF ON MF.IdSaidaFinanceira = SF.IdSaidaFinanceira
    JOIN #PlanoContasExercicio AS PC ON PC.IdPlanoConta = SF.IdPlanoConta
    JOIN #PessoasDirf AS PD ON SF.IdPessoa = PD.IdPessoa
    LEFT JOIN Despesa.TributosRetidosMovimentosFinanceiros AS TMF ON MF.IdMovimentoFinanceiro = TMF.IdMovimentoFinanceiro
WHERE TMF.IdTributoRetidoMovimentoFinanceiro IS NULL
      AND YEAR(MF.Data) = @Exercicio
      AND SF.IdPessoa = ISNULL(@IdPessoa, SF.IdPessoa);











/* ==================================================================
--Data: 11/02/2019 
--Autor :Wesley Neves
--Observação: Inicio dos registros de vinculos das tabelas com as regras da dirf
 
-- ==================================================================
*/

INSERT INTO #TabelaAuxiliarPrimeiroTributoBaseCalculo
(
    IdPessoa,
    IdTributo,
    Codigo,
    NomeTributo
)
SELECT PD.IdPessoa,
       @IdCodigoTributoIsentoPF,
       @CodigoTributoIsentoPF,
       @NomeTributoIsentoPF
FROM #PessoasDirf AS PD
WHERE PD.TipoPessoaFisica = 1






;WITH DadosBaseDeducoes
AS (SELECT p.IdPagamento AS KeyValue,
           'PG' AS TipoDespesa,
           TR.IdPessoa,
           T.Codigo,
           T.Nome,
           T.IdTributo,
           Mes = MONTH(p.DataPagamento),
           ValorDeducao = TR.ValorTributo
    FROM Despesa.TributosRetidos TR
        INNER JOIN Despesa.Tributos T
            ON T.IdTributo = TR.IdTributo
        INNER JOIN Despesa.TributosNaturezas TN
            ON TN.IdTributoNatureza = T.IdTributoNatureza
        INNER JOIN Despesa.TributosRetidosPagamentos TRP
            ON TRP.IdTributoRetido = TR.IdTributoRetido
        INNER JOIN Despesa.Pagamentos p
            ON p.IdPagamento = TRP.IdPagamento
        INNER JOIN Despesa.SaidasFinanceiras SF
            ON SF.IdSaidaFinanceira = p.IdSaidaFinanceira
        JOIN #PessoasDirf AS PD
            ON PD.IdPessoa = TR.IdPessoa
    WHERE TR.ValorTributo >= 0
          AND (
                  PD.Imune = 0
                  AND PD.Isento = 0
              )
          AND YEAR(p.DataPagamento) = @Exercicio
          AND MONTH(p.DataPagamento)
          BETWEEN @MesInicio AND @MesFim
          AND TN.Nome IN (
                             SELECT TTRF.NomeTributo FROM #TableTributosRetidosFonte AS TTRF
                         )
          AND p.Estorno = 0
          AND (
                  (
                      @somenteFavorecidosComRamoDeTributo = 0
                      AND TR.IdPessoa = ISNULL(@IdPessoa, TR.IdPessoa)
                  )
                  OR (
                         @somenteFavorecidosComRamoDeTributo = 1
                         AND EXISTS
    (
        SELECT 1 FROM #PessoasDirf AS PD2 WHERE PD2.IdPessoa = TR.IdPessoa
    )
                     )
              )
    UNION ALL
    SELECT MF.IdMovimentoFinanceiro AS KeyValue,
           'MF' AS TipoDespesa,
           TR.IdPessoa,
           T.Codigo,
           T.Nome,
           T.IdTributo,
           Mes = MONTH(MF.Data),
           ValorDeducao = TR.ValorTributo
    FROM Despesa.TributosRetidos TR
        INNER JOIN Despesa.Tributos T
            ON T.IdTributo = TR.IdTributo
        INNER JOIN Despesa.TributosNaturezas TN
            ON TN.IdTributoNatureza = T.IdTributoNatureza
        INNER JOIN Despesa.TributosRetidosMovimentosFinanceiros TMF
            ON TMF.IdTributoRetido = TR.IdTributoRetido
        INNER JOIN Despesa.MovimentosFinanceiros MF
            ON MF.IdMovimentoFinanceiro = TMF.IdMovimentoFinanceiro
        INNER JOIN Despesa.SaidasFinanceiras SF
            ON SF.IdSaidaFinanceira = MF.IdSaidaFinanceira
        JOIN #PessoasDirf AS PD
            ON PD.IdPessoa = TR.IdPessoa
    WHERE TR.ValorTributo >= 0
          AND (
                  PD.Imune = 0
                  AND PD.Isento = 0
              )
          AND YEAR(MF.Data) = @Exercicio
          AND MONTH(MF.Data)
          BETWEEN @MesInicio AND @MesFim
          AND TN.Nome IN (
                             SELECT TTRF.NomeTributo FROM #TableTributosRetidosFonte AS TTRF
                         )
          AND (
                  (
                      @somenteFavorecidosComRamoDeTributo = 0
                      AND TR.IdPessoa = ISNULL(@IdPessoa, TR.IdPessoa)
                  )
                  OR (
                         @somenteFavorecidosComRamoDeTributo = 1
                         AND EXISTS
    (
        SELECT 1 FROM #PessoasDirf AS p WHERE p.IdPessoa = TR.IdPessoa
    )
                     )
              )
   )
INSERT INTO #TabelaBaseDeducao
(
    KeyValue,
    TipoDespesa,
    IdPessoa,
    CodigoTributo,
    Nome,
    IdTributo,
    Mes,
    ValorDeducao
)
SELECT R.KeyValue,
       R.TipoDespesa,
       R.IdPessoa,
       NULL,
       NULL,
	   NULL,
       R.Mes,
       R.ValorDeducao
FROM DadosBaseDeducoes R





INSERT INTO #TabelaAuxiliarPrimeiroTributoBaseCalculo
(
    IdPessoa,
    IdTributo,
    Codigo,
    NomeTributo
)
SELECT PD.IdPessoa,
       @IdCodigoTributoIsentoPF,
       @CodigoTributoIsentoPF,
       @NomeTributoIsentoPF
FROM #PessoasDirf AS PD
WHERE PD.TipoPessoaFisica = 1
      AND NOT EXISTS
(
    SELECT 1
    FROM #TabelaAuxiliarPrimeiroTributoBaseCalculo T
    WHERE PD.IdPessoa = T.IdPessoa
)






/*Verifica se o pagamento do tipo 1,2,3 teve tributação (IRPF/ IRPJ)*/
UPDATE Tipo123
SET Tipo123.PagamentoTributado_IRPF_IRPJ = 1
FROM #TabelaBasePagamentosAluguelAutonomoAlugueisRoyates AS Tipo123
WHERE EXISTS
(
    SELECT *
    FROM #TabelaBaseTributacao AS TBT
    WHERE TBT.KeyValue = Tipo123.IdPagamento
);


/*Verifica se o pagamento  do tipo 1,2,3 já foi contabilizado na base de calculo  R$*/

UPDATE Tipo123
SET Tipo123.PagamentoFoiContabilizadoNaBaseDeCalculo = 1
FROM #TabelaBasePagamentosAluguelAutonomoAlugueisRoyates AS Tipo123
WHERE EXISTS
(
    SELECT 1
    FROM #TabelaBaseCalculo AS TBC
    WHERE TBC.KeyValue = Tipo123.IdPagamento
);



/*Verifica se o pagamento  do tipo 1,2,3 está relacionado a Pagamentos de diarias  R$*/
UPDATE Tipo123  SET Tipo123.PagamentoReferenteADiarias = 1
FROM #TabelaBasePagamentosAluguelAutonomoAlugueisRoyates AS Tipo123
WHERE  EXISTS(SELECT * FROM #TabelaBaseAjudaCustoDiarias AS Diaria 
					WHERE Diaria.KeyValue = Tipo123.IdPagamento)







/*Updates  #TabelaBasePagamentosGeralNaoSeAplica  (Pagamentos tipo Zero)*/
/*Verifica se o pagamento do tipo 0(Não se Aplica) teve tributação (IRPF/ IRPJ)*/

UPDATE TipoZero
SET TipoZero.PagamentoTributado_IRPF_IRPJ = 1
FROM #TabelaBasePagamentosGeralNaoSeAplica AS TipoZero
WHERE EXISTS
(
    SELECT *
    FROM #TabelaBaseTributacao AS TBT
    WHERE TBT.KeyValue = TipoZero.IdPagamento
);

UPDATE TipoZero
SET TipoZero.PagamentoReferenteAjudaCusto = 1
FROM #TabelaBasePagamentosGeralNaoSeAplica AS TipoZero
WHERE EXISTS
(
    SELECT *
    FROM #TabelaBaseAjudaCustoDiarias AS TBACD
    WHERE TBACD.KeyValue = TipoZero.IdPagamento
);

UPDATE TipoZero
SET TipoZero.PagamentoFoiContabilizadoNaBaseDeCalculo = 1
FROM #TabelaBasePagamentosGeralNaoSeAplica AS TipoZero
WHERE EXISTS
(
    SELECT *
    FROM #TabelaBaseCalculo AS TBC
    WHERE TBC.KeyValue = TipoZero.IdPagamento
);




	



/*Updates  #TabelaBaseAjudaCustoDiarias  (Pagamentos com contas configuradas para diarias)*/

UPDATE diaria
SET diaria.HasTributacao_IRPF_IRPJ = 1
FROM #TabelaBaseAjudaCustoDiarias AS diaria
WHERE EXISTS
(
    SELECT 1
    FROM #TabelaBaseTributacao AS TBT
    WHERE diaria.KeyValue = TBT.KeyValue
);




/*Regras Para as pessoas*/

UPDATE PD
SET PD.HasPagamentoTipoAutonomoMaiorQueSeisMill = 1
FROM #PessoasDirf AS PD
    JOIN
    (
        SELECT Tipo123.IdPessoa,
               SUM(Tipo123.ValorAplicado) TotalPagamentos
        FROM #TabelaBasePagamentosAluguelAutonomoAlugueisRoyates AS Tipo123
		WHERE Tipo123.Tipo =1 --Autônomo
        GROUP BY Tipo123.IdPessoa
        HAVING SUM(Tipo123.ValorAplicado) > @ValorParaPagamentosAutonomos
    ) AS Maior ON PD.IdPessoa = Maior.IdPessoa;


UPDATE PD
SET PD.HasPagamentoTipoAluguelMaiorQueSeisMill = 1
FROM #PessoasDirf AS PD
    JOIN
    (
        SELECT Tipo123.IdPessoa,
               SUM(Tipo123.ValorAplicado) TotalPagamentos
        FROM #TabelaBasePagamentosAluguelAutonomoAlugueisRoyates AS Tipo123
		WHERE Tipo123.Tipo =2 --Aluguel
        GROUP BY Tipo123.IdPessoa
        HAVING SUM(Tipo123.ValorAplicado) > @ValorParaPagamentosAutonomos
    ) AS Maior ON PD.IdPessoa = Maior.IdPessoa;


UPDATE PD
SET PD.HasPagamentoTipoRoyaltesQueSeisMill = 1
FROM #PessoasDirf AS PD
    JOIN
    (
        SELECT Tipo123.IdPessoa,
               SUM(Tipo123.ValorAplicado) TotalPagamentos
        FROM #TabelaBasePagamentosAluguelAutonomoAlugueisRoyates AS Tipo123
		WHERE Tipo123.Tipo =3 --Royalties
        GROUP BY Tipo123.IdPessoa
        HAVING SUM(Tipo123.ValorAplicado) > @ValorParaPagamentosAutonomos
    ) AS Maior ON PD.IdPessoa = Maior.IdPessoa;




		
UPDATE PD
SET PD.HasTributacao = 1
FROM #PessoasDirf AS PD
WHERE EXISTS
(
    SELECT *
    FROM #TabelaBaseTributacao AS TBT
    WHERE TBT.IdPessoa = PD.IdPessoa
);

	
UPDATE PD
SET PD.HasAjudaDeCusto = 1
FROM #PessoasDirf AS PD
WHERE EXISTS
(
    SELECT *
    FROM #TabelaBaseAjudaCustoDiarias AS TBACD
    WHERE TBACD.IdPessoa = PD.IdPessoa
);


UPDATE PD
SET PD.HasDeducao = 1
FROM #PessoasDirf AS PD
WHERE EXISTS
(
    SELECT *
    FROM #TabelaBaseDeducao AS TBD
    WHERE TBD.IdPessoa = PD.IdPessoa
);







DELETE NaoSeAplica 
FROM #TabelaBasePagamentosGeralNaoSeAplica NaoSeAplica
JOIN #PessoasDirf AS PD ON NaoSeAplica.IdPessoa = PD.IdPessoa
WHERE PD.HasTributacao =0  





/* ==================================================================
--Data: 11/02/2019 
--Autor :Wesley Neves
--Observação: Regras 
 
#Regra 1)
quando  a pessoa teve tributação e pagamentos tipo 123 maior que 6000.

Item 1) 
Somar todos os não se aplica 
que não teve tributação e não teve ajuda de custo,    *** e tambem dedução (Falta esse entendimento)
se somar ao primeiro tributo do pivot da base de calculo. (Ajusta a base calculo)

Item 2) 
Criar uma linha para o tributo 1,2,3 dos pagamentos 1,2,3 que não foram tributados e que não seja ajuda de custo
--
1) Pagamento houve retenção?
   Sim = Todos
   Não = 
2) Soma pagamento do tipo (1, 2 e 3) maior que R$ 6,000 para o favorecido


-- ==================================================================
*/



INSERT INTO #TabelaBaseCalculo
	(
		KeyValue,
		TipoDespesa,
		IdPessoa,
		Codigo,
		Nome,
		IdTributo,
		Mes,
		ValorConsiderado
	)

SELECT Tipo123.IdPagamento,
	'Regra 1 Item 1' AS TipoDespesa,
	  Tipo123.IdPessoa,
       TributoIRRF.Codigo,
       TributoIRRF.NomeTributo,
	   TributoIRRF.IdTributo,
       Tipo123.Mes,
       Tipo123.ValorAplicado
FROM #TabelaBasePagamentosAluguelAutonomoAlugueisRoyates AS Tipo123
JOIN #PessoasDirf PD ON Tipo123.IdPessoa = PD.IdPessoa
JOIN #TabelaAuxiliarPrimeiroTributoBaseCalculo AS TributoIRRF ON PD.IdPessoa = TributoIRRF.IdPessoa
WHERE PD.HasTributacao = 1
      AND Tipo123.PagamentoFoiContabilizadoNaBaseDeCalculo = 0;

	
	
	  

INSERT INTO #TabelaBaseCalculo
	(
		KeyValue,
		TipoDespesa,
		IdPessoa,
		Codigo,
		Nome,
		IdTributo,
		Mes,
		ValorConsiderado
	)
	
SELECT NaoAplica.IdPagamento,
		'Regra 1 Item 1' AS TipoDespesa,
       NaoAplica.IdPessoa,
       TributoIRRF.Codigo,
       TributoIRRF.NomeTributo,
       TributoIRRF.IdTributo,
       NaoAplica.Mes,
       NaoAplica.ValorConsiderado
	    FROM #TabelaBasePagamentosGeralNaoSeAplica AS NaoAplica JOIN #PessoasDirf AS PD ON NaoAplica.IdPessoa = PD.IdPessoa
		JOIN #TabelaAuxiliarPrimeiroTributoBaseCalculo AS TributoIRRF ON PD.IdPessoa = TributoIRRF.IdPessoa
WHERE PD.HasTributacao =1 
 AND NaoAplica.PagamentoFoiContabilizadoNaBaseDeCalculo = 0;





/* ==================================================================
--Data: 13/02/2019 
--Autor :Wesley Neves
--Observação: 
#Regra 3)
quando  a pessoa não teve tributação e teve somente ajuda de custo ou dedução
Item 1) 
Somar todos os pagamentos(#TabelaBasePagamentosAluguelAutonomoAlugueisRoyates e #TabelaBasePagamentosGeralNaoSeAplica) , que não seja ajuda de custo
 (Ajusta a base calculo) 
 
-- ==================================================================
*/

/*Trata o tipo 1*/
INSERT INTO #TabelaBaseCalculo
(
    KeyValue,
    TipoDespesa,
    IdPessoa,
    Codigo,
    Nome,
    IdTributo,
    Mes,
    ValorConsiderado
)
SELECT Tipo123.IdPagamento,
       'Regra 2 Item 1' AS TipoDespesa,
       Tipo123.IdPessoa,
       Tipo123.Codigo,
       Tipo123.NomeTributo,
       Tipo123.IdTributo,
       Tipo123.Mes,
       Tipo123.ValorAplicado
FROM #TabelaBasePagamentosAluguelAutonomoAlugueisRoyates AS Tipo123
JOIN #PessoasDirf AS PD ON Tipo123.IdPessoa = PD.IdPessoa
WHERE  PD.HasTributacao = 0  AND PD.HasPagamentoTipoAutonomoMaiorQueSeisMill =1


--SELECT * FROM #TabelaBasePagamentosAluguelAutonomoAlugueisRoyates AS TBPAAAR

--SELECT * FROM #TabelaBaseCalculo AS TBC
--SELECT * FROM  #TabelaBaseDeducao AS TBD
--SELECT * FROM  #TabelaBaseAjudaCustoDiarias AS TBACD

--SELECT * FROM #TabelaBasePagamentosGeralNaoSeAplica AS TBPGNSA


/*Trata o tipo 2*/
INSERT INTO #TabelaBaseCalculo
(
    KeyValue,
    TipoDespesa,
    IdPessoa,
    Codigo,
    Nome,
    IdTributo,
    Mes,
    ValorConsiderado
)
SELECT Tipo123.IdPagamento,
       'Regra 2 Item 1' AS TipoDespesa,
       Tipo123.IdPessoa,
       Tipo123.Codigo,
       Tipo123.NomeTributo,
       Tipo123.IdTributo,
       Tipo123.Mes,
       Tipo123.ValorAplicado
FROM #TabelaBasePagamentosAluguelAutonomoAlugueisRoyates AS Tipo123
JOIN #PessoasDirf AS PD ON Tipo123.IdPessoa = PD.IdPessoa
WHERE  PD.HasTributacao = 0  AND PD.HasPagamentoTipoAluguelMaiorQueSeisMill =1




/*Trata o tipo 3*/
INSERT INTO #TabelaBaseCalculo
(
    KeyValue,
    TipoDespesa,
    IdPessoa,
    Codigo,
    Nome,
    IdTributo,
    Mes,
    ValorConsiderado
)
SELECT Tipo123.IdPagamento,
       'Regra 2 Item 1' AS TipoDespesa,
       Tipo123.IdPessoa,
       Tipo123.Codigo,
       Tipo123.NomeTributo,
       Tipo123.IdTributo,
       Tipo123.Mes,
       Tipo123.ValorAplicado
FROM #TabelaBasePagamentosAluguelAutonomoAlugueisRoyates AS Tipo123
JOIN #PessoasDirf AS PD ON Tipo123.IdPessoa = PD.IdPessoa
WHERE  PD.HasTributacao = 0  AND PD.HasPagamentoTipoRoyaltesQueSeisMill =1





/* ==================================================================
--Data: 11/02/2019 
--Autor :Wesley Neves
--Observação: Resultado Final  Geração dos Pivots
 
-- ==================================================================*/



INSERT INTO #TabelaPivotBaseCalculo
SELECT IdPessoa,
       Codigo,
       Nome,
       IdTributo,
       ISNULL([1], 0) AS PgJan,
       ISNULL([2], 0) AS PgFev,
       ISNULL([3], 0) AS PgMar,
       ISNULL([4], 0) AS PgAbr,
       ISNULL([5], 0) AS PgMai,
       ISNULL([6], 0) AS PgJun,
       ISNULL([7], 0) AS PgJul,
       ISNULL([8], 0) AS PgAgo,
       ISNULL([9], 0) AS PgSet,
       ISNULL([10], 0) AS PgOut,
       ISNULL([11], 0) AS PgNov,
       ISNULL([12], 0) AS PgDez
FROM
(
    SELECT TBC.IdPessoa,
           TBC.Codigo,
           TBC.Nome,
           TBC.IdTributo,
           TBC.Mes,
           SUM(TBC.ValorConsiderado) AS ValorConsiderado
    FROM #TabelaBaseCalculo AS TBC
    GROUP BY TBC.IdPessoa,
             TBC.Codigo,
             TBC.Nome,
             TBC.IdTributo,
             TBC.Mes
) AS BaseCalculoAgrupados
PIVOT
(
    SUM(ValorConsiderado)
    FOR Mes IN ([1], [2], [3], [4], [5], [6], [7], [8], [9], [10], [11], [12])
) AS pvt;




 



INSERT INTO #TabelaPivotDeducoes
SELECT IdPessoa,
      pvt.Codigo,
	  pvt.NomeTributo,
	  pvt.IdTributo,
       ISNULL([1], 0) AS PgJan,
       ISNULL([2], 0) AS PgFev,
       ISNULL([3], 0) AS PgMar,
       ISNULL([4], 0) AS PgAbr,
       ISNULL([5], 0) AS PgMai,
       ISNULL([6], 0) AS PgJun,
       ISNULL([7], 0) AS PgJul,
       ISNULL([8], 0) AS PgAgo,
       ISNULL([9], 0) AS PgSet,
       ISNULL([10], 0) AS PgOut,
       ISNULL([11], 0) AS PgNov,
       ISNULL([12], 0) AS PgDez
FROM
(
    SELECT TBD.IdPessoa,
            Primeiro.Codigo,
           Primeiro.NomeTributo,
           Primeiro.IdTributo,
           TBD.Mes,
           SUM(TBD.ValorDeducao) AS ValorDeducao
    FROM #TabelaBaseDeducao AS TBD
	JOIN #TabelaAuxiliarPrimeiroTributoBaseCalculo AS Primeiro ON TBD.IdPessoa = Primeiro.IdPessoa
    GROUP BY TBD.IdPessoa,
             Primeiro.Codigo,
             Primeiro.NomeTributo,
             Primeiro.IdTributo,
             TBD.Mes
	
          
) AS DeducoesAgrupados
PIVOT
(
    SUM(ValorDeducao)
    FOR Mes IN ([1], [2], [3], [4], [5], [6], [7], [8], [9], [10], [11], [12])
) AS pvt;







INSERT INTO #TabelaPivotTributos
SELECT IdPessoa,
       Codigo,
       Nome,
       IdTributo,
       ISNULL([1], 0) AS PgJan,
       ISNULL([2], 0) AS PgFev,
       ISNULL([3], 0) AS PgMar,
       ISNULL([4], 0) AS PgAbr,
       ISNULL([5], 0) AS PgMai,
       ISNULL([6], 0) AS PgJun,
       ISNULL([7], 0) AS PgJul,
       ISNULL([8], 0) AS PgAgo,
       ISNULL([9], 0) AS PgSet,
       ISNULL([10], 0) AS PgOut,
       ISNULL([11], 0) AS PgNov,
       ISNULL([12], 0) AS PgDez
FROM
(
    SELECT TBT.IdPessoa,
           TBT.Codigo,
           TBT.Nome,
           TBT.IdTributo,
           TBT.Mes,
           SUM(TBT.ValorTributo) AS ValorTributo
    FROM #TabelaBaseTributacao AS TBT
    GROUP BY TBT.IdPessoa,
             TBT.Codigo,
             TBT.Nome,
             TBT.IdTributo,
             TBT.Mes
) AS DadosTributos
PIVOT
(
    SUM(ValorTributo)
    FOR Mes IN ([1], [2], [3], [4], [5], [6], [7], [8], [9], [10], [11], [12])
) AS pvt;



INSERT INTO #TabelaPivotDiariasEAjudaCusto
SELECT PIVT.IdPessoa,
	    Codigo,
	    Nome,
	    IdTributo,
       ISNULL(PIVT.[1], 0),
       ISNULL(PIVT.[2], 0),
       ISNULL(PIVT.[3], 0),
       ISNULL(PIVT.[4], 0),
       ISNULL(PIVT.[5], 0),
       ISNULL(PIVT.[6], 0),
       ISNULL(PIVT.[7], 0),
       ISNULL(PIVT.[8], 0),
       ISNULL(PIVT.[9], 0),
       ISNULL(PIVT.[10], 0),
       ISNULL(PIVT.[11], 0),
       ISNULL(PIVT.[12], 0)
FROM
(
	SELECT TBACD.IdPessoa,
		   TBACD.Codigo,
		   TBACD.Nome,
		   TBACD.IdTributo,
		   TBACD.Mes,
		   SUM(TBACD.ValorDiaria) AS ValorDiaria
	FROM #TabelaBaseAjudaCustoDiarias AS TBACD
	GROUP BY TBACD.IdPessoa,
			 TBACD.Codigo,
			 TBACD.Nome,
			 TBACD.IdTributo,
			 TBACD.Mes
   
) AS DadosAjudaCustoDiarias
PIVOT
(
    SUM(ValorDiaria)
    FOR Mes IN ([1], [2], [3], [4], [5], [6], [7], [8], [9], [10], [11], [12])
) AS PIVT;






INSERT INTO #TabelaPivotBaseCalculo
(
    IdPessoa,
    Codigo,
    NomeTributo,
    IdTributo,
    BaseCalc01,
    BaseCalc02,
    BaseCalc03,
    BaseCalc04,
    BaseCalc05,
    BaseCalc06,
    BaseCalc07,
    BaseCalc08,
    BaseCalc09,
    BaseCalc10,
    BaseCalc11,
    BaseCalc12
)
SELECT Ajuda.IdPessoa,
       Ajuda.CodigoTributo,
       Ajuda.Nometributo,
       Ajuda.IdTributo,
      0,0,0,0,0,0,0,0,0,0,0,0 FROM #TabelaPivotDiariasEAjudaCusto AS Ajuda
	  JOIN #PessoasDirf AS PD ON Ajuda.IdPessoa = PD.IdPessoa
	  WHERE PD.HasTributacao = 0 AND PD.HasAjudaDeCusto =1

	  

--SELECT * FROM #TabelaPivotBaseCalculo AS TPBC
--SELECT * FROM #TabelaPivotDeducoes AS TPD
--SELECT * FROM #TabelaPivotDiariasEAjudaCusto AS TPDEAC
--SELECT * FROM #TabelaPivotTributos AS TPT





INSERT INTO #Dirf
SELECT BASE.IdPessoa,
       CPFCNPJ = Pessoa.CPFCNPJ,
       Pessoa.NomeRazaoSocial,
       Pessoa.TipoPessoaFisica,
       [IdTributo] = ISNULL(TRIB.IdTributo, BASE.IdTributo),
       [Codigo] = ISNULL(TRIB.Codigo, BASE.Codigo),
       BASE.NomeTributo,
       [BaseCalc01] = BASE.BaseCalc01,
       [Trib01] = ISNULL(TRIB.Trib01, 0),
       [Deducoes01] = ISNULL(Deducao.Deducoes01, 0),
       [AjudaCusto01] = ISNULL(AjudaCusto.AjudaCusto01, 0),
       [BaseCalc02] = BASE.BaseCalc02,
       [Trib02] = ISNULL(TRIB.Trib02, 0),
       [Deducoes02] = ISNULL(Deducao.Deducoes02, 0),
       [AjudaCusto02] = ISNULL(AjudaCusto.AjudaCusto02, 0),
       [BaseCalc03] = BASE.BaseCalc03,
       [Trib03] = ISNULL(TRIB.Trib03, 0),
       [Deducoes03] = ISNULL(Deducao.Deducoes03, 0),
       [AjudaCusto03] = ISNULL(AjudaCusto.AjudaCusto03, 0),
       [BaseCalc04] = BASE.BaseCalc04,
       [Trib04] = ISNULL(TRIB.Trib04, 0),
       [Deducoes04] = ISNULL(Deducao.Deducoes04, 0),
       [AjudaCusto04] = ISNULL(AjudaCusto.AjudaCusto04, 0),
       [BaseCalc05] = BASE.BaseCalc05,
       [Trib05] = ISNULL(TRIB.Trib05, 0),
       [Deducoes05] = ISNULL(Deducao.Deducoes05, 0),
       [AjudaCusto05] = ISNULL(AjudaCusto.AjudaCusto05, 0),
       [BaseCalc06] = BASE.BaseCalc06,
       [Trib06] = ISNULL(TRIB.Trib06, 0),
       [Deducoes06] = ISNULL(Deducao.Deducoes06, 0),
       [AjudaCusto06] = ISNULL(AjudaCusto.AjudaCusto06, 0),
       [BaseCalc07] = BASE.BaseCalc07,
       [Trib07] = ISNULL(TRIB.Trib07, 0),
       [Deducoes07] = ISNULL(Deducao.Deducoes07, 0),
       [AjudaCusto07] = ISNULL(AjudaCusto.AjudaCusto07, 0),
       [BaseCalc08] = BASE.BaseCalc08,
       [Trib08] = ISNULL(TRIB.Trib08, 0),
       [Deducoes08] = ISNULL(Deducao.Deducoes08, 0),
       [AjudaCusto08] = ISNULL(AjudaCusto.AjudaCusto08, 0),
       [BaseCalc09] = BASE.BaseCalc09,
       [Trib09] = ISNULL(TRIB.Trib09, 0),
       [Deducoes09] = ISNULL(Deducao.Deducoes09, 0),
       [AjudaCusto09] = ISNULL(AjudaCusto.AjudaCusto09, 0),
       [BaseCalc10] = BASE.BaseCalc10,
       [Trib10] = ISNULL(TRIB.Trib10, 0),
       [Deducoes10] = ISNULL(Deducao.Deducoes10, 0),
       [AjudaCusto10] = ISNULL(AjudaCusto.AjudaCusto10, 0),
       [BaseCalc11] = BASE.BaseCalc11,
       [Trib11] = ISNULL(TRIB.Trib11, 0),
       [Deducoes11] = ISNULL(Deducao.Deducoes11, 0),
       [AjudaCusto11] = ISNULL(AjudaCusto.AjudaCusto11, 0),
       [BaseCalc12] = BASE.BaseCalc12,
       [Trib12] = ISNULL(TRIB.Trib12, 0),
       [Deducoes12] = ISNULL(Deducao.Deducoes12, 0),
       [AjudaCusto12] = ISNULL(AjudaCusto.AjudaCusto12, 0),
       Imune = CAST(0 AS BIT),
       Isento = CAST(0 AS BIT)
FROM #TabelaPivotBaseCalculo AS BASE
    JOIN #PessoasDirf AS Pessoa ON Pessoa.IdPessoa = BASE.IdPessoa
	LEFT JOIN #TabelaPivotDeducoes AS Deducao ON BASE.IdPessoa = Deducao.IdPessoa AND BASE.Codigo = Deducao.Codigo AND BASE.IdTributo = Deducao.IdTributo AND BASE.NomeTributo = Deducao.NomeTributo
    LEFT JOIN #TabelaPivotTributos AS TRIB ON TRIB.IdPessoa = BASE.IdPessoa  AND BASE.IdTributo = TRIB.IdTributo AND BASE.NomeTributo = TRIB.NomeTributo AND BASE.Codigo = TRIB.Codigo
	LEFT JOIN #TabelaPivotDiariasEAjudaCusto AS AjudaCusto ON BASE.IdPessoa = AjudaCusto.IdPessoa  AND BASE.IdTributo = AjudaCusto.IdTributo  AND BASE.Codigo =AjudaCusto.CodigoTributo  AND BASE.NomeTributo = AjudaCusto.Nometributo 

ORDER BY Pessoa.TipoPessoaFisica,
         Pessoa.CPFCNPJ;





		 SELECT SF.IdPessoa,
		 P2.NomeRazaoSocial,
			   MONTH(P.DataPagamento) AS Mes,
			  --case when @Exercicio >= @ConsideraEstorno then SUM(p.Valor - p.ValorEstornado) else SUM(p.Valor) end as Total
			  P.Valor,
			  P.ValorEstornado,
			  Total = SUM(P.Valor) OVER( PARTITION BY SF.IdPessoa)
		FROM Despesa.Pagamentos AS P
			JOIN Despesa.SaidasFinanceiras AS SF ON SF.IdSaidaFinanceira = P.IdSaidaFinanceira
			JOIN Despesa.Liquidacoes AS L ON L.IdLiquidacao = P.IdLiquidacao
			JOIN Despesa.Empenhos AS E ON E.IdEmpenho = L.IdEmpenho
			JOIN #PessoasDirf AS P2 ON P2.IdPessoa = SF.IdPessoa
			JOIN #PlanoContasExercicio AS PCE ON PCE.IdPlanoConta = SF.IdPlanoConta
		WHERE SF.IdPessoa IN 
		(
		'4E02A96E-6354-4D11-942C-2103011A5559',
		'9114FBAB-6362-4B21-9F5F-A7516D4CE040'
		)
		

			  AND YEAR(P.DataPagamento) = @Exercicio
			  AND MONTH(P.DataPagamento) BETWEEN @MesInicio AND @MesFim
			  AND P.Estorno = 0
			  AND (P2.Imune = 1)
		--GROUP BY SF.IdPessoa,
		--		p2.NomeRazaoSocial,
		--		 YEAR(P.DataPagamento),
		--		 MONTH(P.DataPagamento)
		 



		 SELECT SF.IdPessoa,
			   MONTH(P.DataPagamento) AS Mes,
			 --  case when @Exercicio >= @ConsideraEstorno then SUM(p.Valor - p.ValorEstornado) else SUM(p.Valor) end as Total
			  P.Valor,
			  P.ValorEstornado,
			  Total = SUM(P.Valor) OVER( PARTITION BY SF.IdPessoa)
		FROM Despesa.Pagamentos AS P
			JOIN Despesa.SaidasFinanceiras AS SF ON SF.IdSaidaFinanceira = P.IdSaidaFinanceira
			JOIN Despesa.Liquidacoes AS L ON L.IdLiquidacao = P.IdLiquidacao
			JOIN Despesa.Empenhos AS E ON E.IdEmpenho = L.IdEmpenho
			JOIN #PessoasDirf AS P2 ON P2.IdPessoa = SF.IdPessoa
			JOIN #PlanoContasExercicio AS PCE ON PCE.IdPlanoConta = SF.IdPlanoConta
		 WHERE SF.IdPessoa IN 
		(
		'4E02A96E-6354-4D11-942C-2103011A5559',
		'9114FBAB-6362-4B21-9F5F-A7516D4CE040'
		)
			  AND YEAR(P.DataPagamento) = @Exercicio
			  AND MONTH(P.DataPagamento) BETWEEN @MesInicio AND @MesFim
			  AND P.Estorno = 0
			  AND (P2.Isento = 1)
		--GROUP BY SF.IdPessoa,
		--		p2.NomeRazaoSocial,
		--		 YEAR(P.DataPagamento),
		--		 MONTH(P.DataPagamento)





		 /*				*/
	-- Imunes
	; WITH Imunes AS (

		SELECT SF.IdPessoa,
			   MONTH(P.DataPagamento) AS Mes,
			  case when @Exercicio >= @ConsideraEstorno then SUM(p.Valor - p.ValorEstornado) else SUM(p.Valor) end as Total
		FROM Despesa.Pagamentos AS P
			JOIN Despesa.SaidasFinanceiras AS SF ON SF.IdSaidaFinanceira = P.IdSaidaFinanceira
			JOIN Despesa.Liquidacoes AS L ON L.IdLiquidacao = P.IdLiquidacao
			JOIN Despesa.Empenhos AS E ON E.IdEmpenho = L.IdEmpenho
			JOIN #PessoasDirf AS P2 ON P2.IdPessoa = SF.IdPessoa
			JOIN #PlanoContasExercicio AS PCE ON PCE.IdPlanoConta = SF.IdPlanoConta
		WHERE SF.IdPessoa = ISNULL(@IdPessoa, SF.IdPessoa)
			  AND YEAR(P.DataPagamento) = @Exercicio
			  AND MONTH(P.DataPagamento) BETWEEN @MesInicio AND @MesFim
			  AND P.Estorno = 0
			  AND (P2.Imune = 1)
		GROUP BY SF.IdPessoa,
				p2.NomeRazaoSocial,
				 YEAR(P.DataPagamento),
				 MONTH(P.DataPagamento)
	)
	,ImuneResult AS (
	SELECT IdPessoa,
		   ISNULL([1], 0) AS PgJan,
		   ISNULL([2], 0) AS PgFev,
		   ISNULL([3], 0) AS PgMar,
		   ISNULL([4], 0) AS PgAbr,
		   ISNULL([5], 0) AS PgMai,
		   ISNULL([6], 0) AS PgJun,
		   ISNULL([7], 0) AS PgJul,
		   ISNULL([8], 0) AS PgAgo,
		   ISNULL([9], 0) AS PgSet,
		   ISNULL([10], 0) AS PgOut,
		   ISNULL([11], 0) AS PgNov,
		   ISNULL([12], 0) AS PgDez
	FROM Imunes I
		PIVOT
		(
			SUM(Total)
			FOR Mes IN ([1], [2], [3], [4], [5], [6], [7], [8], [9], [10], [11], [12])
		) AS pvt)

		INSERT INTO #DIRF
		(
		    IdPessoa,
		    CPFCNPJ,
		    NomeRazaoSocial,
		    TipoPessoaFisica,
			IdTributo,
			Codigo,
		    NomeTributo,
		    BaseCalc01,
		    BaseCalc02,
		    BaseCalc03,
		    BaseCalc04,
		    BaseCalc05,
		    BaseCalc06,
		    BaseCalc07,
		    BaseCalc08,
		    BaseCalc09,
		    BaseCalc10,
		    BaseCalc11,
		    BaseCalc12,

			AjudaCusto01,
			AjudaCusto02,
			AjudaCusto03,
			AjudaCusto04,
			AjudaCusto05,
			AjudaCusto06,
			AjudaCusto07,
			AjudaCusto08,
			AjudaCusto09,
			AjudaCusto10,
			AjudaCusto11,
			AjudaCusto12,
			Deducoes01,
			Deducoes02,
			Deducoes03,
			Deducoes04,
			Deducoes05,
			Deducoes06,
			Deducoes07,
			Deducoes08,
			Deducoes09,
			Deducoes10,
			Deducoes11,
			Deducoes12,
			Trib01 ,
			Trib02 ,
			Trib03 ,
			Trib04 ,
			Trib05 ,
			Trib06 ,
			Trib07 ,
			Trib08 ,
			Trib09 ,
			Trib10 ,
			Trib11 ,
			Trib12,
			Imune,
			Isento
		)

		SELECT P.IdPessoa,
			   P.CPFCNPJ,
			   P.NomeRazaoSocial,
			   P.TipoPessoaFisica,
			   IdTributo = @IdTributoImune,
			   Codigo = @CodigoImune,
			   NomeTributo = @NomeTributoImune  ,			   
			   I.PgJan,
			   I.PgFev,
			   I.PgMar,
			   I.PgAbr,
			   I.PgMai,
			   I.PgJun,
			   I.PgJul,
			   I.PgAgo,
			   I.PgSet,
			   I.PgOut,
			   I.PgNov,
			   I.PgDez,
			    AjudaCusto01 = 0,
				AjudaCusto02 = 0,
				AjudaCusto03 = 0,
				AjudaCusto04 = 0,
				AjudaCusto05 = 0,
				AjudaCusto06 = 0,
				AjudaCusto07 = 0,
				AjudaCusto08 = 0,
				AjudaCusto09 = 0,
				AjudaCusto10 = 0,
				AjudaCusto11 = 0,
				AjudaCusto12 = 0,
				Deducoes01 = 0,
				Deducoes02 = 0,
				Deducoes03 = 0,
				Deducoes04 = 0,
				Deducoes05 = 0,
				Deducoes06 = 0,
				Deducoes07 = 0,
				Deducoes08 = 0,
				Deducoes09 = 0,
				Deducoes10 = 0,
				Deducoes11 = 0,
				Deducoes12 = 0,
				Trib01 = 0,
				Trib02 = 0,
				Trib03 = 0,
				Trib04 = 0,
				Trib05 = 0,
				Trib06 = 0,
				Trib07 = 0,
				Trib08 = 0,
				Trib09 = 0,
				Trib10 = 0,
				Trib11 = 0,
				Trib12 = 0,
				Imune = p.Imune,
				Isento = p.Isento
		FROM ImuneResult I
			JOIN #PessoasDirf  AS P
				ON P.IdPessoa = I.IdPessoa;


	-- Isentos
	; WITH Isentos AS (

		SELECT SF.IdPessoa,
			   MONTH(P.DataPagamento) AS Mes,
			   case when @Exercicio >= @ConsideraEstorno then SUM(p.Valor - p.ValorEstornado) else SUM(p.Valor) end as Total
		FROM Despesa.Pagamentos AS P
			JOIN Despesa.SaidasFinanceiras AS SF ON SF.IdSaidaFinanceira = P.IdSaidaFinanceira
			JOIN Despesa.Liquidacoes AS L ON L.IdLiquidacao = P.IdLiquidacao
			JOIN Despesa.Empenhos AS E ON E.IdEmpenho = L.IdEmpenho
			JOIN #PessoasDirf AS P2 ON P2.IdPessoa = SF.IdPessoa
			JOIN #PlanoContasExercicio AS PCE ON PCE.IdPlanoConta = SF.IdPlanoConta
		WHERE SF.IdPessoa = ISNULL(@IdPessoa, SF.IdPessoa)
			  AND YEAR(P.DataPagamento) = @Exercicio
			  AND MONTH(P.DataPagamento) BETWEEN @MesInicio AND @MesFim
			  AND P.Estorno = 0
			  AND (P2.Isento = 1)
		GROUP BY SF.IdPessoa,
				p2.NomeRazaoSocial,
				 YEAR(P.DataPagamento),
				 MONTH(P.DataPagamento)
	)
	,IsentosResult AS (
	SELECT IdPessoa,
		   ISNULL([1], 0) AS PgJan,
		   ISNULL([2], 0) AS PgFev,
		   ISNULL([3], 0) AS PgMar,
		   ISNULL([4], 0) AS PgAbr,
		   ISNULL([5], 0) AS PgMai,
		   ISNULL([6], 0) AS PgJun,
		   ISNULL([7], 0) AS PgJul,
		   ISNULL([8], 0) AS PgAgo,
		   ISNULL([9], 0) AS PgSet,
		   ISNULL([10], 0) AS PgOut,
		   ISNULL([11], 0) AS PgNov,
		   ISNULL([12], 0) AS PgDez
	FROM Isentos I
		PIVOT
		(
			SUM(Total)
			FOR Mes IN ([1], [2], [3], [4], [5], [6], [7], [8], [9], [10], [11], [12])
		) AS pvt)

		INSERT INTO #DIRF
		(
		    IdPessoa,
		    CPFCNPJ,
		    NomeRazaoSocial,
		    TipoPessoaFisica,
			IdTributo,
			Codigo,
		    NomeTributo,
		    BaseCalc01,
		    BaseCalc02,
		    BaseCalc03,
		    BaseCalc04,
		    BaseCalc05,
		    BaseCalc06,
		    BaseCalc07,
		    BaseCalc08,
		    BaseCalc09,
		    BaseCalc10,
		    BaseCalc11,
		    BaseCalc12,

			AjudaCusto01,
			AjudaCusto02,
			AjudaCusto03,
			AjudaCusto04,
			AjudaCusto05,
			AjudaCusto06,
			AjudaCusto07,
			AjudaCusto08,
			AjudaCusto09,
			AjudaCusto10,
			AjudaCusto11,
			AjudaCusto12,
			Deducoes01,
			Deducoes02,
			Deducoes03,
			Deducoes04,
			Deducoes05,
			Deducoes06,
			Deducoes07,
			Deducoes08,
			Deducoes09,
			Deducoes10,
			Deducoes11,
			Deducoes12,
			Trib01 ,
			Trib02 ,
			Trib03 ,
			Trib04 ,
			Trib05 ,
			Trib06 ,
			Trib07 ,
			Trib08 ,
			Trib09 ,
			Trib10 ,
			Trib11 ,
			Trib12,
			Imune,
			Isento
		)

		/*  
		VPEIM – Valores pagos às entidades imunes ou isentas
			-> RIMUM – Rendimentos Imunes
			-> RISEN – Rendimentos Isentos
		*/
		
		SELECT P.IdPessoa,
			   P.CPFCNPJ,
			   P.NomeRazaoSocial,
			   P.TipoPessoaFisica,
			   IdTributo = @IdtributoIsento,
			   Codigo = @CodigoIsento,
			   NomeTributo = @TributoIsento  ,			   
			   I.PgJan,
			   I.PgFev,
			   I.PgMar,
			   I.PgAbr,
			   I.PgMai,
			   I.PgJun,
			   I.PgJul,
			   I.PgAgo,
			   I.PgSet,
			   I.PgOut,
			   I.PgNov,
			   I.PgDez,
			   AjudaCusto01 = 0,
				AjudaCusto02 = 0,
				AjudaCusto03 = 0,
				AjudaCusto04 = 0,
				AjudaCusto05 = 0,
				AjudaCusto06 = 0,
				AjudaCusto07 = 0,
				AjudaCusto08 = 0,
				AjudaCusto09 = 0,
				AjudaCusto10 = 0,
				AjudaCusto11 = 0,
				AjudaCusto12 = 0,
				Deducoes01 = 0,
				Deducoes02 = 0,
				Deducoes03 = 0,
				Deducoes04 = 0,
				Deducoes05 = 0,
				Deducoes06 = 0,
				Deducoes07 = 0,
				Deducoes08 = 0,
				Deducoes09 = 0,
				Deducoes10 = 0,
				Deducoes11 = 0,
				Deducoes12 = 0,
				Trib01 = 0,
				Trib02 = 0,
				Trib03 = 0,
				Trib04 = 0,
				Trib05 = 0,
				Trib06 = 0,
				Trib07 = 0,
				Trib08 = 0,
				Trib09 = 0,
				Trib10 = 0,
				Trib11 = 0,
				Trib12 = 0,
				Imune = p.Imune,
				Isento = p.Isento
		FROM IsentosResult I
			JOIN #PessoasDirf AS P
				ON P.IdPessoa = I.IdPessoa;
		 


SELECT *
FROM #Dirf AS D
--WHERE d.IdPessoa ='61DA5AF0-F54C-4263-8C30-73573BC9CBFC'
ORDER BY  D.CPFCNPJ ,
           D.Codigo;


