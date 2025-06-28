
/*########################
# Shared locks (S)

Os bloqueios compartilhados são mantidos em dados que estão sendo lidos sob o modelo de
 concorrência simultaneamente pessimista. Enquanto um bloqueio compartilhado está sendo realizado, 
 outras transações podem ler, mas não podem modificar os dados bloqueados. 
 Depois que os dados bloqueados foram lidos, o bloqueio compartilhado é liberado, 
 a menos que a transação seja executada com a dica de bloqueio
  (READCOMMITTED, READCOMMITTEDLOCK) ou sob o nível de isolamento igual 
  ou mais restritivo do que a leitura repetitiva. No exemplo, 
  você não pode ver os bloqueios compartilhados porque eles são usados 
  durante a duração da declaração de seleção e já são lançados 
  quando selecionamos dados de sys.dm_tran_locks. É por isso que 
  é necessária uma adição de WITH (HOLDLOCK) para ver os bloqueios.
*/


USE WideWorldImporters

BEGIN TRAN


-- primeiro Select
SELECT * FROM  Application.People AS P
WHERE P.PersonID =2


SELECT request_type,
       resource_type,
       [Type Lock] = (CASE
                          WHEN request_mode = 'IS' THEN
                              'Shared locks (S)'
                          ELSE
                              ''
                      END
                     ),
       request_mode,
       resource_description,
       request_status,
       request_owner_type
FROM sys.dm_tran_locks
WHERE resource_type <> 'DATABASE';



-- segundo Select
SELECT * FROM  Application.People AS P WITH(HOLDLOCK)
WHERE P.PersonID =2

SELECT request_type,
       resource_type,
       [Type Lock] = (CASE
                          WHEN request_mode = 'IS' THEN
                              'Shared locks (S)'
                          ELSE
                              ''
                      END
                     ),
       request_mode,
       resource_description,
       request_status,
       request_owner_type
FROM sys.dm_tran_locks
WHERE resource_type <> 'DATABASE';


COMMIT

BEGIN TRAN 
  

-- terceiro Select
SELECT * FROM  Application.People AS P WITH(NOLOCK) --READCOMMITTEDLOCK /READCOMMITTED
WHERE P.PersonID =2



SELECT request_type,
       resource_type,
       [Type Lock] = (CASE
                          WHEN request_mode = 'IS' THEN
                              'Shared locks (S)'
                          ELSE
                              ''
                      END
                     ),
       request_mode,
       resource_description,
       request_status,
       request_owner_type
FROM sys.dm_tran_locks
WHERE resource_type <> 'DATABASE';

ROLLBACK