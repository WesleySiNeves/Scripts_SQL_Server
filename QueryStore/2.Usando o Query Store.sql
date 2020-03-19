/* ==================================================================

--Observa��o: Tamanho M�ximo (MB): especifica o limite para o espa�o de dados que o Reposit�rio de
 Consultas admitir� em seu banco de dados. Essa � a configura��o mais importante, que afeta diretamente
  o modo de opera��o do Reposit�rio de Consultas.

Conforme o Reposit�rio de Consultas coleta consultas, planos de execu��o e estat�sticas, 
seu tamanho no banco de dados cresce at� esse limite ser atingido. Quando isso acontece,
 o Reposit�rio de Consultas automaticamente altera o modo de opera��o para somente leitura e para de coletar novos dados, o que significa que a an�lise de desempenho n�o � mais precisa.

O valor padr�o (100 MB) pode n�o ser suficiente se sua carga de trabalho gerar muitos e planos
 e consultas diferentes, ou caso voc� deseje manter o hist�rico de consulta por um per�odo de tempo maior. Controle o uso de espa�o atual e aumente o Tamanho M�ximo (MB) para impedir que o Reposit�rio de Consultas passe para o modo somente leitura. Use Management Studio ou execute o script a seguir para obter as informa��es mais recentes sobre o tamanho do Reposit�rio de Consultas
 
-- ==================================================================
*/

ALTER DATABASE [13-implanta]  
SET QUERY_STORE (MAX_STORAGE_SIZE_MB = 50); 

/* ==================================================================
	
--Observa��o: Intervalo de Coleta de Estat�sticas: define o n�vel de granularidade para a estat�stica de tempo de execu��o
 coletada (o padr�o � 1 hora). Considere usar o valor mais baixo se voc� precisar de granularidade mais fina ou menos 
 tempo para detectar e mitigar os problemas, mas tenha em mente que isso afetar� diretamente o tamanho dos dados do Reposit�rio de Consultas. Use o SSMS ou Transact-SQL para definir um valor diferente para o Intervalo de Coleta de Estat�sticas:
 
-- ==================================================================
*/

ALTER DATABASE [13-implanta] SET QUERY_STORE (INTERVAL_LENGTH_MINUTES = 30); 


/* ==================================================================
--Observa��o: 
 
Limite de Consulta Obsoleto (Dias): pol�tica de limpeza com base em tempo que controla o per�odo de reten��o de estat�sticas de tempo
 de execu��o persistentes e consultas inativas.
Por padr�o, o Reposit�rio de Consultas est� configurado para manter os dados por 30 dias, o que pode ser desnecessariamente
 longo para seu cen�rio.

Evite manter dados hist�ricos que voc� n�o planeja usar. Isso reduzir� as altera��es para o status somente leitura.
 O tamanho dos dados do Reposit�rio de Consultas, bem como o tempo para detectar e reduzir o problema, ser�o mais previs�veis. 
 
-- ==================================================================
*/

ALTER DATABASE [13-implanta]   
SET QUERY_STORE (CLEANUP_POLICY = (STALE_QUERY_THRESHOLD_DAYS = 90));  


/* ==================================================================
--Data: 20/11/2018 
--Autor :Wesley Neves
--Observa��o: Modo de Limpeza com Base no Tamanho: especifica se a limpeza autom�tica de dados ocorrer� quando o tamanho dos dados no
 Reposit�rio de Consultas se aproximar do limite.

� altamente recomend�vel ativar limpeza com base no tamanho para certificar-se de que o reposit�rio de consultas seja sempre executado no
 modo de leitura-grava��o e colete sempre os dados mais recentes.
 
-- ==================================================================
*/

ALTER DATABASE [13-implanta]   
SET QUERY_STORE (SIZE_BASED_CLEANUP_MODE = AUTO);  

/* ==================================================================

--Observa��o: 
 Modo de Captura do Reposit�rio de Consultas: Especifica a pol�tica de captura de consultas para o reposit�rio de consultas.

All � captura todas as consultas. Essa � a op��o padr�o.

Auto � consultas incomuns e consultas com dura��o de compila��o e execu��o insignificantes s�o ignoradas. Os limites para a dura��o da execu��o de contagem, da compila��o e do tempo de execu��o s�o determinados internamente.

None � o Reposit�rio de Consultas para de capturar novas consultas.

O script a seguir define o Modo de Captura de Consultas para Auto:
-- ==================================================================
*/


ALTER DATABASE [QueryStoreDB]   
SET QUERY_STORE (QUERY_CAPTURE_MODE = AUTO);  