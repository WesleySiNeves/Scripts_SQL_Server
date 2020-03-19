
SELECT * FROM sys.resource_governor_configuration AS RGC
SELECT * FROM sys.dm_resource_governor_configuration AS DRGC

SELECT * FROM sys.resource_governor_external_resource_pool_affinity AS RGERPA




/*########################
# OBS:Mostra a relação entre vários componentes gerenciados pelo Resource
Governador. Um pool de recursos define os recursos físicos do servidor e se comporta muito
como um servidor virtual. O SQL Server cria um pool interno e um pool padrão durante
instalação e você pode adicionar pools de recursos definidos pelo usuário. Você associa um ou mais
grupos de carga de trabalho, um conjunto de solicitações com características comuns, para um pool de recursos. Como
O SQL Server recebe uma solicitação de uma sessão, o processo de classificação a atribui ao
grupo de carga de trabalho com características correspondentes. Você pode ajustar os resultados deste
processo criando funções definidas pelo usuário do classificador
*/


/*########################
# OBS: Você deve ativar o Administrador de Recursos para começar a usá-lo. Você pode fazer isso no SQL Server
Management Studio expandindo o nó Management no Object Explorer, clicando com o botão direito
Resource Governor e selecionando Ativar. Como alternativa, você pode executar o seguinte
Declaração T-SQL:

*/


ALTER RESOURCE GOVERNOR RECONFIGURE;
GO


/*########################
# OBS: Pools de recursos
Você distribui a quantidade de memória, CPU e IO disponível para o SQL Server entre
pools de recursos como meio de reduzir a contenção entre cargas de trabalho. Cada pool de recursos
está configurado com as seguintes configurações (exceto o pool de recursos externos, conforme
*/


/*########################
# OBS: mais adiante nesta seção):% de CPU mínima,% de CPU máxima,% de memória mínima e
Memória Máxima%. A soma de% de CPU mínima e% de memória mínima para todos
os pools de recursos não podem ser maiores que 100. Esses valores representam a média garantida
quantidade desse recurso que cada pool de recursos pode usar para responder a solicitações. o
Máximo% de CPU e Máxima% de Memória refletem o valor médio máximo para o
respectivos recursos. O SQL Server pode usar mais do que a porcentagem máxima definida para um
recurso se estiver disponível. Para evitar esse comportamento, você pode configurar um limite
recurso disponível para o pool de recursos.
Depois de habilitar o Administrador de Recursos, o SQL Server tem os seguintes tipos de recurso:
*/


/*########################
# OBS: O SQL Server interno usa o pool de recursos internos para recursos necessários para executar
mecanismo de banco de dados. Você não pode alterar a configuração de recursos para o
pool de recursos. O SQL Server cria um quando você habilita o Administrador de Recursos.
*/


/*########################
# OBS: Padrão No SQL Server 2016, há um pool de recursos para o banco de dados padrão
operações e um conjunto de recursos separado para processos externos, como script R
execução. Esses dois pools de recursos são criados quando você ativa o recurso
Governador.

*/


/*########################
# OBS: Externo Um pool de recursos externos é um novo tipo para o SQL Server 2016 que foi
adicionado para suportar o R Services. Como a execução de scripts R pode ser intuitiva, a capacidade de gerenciar o consumo de recursos usando o recurso
O governador é necessário para proteger as operações normais do banco de dados. Além disso, você pode
Adicionar um pool de recursos externos para alocar recursos para outros processos externos. o
A configuração de um pool de recursos externos é diferente dos outros tipos de pool de recursos
e inclui apenas as seguintes configurações:% Máxima da CPU,% Máxima da Memória,
e Máximo de Processos.

*/


/*########################
# OBS: Conjunto de recursos definido pelo usuário Você pode adicionar um pool de recursos para alocar recursos para
operações de banco de dados relacionadas a uma carga de trabalho específica
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
O Administrador de Recursos monitora os recursos consumidos em conjunto pelas sessões em um
grupo de carga de trabalho para garantir que o consumo não exceda os limites definidos para
grupo de carga de trabalho e o pool de recursos ao qual ele está designado
*/


/*########################
# OBS: Cada grupo possui um grupo de carga de trabalho predefinido, mas você também pode adicionar grupos de carga de trabalho ao grupo de carga de trabalho predefinido.
conjuntos de recursos padrão, externos e definidos pelo usuário

*/


/*########################
# OBS: Ao configurar um grupo de carga de trabalho, conforme mostrado na Listagem 4-34, você pode especificar o
importância relativa de um grupo de carga de trabalho em comparação com outros grupos de
mesmo pool de recursos apenas. Você também pode especificar a quantidade máxima de memória ou CPU
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