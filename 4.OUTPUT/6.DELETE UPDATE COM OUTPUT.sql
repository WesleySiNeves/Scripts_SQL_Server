Declare @tabTeste Table (Codigo int, Descricao Varchar(100))

-- Insere os dados para o teste
Insert into @tabTeste(Codigo, Descricao) Values(1, 'Valor Antigo 1')
Insert into @tabTeste(Codigo, Descricao) Values(2, 'Valor Antigo 2')

-- Retornar o Valro antigo da coluna (Antes do update)
Update @tabTeste
Set Descricao = 'Valor Novo 1'
Output Deleted.*
Where codigo = '1'

--
-- Retornar o Valor novo da coluna (Após o Update)
Update @tabTeste
Set Descricao = 'Valor Novo 1'
Output inserted.*
Where codigo = '1'