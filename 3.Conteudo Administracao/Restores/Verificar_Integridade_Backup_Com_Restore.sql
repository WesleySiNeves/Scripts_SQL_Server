/* ==================================================================
--Data: 16/01/2020 
--Autor :Wesley Neves
--Observação:  RESTAURAR BANCOS DE DADOS
 
 Opções em Restore

 FILELISTONLY :Esta instrução retorna uma lista dos arquivos de banco de dados e log contidos no conjunto de backup. Isso lista apenas os arquivos sem validar seu conteúdo.
 HEADERONLY :Esta instrução retorna as informações do cabeçalho de backup de todos os conjuntos de backup em um dispositivo de backup específico. Isso lista as informações do cabeçalho sem validação adicional.
 LABELONLY :Esta declaração retorna informações sobre a mídia de backup identificada pelo dispositivo de backup fornecido. Isso lista as informações da mídia sem validação adicional.	
 VERIFYONLY :Esta instrução verifica o backup, mas não executa a operação de restauração. Ele verifica se o conjunto de backup está completo e se todo o backup está legível. O objetivo da operação RESTORE VERIFYONLY é estar o mais próximo possível de uma operação de restauração real. O RESTORE VERFIYONLY executa várias verificações que incluem:
	Verificando alguns campos de cabeçalho das páginas do banco de dados, como o ID da página.
	O conjunto de backup está completo e todos os volumes são legíveis.
	A soma de verificação está correta, se presente.
	Há espaço suficiente nos discos de destino.
-- ==================================================================
*/

RESTORE VERIFYONLY
FROM DISK = 'F:\Bases\BaseLine.bak'

-- A mensagem importante está aqui :
-- The backup set on file 1 is valid.

/* ==================================================================
--Data: 16/01/2020 
--Autor :Wesley Neves
--Observação: Depois de validado podemos fazer o Restore
 
-- ==================================================================
*/
