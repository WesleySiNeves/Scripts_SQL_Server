--SELECT  AI.IdArquivoIntegracao ,
--		ExisteBlocoP = AI.Conteudo.exist('/Implanta/BlocoP'),
--        [AI].[Conteudo].value('(/Implanta/BlocoQ/RecebimentoExcedente//Valor/node())[1]',
--                              'nvarchar(max)') AS Valor ,
--        [AI].[Conteudo].value('(Implanta/BlocoQ//RecebimentoExcedente//CodigoConta/node())[1]',
--                              'nvarchar(max)') AS CodigoConta ,
--        AI.Conteudo
--FROM    Contabilidade.ArquivosIntegracao AS AI
--WHERE   YEAR(AI.DataCreditoContabil) = 2017;

--https://sqlfromhell.wordpress.com/2011/08/02/lendo-xml-no-sql-server-iniciando-com-xquery/
SELECT  AI.Nome ,
        AI.DataCreditoContabil ,
        AI.Conteudo ,
        AI.Conteudo.exist('/Implanta/BlocoE'),
		AI.Conteudo.query('/Implanta/BlocoE') --Aqui so recupera o bloco P
FROM    Contabilidade.ArquivosIntegracao AS AI
WHERE   YEAR(AI.DataCreditoContabil) = 2017
        AND MONTH(AI.DataCreditoContabil) =8
		ORDER BY AI.DataCreditoContabil
		--SELECT @XML.query('note/to')


		WITH Dados AS (

SELECT  AI.*,
        ExisteBlocoE = AI.Conteudo.exist('/Implanta/BlocoE'),
		BlocoE=  AI.Conteudo.query('/Implanta/BlocoE') --Aqui so recupera o bloco P
FROM     Despesa.ArquivosFolhaPagamento AS AI
)
SELECT	* FROM Dados R
        WHERE R.ExisteBlocoE =1