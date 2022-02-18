

CREATE FUNCTION dbo.ufnRetornaSomenteInciaisDoNome ( @valor NVARCHAR(200),@separador NVARCHAR(5)  )
RETURNS NVARCHAR(200)
    BEGIN
     
	 
        DECLARE @Iniciais NVARCHAR(200) = ( SELECT
                                                COALESCE(
		(SELECT
            LEFT(SV.DATA, 1) + ' ' AS [text()]
         FROM
            dbo.SplitValues(@valor, @separador) AS SV
                                                FOR XML PATH('') ,TYPE).value('.[1]',
                                                            'VARCHAR(MAX)'),
                                                        '')
                                          );

        RETURN @Iniciais;
    END;

 SELECT * FROM  dbo.SplitValues('JOSÉ FERREIRA DE SOUZA',' ')