/*########################
# OBS: Voc� pode usar as seguintes exibi��es de gerenciamento din�mico (DMVs) para exibir informa��es
sobre locks:
*/

/*########################
# OBS: 
sys.dm_tran_locks Use este DMV para ver todos os bloqueios atuais, os recursos de bloqueio, bloqueio
modo e outras informa��es relacionadas
*/

SELECT * FROM sys.dm_tran_locks AS DTL