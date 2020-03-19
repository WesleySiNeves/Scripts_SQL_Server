/*
Fagmentação de indices
*/

/* ==================================================================
--Data: 03/09/2018 
--Autor :Wesley Neves
--Observação: dm_db_index_physical_stats
campos importantes :
alloc_unit_type_desc: IN_ROW_DATA/  LOB_DATA/ ROW_OVERFLOW_DATA
Unidade de alocação LOB_DATA contém os dados que são armazenados em colunas do tipo texto,
 ntext, imagem, varchar (max), nvarchar (max), varbinary (max), e xml. 
 Para obter mais informações, veja Tipos de dados (Transact-SQL).

Unidade de alocação ROW_OVERFLOW_DATA contém os dados que são armazenados em colunas 
do tipo varchar (n), nvarchar (n), varbinary (n), e SQL _ variante que foi colocada fora da linha.
 
index_depth: Número de níveis de índice.
index_level : Nível atual do índice. 0 para níveis folha de índice, heaps e unidades de alocação LOB_DATA ou ROW_OVERFLOW_DATA.
Maior que 0 para níveis de índice nonleaf. index_level será o mais alto no nível raiz de um índice.

avg_fragmentation_in_percent : Fragmentação lógica para índices ou fragmentação de extensão para heaps na unidade de alocação IN_ROW_DATA.
fragment_count : Número de fragmentos no nível folha de uma unidade de alocação IN_ROW_DATA.

avg_fragment_size_in_pages   : Número médio de páginas em um fragmento no nível folha de uma unidade de alocação IN_ROW_DATA.
Fragmentos maiores indicam que menos E/S de disco é necessária para ler o mesmo número de páginas. Por isso, 
quanto maior o valor avg_fragment_size_in_pages, melhor o desempenho de exame de intervalo.

page_count : Número total de páginas de índice ou dados. Para um índice, o número total de páginas de índice no nível atual da árvore b na unidade de alocação IN_ROW_DATA.

avg_page_space_used_in_percent : Porcentagem média de espaço de armazenamento de dados disponível usada em todas as páginas.
coluna avg_page_space_used_in_percent indica que a página está cheia. Para se obter um ótimo uso do espaço em disco, 
esse valor deverá estar perto de 100% para um índice que não terá muitas inserções aleatórias.
Entretanto, um índice que tem muitas inserções aleatórias e páginas muito cheias terá um número maior de divisões de página. 
Isso causa mais fragmentação. Por isso, para reduzir as divisões de página, o valor deve ser menor que 100%

Os valores avg_fragment_size_in_pages e avg_fragmentation_in_percent são inversamente proporcionais entre si. Por isso, a reconstrução ou a reorganização
 de um índice deve reduzir a quantidade de fragmentação e aumentar o tamanho do fragmento.

record_count : Número total de registros.
 para um heap, o número de registros retornados por essa função pode não corresponder ao número de linha
 s que são retornados ao executar um SELECT COUNT (*) contra o heap.
  Isso porque uma linha pode conter vários registros. Por exemplo, em algumas situações de atualização, uma única linha de heap pode ter um registro de encaminhamento e um registro encaminhado como resultado de uma operação de atualização. Da mesma forma, a maior parte das linhas de LOB grandes é dividida em vários registros no armazenamento LOB_DATA.
   
min_record_size_in_bytes :Tamanho de registro mínimo em bytes.

max_record_size_in_bytes : Tamanho de registro máximo em bytes.

avg_record_size_in_bytes : Tamanho de registro médio em bytes.
 
-- ==================================================================


*/


/*
O nível de fragmentação de um índice ou heap é mostrado na coluna avg_fragmentation_in_percent.
 Para heaps, o valor representa a fragmentação de extensão do heap. Para índices, o valor representa a fragmentação lógica do índice

 Fragmentação lógica :É a porcentagem de páginas com problema nas páginas de folha de um índice. Uma página fora de ordem é aquela cuja próxima página física alocada ao índice não é a página apontada pelo ponteiro de próxima página na página de folha atual.

 Fragmentação de extensão :É a porcentagem de extensões com problema nas páginas de folha de um heap. Uma extensão com problema é aquela para a qual a extensão que contém a página atual de um heap não é fisicamente a próxima extensão depois da extensão que contém a página anterior.

 
*/

/* ==================================================================
--Data: 03/09/2018 
--Autor :Wesley Neves
--Observação: Importante 
 
 1)O valor de avg_fragmentation_in_percent deve ser o mais próximo possível de zero para um máximo desempenho. Porém, valores de 0% a 10% podem ser aceitáveis

2)A fragmentação sozinha não é uma razão suficiente para reorganizar ou reconstruir um índice. 
O efeito principal da fragmentação é que ela reduz a velocidade da taxa de transferência read-ahead da 
página durante os exames de índice. O resultado é tempos de resposta mais lentos. Se a carga de trabalho da
 consulta em uma tabela ou índice fragmentado não envolver exames porque a carga de trabalho é composta por pesquisas singleton,
-- ==================================================================
*/
SELECT Idx.database_id,
       [DataBaseName] = DB_NAME(Idx.database_id),
       [TableName] = T.name,
       [IndexName] = I.name,
       Idx.partition_number,
       Idx.index_type_desc,
       Idx.alloc_unit_type_desc,
       Idx.index_depth,
       Idx.index_level,
       Idx.avg_fragmentation_in_percent,
       Idx.fragment_count,
       Idx.avg_fragment_size_in_pages,
       Idx.page_count,
       Idx.avg_page_space_used_in_percent,
       Idx.record_count,
       Idx.min_record_size_in_bytes,
       Idx.max_record_size_in_bytes,
       Idx.avg_record_size_in_bytes
FROM sys.dm_db_index_physical_stats(DB_ID(), NULL, NULL, NULL, 'SAMPLED') Idx
     JOIN
     sys.tables AS T ON Idx.object_id = T.object_id
     JOIN
     sys.indexes AS I ON Idx.object_id = I.object_id
                         AND Idx.index_id = I.index_id
WHERE Idx.avg_fragmentation_in_percent > 10.0
ORDER BY
    Idx.avg_fragmentation_in_percent DESC;
GO

