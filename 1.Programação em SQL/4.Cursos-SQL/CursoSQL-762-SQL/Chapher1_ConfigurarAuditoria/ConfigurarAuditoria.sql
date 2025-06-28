/* ==================================================================
--Data: 09/09/2019 
--Autor :Wesley Neves
--Observação: A seção final deste capítulo de segurança examina as habilidades necessárias para implementar a auditoria no SQL Server.
 A auditoria é um recurso importante no contexto de segurança. Ajuda a entender a atividade do banco de dados,
  mantém a conformidade regulatória e fornece informações  sobre discrepâncias ou anomalias que podem indicar preocupações comerciais ou suspeitas de violações de segurança.
 
-- ==================================================================
*/


/* ==================================================================
--Data: 09/09/2019 
--Autor :Wesley Neves
--Observação: Configurar uma auditoria no SQL Server
A auditoria está disponível desde o SQL Server 2008 e permite rastrear e registrar eventos específicos no mecanismo ou no nível do banco de dados.
 A auditoria foi projetada para ter um impacto mínimo no mecanismo de banco de dados. Conseqüentemente,
 a auditoria aproveita eventos estendidos e só pode gravar em destinos de alto desempenho, como arquivos e logs de eventos do Windows.
 
-- ==================================================================
*/