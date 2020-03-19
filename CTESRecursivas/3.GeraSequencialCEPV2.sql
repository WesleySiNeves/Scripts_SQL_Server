declare @Tabela table
(Codigo int, Cidade varchar(40), Inicio char(9), Fim char(9));

insert into @Tabela values
(1, 'Belo Horizonte', '30000-000', '35000-000');

with CTE_Rec as
(
    select
        Cidade,
        cast(left(Fim, 5) + right(Fim, 3) as int) as Fim,
        cast(left(Inicio, 5) + right(Inicio, 3) as int) as Cep
    from @Tabela
    
    union all
    
    select
        Cidade,
        Fim,
        Cep + 1
    from CTE_rec
    where
        Cep < Fim
)

select 
    Cidade,
    cast(Cep / 1000 as char(5)) + '-' + right('00' + cast(Cep % 1000 as varchar), 3) as Cep
from CTE_Rec
OPTION (MAXRECURSION 0);