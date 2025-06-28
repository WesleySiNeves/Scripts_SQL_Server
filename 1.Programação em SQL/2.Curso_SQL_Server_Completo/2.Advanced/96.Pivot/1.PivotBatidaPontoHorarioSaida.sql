DECLARE @dados TABLE
        (
          id_pessoa INT ,
          data VARCHAR(10) ,
          hora VARCHAR(5)
        );

INSERT  INTO @dados
VALUES  ( 1, '01/01/2010', '08:00' ),
        ( 1, '01/01/2010', '12:00' ),
        ( 1, '01/01/2010', '13:00' ),
        ( 1, '01/01/2010', '17:00' ),
        ( 1, '02/01/2010', '08:00' ),
        ( 1, '02/01/2010', '10:00' );



SELECT  data ,
        [1] ,
        [2] ,
        [3] ,
        [4] ,
        [5] ,
        [6] ,
        [7] ,
        [8] ,
        [9] ,
        [10] ,
        [11] ,
        [12] ,
        [13] ,
        [14] ,
        [15] ,
        [16] ,
        [17] ,
        [18] ,
        [19] ,
        [20]
FROM    ( SELECT    data ,
                    hora ,
                    ROW_NUMBER() OVER ( PARTITION BY data ORDER BY data ) AS t_index
          FROM      @dados
          WHERE     id_pessoa = 1
          GROUP BY  data ,
                    hora ) C PIVOT ( MAX(hora) FOR t_index IN ( [1], [2], [3],
                                                              [4], [5], [6],
                                                              [7], [8], [9],
                                                              [10], [11], [12],
                                                              [13], [14], [15],
                                                              [16], [17], [18],
                                                              [19], [20] ) ) AS P;