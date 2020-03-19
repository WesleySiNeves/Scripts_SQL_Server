
use [Implanta]

select DISTINCT  sysobjects.name  as tabela, syscolumns.name as Nome from  
sysobjects  inner join syscolumns on sysobjects.id = syscolumns.id
where syscolumns.name ='idPessoa'










  