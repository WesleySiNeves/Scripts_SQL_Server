


IF ( OBJECT_ID('Examples.UniquenessConstraint') IS  NULL )
    BEGIN
		
        CREATE TABLE Examples.UniquenessConstraint
            (
              PrimaryUniqueValue INT NOT NULL ,
              AlternateUniqueValue1 INT NULL ,
              AlternateUniqueValue2 INT NULL
            );
    END;


ALTER TABLE Examples.UniquenessConstraint
ADD CONSTRAINT PKUniquenessContraint PRIMARY KEY
(PrimaryUniqueValue);



-- ==================================================================
--Observação: Retorna se a CONSTRAINT e unique
-- ==================================================================
SELECT  type_desc ,
        is_primary_key ,
        is_unique ,
        is_unique_constraint
FROM    sys.indexes
WHERE   OBJECT_ID('Examples.UniquenessConstraint') = object_id;



ALTER TABLE Examples.UniquenessConstraint
ADD CONSTRAINT AKUniquenessContraint UNIQUE
(AlternateUniqueValue1, AlternateUniqueValue2);

INSERT  INTO Examples.UniquenessConstraint
        ( PrimaryUniqueValue ,
          AlternateUniqueValue1 ,
          AlternateUniqueValue2
        )
VALUES  ( 1 ,
          NULL ,
          NULL
        );

SELECT  *
FROM    Examples.UniquenessConstraint AS UC;

INSERT  INTO Examples.UniquenessConstraint
        ( PrimaryUniqueValue ,
          AlternateUniqueValue1 ,
          AlternateUniqueValue2
        )
VALUES  ( 2 ,
          NULL ,
          NULL
        );
/*
Violação da restrição UNIQUE KEY 'AKUniquenessContraint'. Não é possível inserir a chave duplicada no objeto 'Examples.UniquenessConstraint'.
 O valor de chave duplicada é (<NULL>, <NULL>).
*/

SELECT type_desc, is_primary_key, is_unique,
is_unique_constraint
FROM sys.indexes
WHERE OBJECT_ID('Examples.UniquenessConstraint') =
object_id;

--Foreign Key Columns