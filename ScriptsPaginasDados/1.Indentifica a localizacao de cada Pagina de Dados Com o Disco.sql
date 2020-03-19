
/*Formato 
(1:384:3)
1 : aquivo , no caso é o primario,
348: Pagina
3: Slot
*/
SELECT  sys.fn_PhysLocFormatter(%%PhysLoc%%),L.* FROM Contabilidade.Lancamentos AS L
