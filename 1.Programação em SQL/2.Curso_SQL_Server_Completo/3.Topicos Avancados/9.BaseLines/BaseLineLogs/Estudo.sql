/* ==================================================================
--Data: 13/11/2019 
--Autor :Wesley Neves
--Observação:  Exemplo de utilização Json 

qualquer duvida acesse :https://docs.microsoft.com/pt-br/sql/relational-databases/json/json-data-sql-server?view=sql-server-ver15 
-- ==================================================================
*/



DECLARE @Exemplo1 VARCHAR(1000) = '{"Credito":"False","Historico":"RENTABILIDADE - MÊS JUNHO\/2018","IdLancamento":"3984d035-318c-426b-a2ec-07618c5efb5d","IdMovimento":"cd4ebf43-85e6-48ae-8c8d-61510c6f2dba","IdPlanoConta":"befe73df-95f9-4612-b76c-9e5af0ccfb2c","Valor":"91099,73"}';


SELECT *
FROM OPENJSON(@Exemplo1) AS OJ;


DECLARE @Exemplo2 VARCHAR(1000)
    = '{"DataModificacao":"25\/07\/2018 11:31:33","DataRecebimento":"25\/07\/2018 11:31:12","Deducao":"False","Devolucao":"False","DireitoContratual":"False","Historico":"Histórico padrão dos lançamentos de recebimentos relativos a cartões de crédito e débito","IdPlanoConta":"36ae3c5d-865e-4200-b470-41395d5c0c33","IdPlanoContaBanco":"7f23b79f-7a48-41d7-bc0b-f496994e46d7","IdPlanoContaContrapartidaPatrimonio":"d7809ca3-bccb-476d-af9e-ba44d6ee96d6","IdRecebimento":"2e52b971-08dc-4a7e-8739-e57d1888cca9","IdRegiao":"6bb72d6e-ddfe-4c9f-95f9-9cee3c6c3976","Numero":"24974","Quantidade":"1","RepasseAutomatico":"False","Valor":"2,55"}';

SELECT *
FROM OPENJSON(@Exemplo2) AS OJ;


SELECT ISJSON(@Exemplo1)
SELECT ISJSON(@Exemplo2)


/*Valores Nulos e vazios não são categorizados como Json*/
SELECT ISJSON('') AS ValorPodeSerConvertidoEmJSON

SELECT ISJSON(NULL) AS ValorPodeSerConvertidoEmJSON

/* ==================================================================
--Data: 30/08/2019 
--Autor :Wesley Neves
--Observação:  Querys na tabela de Logs
 
-- ==================================================================
*/






SELECT TOP 10
    LJ.IdLog,
    LJ.IdPessoa,
    LJ.IdEntidade,
    LJ.Entidade,
    LJ.IdLogAntigo,
    LJ.Acao,
    LJ.Data,
    LJ.IdSistemaEspelhamento,
    LJ.IPAdress,
    LJ.Conteudo,
    JS.[Key],
    JS.Value,
    JS.Type
FROM Log.LogsJson AS LJ
     CROSS APPLY (
                 SELECT *
                 FROM OPENJSON(LJ.Conteudo) AS JS
                 ) JS
WHERE LEN(LJ.Conteudo) > 0;



DECLARE @IdEntidade UNIQUEIDENTIFIER = (
                                       SELECT TOP 1
                                           L.IdEntidade
                                       FROM Log.LogsJson AS L
                                       WHERE L.Entidade = 'Despesa.Pagamentos'
                                       );



/*
exemplo para recuperar apenas alguns campos da coluna conteudo
*/
SELECT P.NomeRazaoSocial AS Pessoa,
       LJ.IdLog,
       LJ.IdEntidade,
       SE.Nome AS Sistema,
       LJ.Entidade,
       Acao = CASE LJ.Acao
                  WHEN 'I' THEN
                      'Inserção'
				   WHEN 'D' THEN 'Deleção'
                  ELSE 'Alteração'
              END,
       LJ.Data,
       LJ.Conteudo,
       JS.*
FROM Log.LogsJson AS LJ
     JOIN Cadastro.Pessoas AS P ON P.IdPessoa = LJ.IdPessoa
     JOIN Sistema.SistemasEspelhamentos AS SE ON SE.IdSistemaEspelhamento = LJ.IdSistemaEspelhamento
     CROSS APPLY (
					SELECT *	
					FROM OPENJSON(LJ.Conteudo)
                         WITH (
								Numero INT,
								DataCadastro VARCHAR(20),
								Valor VARCHAR(20)
                              ) AS JS
                 ) JS
WHERE LJ.IdEntidade = @IdEntidade;



/*Usando JSON_VALUE */

SELECT TOP 100 LJ.IdLog,
       LJ.IdEntidade,
	   LJ.Conteudo,
       JSON_VALUE(LJ.Conteudo, '$.ConsiderarDirf') AS ConsiderarDirf,
       JSON_VALUE(LJ.Conteudo, '$.DataCadastro') AS DataCadastro,
	   JSON_VALUE(LJ.Conteudo, '$.IdTipoDocumento') AS IdTipoDocumento,
	   JSON_VALUE(LJ.Conteudo, '$.IdLiquidacao') AS IdLiquidacao,
	   JSON_VALUE(LJ.Conteudo, '$.IdEmpenho') AS IdEmpenho
FROM Log.LogsJson AS LJ
WHERE ISJSON(LJ.Conteudo) > 0
AND LJ.Entidade ='Despesa.Liquidacoes'
