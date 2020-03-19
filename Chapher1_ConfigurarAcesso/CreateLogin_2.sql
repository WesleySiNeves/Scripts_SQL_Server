/* ==================================================================
--Data: 19/08/2019 
--Autor :Wesley Neves
--Observação: 
172
Diferença entre um usuário e um login . 
Um Login é uma conta no SQL Server como um todo - alguém que pode efetuar login no servidor e possui uma senha. 
Um usuário é um login com acesso a um banco de dados específico.

Criar um Login é fácil e deve (obviamente) ser feito antes de criar uma conta de usuário para 
o login em um banco de dados específico:
 
-- ==================================================================
*/


USE master

CREATE LOGIN NewAdminName WITH PASSWORD = '96086512'
GO


/* ==================================================================
--Data: 19/08/2019 
--Autor :Wesley Neves
--Observação: 
Aqui está como você cria um usuário com privilégios db_owner usando o Login que acabou de declarar:
 
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