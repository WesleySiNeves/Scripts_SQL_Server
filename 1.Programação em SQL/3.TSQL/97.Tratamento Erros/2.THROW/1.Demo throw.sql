


--https://docs.microsoft.com/pt-br/sql/t-sql/language-elements/try-catch-transact-sql

/*
As construções TRY…CATCH não interceptam as seguintes condições:

Avisos ou mensagens informativas que têm uma severidade 10 ou menor.

Erros que têm uma severidade 20 ou maior, que param o processamento de tarefa do Mecanismo de Banco de Dados do SQL Server para a sessão. Se ocorrer um erro com severidade 20 ou maior e a conexão com o banco de dados não for interrompida, TRY…CATCH tratará o erro.

Atenções, como solicitações da interrupção de cliente ou conexões de cliente desfeitas.

Quando a sessão for finalizada por um administrador de sistema com o uso da instrução KILL.

Os seguintes tipos de erros não são tratados por um bloco CATCH quando ocorrerem no mesmo nível de execução que a construção TRY…CATCH:

Erros de compilação, como erros de sintaxe, que impeçam a execução de um lote.

Erros que ocorrem durante a recompilação em nível de instrução, como os erros de resolução do nome de objeto que ocorrem após a compilação, devido à resolução adiada do nome.

Esses erros são retornados ao nível que executou o lote, o procedimento armazenado ou o gatilho.

Se ocorrer um erro durante a compilação ou a recompilação no nível da instrução em um nível de execução inferior (por exemplo, ao executar sp_executesql ou um procedimento armazenado definido pelo usuário) dentro do bloco TRY, o erro ocorrerá em um nível inferior ao da construção TRY…CATCH e será tratado pelo bloco CATCH associado.

O exemplo a seguir mostra como um erro de resolução de nome de objeto gerado por uma instrução SELECT não é capturado pela construção TRY…CATCH, mas é capturado pelo bloco CATCH quando a mesma instrução SELECT é executada dentro de um procedime

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