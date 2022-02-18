
/*########################
# OBS: Script que recupera um banco de dados em Status Suspect
*/


EXEC sp_resetstatus  @DBName='Lancamentos';

ALTER DATABASE Lancamentos SET SINGLE_USER WITH ROLLBACK IMMEDIATE;

ALTER DATABASE Lancamentos SET  EMERGENCY ;
DBCC CHECKDB(Lancamentos);
/*
REPAIR_ALLOW_DATA_LOSS | REPAIR_FAST | REPAIR_REBUILD
Especifica que DBCC CHECKDB repara os erros encontrados. 
Use as op��es REPAIR apenas como um �ltimo recurso. 
O banco de dados especificado deve estar em modo de usu�rio �nico
 para usar uma das op��es de reparo a seguir.
*/



--| , { REPAIR_ALLOW_DATA_LOSS | REPAIR_FAST | REPAIR_REBUILD } ]   

/*
[ WITH     
        {    
            [ ALL_ERRORMSGS ]    
            [ , EXTENDED_LOGICAL_CHECKS ]     
            [ , NO_INFOMSGS ]    
            [ , TABLOCK ]    
            [ , ESTIMATEONLY ]    
            [ , { PHYSICAL_ONLY | DATA_PURITY } ]    
            [ , MAXDOP  = number_of_processors ]    
        }    
    ]    
*/

/*
A op��o REPAIR_ALLOW_DATA_LOSS � um recurso com suporte, mas n�o pode ser sempre a melhor op��o
 para colocar um banco de dados 
em um estado fisicamente consistente. Se for bem-sucedida, a op��o REPAIR_ALLOW_DATA_LOSS
 poder� resultar em alguma perda de dados. Na verdade, ela pode resultar em mais dados perdidos do que
 se um usu�rio restaurar o banco de dados por meio do �ltimo backup v�lido
  uma op��o emergencial de "�ltimo recurso" recomendada para uso somente se n�o for poss�vel restaurar de um backup.
*/

/*
REPAIR_FAST
Mant�m a sintaxe apenas para compatibilidade com vers�es anteriores. Nenhuma a��o de reparo � executada.
*/


/*
REPAIR_REBUILD
Executa reparos que n�o t�m nenhuma possibilidade de perda de dados. Isso pode incluir
 reparos r�pidos, como reparo de linhas perdidas em �ndices n�o clusterizados 
 e reparos mais demorados, como a recria��o de um �ndice.
Esse argumento n�o repara erros que envolvem dados FILESTREAM.

Logo e o mais Indicado
*/

DBCC CHECKDB(Lancamentos, REPAIR_REBUILD);

/*
O usu�rio deve verificar a integridade referencial do banco de dados (usando DBCC CHECKCONSTRAINTS) 
depois de usar a op��o REPAIR_ALLOW_DATA_LOSS.
*/

ALTER DATABASE WideWorldImporters SET MULTI_USER;