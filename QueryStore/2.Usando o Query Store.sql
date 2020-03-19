/* ==================================================================

--Observação: Tamanho Máximo (MB): especifica o limite para o espaço de dados que o Repositório de
 Consultas admitirá em seu banco de dados. Essa é a configuração mais importante, que afeta diretamente
  o modo de operação do Repositório de Consultas.

Conforme o Repositório de Consultas coleta consultas, planos de execução e estatísticas, 
seu tamanho no banco de dados cresce até esse limite ser atingido. Quando isso acontece,
 o Repositório de Consultas automaticamente altera o modo de operação para somente leitura e para de coletar novos dados, o que significa que a análise de desempenho não é mais precisa.

O valor padrão (100 MB) pode não ser suficiente se sua carga de trabalho gerar muitos e planos
 e consultas diferentes, ou caso você deseje manter o histórico de consulta por um período de tempo maior. Controle o uso de espaço atual e aumente o Tamanho Máximo (MB) para impedir que o Repositório de Consultas passe para o modo somente leitura. Use Management Studio ou execute o script a seguir para obter as informações mais recentes sobre o tamanho do Repositório de Consultas
 
-- ==================================================================
*/

ALTER DATABASE [13-implanta]  
SET QUERY_STORE (MAX_STORAGE_SIZE_MB = 50); 

/* ==================================================================
	
--Observação: Intervalo de Coleta de Estatísticas: define o nível de granularidade para a estatística de tempo de execução
 coletada (o padrão é 1 hora). Considere usar o valor mais baixo se você precisar de granularidade mais fina ou menos 
 tempo para detectar e mitigar os problemas, mas tenha em mente que isso afetará diretamente o tamanho dos dados do Repositório de Consultas. Use o SSMS ou Transact-SQL para definir um valor diferente para o Intervalo de Coleta de Estatísticas:
 
-- ==================================================================
*/

ALTER DATABASE [13-implanta] SET QUERY_STORE (INTERVAL_LENGTH_MINUTES = 30); 


/* ==================================================================
--Observação: 
 
Limite de Consulta Obsoleto (Dias): política de limpeza com base em tempo que controla o período de retenção de estatísticas de tempo
 de execução persistentes e consultas inativas.
Por padrão, o Repositório de Consultas está configurado para manter os dados por 30 dias, o que pode ser desnecessariamente
 longo para seu cenário.

Evite manter dados históricos que você não planeja usar. Isso reduzirá as alterações para o status somente leitura.
 O tamanho dos dados do Repositório de Consultas, bem como o tempo para detectar e reduzir o problema, serão mais previsíveis. 
 
-- ==================================================================
*/

ALTER DATABASE [13-implanta]   
SET QUERY_STORE (CLEANUP_POLICY = (STALE_QUERY_THRESHOLD_DAYS = 90));  


/* ==================================================================
--Data: 20/11/2018 
--Autor :Wesley Neves
--Observação: Modo de Limpeza com Base no Tamanho: especifica se a limpeza automática de dados ocorrerá quando o tamanho dos dados no
 Repositório de Consultas se aproximar do limite.

É altamente recomendável ativar limpeza com base no tamanho para certificar-se de que o repositório de consultas seja sempre executado no
 modo de leitura-gravação e colete sempre os dados mais recentes.
 
-- ==================================================================
*/

ALTER DATABASE [13-implanta]   
SET QUERY_STORE (SIZE_BASED_CLEANUP_MODE = AUTO);  

/* ==================================================================

--Observação: 
 Modo de Captura do Repositório de Consultas: Especifica a política de captura de consultas para o repositório de consultas.

All – captura todas as consultas. Essa é a opção padrão.

Auto – consultas incomuns e consultas com duração de compilação e execução insignificantes são ignoradas. Os limites para a duração da execução de contagem, da compilação e do tempo de execução são determinados internamente.

None – o Repositório de Consultas para de capturar novas consultas.

O script a seguir define o Modo de Captura de Consultas para Auto:
-- ==================================================================
*/


ALTER DATABASE [QueryStoreDB]   
SET QUERY_STORE (QUERY_CAPTURE_MODE = AUTO);  