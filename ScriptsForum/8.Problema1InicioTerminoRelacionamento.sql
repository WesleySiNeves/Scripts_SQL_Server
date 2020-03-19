/*Pergunta https://social.technet.microsoft.com/Forums/sqlserver/pt-BR/b6b14eb3-75ff-4ac7-838f-eeeef70bd67e/lgica-dentro-de-um-select?forum=520 */
/*
Preciso fazer um select numa tabela que tem 3 colunas, data,  tipo e valor. Eu preciso trazer nesse select a data início de relacionamento. Ex:

01/02/10 - Comprou  100 ->>> Iniciou o relacionamento
02/02/10 - Comprou  50
03/02/10 - vendeu  150 ->>> Encerrou o relacionamento pq zerou a conta com essa venda
04/02/10 - Comprou  100 -->> Novo incio de relacionamento
05/02/10 - Comprou  100
Nesse caso a data de inicio de relacionamento seria 04/02/2010
Alguem pode me ajudar com uma lógica pra trazer essa data de inicio num select?
Obrigado


Os registros do tipo "comprou" somam seu valor ao total parcial e os registros do tipo "vendeu" subtraem seu valor do total parcial.
 Quando há um primeiro registro do tipo "comprou", um agrupamento novo é criado.
 Quando há um último registro do tipo "vendeu" que faça o total parcial ser 0 (zero), o agrupamento é encerrado neste item.
*/

DECLARE @tableDemostracao TABLE
    (
      IdCliente INT NOT NULL ,-- Chave para determinar de qual relacionamento e feito
      Data DATE NOT NULL ,
      Tipo BIT NOT NULL ,-- (0) para comprou, (1) para vendeu
      Quantidade INT NOT NULL
    );

INSERT  INTO @tableDemostracao
        ( IdCliente, Data, Tipo, Quantidade )
VALUES  ( 1, '2010-02-01', 0, 100 ),
        ( 1, '2010-02-02', 0, 50 ),
        ( 1, '2010-02-03', 1, 150 ),
        ( 1, '2010-02-04', 0, 100 ),
        ( 1, '2010-02-05', 1, 100 );

INSERT  INTO @tableDemostracao
        ( IdCliente, Data, Tipo, Quantidade )
VALUES  ( 2, '2010-02-01', 0, 30 ),
        ( 2, '2010-02-02', 0, 10 ),
        ( 2, '2010-02-03', 1, 40 ),
        ( 2, '2010-02-04', 0, 20 ),
        ( 2, '2010-02-05', 1, 20 );


DECLARE @InicioRelacionamento VARCHAR(MAX) ='Iniciou o relacionamento';


DECLARE @Resultado TABLE
    (
	  Ordem INT,
      IdCliente INT NOT NULL ,-- Chave para determinar de qual relacionamento e feito
      Data DATE NOT NULL ,
      Tipo BIT NOT NULL ,-- (0) para comprou, (1) para vendeu
      TipoOperacao VARCHAR(MAX),
	  TotalComprado INT,
	  TotalVendido INT,
	  QuantidadeDisponivel INT,
	  InicioTermino VARCHAR(MAX)
    );

WITH    DadosRelacionamento
          AS ( SELECT   TD.IdCliente ,
                        TD.Data ,
                        TD.Tipo ,
                        TipoOperacao = CASE TD.Tipo
                                         WHEN 0 THEN 'Comprou'
                                         ELSE 'Vendeu'
                                       END ,
                        TotalComprado = SUM(CASE TD.Tipo
                                              WHEN 0 THEN TD.Quantidade
                                              ELSE 0
                                            END) OVER ( PARTITION BY TD.IdCliente ORDER BY TD.Data ) ,
                        TotalVendido = SUM(CASE TD.Tipo
                                             WHEN 0 THEN 0
                                             ELSE TD.Quantidade
                                           END) OVER ( PARTITION BY TD.IdCliente ORDER BY TD.Data ) ,
                        TD.Quantidade
               FROM     @tableDemostracao AS TD
             )

INSERT INTO @Resultado
    SELECT   
	        Orden = ROW_NUMBER() OVER(PARTITION BY X.IdCliente ORDER BY X.IdCliente),
	        X.IdCliente ,
            X.Data ,
            X.Tipo ,
            X.TipoOperacao ,
            X.TotalComprado ,
            X.TotalVendido ,
            [Quantidade Titulo Disponivel] = X.AindaTemDisponivel ,
			Relacionamento = IIF(X.AindaTemDisponivel > 0,'Tem Relaciomamento','Finalizou Relacionamento')
    FROM    ( SELECT    R.IdCliente ,
                        R.Data ,
                        R.Tipo ,
                        R.TipoOperacao ,
                        R.TotalComprado ,
                        R.TotalVendido ,
                        AindaTemDisponivel = R.TotalComprado - R.TotalVendido ,
                        R.Quantidade
              FROM      DadosRelacionamento R
            ) AS X;

UPDATE @Resultado SET InicioTermino =@InicioRelacionamento WHERE Ordem =1

SELECT * FROM @Resultado AS R