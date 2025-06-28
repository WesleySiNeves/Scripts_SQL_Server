SELECT e.IdEstado ,
       e.IdPais ,
       e.Nome ,
       e.SiglaUF ,
       e.Ativo ,
       e.CodigoIBGE,
	   ROW_NUMBER() OVER(ORDER BY e.SiglaUF) AS Ordem FROM  Corporativo.Estados AS e