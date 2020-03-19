
SET QUOTED_IDENTIFIER ON
SET ANSI_NULLS ON
GO
ALTER FUNCTION [dbo].[ufnRetornaSomenteInciaisDoNome] ( @valor NVARCHAR(200), @separador NVARCHAR(5) = NULL)
RETURNS NVARCHAR(200)
    BEGIN
     
	 SELECT @separador = ISNULL(@separador,' ')
	 
        DECLARE @Iniciais NVARCHAR(200) = ( SELECT
                                                COALESCE(
		(SELECT
            CAST(LEFT(SV.DATA, 1) AS CHAR(1)) + ' ' AS [text()]
         FROM
            dbo.SplitValues(REPLACE(REPLACE(@valor,'<','&lt;'),'&','&amp;'), @separador) AS SV
                                                FOR XML PATH('') ,TYPE).value('.[1]','VARCHAR(MAX)'),
                                                        '')
                                          );

        RETURN @Iniciais;
    END;



GO
