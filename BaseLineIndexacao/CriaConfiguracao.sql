


IF( NOT EXISTS(
SELECT * FROM  Sistema.Configuracoes AS C
WHERE C.Configuracao ='DataStartMonitoramentoHealthCheck'))
BEGIN
		
		INSERT INTO Sistema.Configuracoes (CodConfiguracao,
		                                   CodSistema,
		                                   Modulo,
		                                   Configuracao,
		                                   Valor,
		                                   Ano)
		VALUES (NEWID(), -- CodConfiguracao - uniqueidentifier
		        '00000000-0000-0000-0000-000000000000', -- CodSistema - uniqueidentifier
		        'Global', -- Modulo - varchar(100)
		        'DataStartMonitoramentoHealthCheck', -- Configuracao - varchar(100)
		        CONVERT(VARCHAR, GETDATE(), 20) , -- Valor - varchar(max)
		        0 -- Ano - int
		    )

END

