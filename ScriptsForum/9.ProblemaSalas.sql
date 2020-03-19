
CREATE TABLE Predios 
        (
          IdPredio INT NOT NULL  PRIMARY KEY ,
          QuantidadeSala INT
        );

INSERT Predios
        ( IdPredio, QuantidadeSala )
VALUES  ( 1, -- IdPredio - int
          20  -- QuantidadeSala - int
          );



CREATE TABLE Salas
       (
         IdSala INT PRIMARY KEY ,
         IdPredio INT NOT NULL
                      FOREIGN KEY REFERENCES dbo.Predios ( IdPredio ) ,
         NomeSala VARCHAR(MAX),
       );

WITH    Recursividade
          AS ( SELECT   IdPredio = P.IdPredio ,
                        IdSala = 1 ,
                        NomeSala = CONCAT('Sala-', 1)
               FROM     dbo.Predios AS P
               UNION ALL
               SELECT   IdPredio = RS.IdPredio ,
                        IdSala = RS.IdSala + 1 ,
                        NomeSala = CONCAT('Sala-', RS.IdSala + 1)
               FROM     Recursividade AS RS
               WHERE    RS.IdSala < 20
             )
     INSERT INTO dbo.Salas
            ( IdPredio ,
              IdSala ,
              NomeSala
            )
            SELECT  R.IdPredio ,
                    R.IdSala ,
                    R.NomeSala
            FROM    Recursividade R;


