

CHECKPOINT ;
GO
-- Limpa buffers (comandos add-hoc)
 DBCC DROPCLEANBUFFERS; -- deleta o cache da query 
 GO
  DBCC  FREEPROCCACHE; --deleta o plano execu��o ja feito
  GO
  DBCC FREESESSIONCACHE
  GO