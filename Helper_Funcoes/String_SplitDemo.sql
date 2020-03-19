DECLARE @tabela TABLE (
    id INT,
    Valores VARCHAR(20));

INSERT INTO @tabela (id,
                     Valores)
VALUES (1, -- id - int
        '2,3,4,5,6,7,8' -- Valores - varchar(20)
    );
SELECT T.id,
      
       V.Valor
  FROM @tabela AS T
 CROSS APPLY (SELECT  value Valor FROM STRING_SPLIT(T.Valores, ',')
 
 ) V




