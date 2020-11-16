CREATE OR ALTER PROCEDURE HealthCheck.uspDeletaLogsDuplicados
(
    @Visualizar BIT = 1,
    @Deletar    BIT = 0
)
AS
    BEGIN
        IF(OBJECT_ID('TEMPDB..#LogsDuplicados') IS NOT NULL)
            DROP TABLE #LogsDuplicados;

        CREATE TABLE #LogsDuplicados
        (
            [Rn]          BIGINT,
            [IdLog]       INT             PRIMARY KEY,
            [IdPessoa]    UNIQUEIDENTIFIER,
            [IdEntidade]  UNIQUEIDENTIFIER,
            [Entidade]    VARCHAR(128),
            [IdLogAntigo] UNIQUEIDENTIFIER,
            [Acao]        CHAR(1),
            [Data]        DATETIME2(2),
            [IPAdress]    VARCHAR(30),
            [Conteudo]    VARCHAR(MAX)
        );

        ;WITH DadosDuplicados
            AS
            (
                SELECT Rn = ROW_NUMBER() OVER (PARTITION BY LJ.IdEntidade,
                                                            LJ.IdPessoa,
                                                            LJ.Acao,
                                                            LJ.Data,
                                                            LJ.Conteudo
                                                   ORDER BY
                                                   LJ.IdLog
                                              ),
                       LJ.IdLog,
                       LJ.IdPessoa,
                       LJ.IdEntidade,
                       LJ.Entidade,
                       LJ.IdLogAntigo,
                       LJ.Acao,
                       LJ.Data,
                       LJ.IPAdress,
                       LJ.Conteudo
                  FROM Log.LogsJson AS LJ
            )
        INSERT INTO #LogsDuplicados
        SELECT R.*
          FROM DadosDuplicados R
         WHERE
            EXISTS (
                       SELECT *
                         FROM DadosDuplicados R2
                        WHERE
                           R.IdEntidade = R2.IdEntidade
                           AND R.Data = R2.Data
                           AND R2.Acao = R.Acao
                           AND R2.Conteudo = R.Conteudo
                           AND R2.Rn > 1
                   );

        IF(@Visualizar = 1)
            BEGIN
                SELECT * FROM #LogsDuplicados AS LD;
            END;

        IF(@Deletar = 1)
            BEGIN
                DELETE target
                  FROM Log.LogsJson target
                 WHERE
                    target.IdLog IN(
                                       SELECT LD.IdLog FROM #LogsDuplicados AS LD WHERE LD.Rn > 1
                                   );
            END;
    END;



