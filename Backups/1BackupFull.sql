/* ==================================================================
--Data: 12/11/2019 
--Autor :Wesley Neves
--Observação: Os tipos mais comuns de backups do SQL Server são backups completos ou completos, 
também conhecidos como backups de banco de dados. Esses backups criam um backup completo do seu banco de dados,
 bem como parte do log de transações, para que o banco de dados possa ser recuperado. 
 Isso permite a forma mais simples de restauração do banco de dados, pois todo o conteúdo está contido em um backup.
 
 Option COPY_ONLY
 Isso especifica que o backup é um backup apenas de cópia, o que significa que sua sequência de backup não é afetada.
  Para todos os efeitos, a operação de backup não ocorreu. Para um backup completo, uma opção somente cópia não redefine o DMC;  

-- ==================================================================
*/

--CREATE PROCEDURE HealthCheck.uspExecBackup
--(
--    @DbName    VARCHAR(128),
--    @diretorio VARCHAR(300),
--	@Diferencial BIT = 0
--)
--AS
--    BEGIN

DECLARE @DbName        VARCHAR(128) = 'AdventureWorks',
        @diretorio     VARCHAR(300) = 'F:\Bases\Backups',
        @IsMirror      BIT          = 0,
        @Path_isMirror VARCHAR(300) = '',
        @Diferencial   BIT          = 0,
        @COPY_ONLY     BIT          = 0,
        @COMPRESSION   BIT          = 1;




DECLARE @comand VARCHAR(MAX);
DECLARE @space CHAR(2) = SPACE(2);
DECLARE @horaFormatada VARCHAR(50) = FORMAT(GETDATE(), 'dd-MM-yyyy hh-mm-ss', 'Pt-br');
DECLARE @ClientMessage VARCHAR(1000);
DECLARE @options VARCHAR(1000) = ' WITH ';
DECLARE @Tipo VARCHAR(20) = 'FULL';
DECLARE @to VARCHAR(30) = ' TO DISK =';
DECLARE @to_mirror VARCHAR(30)  ='MIRROR TO DISK ='
DECLARE @valor_COPY_ONLY VARCHAR(30) = 'COPY_ONLY';
DECLARE @valor_CHECKSUM VARCHAR(30) = 'CHECKSUM';
DECLARE @valor_Compression VARCHAR(30) = 'COMPRESSION';
DECLARE @HasOptions BIT = IIF(@COPY_ONLY > 0 OR @Diferencial > 0 OR @COMPRESSION > 0, 1, 0);




IF(NOT EXISTS (
                  SELECT * FROM sys.databases AS D WHERE D.database_id = DB_ID(@DbName)
              )
  )
    BEGIN
        SET @ClientMessage = FORMATMESSAGE('O Database %s não existe em sys.databases', @DbName);

        THROW 50000, @ClientMessage, 0;
    END;


SET @IsMirror = IIF(LTRIM(RTRIM(LEN(@Path_isMirror))) = 0,0, @IsMirror);



IF (@IsMirror = 1 AND  LTRIM(RTRIM(LEN(@Path_isMirror))) = 0)
BEGIN
		
		SET @ClientMessage = FORMATMESSAGE('para fazer um backup espelhado do banco de dados %s é necessário o diretorio de espelhamento', @DbName);

        THROW 50000, @ClientMessage, 0;
END


SET @to_mirror = IIF(@IsMirror = 0,0, @to_mirror);



IF(CHARINDEX('http', @Diferencial) > 0)
    BEGIN
        SELECT @to = ' TO URL =';
    END;

IF(@Diferencial = 1)SELECT @Tipo = 'DIFFERENTIAL';

DECLARE @tableOptions TABLE
(
    Opcao VARCHAR(200)
);

INSERT INTO @tableOptions(
                             Opcao
                         )
SELECT IIF(@Diferencial = 1, 'DIFFERENTIAL ,', '')
UNION
SELECT @valor_CHECKSUM
UNION
SELECT @valor_COPY_ONLY
UNION
SELECT @valor_Compression;

SELECT @options += string_agg(CONCAT(T.Opcao, SPACE(1)), ' , ')
  FROM @tableOptions T
 WHERE
    LEN(T.Opcao) > 0;

BEGIN TRY

    /*Region Logical Querys*/
    SET @comand = CONCAT('BACKUP DATABASE ', @DbName, @to, CHAR(39), @diretorio, CHAR(39), @options);

    PRINT @comand;
--EXEC(@comand);

/*End region */
END TRY
BEGIN CATCH
    DECLARE @ErrorNumber INT = ERROR_NUMBER();
    DECLARE @ErrorLine INT = ERROR_LINE();
    DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
    DECLARE @ErrorSeverity INT = ERROR_SEVERITY();
    DECLARE @ErrorState INT = ERROR_STATE();

    PRINT 'Actual error number: ' + CAST(@ErrorNumber AS VARCHAR(MAX));
    PRINT 'Actual line number: ' + CAST(@ErrorLine AS VARCHAR(MAX));
    PRINT '@ErrorMessage: ' + CAST(@ErrorMessage AS VARCHAR(MAX));
    PRINT '@ErrorSeverity: ' + CAST(@ErrorLine AS VARCHAR(MAX));
    PRINT '@ErrorState: ' + CAST(@ErrorLine AS VARCHAR(MAX));

    RAISERROR(@ErrorMessage, @ErrorSeverity, @ErrorState);

    PRINT 'Error detected, all changes reversed.';
END CATCH;
--END;
