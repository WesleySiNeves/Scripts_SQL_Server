



/* ==================================================================
--Data: 24/07/2018 
--Autor :Wesley Neves
--Observação: Cria a tabela em novo formato  NVARCHAR(4000) e usado afim de abter performace
 
-- ==================================================================
*/

IF (NOT EXISTS
(
    SELECT 1
    FROM sys.tables AS T
    WHERE T.name = 'LogsDetalhesJSON'
)
   )
BEGIN


    CREATE TABLE Log.LogsDetalhesJSON
    (
        IdLog UNIQUEIDENTIFIER NOT NULL ROWGUIDCOL PRIMARY KEY
            DEFAULT (NEWSEQUENTIALID()),
        Conteudo VARCHAR(4000),
    );


    /* ==================================================================
--Data: 24/07/2018 
--Autor :Wesley Neves
--Observação: 
Sempre que alguém insere ou atualiza um documento na tabela, essa restrição verifica se o documento JSON está formatado corretamente.
 Sem a restrição, a tabela é otimizada para inserções, 
porque qualquer documento JSON é adicionado diretamente à coluna sem nenhum processamento.
 
-- ==================================================================
*/

    ALTER TABLE Log.LogsDetalhesJSON
    ADD CONSTRAINT CheckLogsDetalhesJSON CHECK (ISJSON(LogsDetalhesJSON.Conteudo) = 1);

END;


TRUNCATE TABLE Log.LogsDetalhesJSON;



DECLARE @Inicio INT = 1;

DECLARE @termino INT = 100;


WHILE (@Inicio <= @termino)
BEGIN

    DECLARE @entidade1 VARCHAR(4000) = (
                                           SELECT TOP 1 * FROM Despesa.Empenhos AS E ORDER BY NEWID() FOR JSON PATH, ROOT('Entidade')
                                       );

    DECLARE @entidade2 VARCHAR(4000) = (
                                           SELECT TOP 1
                                               *
                                           FROM Despesa.MovimentosFinanceiros AS MF
                                           ORDER BY NEWID()
                                           FOR JSON PATH, ROOT('Entidade')
                                       );


    DECLARE @entidade3 VARCHAR(4000) = (
                                           SELECT TOP 1
                                               *
                                           FROM Despesa.Pagamentos AS P
                                           ORDER BY NEWID()
                                           FOR JSON PATH, ROOT('Entidade')
                                       );




    INSERT INTO Log.LogsDetalhesJSON
    (
        Conteudo
    )
    VALUES (@entidade1),
    (@entidade2),
    (@entidade3);



    SET @Inicio += 1;
END;



SELECT LDJ.IdLog,
       LDJ.Conteudo,
	   JSON_VALUE(LDJ.Conteudo,'$.Entidade[0].IdPagamento') AS ID
       	FROM Log.LogsDetalhesJSON AS LDJ


{"Entidade":[{"IdEmpenho":"1439C87A-EA80-4927-BB0E-342D0EE910AD","IdPessoa":"B715CC8C-9699-485C-A00D-EF490C869CD4","IdPlanoConta":"96B602AC-2998-44BC-B098-C460606B0970","Exercicio":2015,"Numero":1686,"Processo":"PEF 006\/2015","Tipo":1,"Data":"2015-07-29T00:00:00","Modificacao":"2015-07-29T08:12:40.497","Historico":"Valor empenhado a SILVIA MARIA NERI PIEDADE, despesa com pagamento de 3,5 diárias para viagem a Brasília\/DF no periodo de 27\/07 a 30\/07\/2015 conforme Portaria nº 522\/2015 e Convocatória. (3,5 x 550,00)","SaldoConta":2533394.43,"RestoAPagar":false,"ValorOriginalEmpenho":1925.00,"ValorInscritoRestoAPagar":0.00,"InscricaoRestoAPagarManual":true,"DataCadastro":"2015-07-29T08:12:20.417","ValorAnulado":0.00,"ValorPago":1925.00,"ValorLiquidado":1925.00,"Valor":1925.00,"SaldoALiquidar":0.00,"ProrrogacaoRestoAPagar":false,"ObrigacaoContratual":false}]}