



IF (NOT EXISTS (
               SELECT *
               FROM Sistema.Configuracoes AS C
               WHERE C.Configuracao = 'DataExecucaoExpurgo'
               )
   )
BEGIN
    INSERT INTO Sistema.Configuracoes (
                                      CodConfiguracao,
                                      CodSistema,
                                      Modulo,
                                      Configuracao,
                                      Valor,
                                      Ano
                                      )
    VALUES (NEWID(),                                -- CodConfiguracao - uniqueidentifier
            '00000000-0000-0000-0000-000000000000', -- CodSistema - uniqueidentifier
            'Global',                               -- Modulo - varchar(100)
            'DataExecucaoExpurgo',                  -- Configuracao - varchar(100)
            '2019-12-31',                           -- Valor - varchar(max)
            0                                       -- Ano - int
           );



END;
ELSE
BEGIN
    UPDATE C
    SET C.Valor = '2019-12-31'
    FROM Sistema.Configuracoes AS C
    WHERE C.Configuracao = 'DataExecucaoExpurgo';
END;

