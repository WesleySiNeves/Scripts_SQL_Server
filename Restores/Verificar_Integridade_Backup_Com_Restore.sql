/* ==================================================================
--Data: 16/01/2020 
--Autor :Wesley Neves
--Observa��o:  RESTAURAR BANCOS DE DADOS
 
 Op��es em Restore

 FILELISTONLY :Esta instru��o retorna uma lista dos arquivos de banco de dados e log contidos no conjunto de backup. Isso lista apenas os arquivos sem validar seu conte�do.
 HEADERONLY :Esta instru��o retorna as informa��es do cabe�alho de backup de todos os conjuntos de backup em um dispositivo de backup espec�fico. Isso lista as informa��es do cabe�alho sem valida��o adicional.
 LABELONLY :Esta declara��o retorna informa��es sobre a m�dia de backup identificada pelo dispositivo de backup fornecido. Isso lista as informa��es da m�dia sem valida��o adicional.	
 VERIFYONLY :Esta instru��o verifica o backup, mas n�o executa a opera��o de restaura��o. Ele verifica se o conjunto de backup est� completo e se todo o backup est� leg�vel. O objetivo da opera��o RESTORE VERIFYONLY � estar o mais pr�ximo poss�vel de uma opera��o de restaura��o real. O RESTORE VERFIYONLY executa v�rias verifica��es que incluem:
	Verificando alguns campos de cabe�alho das p�ginas do banco de dados, como o ID da p�gina.
	O conjunto de backup est� completo e todos os volumes s�o leg�veis.
	A soma de verifica��o est� correta, se presente.
	H� espa�o suficiente nos discos de destino.
-- ==================================================================
*/

RESTORE VERIFYONLY
FROM DISK = 'F:\Bases\BaseLine.bak'

-- A mensagem importante est� aqui :
-- The backup set on file 1 is valid.

/* ==================================================================
--Data: 16/01/2020 
--Autor :Wesley Neves
--Observa��o: Depois de validado podemos fazer o Restore
 
-- ==================================================================
*/
