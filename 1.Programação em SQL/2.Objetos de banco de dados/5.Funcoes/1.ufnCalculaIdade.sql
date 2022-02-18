https://social.technet.microsoft.com/Forums/pt-BR/c1d3a72a-c535-476d-b194-ae1b9f03cc6e/trigger-dando-erro-com-funo-de-calcular-idade?forum=520

-- Criando a Function F_CalcularDiferencaAnos --
Create Function F_CalcularDiferencaAnos (@DataNascimento Date) 
Returns Int 
As 
Begin
 Return (Select DATEDIFF(Year, @DataNascimento, GetDate()))
End
Go

-- Criando a Tabela1 para Teste --
Create Table Tabela1
(Codigo Int,
 DataNascimento Date,
 DiferencaComputada As (dbo.F_CalcularDiferencaAnos(DataNascimento))) -- Criando uma coluna computada com a function --
Go

-- Inserindo os dados --
Insert Into Tabela1 (Codigo, DataNascimento)
Values (1,'1980-04-28'), (2,'1981-01-28')
Go

-- Validando o resultado --
Select * from Tabela1
Go