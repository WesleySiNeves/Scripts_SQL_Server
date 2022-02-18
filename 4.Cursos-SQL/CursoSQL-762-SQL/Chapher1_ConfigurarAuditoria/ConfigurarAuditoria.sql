/* ==================================================================
--Data: 09/09/2019 
--Autor :Wesley Neves
--Observa��o: A se��o final deste cap�tulo de seguran�a examina as habilidades necess�rias para implementar a auditoria no SQL Server.
 A auditoria � um recurso importante no contexto de seguran�a. Ajuda a entender a atividade do banco de dados,
  mant�m a conformidade regulat�ria e fornece informa��es  sobre discrep�ncias ou anomalias que podem indicar preocupa��es comerciais ou suspeitas de viola��es de seguran�a.
 
-- ==================================================================
*/


/* ==================================================================
--Data: 09/09/2019 
--Autor :Wesley Neves
--Observa��o: Configurar uma auditoria no SQL Server
A auditoria est� dispon�vel desde o SQL Server 2008 e permite rastrear e registrar eventos espec�ficos no mecanismo ou no n�vel do banco de dados.
 A auditoria foi projetada para ter um impacto m�nimo no mecanismo de banco de dados. Conseq�entemente,
 a auditoria aproveita eventos estendidos e s� pode gravar em destinos de alto desempenho, como arquivos e logs de eventos do Windows.
 
-- ==================================================================
*/