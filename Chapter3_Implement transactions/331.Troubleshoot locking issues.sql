/*########################
# OBS: Você pode usar as seguintes exibições de gerenciamento dinâmico (DMVs) para exibir informações
sobre locks:
*/

/*########################
# OBS: 
sys.dm_tran_locks Use este DMV para ver todos os bloqueios atuais, os recursos de bloqueio, bloqueio
modo e outras informações relacionadas
*/

SELECT * FROM sys.dm_tran_locks AS DTL