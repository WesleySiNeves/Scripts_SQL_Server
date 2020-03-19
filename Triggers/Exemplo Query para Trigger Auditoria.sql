
SELECT SYSDATETIME()

DECLARE @Logs  TABLE
(
 IdLog  UNIQUEIDENTIFIER NOT NULL PRIMARY KEY ,
 DataGetDate DATETIME NOT NULL DEFAULT(GETDATE()),
 DataSisDate DATETIME2 NOT NULL DEFAULT(SYSDATETIME()),
 ConteudoDeletado XML NOT NULL
)


DECLARE @Conteudo XML 


SET @Conteudo = ( SELECT    P.IdPagamento ,
                            P.IdLiquidacao ,
                            P.IdSaidaFinanceira ,
                            P.Numero ,
                            P.DataPagamento ,
                            P.NumeroProcesso ,
                            P.RestoAPagar ,
                            P.Estorno ,
                            P.CalculoTributo ,
                            P.DataNotaFiscal ,
                            P.SaldoEmpenho ,
                            P.SaldoLiquidacao ,
                            P.DataCadastro ,
                            P.Valor ,
                            P.ValorLiquido ,
                            P.ValorEstornado ,
                            P.ProrrogacaoRestoAPagar ,
                            P.Tipo
                  FROM      Despesa.Pagamentos AS P
                  WHERE     YEAR(P.DataPagamento) = 2016
                            AND P.Numero = '47041'
                FOR
                  XML RAW
                );

INSERT INTO @Logs
        ( IdLog ,
          DataGetDate ,
          DataSisDate ,
          ConteudoDeletado
        )
VALUES  ( NEWID() , -- IdLog - uniqueidentifier
          GETDATE() , -- DataGetDate - datetime
          SYSDATETIME() , -- DataSisDate - datetime2
          @Conteudo  -- ConteudoDeletado - xml
        )


SELECT * FROM @Logs AS L