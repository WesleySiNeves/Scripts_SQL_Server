


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
--Observa��o: Retorna se a CONSTRAINT e unique
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
Viola��o da restri��o UNIQUE KEY 'AKUniquenessContraint'. N�o � poss�vel inserir a chave duplicada no objeto 'Examples.UniquenessConstraint'.
 O valor de chave duplicada � (<NULL>, <NULL>).
*/

SELECT type_desc, is_primary_key, is_unique,
is_unique_constraint
FROM sys.indexes
WHERE OBJECT_ID('Examples.UniquenessConstraint') =
object_id;

--Foreign Key Columns