/*
https://social.technet.microsoft.com/Forums/pt-BR/e7046345-3361-4d5f-8131-0f2c228efc11/fazer-uma-consulta-com-like?forum=520&prof=required
*/

DECLARE @MinhaTabela Table
(Codigo Int Identity(1,1),
 Descricao Varchar(100))

 Insert Into @MinhaTabela Values ('USH CAPA  - MANDALA AZUL E ROSA')
 Insert Into @MinhaTabela Values ('USH CAPA  - MANDALA rosa E ROSA')

 Select * from @MinhaTabela
 Where Descricao Like '%[capa USH]%'
 
 Select * from @MinhaTabela
 Where Descricao Like '%[capa]%'
 
 Select * from @MinhaTabela
 Where Descricao Like '%[USH]%'

 Select * from @MinhaTabela
 Where Descricao Like '%[ USH]%'
 
 Select * from @MinhaTabela
 Where Descricao Like '%[capa ]%' 
 Go