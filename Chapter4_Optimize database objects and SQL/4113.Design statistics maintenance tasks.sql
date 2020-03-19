/*########################
# OBS: 
O SQL Server cria e atualiza estat�sticas automaticamente para todos os �ndices e colunas
usado em uma cl�usula WHERE ou JOIN ON. Em um extremo, a atualiza��o autom�tica 
de estat�sticasO processo pode ser executado quando o banco de dados est� ocupado 
e afeta adversamente o desempenho ou, na
outro extremo, pode n�o ser executado com freq��ncia suficiente para 
uma tabela que est� sujeita a alto volume
altera��es de dados. Para essas situa��es, voc� pode desativar as op��es
 de atualiza��o autom�tica de estat�sticas
para o banco de dados e, em seguida, implementar um plano de manuten��o 
	para atualizar as estat�sticas sob demanda ou
em um hor�rio.
*/


/*########################
# OBS: Antes devemos habilitar  Agent XPs que habilita o uso do plano 
de manuten��o
*/

EXEC sp_configure 'show advanced options', 1;
GO
RECONFIGURE;
GO
EXEC sp_configure 'Agent XPs', 1;
GO
RECONFIGURE;
GO




/*########################
# OBS: Agora vamos criar um plano de manuten��o para statisticas
Coloquei o  nome "Manutencao_Statisticas"
*/



