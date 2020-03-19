/*
Fagmenta��o de indices
*/

/* ==================================================================
--Data: 03/09/2018 
--Autor :Wesley Neves
--Observa��o: dm_db_index_physical_stats
campos importantes :
alloc_unit_type_desc: IN_ROW_DATA/  LOB_DATA/ ROW_OVERFLOW_DATA
Unidade de aloca��o LOB_DATA cont�m os dados que s�o armazenados em colunas do tipo texto,
 ntext, imagem, varchar (max), nvarchar (max), varbinary (max), e xml. 
 Para obter mais informa��es, veja Tipos de dados (Transact-SQL).

Unidade de aloca��o ROW_OVERFLOW_DATA cont�m os dados que s�o armazenados em colunas 
do tipo varchar (n), nvarchar (n), varbinary (n), e SQL _ variante que foi colocada fora da linha.
 
index_depth: N�mero de n�veis de �ndice.
index_level : N�vel atual do �ndice. 0 para n�veis folha de �ndice, heaps e unidades de aloca��o LOB_DATA ou ROW_OVERFLOW_DATA.
Maior que 0 para n�veis de �ndice nonleaf. index_level ser� o mais alto no n�vel raiz de um �ndice.

avg_fragmentation_in_percent : Fragmenta��o l�gica para �ndices ou fragmenta��o de extens�o para heaps na unidade de aloca��o IN_ROW_DATA.
fragment_count : N�mero de fragmentos no n�vel folha de uma unidade de aloca��o IN_ROW_DATA.

avg_fragment_size_in_pages   : N�mero m�dio de p�ginas em um fragmento no n�vel folha de uma unidade de aloca��o IN_ROW_DATA.
Fragmentos maiores indicam que menos E/S de disco � necess�ria para ler o mesmo n�mero de p�ginas. Por isso, 
quanto maior o valor avg_fragment_size_in_pages, melhor o desempenho de exame de intervalo.

page_count : N�mero total de p�ginas de �ndice ou dados. Para um �ndice, o n�mero total de p�ginas de �ndice no n�vel atual da �rvore b na unidade de aloca��o IN_ROW_DATA.

avg_page_space_used_in_percent : Porcentagem m�dia de espa�o de armazenamento de dados dispon�vel usada em todas as p�ginas.
coluna avg_page_space_used_in_percent indica que a p�gina est� cheia. Para se obter um �timo uso do espa�o em disco, 
esse valor dever� estar perto de 100% para um �ndice que n�o ter� muitas inser��es aleat�rias.
Entretanto, um �ndice que tem muitas inser��es aleat�rias e p�ginas muito cheias ter� um n�mero maior de divis�es de p�gina. 
Isso causa mais fragmenta��o. Por isso, para reduzir as divis�es de p�gina, o valor deve ser menor que 100%

Os valores avg_fragment_size_in_pages e avg_fragmentation_in_percent s�o inversamente proporcionais entre si. Por isso, a reconstru��o ou a reorganiza��o
 de um �ndice deve reduzir a quantidade de fragmenta��o e aumentar o tamanho do fragmento.

record_count : N�mero total de registros.
 para um heap, o n�mero de registros retornados por essa fun��o pode n�o corresponder ao n�mero de linha
 s que s�o retornados ao executar um SELECT COUNT (*) contra o heap.
  Isso porque uma linha pode conter v�rios registros. Por exemplo, em algumas situa��es de atualiza��o, uma �nica linha de heap pode ter um registro de encaminhamento e um registro encaminhado como resultado de uma opera��o de atualiza��o. Da mesma forma, a maior parte das linhas de LOB grandes � dividida em v�rios registros no armazenamento LOB_DATA.
   
min_record_size_in_bytes :Tamanho de registro m�nimo em bytes.

max_record_size_in_bytes : Tamanho de registro m�ximo em bytes.

avg_record_size_in_bytes : Tamanho de registro m�dio em bytes.
 
-- ==================================================================


*/


/*
O n�vel de fragmenta��o de um �ndice ou heap � mostrado na coluna avg_fragmentation_in_percent.
 Para heaps, o valor representa a fragmenta��o de extens�o do heap. Para �ndices, o valor representa a fragmenta��o l�gica do �ndice

 Fragmenta��o l�gica :� a porcentagem de p�ginas com problema nas p�ginas de folha de um �ndice. Uma p�gina fora de ordem � aquela cuja pr�xima p�gina f�sica alocada ao �ndice n�o � a p�gina apontada pelo ponteiro de pr�xima p�gina na p�gina de folha atual.

 Fragmenta��o de extens�o :� a porcentagem de extens�es com problema nas p�ginas de folha de um heap. Uma extens�o com problema � aquela para a qual a extens�o que cont�m a p�gina atual de um heap n�o � fisicamente a pr�xima extens�o depois da extens�o que cont�m a p�gina anterior.

 
*/

/* ==================================================================
--Data: 03/09/2018 
--Autor :Wesley Neves
--Observa��o: Importante 
 
 1)O valor de avg_fragmentation_in_percent deve ser o mais pr�ximo poss�vel de zero para um m�ximo desempenho. Por�m, valores de 0% a 10% podem ser aceit�veis

2)A fragmenta��o sozinha n�o � uma raz�o suficiente para reorganizar ou reconstruir um �ndice. 
O efeito principal da fragmenta��o � que ela reduz a velocidade da taxa de transfer�ncia read-ahead da 
p�gina durante os exames de �ndice. O resultado � tempos de resposta mais lentos. Se a carga de trabalho da
 consulta em uma tabela ou �ndice fragmentado n�o envolver exames porque a carga de trabalho � composta por pesquisas singleton,
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

