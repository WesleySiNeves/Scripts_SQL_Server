--— Prepara ambiente
--— Aproximadamente 2 minutos para rodar
--— Tab com 287368 KB
IF OBJECT_ID('OrdersBig') IS NOT NULL
    DROP TABLE OrdersBig;
GO
CREATE TABLE OrdersBig
    (
      OrderID INT NOT NULL
                  IDENTITY(1, 1) ,
      CustomerID INT NULL ,
      OrderDate DATE NULL ,
      Value NUMERIC(18, 2) NOT NULL
    );
GO
ALTER TABLE OrdersBig ADD CONSTRAINT xpk_OrdersBig PRIMARY KEY CLUSTERED  (OrderID);
GO
-- Tab com 5 milhões de linhas
INSERT  INTO OrdersBig
        ( CustomerID ,
          OrderDate ,
          Value
        )

        SELECT TOP 5000000
                ABS(CONVERT(INT, ( CHECKSUM(NEWID()) / 10000000 ))) ,
                CONVERT(DATE, GETDATE() - ABS(CONVERT(INT, ( CHECKSUM(NEWID())
                                                             / 10000000 )))) ,
                ABS(CONVERT(NUMERIC(18, 2), ( CHECKSUM(NEWID()) / 1000000.5 )))
        FROM    sysobjects a ,
                sysobjects b ,
                sysobjects c ,
                sysobjects d;
GO
ALTER TABLE OrdersBig ADD CountCol VARCHAR(20);
GO
UPDATE TOP ( 50 ) PERCENT
        OrdersBig
SET     CountCol = 'Count'
WHERE   CountCol IS NULL;
GO
UPDATE TOP ( 50 ) PERCENT
        OrdersBig
SET     CountCol = 'CountDistinct'
WHERE   CountCol IS NULL;
GO
UPDATE  OrdersBig
SET     CountCol = 'CountDistinct_1'
WHERE   CountCol IS NULL;
GO
CHECKPOINT;
GO