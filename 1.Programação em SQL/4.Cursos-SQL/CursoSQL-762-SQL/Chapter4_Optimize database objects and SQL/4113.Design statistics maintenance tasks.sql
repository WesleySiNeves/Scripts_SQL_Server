/*########################
# OBS: 
O SQL Server cria e atualiza estatísticas automaticamente para todos os índices e colunas
usado em uma cláusula WHERE ou JOIN ON. Em um extremo, a atualização automática 
de estatísticasO processo pode ser executado quando o banco de dados está ocupado 
e afeta adversamente o desempenho ou, na
outro extremo, pode não ser executado com freqüência suficiente para 
uma tabela que está sujeita a alto volume
alterações de dados. Para essas situações, você pode desativar as opções
 de atualização automática de estatísticas
para o banco de dados e, em seguida, implementar um plano de manutenção 
	para atualizar as estatísticas sob demanda ou
em um horário.
*/


/*########################
# OBS: Antes devemos habilitar  Agent XPs que habilita o uso do plano 
de manutenção
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
# OBS: Agora vamos criar um plano de manutenção para statisticas
Coloquei o  nome "Manutencao_Statisticas"
*/



