
DROP TABLE  IF EXISTS produtos

CREATE TABLE produtos
(
 idproduto INT NOT NULL IDENTITY(1,1) PRIMARY KEY,
 Nome VARCHAR(100),
 Codigo VARCHAR(10) 
)


CREATE UNIQUE NONCLUSTERED INDEX UniqueXPRDRED ON dbo.produtos(Codigo)

INSERT INTO dbo.produtos (Nome,Codigo)VALUES ('Produto 1',NULL );
INSERT INTO dbo.produtos (Nome,Codigo)VALUES ('Produto 2','P2' );
INSERT INTO dbo.produtos (Nome,Codigo)VALUES ('Produto 3','P3' );

--So existe uma linha
SELECT * FROM dbo.produtos AS P
WHERE P.Codigo IS NULL


--Essa linha gera o erro
INSERT INTO dbo.produtos (Nome,Codigo)VALUES ('Produto 4',NULL );
--Cannot insert duplicate key row in object 'dbo.produtos' with unique index 'TXPRDRED'. The duplicate key value is (<NULL>).


--Identificar a coluna indexada


SELECT I.object_id,
       [Nome Indice] = I.name,
       I.type_desc,
       I.is_unique,
       tabela = T.name,
       [Coluna Indice] = IC.column_id,
       IC.key_ordinal,
       IC.is_included_column,
       [Nome Coluna Indexada] = C.name,
       [Coluna Tabela] = C.column_id,
       C.system_type_id
  FROM sys.indexes AS I
  JOIN sys.index_columns AS IC
    ON I.object_id  = IC.object_id
   AND I.index_id   = IC.index_id
  JOIN sys.columns AS C
    ON IC.object_id = C.object_id
  JOIN sys.tables AS T
    ON IC.object_id = T.object_id
 WHERE I.object_id  = OBJECT_ID('produtos', 'U')
   AND I.name       = 'UniqueXPRDRED'
   AND IC.column_id = C.column_id;


   --Desabilitar o indice se realmente necessário
  ALTER  INDEX UniqueXPRDRED ON dbo.produtos DISABLE 

  --Essa linha gerava um erro  agora não gera mais 
INSERT INTO dbo.produtos (Nome,Codigo)VALUES ('Produto 4',NULL );


--Habilitando o Indice Novamente

ALTER  INDEX UniqueXPRDRED ON dbo.produtos   REORGANIZE; 
/*Msg 1973, Level 16, State 1, Line 64
Cannot perform the specified operation on disabled index 'UniqueXPRDRED' on table 'dbo.produtos'.*/

  ALTER  INDEX UniqueXPRDRED ON dbo.produtos   REBUILD; 
  /*
  Msg 1505, Level 16, State 1, Line 68
The CREATE UNIQUE INDEX statement terminated because a duplicate key was found for the object name 'dbo.produtos' and the index name 'UniqueXPRDRED'. The duplicate key value is (<NULL>).
The statement has been terminated
  */

  /* ==================================================================
  --Data: 03/09/2018 
  --Autor :Wesley Neves
  --Observação: habilitar um indice desabilitado usando  DBREINDEX
   
  -- ==================================================================
  */
  DBCC DBREINDEX ('dbo.produtos', UniqueXPRDRED);  
  /*
  Msg 1505, Level 16, State 1, Line 82
The CREATE UNIQUE INDEX statement terminated because a duplicate key was found for the object name 'dbo.produtos' and the index name 'UniqueXPRDRED'. The duplicate key value is (<NULL>).
The statement has been terminated.
  */