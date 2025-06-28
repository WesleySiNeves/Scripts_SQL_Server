
--SELECT * FROM Log.LogsJSON AS LJ

CREATE OR ALTER PROCEDURE Log.uspInsertLog
(
@IdPessoa UNIQUEIDENTIFIER ,
@IdEntidade UNIQUEIDENTIFIER , 
@Entidade VARCHAR(128) ,
@Acao CHAR(1),
@Data DATETIME2(2) ,
@CodSistema TINYINT,
@IPAdress VARCHAR(20),
@Conteudo VARCHAR(MAX))
AS 
BEGIN
		BEGIN TRY
				/*Region Logical Querys*/
				
		
		INSERT INTO Log.LogsJSON
		(
		    IdPessoa,
		    IdEntidade,
		    Entidade,
		    Acao,
		    Data,
		    CodSistema,
		    IPAdress,
		    Conteudo
		)
		VALUES
		(   
		    @IdPessoa,          -- IdPessoa - uniqueidentifier
		    @IdEntidade,          -- IdEntidade - uniqueidentifier
		    @Entidade,            -- Entidade - varchar(128)
		    @Acao,            -- Acao - char(1)
		    @Data, -- Data - datetime2(2)
		    @CodSistema,             -- CodSistema - tinyint
		    @IPAdress,            -- IPAdress - varchar(20)
		    @Conteudo             -- Conteudo - varchar(max)
		)
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

END

