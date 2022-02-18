
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
Use as opções REPAIR apenas como um último recurso. 
O banco de dados especificado deve estar em modo de usuário único
 para usar uma das opções de reparo a seguir.
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
A opção REPAIR_ALLOW_DATA_LOSS é um recurso com suporte, mas não pode ser sempre a melhor opção
 para colocar um banco de dados 
em um estado fisicamente consistente. Se for bem-sucedida, a opção REPAIR_ALLOW_DATA_LOSS
 poderá resultar em alguma perda de dados. Na verdade, ela pode resultar em mais dados perdidos do que
 se um usuário restaurar o banco de dados por meio do último backup válido
  uma opção emergencial de "último recurso" recomendada para uso somente se não for possível restaurar de um backup.
*/

/*
REPAIR_FAST
Mantém a sintaxe apenas para compatibilidade com versões anteriores. Nenhuma ação de reparo é executada.
*/


/*
REPAIR_REBUILD
Executa reparos que não têm nenhuma possibilidade de perda de dados. Isso pode incluir
 reparos rápidos, como reparo de linhas perdidas em índices não clusterizados 
 e reparos mais demorados, como a recriação de um índice.
Esse argumento não repara erros que envolvem dados FILESTREAM.

Logo e o mais Indicado
*/

DBCC CHECKDB(Lancamentos, REPAIR_REBUILD);

/*
O usuário deve verificar a integridade referencial do banco de dados (usando DBCC CHECKCONSTRAINTS) 
depois de usar a opção REPAIR_ALLOW_DATA_LOSS.
*/

ALTER DATABASE WideWorldImporters SET MULTI_USER;