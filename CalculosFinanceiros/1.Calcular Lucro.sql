/* ==================================================================
--Data: 21/10/2019 
--Autor :Wesley Neves
--Observa��o: 

A miss�o � relativamente simples. Calcular o lucro, a margem de lucro e a rentabilidade de cada m�s (nesse caso em rela��o ao m�s anterior).
 Antes de iniciar o c�lculo, precisamos de uma valor inicial de avalia��o da empresa.
  Digamos que em 01/10/2008 (quando a empresa iniciou suas atividades)
  ela estava avaliada em R$ 15 mil.
 Quem desejar tentar por conta pr�pria � um �timo exerc�cio. Adianto as respostas na tabela abaixo:
 
-- ==================================================================
*/

--� Cria uma tabela de lan�amentos cont�beis


DROP TABLE IF EXISTS #Lancamentos


CREATE TABLE #Lancamentos
(
    IDLanc INT IDENTITY(1, 1) NOT NULL,
    Data   SMALLDATETIME,
    Valor  SMALLMONEY,
    Tipo   CHAR(1),
    CONSTRAINT PK_Lancamento PRIMARY KEY(IDLanc),
    CONSTRAINT CK_Tipo CHECK(Tipo IN ('C', 'D'))
);

--� Insere alguns lan�amentos cont�beis
INSERT INTO #Lancamentos(
                                         Data,
                                         Valor,
                                         Tipo
                                     )
VALUES('20081005', 190, 'D');

INSERT INTO #Lancamentos(
                                         Data,
                                         Valor,
                                         Tipo
                                     )
VALUES('20081009', 290, 'C');

INSERT INTO #Lancamentos(
                                         Data,
                                         Valor,
                                         Tipo
                                     )
VALUES('20081011', 410, 'D');

INSERT INTO #Lancamentos(
                                         Data,
                                         Valor,
                                         Tipo
                                     )
VALUES('20081014', 780, 'C');

INSERT INTO #Lancamentos(
                                         Data,
                                         Valor,
                                         Tipo
                                     )
VALUES('20081103', 560, 'C');

INSERT INTO #Lancamentos(
                                         Data,
                                         Valor,
                                         Tipo
                                     )
VALUES('20081110', 320, 'D');

INSERT INTO #Lancamentos(
                                         Data,
                                         Valor,
                                         Tipo
                                     )
VALUES('20081113', 700, 'D');

INSERT INTO #Lancamentos(
                                         Data,
                                         Valor,
                                         Tipo
                                     )
VALUES('20081114', 970, 'C');

INSERT INTO #Lancamentos(
                                         Data,
                                         Valor,
                                         Tipo
                                     )
VALUES('20081129', 100, 'C');

INSERT INTO #Lancamentos(
                                         Data,
                                         Valor,
                                         Tipo
                                     )
VALUES('20081215', 490, 'C');

INSERT INTO #Lancamentos(
                                         Data,
                                         Valor,
                                         Tipo
                                     )
VALUES('20081217', 930, 'C');

INSERT INTO #Lancamentos(
                                         Data,
                                         Valor,
                                         Tipo
                                     )
VALUES('20081218', 280, 'D');

INSERT INTO #Lancamentos(
                                         Data,
                                         Valor,
                                         Tipo
                                     )
VALUES('20081219', 110, 'D');

INSERT INTO #Lancamentos(
                                         Data,
                                         Valor,
                                         Tipo
                                     )
VALUES('20081223', 320, 'D');

INSERT INTO #Lancamentos(
                                         Data,
                                         Valor,
                                         Tipo
                                     )
VALUES('20081226', 470, 'D');

INSERT INTO #Lancamentos(
                                         Data,
                                         Valor,
                                         Tipo
                                     )
VALUES('20081230', 780, 'C');

INSERT INTO #Lancamentos(
                                         Data,
                                         Valor,
                                         Tipo
                                     )
VALUES('20090108', 230, 'D');

INSERT INTO #Lancamentos(
                                         Data,
                                         Valor,
                                         Tipo
                                     )
VALUES('20090116', 570, 'D');

INSERT INTO #Lancamentos(
                                         Data,
                                         Valor,
                                         Tipo
                                     )
VALUES('20090119', 990, 'C');

INSERT INTO #Lancamentos(
                                         Data,
                                         Valor,
                                         Tipo
                                     )
VALUES('20090121', 840, 'C');

INSERT INTO #Lancamentos(
                                         Data,
                                         Valor,
                                         Tipo
                                     )
VALUES('20090125', 160, 'D');

INSERT INTO #Lancamentos(
                                         Data,
                                         Valor,
                                         Tipo
                                     )
VALUES('20090131', 330, 'D');



/* ==================================================================
--Data: 21/10/2019 
--Autor :Wesley Neves
--Observa��o: A miss�o � relativamente simples. Calcular o lucro, a margem de lucro e a rentabilidade de cada m�s 
(nesse caso em rela��o ao m�s anterior). Antes de iniciar o c�lculo, precisamos de uma valor inicial de avalia��o da empresa.
 Digamos que em 01/10/2008 (quando a empresa iniciou suas atividades) ela estava avaliada em R$ 15 mil.
 Quem desejar tentar por conta pr�pria � um �timo exerc�cio. Adianto as respostas na tabela abaixo:
 
-- ==================================================================
*/

SELECT * FROM #Lancamentos AS L
ORDER BY L.Data