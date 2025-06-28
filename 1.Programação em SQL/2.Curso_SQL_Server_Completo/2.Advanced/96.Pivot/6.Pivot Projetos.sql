DECLARE @tableProjetos TABLE
        (
          IdProjeto INT IDENTITY(1, 1) ,
          Nome VARCHAR(MAX)
        );


DECLARE @tableAtividades TABLE
        (
          IdAtividade INT PRIMARY KEY
                          IDENTITY(1, 1) ,
          IdProjeto INT ,
          Data DATE ,
          Quantidade INT
        );

INSERT  INTO @tableProjetos
        ( Nome )
VALUES  ( 'PROJETO1' ),
        ( 'PROJETO2' );

INSERT  INTO @tableAtividades
        ( IdProjeto, Data, Quantidade )
VALUES  ( 1, DATEFROMPARTS(2016, 1, 1), 5 ),
        ( 1, DATEFROMPARTS(2016, 1, 10), 5 ),
        ( 1, DATEFROMPARTS(2016, 2, 10), 15 ),
        ( 1, DATEFROMPARTS(2016, 2, 10), 15 ),
        ( 1, DATEFROMPARTS(2016, 3, 10), 20 ),
        ( 1, DATEFROMPARTS(2016, 3, 10), 30 ),
        ( 2, DATEFROMPARTS(2016, 1, 01), 1 ),
        ( 2, DATEFROMPARTS(2016, 1, 10), 1 ),
        ( 2, DATEFROMPARTS(2016, 2, 10), 1 ),
        ( 2, DATEFROMPARTS(2016, 2, 10), 1 ),
        ( 2, DATEFROMPARTS(2016, 3, 01), 3 ),
        ( 2, DATEFROMPARTS(2016, 3, 01), 2 );
       

WITH    DadosPivot
          AS ( SELECT   TP.Nome AS NomeProjeto ,
                        MONTH(TA.Data) AS Mes ,
                        SUM(TA.Quantidade) AS Quantidade
               FROM     @tableProjetos AS TP
                        JOIN @tableAtividades AS TA ON TA.IdProjeto = TP.IdProjeto
               GROUP BY TP.Nome ,
                        TA.Data
             )
     SELECT PivotTable.NomeProjeto ,
            Janeiro = [1] ,
            Fevereiro = [2] ,
            Março = [3] ,
            Total = ( [1] + [2] + [3] )
     FROM   DadosPivot R PIVOT( SUM(Quantidade) FOR Mes IN ( [1], [2], [3] ) ) AS PivotTable;
	 



--	    TOTAL	  -JANEIRO	 -FEVEREIRO-	MARÇO
--PROJETO1	90			10		30			50
--PROJETO2	9			2		2			5
