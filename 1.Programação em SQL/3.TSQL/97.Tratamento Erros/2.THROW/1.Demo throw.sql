


--https://docs.microsoft.com/pt-br/sql/t-sql/language-elements/try-catch-transact-sql

/*
As constru��es TRY�CATCH n�o interceptam as seguintes condi��es:

Avisos ou mensagens informativas que t�m uma severidade 10 ou menor.

Erros que t�m uma severidade 20 ou maior, que param o processamento de tarefa do Mecanismo de Banco de Dados do SQL Server para a sess�o. Se ocorrer um erro com severidade 20 ou maior e a conex�o com o banco de dados n�o for interrompida, TRY�CATCH tratar� o erro.

Aten��es, como solicita��es da interrup��o de cliente ou conex�es de cliente desfeitas.

Quando a sess�o for finalizada por um administrador de sistema com o uso da instru��o KILL.

Os seguintes tipos de erros n�o s�o tratados por um bloco CATCH quando ocorrerem no mesmo n�vel de execu��o que a constru��o TRY�CATCH:

Erros de compila��o, como erros de sintaxe, que impe�am a execu��o de um lote.

Erros que ocorrem durante a recompila��o em n�vel de instru��o, como os erros de resolu��o do nome de objeto que ocorrem ap�s a compila��o, devido � resolu��o adiada do nome.

Esses erros s�o retornados ao n�vel que executou o lote, o procedimento armazenado ou o gatilho.

Se ocorrer um erro durante a compila��o ou a recompila��o no n�vel da instru��o em um n�vel de execu��o inferior (por exemplo, ao executar sp_executesql ou um procedimento armazenado definido pelo usu�rio) dentro do bloco TRY, o erro ocorrer� em um n�vel inferior ao da constru��o TRY�CATCH e ser� tratado pelo bloco CATCH associado.

O exemplo a seguir mostra como um erro de resolu��o de nome de objeto gerado por uma instru��o SELECT n�o � capturado pela constru��o TRY�CATCH, mas � capturado pelo bloco CATCH quando a mesma instru��o SELECT � executada dentro de um procedime

*/

-- Verify that the stored procedure does not already exist.  
IF OBJECT_ID ( 'usp_GetErrorInfo', 'P' ) IS NOT NULL   
    DROP PROCEDURE usp_GetErrorInfo;  
GO  

-- Create procedure to retrieve error information.  
CREATE PROCEDURE usp_GetErrorInfo  
AS  
SELECT  
    ERROR_NUMBER() AS ErrorNumber  
    ,ERROR_SEVERITY() AS ErrorSeverity  
    ,ERROR_STATE() AS ErrorState  
    ,ERROR_PROCEDURE() AS ErrorProcedure  
    ,ERROR_LINE() AS ErrorLine  
    ,ERROR_MESSAGE() AS ErrorMessage;  
GO  

BEGIN TRY  
    -- Generate divide-by-zero error.  
    SELECT 1/0;  
END TRY  
BEGIN CATCH  
    -- Execute error retrieval routine.  
    EXECUTE usp_GetErrorInfo;  
END CATCH;   


/*Segundo Exemplo */


BEGIN TRY  
    -- Table does not exist; object name resolution  
    -- error not caught.  
    SELECT * FROM NonexistentTable;  
END TRY  
BEGIN CATCH  
    SELECT   
        ERROR_NUMBER() AS ErrorNumber  
       ,ERROR_MESSAGE() AS ErrorMessage;  
END CATCH  