DROP TABLE IF EXISTS #DadosDeletar;


DECLARE @QuantidadeADeletar INT = 1500;

DECLARE @quantiadeRegistrosEncontrados INT = 0;
DECLARE @quantiadeRegistrosAposDelete INT = 0;


DROP TABLE IF EXISTS #DadosDeletar;

CREATE TABLE #DadosDeletar
    (
        [IdEntidade] UNIQUEIDENTIFIER,
        [Data]       DATE,
        [MaxData]    DATETIME2(2),
        [Quantidade] INT
    );


INSERT INTO #DadosDeletar
            SELECT
                IdEntidade,
                CAST(Data AS DATE) Data,
                MAX(Data)          AS MaxData,
                COUNT(1)           AS Quantidade
            FROM
                Log.LogsJson
            WHERE
                Entidade = 'Processo.ProcessosAndamentos'
                AND Acao = 'U'
            GROUP BY
                IdEntidade,
                CAST(Data AS DATE)
            HAVING
                COUNT(1) > 50;



SET @quantiadeRegistrosEncontrados =
    (
        SELECT
            ISNULL(SUM(Quantidade), 0)
        FROM
            #DadosDeletar
    );


IF (@quantiadeRegistrosEncontrados > 0)
    BEGIN


        DECLARE
            @Identidade UNIQUEIDENTIFIER,
            @Data       DATE,
            @MaxData    DATETIME2(2),
            @Quantidade INT;


        /* declare variables */
        DECLARE @variable INT;

        DECLARE cursor_DeletarLogs CURSOR FAST_FORWARD READ_ONLY FOR
            SELECT TOP (@QuantidadeADeletar)
                   *
            FROM
                   #DadosDeletar;

        OPEN cursor_DeletarLogs;

        FETCH NEXT FROM cursor_DeletarLogs
        INTO
            @Identidade,
            @Data,
            @MaxData,
            @Quantidade;

        WHILE @@FETCH_STATUS = 0
            BEGIN



                ;WITH DadosDelete
                 AS (   SELECT TOP (@Quantidade - 1)
                               IdLog
                        FROM
                               Log.LogsJson
                        WHERE
                               IdEntidade = @Identidade
                               AND Data >= @Data
                               AND Data < @MaxData
                 --2025-06-08	2025-06-08 23:50:23.06
                 )
                DELETE
                    R
                FROM
                    DadosDelete R;


                FETCH NEXT FROM cursor_DeletarLogs
                INTO
                    @Identidade,
                    @Data,
                    @MaxData,
                    @Quantidade;
            END;

        CLOSE cursor_DeletarLogs;
        DEALLOCATE cursor_DeletarLogs;

        TRUNCATE TABLE #DadosDeletar;


        INSERT INTO #DadosDeletar
                    SELECT
                        IdEntidade,
                        CAST(Data AS DATE) Data,
                        MAX(Data)          AS MaxData,
                        COUNT(1)           AS Quantidade
                    FROM
                        Log.LogsJson
                    WHERE
                        Entidade = 'Processo.ProcessosAndamentos'
                        AND Acao = 'U'
                    GROUP BY
                        IdEntidade,
                        CAST(Data AS DATE)
                    HAVING
                        COUNT(1) > 5;


        SET @quantiadeRegistrosAposDelete =
            (
                SELECT
                    ISNULL(SUM(Quantidade), 0)
                FROM
                    #DadosDeletar
            );

        SELECT
            CONCAT(
                      'Qtd Registros: Antes:', FORMAT(@quantiadeRegistrosEncontrados, 'n0', 'Pt-Br'), ' Apos Delete ',
                      FORMAT(@quantiadeRegistrosAposDelete, 'n0', 'Pt-Br'), ' Deletados ',
                      FORMAT(@quantiadeRegistrosEncontrados - @quantiadeRegistrosAposDelete, 'n0', 'Pt-Br')
                  );


    END;


