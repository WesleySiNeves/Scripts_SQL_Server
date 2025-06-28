;
WITH    Pags ( Posicao, SiglaUF, Nome, CodigoIBGE )
          AS ( SELECT   ROW_NUMBER() OVER ( ORDER BY e.SiglaUF ) ,
                        e.SiglaUF ,
                        e.Nome ,
                        e.CodigoIBGE
               FROM     Corporativo.Estados AS e
             )
    SELECT  *
    FROM    Pags
	WHERE Pags.Posicao BETWEEN 1 AND 5
