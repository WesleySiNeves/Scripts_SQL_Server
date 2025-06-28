/* ==================================================================
--Data: 19/08/2019 
--Autor :Wesley Neves
--Observa��o: 
172
Diferen�a entre um usu�rio e um login . 
Um Login � uma conta no SQL Server como um todo - algu�m que pode efetuar login no servidor e possui uma senha. 
Um usu�rio � um login com acesso a um banco de dados espec�fico.

Criar um Login � f�cil e deve (obviamente) ser feito antes de criar uma conta de usu�rio para 
o login em um banco de dados espec�fico:
 
-- ==================================================================
*/


USE master

CREATE LOGIN NewAdminName WITH PASSWORD = '96086512'
GO


/* ==================================================================
--Data: 19/08/2019 
--Autor :Wesley Neves
--Observa��o: 
Aqui est� como voc� cria um usu�rio com privil�gios db_owner usando o Login que acabou de declarar:
 
-- ==================================================================
*/


Use master;
GO

IF NOT EXISTS (
                  SELECT *
                    FROM sys.database_principals
                   WHERE
                      database_principals.name = N'NewAdminName'
              )
    BEGIN
        CREATE USER [NewAdminName] FOR LOGIN [NewAdminName];

        EXEC sys.sp_addrolemember N'db_owner', N'NewAdminName';
    END;
GO