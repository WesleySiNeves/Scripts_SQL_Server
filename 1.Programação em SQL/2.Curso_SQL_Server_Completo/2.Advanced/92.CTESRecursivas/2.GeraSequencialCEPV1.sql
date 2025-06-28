DECLARE @TabelaCeps TABLE 
(
 Codigo CHAR(2),
 Cidade VARCHAR(100),
 Inicio VARCHAR(12),
 Termino VARCHAR(12)
)


INSERT INTO @TabelaCeps
        ( Codigo, Cidade, Inicio, Termino )
VALUES  ( '01','Belo Horizonte','30000-000','30002-000' ), --( '01','Belo Horizonte','30000-000','35000-000' )
		 ( '02','São Paulo','10000-000','10010-000' ) --( '02','São Paulo','10000-000','19000-000' )

;WITH DadosFormatados AS 
(
SELECT TC.Codigo ,
       TC.Cidade ,
       TC.Inicio ,
       TC.Termino,
	   InicioFormatado=  CAST( REPLACE(TC.Inicio,'-','') AS BIGINT),
	   TerminoFormatado=  CAST( REPLACE(TC.Termino,'-','') AS BIGINT)
	    FROM @TabelaCeps AS TC
	   
	   
),
Recursividade AS (
SELECT DadosFormatados.Codigo ,
       DadosFormatados.Cidade ,
       DadosFormatados.Inicio ,
       DadosFormatados.Termino ,
       DadosFormatados.InicioFormatado ,
	   [IntervaloCepInicio] =  DadosFormatados.InicioFormatado,
	   [IntervaloCepTermino] = DadosFormatados.InicioFormatado +1,
       DadosFormatados.TerminoFormatado FROM DadosFormatados
	   UNION ALL
	   SELECT R.Codigo ,
              R.Cidade ,
              R.Inicio ,
              R.Termino ,
              R.InicioFormatado ,
              R.[IntervaloCepInicio] +1 ,
              R.[IntervaloCepTermino] +1,
              R.TerminoFormatado FROM Recursividade R
			  WHERE R.IntervaloCepInicio + 1 < R.TerminoFormatado
	 
) 

SELECT
		-- RES.Codigo ,
       RES.Cidade ,
       RES.Inicio ,
       RES.Termino ,
       RES.InicioFormatado ,
	   RES.TerminoFormatado,
       RES.IntervaloCepInicio ,
       RES.IntervaloCepTermino ,
	   CEPInicio = cast(RES.IntervaloCepInicio / 1000 as char(5)) + '-' + right('00' + cast(RES.IntervaloCepInicio % 1000 as varchar), 3),
	   CEPTermino = cast(RES.IntervaloCepTermino / 1000 as char(5)) + '-' + right('00' + cast(RES.IntervaloCepTermino % 1000 as varchar), 3)
	    FROM Recursividade RES
		ORDER BY RES.Cidade,RES.IntervaloCepInicio
		 OPTION(MAXRECURSION 0)

		