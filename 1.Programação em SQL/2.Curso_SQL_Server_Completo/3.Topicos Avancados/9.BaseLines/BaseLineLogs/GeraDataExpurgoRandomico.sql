DECLARE @DataMin DATE = DATEFROMPARTS(2019, 12, 01);

DECLARE @DataMax DATE = DATEFROMPARTS(2019, 12, 31);


DECLARE @diferenca INT = DATEDIFF(DAY, @DataMin, @DataMax);

DECLARE @Lower INT = 1; ---- The lowest random number

DECLARE @randon INT = ROUND(((@diferenca - @Lower - 1) * RAND() + @Lower), 0);


DECLARE @NewDate DATE = CAST(CONCAT('2019-12-', @randon) AS DATE);


UPDATE C
SET C.Valor = @NewDate
FROM Sistema.Configuracoes C
WHERE C.Configuracao = 'DataExecucaoExpurgo';


SELECT *
FROM Sistema.Configuracoes
WHERE Configuracao = 'DataExecucaoExpurgo';

