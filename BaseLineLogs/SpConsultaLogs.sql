/* ==================================================================
--Data: 17/01/2019 
--Autor :Wesley Neves
Acao permitidas
Added
Deleted
Modified
 
-- ==================================================================
*/

DECLARE @IdpessoaParam UNIQUEIDENTIFIER = '2E8F39FE-7CA3-42CF-BC81-0012E3767FA7';
DECLARE @IdEntidadeParam UNIQUEIDENTIFIER = 'B7AFBE97-F944-448A-B094-019FF8156C37';
DECLARE @CodSistemaParam TINYINT = 1; --Siscont
DECLARE @IdLogParam INT = 1000;
DECLARE @EntidadeParam VARCHAR(128) = 'Cadastro.Pessoas';
DECLARE @DataInicioParam DATETIME = DATEFROMPARTS(2019, 1, 1);
DECLARE @DataTerminoParam DATETIME = DATEFROMPARTS(2019, 03, 08);
DECLARE @FiltroTamanho INT = 1000;
DECLARE @Campo VARCHAR(128) = 'NomeRazaoSocial';
DECLARE @Conteudo VARCHAR(128) = 'Amanda';

SET @DataInicioParam = CAST(@DataInicioParam AS DATE);
SET @DataTerminoParam = CAST(@DataTerminoParam AS DATE);

DECLARE @AcaoParam CHAR(1) = 'I';

IF(@DataInicioParam IS NULL OR @DataInicioParam IS NULL)
    BEGIN
        THROW 50000, 'O parametro @DataInicioParam e @DataInicioParam é obrigatório', 0;
    END;

IF(OBJECT_ID('TEMPDB..#Retorno') IS NOT NULL)
    DROP TABLE #Retorno;

CREATE TABLE #Retorno
(
    [CodSistema] UNIQUEIDENTIFIER,
    [Nome]       VARCHAR(100),
    [IdLog]      INT             PRIMARY KEY,
    [IdEntidade] UNIQUEIDENTIFIER,
    [IdPessoa]   UNIQUEIDENTIFIER,
    [Acao]       CHAR(1),
    [Entidade]   VARCHAR(128),
    [Data]       DATETIME2(2),
    [Pessoa]     VARCHAR(250),
    [IPAdress]   VARCHAR(30),
    [Conteudo]   VARCHAR(MAX)
);

DECLARE @Tsql VARCHAR(1000) = '';

SET @Tsql = ' INSERT INTO #Retorno 
    SELECT 
	SEL.Codsistema,
	SEL.Nome,
	LJ.IdLog,
    LJ.IdEntidade,
	LJ.IdPessoa,
	LJ.Acao,
    LJ.Entidade,
    LJ.Data,
	ISNULL(P.NomeRazaoSocial,NULL) as Pessoa,
    LJ.IPAdress,
    LJ.Conteudo FROM Log.LogsJSON AS LJ
    JOIN Sistema.SistemasEspelhamentos AS SEL ON LJ.CodSistema = SEL.IdSistema
    LEFT JOIN Cadastro.Pessoas AS P ON LJ.IdPessoa = P.IdPessoa';

IF(@EntidadeParam IS NOT NULL AND @Campo IS NOT NULL)
    BEGIN
        SET @Tsql += CONCAT(' CROSS APPLY OPENJSON(LJ.Conteudo) AS JS', '');
    END;

DECLARE @HasFilter BIT = IIF(
                             @AcaoParam IS NOT NULL
                             OR @IdpessoaParam IS NOT NULL
                             OR @CodSistemaParam IS NOT NULL
                             OR @EntidadeParam IS NOT NULL
                             OR @IdLogParam IS NOT NULL
                             OR @DataInicioParam IS NOT NULL
                             OR @DataTerminoParam IS NOT NULL,
                             1,
                             0);

IF(@HasFilter = 1)
    BEGIN
        SET @Tsql += CONCAT(' WHERE 1=1 AND ', '(');
    END;

IF(@DataInicioParam IS NOT NULL AND @DataTerminoParam IS NOT NULL)
    BEGIN
        SET @Tsql += CONCAT(' ( LJ.Data >= ', CHAR(39), DATEFROMPARTS(YEAR(@DataInicioParam), MONTH(@DataInicioParam), DAY(@DataInicioParam)), CHAR(39));
        SET @Tsql += CONCAT('AND  LJ.Data <=', CHAR(39), DATEFROMPARTS(YEAR(@DataTerminoParam), MONTH(@DataTerminoParam), DAY(@DataTerminoParam)), CHAR(39), ')');
    END;

IF(@AcaoParam IS NOT NULL)
    BEGIN
        SET @Tsql += CONCAT('AND (   LJ.Acao =', CHAR(39), @AcaoParam, CHAR(39), ')');
    END;

IF(@IdpessoaParam IS NOT NULL)
    BEGIN
        SET @Tsql += CONCAT('AND ( LJ.IdPessoa =', CHAR(39), @IdpessoaParam, CHAR(39), ')');
    END;

IF(@CodSistemaParam IS NOT NULL)
    BEGIN
        SET @Tsql += CONCAT('AND ( LJ.CodSistema =', @CodSistemaParam, ')');
    END;

IF(@EntidadeParam IS NOT NULL AND LEN(@EntidadeParam) > 0)
    BEGIN
        SET @Tsql += CONCAT('AND ( LJ.Entidade =', CHAR(39), @EntidadeParam, CHAR(39), ')');
    END;

IF(@IdLogParam IS NOT NULL)
    BEGIN
        SET @Tsql += CONCAT('AND ( LJ.IdLog =', CHAR(39), @IdLogParam, CHAR(39), ')');
    END;

IF(@IdEntidadeParam IS NOT NULL)
    BEGIN
        SET @Tsql += CONCAT('AND ( LJ.IdEntidade =', CHAR(39), @IdEntidadeParam, CHAR(39), ')');
    END;

IF(@EntidadeParam IS NOT NULL AND @Campo IS NOT NULL)
    BEGIN
        SET @Tsql += CONCAT(' AND (JS.[Key] =', CHAR(39), @Campo, CHAR(39), ')');

        IF(@Conteudo IS NOT NULL)
            BEGIN
                SET @Tsql += CONCAT(' AND (JS.[Value] LIKE CONCAT(', CHAR(39), '%', @Conteudo, '%', CHAR(39), ',', CHAR(39), CHAR(39), '))');
            END;
    END;

IF(@HasFilter = 1)
    BEGIN
        SET @Tsql += ')';
    END;

SET @Tsql += CONCAT(' ORDER BY LJ.Acao ,LJ.Entidade ', '');

IF(@FiltroTamanho IS NOT NULL)
    BEGIN
        SET @Tsql += CONCAT(' OFFSET 0 ROW FETCH NEXT ', @FiltroTamanho, ' ROW ONLY', '');
    END;

DECLARE @HasError INT = 0;

PRINT @Tsql;

EXEC(@Tsql);

SELECT * FROM #Retorno AS R;
