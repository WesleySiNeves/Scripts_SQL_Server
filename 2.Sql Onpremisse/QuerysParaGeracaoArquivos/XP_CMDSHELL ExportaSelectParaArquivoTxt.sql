

-- ==================================================================
--Observação: necessita de permissão para executar xp_cmdshell
-- ==================================================================
USE Implanta
--Abre a sp para exportar a query para o formato txt
--Paramentros
--queryout e o caminho fisico da onde vai ficar o arquivo a ser exportado
--(-S) servidor NO nesse caso e local
--(-u) -Usuario que nesse caso e o (sa)
--(-p) e a senha 
--(-T) o  separador de colunas e a (virgula)
--(-R) separador de linha 
--(-w) e para a formatação de saida ser em (UNICODE)


EXEC master.dbo.XP_CMDSHELL  'bcp "SELECT P.NomeRazaoSocial,p.CPFCNPJ,p.TipoPessoaFisica FROM Cadastro.Pessoas AS P ORDER BY P.NomeRazaoSocial" 
queryout D:\favorecidos.txt -s (DS11\MSSQLSERVER2017)  -t -r \n -w'




