

/* ==================================================================
--Data: 17/09/2018 
--Autor :Wesley Neves
--Observação: Caso de erro no provider OLEDB 
versão 64 bits :https://www.microsoft.com/en-us/download/confirmation.aspx?id=13255
				https://www.microsoft.com/pt-br/download/details.aspx?id=39358
-- ==================================================================
*/
USE master;

EXEC sys.sp_configure 'show advanced options', 1;
GO
RECONFIGURE WITH OVERRIDE;
GO
EXEC sys.sp_configure 'Ad Hoc Distributed Queries', 1;
GO
RECONFIGURE WITH OVERRIDE;
GO

EXEC master.sys.sp_MSset_oledb_prop N'Microsoft.ACE.OLEDB.16.0',
                                    N'AllowInProcess',
                                    1;
GO
EXEC master.sys.sp_MSset_oledb_prop N'Microsoft.ACE.OLEDB.16.0',
                                    N'DynamicParameters',
                                    1;

GO

USE Implanta;

GO

																	--Nome Da Planilha     -- Nome da aba do excel
SELECT *
INTO ResultBens
FROM
    OPENROWSET('Microsoft.ACE.OLEDB.15.0', 'Excel 12.0;Database=D:\BensCRO.xlsx', [CRODF$]);

	


--- Utilizando OPENDATASOURCE			--Nome Da Planilha									 -- Nome da aba do excel
SELECT *
INTO ResultBens
FROM OPENDATASOURCE('Microsoft.ACE.OLEDB.12.0', 'Data Source=D:\Geral\BensCRO.xls;Extended Properties=Excel 12.0')
     ...[CRODF$];


