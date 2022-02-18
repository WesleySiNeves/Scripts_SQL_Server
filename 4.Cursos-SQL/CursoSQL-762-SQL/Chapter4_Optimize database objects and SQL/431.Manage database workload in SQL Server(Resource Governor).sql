
SELECT * FROM sys.resource_governor_configuration AS RGC
SELECT * FROM sys.dm_resource_governor_configuration AS DRGC

SELECT * FROM sys.resource_governor_external_resource_pool_affinity AS RGERPA




/*########################
# OBS:Mostra a rela��o entre v�rios componentes gerenciados pelo Resource
Governador. Um pool de recursos define os recursos f�sicos do servidor e se comporta muito
como um servidor virtual. O SQL Server cria um pool interno e um pool padr�o durante
instala��o e voc� pode adicionar pools de recursos definidos pelo usu�rio. Voc� associa um ou mais
grupos de carga de trabalho, um conjunto de solicita��es com caracter�sticas comuns, para um pool de recursos. Como
O SQL Server recebe uma solicita��o de uma sess�o, o processo de classifica��o a atribui ao
grupo de carga de trabalho com caracter�sticas correspondentes. Voc� pode ajustar os resultados deste
processo criando fun��es definidas pelo usu�rio do classificador
*/


/*########################
# OBS: Voc� deve ativar o Administrador de Recursos para come�ar a us�-lo. Voc� pode fazer isso no SQL Server
Management Studio expandindo o n� Management no Object Explorer, clicando com o bot�o direito
Resource Governor e selecionando Ativar. Como alternativa, voc� pode executar o seguinte
Declara��o T-SQL:

*/


ALTER RESOURCE GOVERNOR RECONFIGURE;
GO


/*########################
# OBS: Pools de recursos
Voc� distribui a quantidade de mem�ria, CPU e IO dispon�vel para o SQL Server entre
pools de recursos como meio de reduzir a conten��o entre cargas de trabalho. Cada pool de recursos
est� configurado com as seguintes configura��es (exceto o pool de recursos externos, conforme
*/


/*########################
# OBS: mais adiante nesta se��o):% de CPU m�nima,% de CPU m�xima,% de mem�ria m�nima e
Mem�ria M�xima%. A soma de% de CPU m�nima e% de mem�ria m�nima para todos
os pools de recursos n�o podem ser maiores que 100. Esses valores representam a m�dia garantida
quantidade desse recurso que cada pool de recursos pode usar para responder a solicita��es. o
M�ximo% de CPU e M�xima% de Mem�ria refletem o valor m�dio m�ximo para o
respectivos recursos. O SQL Server pode usar mais do que a porcentagem m�xima definida para um
recurso se estiver dispon�vel. Para evitar esse comportamento, voc� pode configurar um limite
recurso dispon�vel para o pool de recursos.
Depois de habilitar o Administrador de Recursos, o SQL Server tem os seguintes tipos de recurso:
*/


/*########################
# OBS: O SQL Server interno usa o pool de recursos internos para recursos necess�rios para executar
mecanismo de banco de dados. Voc� n�o pode alterar a configura��o de recursos para o
pool de recursos. O SQL Server cria um quando voc� habilita o Administrador de Recursos.
*/


/*########################
# OBS: Padr�o No SQL Server 2016, h� um pool de recursos para o banco de dados padr�o
opera��es e um conjunto de recursos separado para processos externos, como script R
execu��o. Esses dois pools de recursos s�o criados quando voc� ativa o recurso
Governador.

*/


/*########################
# OBS: Externo Um pool de recursos externos � um novo tipo para o SQL Server 2016 que foi
adicionado para suportar o R Services. Como a execu��o de scripts R pode ser intuitiva, a capacidade de gerenciar o consumo de recursos usando o recurso
O governador � necess�rio para proteger as opera��es normais do banco de dados. Al�m disso, voc� pode
Adicionar um pool de recursos externos para alocar recursos para outros processos externos. o
A configura��o de um pool de recursos externos � diferente dos outros tipos de pool de recursos
e inclui apenas as seguintes configura��es:% M�xima da CPU,% M�xima da Mem�ria,
e M�ximo de Processos.

*/


/*########################
# OBS: Conjunto de recursos definido pelo usu�rio Voc� pode adicionar um pool de recursos para alocar recursos para
opera��es de banco de dados relacionadas a uma carga de trabalho espec�fica
*/



/*########################
# OBS: Create user-defined resource pools
*/

CREATE RESOURCE POOL poolExamBookDaytime
WITH
(
    MIN_CPU_PERCENT = 50,
    MAX_CPU_PERCENT = 80,
    CAP_CPU_PERCENT = 90,
    AFFINITY SCHEDULER = (0 TO 3),
    MIN_MEMORY_PERCENT = 50,
    MAX_MEMORY_PERCENT = 100,
    MIN_IOPS_PER_VOLUME = 20,
    MAX_IOPS_PER_VOLUME = 100
);


GO
CREATE RESOURCE POOL poolExamBookNighttime
WITH
(
    MIN_CPU_PERCENT = 0,
    MAX_CPU_PERCENT = 50,
    CAP_CPU_PERCENT = 50,
    AFFINITY SCHEDULER = (0 TO 3),
    MIN_MEMORY_PERCENT = 5,
    MAX_MEMORY_PERCENT = 15,
    MIN_IOPS_PER_VOLUME = 45,
    MAX_IOPS_PER_VOLUME = 100
);
GO
ALTER RESOURCE GOVERNOR RECONFIGURE;
GO

/*########################
# OBS: Apos criar os Polls devemos criar os Workload groups
O Administrador de Recursos monitora os recursos consumidos em conjunto pelas sess�es em um
grupo de carga de trabalho para garantir que o consumo n�o exceda os limites definidos para
grupo de carga de trabalho e o pool de recursos ao qual ele est� designado
*/


/*########################
# OBS: Cada grupo possui um grupo de carga de trabalho predefinido, mas voc� tamb�m pode adicionar grupos de carga de trabalho ao grupo de carga de trabalho predefinido.
conjuntos de recursos padr�o, externos e definidos pelo usu�rio

*/


/*########################
# OBS: Ao configurar um grupo de carga de trabalho, conforme mostrado na Listagem 4-34, voc� pode especificar o
import�ncia relativa de um grupo de carga de trabalho em compara��o com outros grupos de
mesmo pool de recursos apenas. Voc� tamb�m pode especificar a quantidade m�xima de mem�ria ou CPU
*/



 --Create workload groups
ALTER WORKLOAD GROUP apps
WITH
(
    IMPORTANCE = HIGH,
    REQUEST_MAX_MEMORY_GRANT_PERCENT = 35,
    REQUEST_MAX_CPU_TIME_SEC = 0,          --0 = unlimited
    REQUEST_MEMORY_GRANT_TIMEOUT_SEC = 60, --seconds
    MAX_DOP = 0,                           -- uses global setting
    GROUP_MAX_REQUESTS = 1000              --0 = unlimited
) USING "poolExamBookNighttime";

CREATE WORKLOAD GROUP reports
WITH
(
    IMPORTANCE = LOW,
    REQUEST_MAX_MEMORY_GRANT_PERCENT = 25,
    REQUEST_MAX_CPU_TIME_SEC = 0,          --0 = unlimited
    REQUEST_MEMORY_GRANT_TIMEOUT_SEC = 60, --seconds
    MAX_DOP = 0,                           -- uses global setting
    GROUP_MAX_REQUESTS = 100               --0 = unlimited
)
USING "poolExamBookNighttime";
GO


ALTER RESOURCE GOVERNOR RECONFIGURE;
GO