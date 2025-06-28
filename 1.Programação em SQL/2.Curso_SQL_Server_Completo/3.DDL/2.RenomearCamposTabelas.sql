
DROP TABLE IF EXISTS dbo.Pessoas
CREATE TABLE [dbo].[Pessoas] (
    [IdPessoa] [UNIQUEIDENTIFIER] NOT NULL,
    [NomeRazaoSocial] [VARCHAR](MAX),
    [CPFCNPJ] [VARCHAR](MAX),
    [TipoPessoaFisica] [BIT] NULL,
    [DataCadastro] [DATETIME] NULL
        DEFAULT (GETDATE()),
    [DataAtualizacao] [DATETIME]
        DEFAULT (GETDATE()))


		GO

CREATE PROCEDURE uspBuscaPessoas (@idPessoa UNIQUEIDENTIFIER)
AS
BEGIN

    SELECT p.IdPessoa,
           p.NomeRazaoSocial,
           p.CPFCNPJ,
           p.TipoPessoaFisica,
           AnoCadastro = YEAR(p.DataCadastro),
           p.DataCadastro,
           p.DataAtualizacao
      FROM dbo.Pessoas AS p
     WHERE p.IdPessoa = ISNULL(@idPessoa, p.IdPessoa)
     ORDER BY AnoCadastro ASC;

END;


EXEC dbo.uspBuscaPessoas @idPessoa =NULL?

EXEC sp_rename 'dbo.Pessoas.NomeRazaoSocial', 'Nome','COLUMN';?

?

SELECT * FROM dbo.Pessoas AS p?


SELECT OBJECT_NAME(Dep.referencing_id),
       Dep.referenced_database_name,
       Dep.referenced_schema_name,
       Dep.referenced_entity_name
  FROM sys.sql_expression_dependencies Dep
 WHERE OBJECT_NAME(Dep.referenced_id) = 'Pessoas'
   AND OBJECT_DEFINITION(Dep.referencing_id) LIKE '%NomeRazaoSocial%';

?


EXEC dbo.uspBuscaPessoas @idPessoa =NULL?

/*
Msg 207, Level 16, State 1, Procedure uspBuscaPessoas, Line 5?

Invalid column name 'NomeRazaoSocial'??
*/

        


