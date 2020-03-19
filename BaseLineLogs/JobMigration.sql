DECLARE @database VARCHAR(200) = DB_NAME();




    /* ==================================================================
--Data: 08/10/2019 
--Autor :Wesley Neves
--Observação: Script responsavel por executar a migração dos logs antigos para o novo formato 

DEVE SER COLOCADO A DATA LIMITE DE EXECUÇÃO DO SCRIPT , POIS ESSE FINALIZA OU QUANDO A MIGRAÇÃO FOR CONCLUIDA COM SUCESSO 
OU QUANDO A HORA ATUAL FOR MAIOR DO QUE A DATA FIM .
 
-- ==================================================================
*/
    DECLARE @DataFim DATETIME = '2019-11-28 11:00:00';


    DECLARE @QuantidadeRegistroAMigrar INT = 102400;
    DECLARE @DeletarRegistrosMigrados BIT = 1;

    /* ==================================================================
--Data: 22/07/2019 
--Autor :Wesley Neves
--Observação: Configurações de controle
 
-- ==================================================================
*/
    DECLARE @version VARCHAR(200) = @@VERSION;
    DECLARE @TipoVersion VARCHAR(100) = CASE
                                            WHEN CHARINDEX('Azure', @version) > 0 THEN
                                                'Azure'
                                            ELSE
                                                'Local'
                                        END;
    DECLARE @DataHoraInicio DATETIME = SYSDATETIME();
    DECLARE @ConfigExecutouMigracaoLogsJSON BIT = (
                                                  SELECT ISNULL(TRY_CAST(C.Valor AS BIT), 0)
                                                  FROM Sistema.Configuracoes AS C
                                                  WHERE C.Configuracao = 'ExecutouMigracaoLogsJSON'
                                                  );


    DECLARE @QuantidadeRegistros INT = (
                                       SELECT COUNT(*)
                                       FROM Log.Logs AS L WITH (NOLOCK)
                                       ) + (
                                           SELECT COUNT(*)
                                           FROM Expurgo.Logs AS L WITH (NOLOCK)
                                           );

    IF (@QuantidadeRegistros > 0)
    BEGIN
        SET @ConfigExecutouMigracaoLogsJSON = 0;
    END;
    ELSE
    BEGIN
        SET @ConfigExecutouMigracaoLogsJSON = 1;
    END;

    UPDATE Sistema.Configuracoes
    SET Valor = IIF(@ConfigExecutouMigracaoLogsJSON = 1, 'True', 'False')
    WHERE Configuracao = 'ExecutouMigracaoLogsJSON';




    IF (@ConfigExecutouMigracaoLogsJSON = 1)
    BEGIN


        IF (@ConfigExecutouMigracaoLogsJSON = 1)
        BEGIN
            SELECT 'A Configuração @ConfigExecutouMigracaoLogsJSON está verdadeira ou seja, cliente migrado ';

            RETURN;
        END;
    END;

    IF (NOT EXISTS (
                   SELECT S.name,
                          T.name
                   FROM sys.tables AS T
                        JOIN
                        sys.schemas AS S ON T.schema_id = S.schema_id
                   WHERE T.name = 'LogsJson'
                   )
       )
    BEGIN
        SELECT CONCAT('Cliente:', DB_NAME(), ' ainda não recebeu a versão dos logs');

        RETURN;
    END;

    IF (NOT EXISTS (
                   SELECT S.name,
                          T.name
                   FROM sys.tables AS T
                        JOIN
                        sys.schemas AS S ON T.schema_id = S.schema_id
                   WHERE T.name = 'SistemasEspelhamentos'
                   )
       )
    BEGIN
        SELECT CONCAT('Cliente:', DB_NAME(), ' Não tem a tabela de espelhamento');

        RETURN;
    END;

    IF (NOT EXISTS (
                   SELECT *
                   FROM sys.procedures AS P
                   WHERE P.name = 'uspMigrarConteudoLogsForLogsJSON'
                   )
       )
    BEGIN
        SELECT CONCAT('Cliente:', DB_NAME(), ' Não tem a Procedure que executa a migração ');

        RETURN;
    END;

    INSERT INTO Sistema.SistemasEspelhamentos (
                                              CodSistema,
                                              Nome,
                                              Descricao
                                              )
    SELECT SE.*
    FROM Sistema.Sistemas AS SE
    WHERE NOT EXISTS (
                     SELECT *
                     FROM Sistema.SistemasEspelhamentos AS S
                     WHERE SE.CodSistema = SE.CodSistema
                     );

    IF (@TipoVersion = 'Azure')
    BEGIN
        SET @DataHoraInicio = DATEADD(HOUR, -3, @DataHoraInicio);
    END;

    --SELECT @DataHoraInicio AS [DataHoraInicio];
    --SELECT CONCAT(CONVERT(VARCHAR(20), @DataHoraInicio, 105), ' ', @HoraFim) AS [HoraFinalDeExecução];
    DECLARE @dataStart DATETIME = @DataHoraInicio;
    DECLARE @Iteracao INTEGER = 0;

    WHILE (@dataStart < @DataFim)
    BEGIN
        SET @Iteracao += 1;

        EXEC Log.uspMigrarConteudoLogsForLogsJSON @DeletarRegistrosMigrados = @DeletarRegistrosMigrados,   -- bit
                                                  @QuantidadeRegistrosMigrar = @QuantidadeRegistroAMigrar; -- int

        IF (@@TRANCOUNT > 0)
        BEGIN
            COMMIT;
        END;

        SELECT CONCAT('Interacao:', @Iteracao)
        UNION
        SELECT CONCAT('Hora Inicio Procedure:', CONVERT(VARCHAR(20), @dataStart, 121))
        UNION
        SELECT CONCAT('Data Fim Procedure:', CONVERT(VARCHAR(20), DATEADD(HOUR, -3, GETDATE()), 121))
        UNION
        SELECT CONCAT('Data Fim:	', CONVERT(VARCHAR(20), @DataFim, 121));

        SET @QuantidadeRegistros = (
                                   SELECT SUM(S.rowcnt) AS QuantidadeLinhas
                                   FROM sys.sysindexes AS S
                                   WHERE (
                                         S.id = OBJECT_ID('Log.Logs')
                                         OR S.id = OBJECT_ID('Expurgo.Logs')
                                         )
                                         AND S.indid = 1
                                   );

        IF (@QuantidadeRegistros = 0)
        BEGIN
            SELECT CONCAT(
                             'Migração Finalizada ==> Total Interações:',
                             @Iteracao,
                             ' Hora Final:',
                             CONVERT(VARCHAR(20), @DataFim, 121)
                         );

            BREAK;
        END;

        SET @dataStart = DATEADD(HOUR, -3, GETDATE());

        IF (@dataStart > @DataFim)
        BEGIN
            BREAK;
        END;
    END;

