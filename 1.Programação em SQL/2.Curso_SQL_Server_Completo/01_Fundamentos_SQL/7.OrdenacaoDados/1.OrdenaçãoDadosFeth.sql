SELECT e.IdEstado ,
       e.IdPais ,
       e.Nome ,
       e.SiglaUF ,
       e.Ativo ,
       e.CodigoIBGE
	   FROM Corporativo.Estados AS e
	   ORDER BY e.SiglaUF	
	   OFFSET 0 ROWS  --pule nunhuma linha
	   FETCH NEXT  2 ROWS ONLY -- busca apenas 2 linhas

	   SELECT e.IdEstado ,
       e.IdPais ,
       e.Nome ,
       e.SiglaUF ,
       e.Ativo ,
       e.CodigoIBGE
	   FROM Corporativo.Estados AS e
	   ORDER BY e.SiglaUF	
	   OFFSET 2 ROWS  --pule duas linhas
	   FETCH NEXT  2 ROWS ONLY -- busca apenas 2 linhas proximas
