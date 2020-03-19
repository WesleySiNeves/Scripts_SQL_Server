
/*########################
# Shared locks (S)

Os bloqueios compartilhados s�o mantidos em dados que est�o sendo lidos sob o modelo de
 concorr�ncia simultaneamente pessimista. Enquanto um bloqueio compartilhado est� sendo realizado, 
 outras transa��es podem ler, mas n�o podem modificar os dados bloqueados. 
 Depois que os dados bloqueados foram lidos, o bloqueio compartilhado � liberado, 
 a menos que a transa��o seja executada com a dica de bloqueio
  (READCOMMITTED, READCOMMITTEDLOCK) ou sob o n�vel de isolamento igual 
  ou mais restritivo do que a leitura repetitiva. No exemplo, 
  voc� n�o pode ver os bloqueios compartilhados porque eles s�o usados 
  durante a dura��o da declara��o de sele��o e j� s�o lan�ados 
  quando selecionamos dados de sys.dm_tran_locks. � por isso que 
  � necess�ria uma adi��o de WITH (HOLDLOCK) para ver os bloqueios.
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