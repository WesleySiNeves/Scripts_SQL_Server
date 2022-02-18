
IF ( OBJECT_ID('TEMPDB..#TempFuncionarios') IS NOT NULL )
    DROP TABLE #TempFuncionarios;	

CREATE TABLE #TempFuncionarios
    (
      IdFuncionario INT IDENTITY(1, 1)
                        NOT NULL PRIMARY KEY CLUSTERED ( IdFuncionario ) ,
      Nome VARCHAR(MAX) ,
      GerenteId INT NULL
                    FOREIGN KEY REFERENCES #TempFuncionarios ( IdFuncionario ) ,
      DataNascimento DATETIME
    );

INSERT  INTO #TempFuncionarios
        ( Nome, GerenteId, DataNascimento )
VALUES  ( 'Ricardo', NULL, '19810609' ),
        ( 'Vania', 1, '19970101' ),
        ( 'Maria', 2, '20000101' ),
        ( 'Eleusa', 3, '19850101' ),
        ( 'Leandro', 2, '19670401' ),
        ( 'Daniel', 2, '19820101' ),
        ( 'Rasta', 1, '19560101' ),
        ( 'Dodo', 7, '19670109' ),
        ( 'Estag1', 8, '19870809' ),
        ( 'Estagiário', 9, '19790302' );


WITH    cte ( Id, Nome, GerenteId, GerenteNome )
          AS (
--select simples para retornar o funcionário sem gerente, no caso o
--Presidente da Empresa
               SELECT   --1  AS NivelRecursividade,
                        IdFuncionario ,
                        Nome ,
                        GerenteId ,
                        CAST(NULL AS VARCHAR(10)) [GerenteNome]
               FROM     #TempFuncionarios
               WHERE    GerenteId IS NULL
               UNION ALL
--select com um UNION com o select Anterior
               SELECT   F.IdFuncionario ,
                        F.Nome ,
                        F.GerenteId ,
                        G.Nome [GerenteNome]
               FROM    #TempFuncionarios F
                        JOIN #TempFuncionarios G ON F.GerenteId = G.IdFuncionario
             )
    SELECT  c.Id ,
            c.Nome ,
            c.GerenteId ,
            c.GerenteNome
    FROM    cte c
    ORDER BY 1;

