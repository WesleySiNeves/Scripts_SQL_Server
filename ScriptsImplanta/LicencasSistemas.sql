



    ;WITH Dados
       AS (SELECT DB_NAME() AS Cliente,
                  C.Configuracao,
                  C.Valor,
                  Sistema = REPLACE(C.Configuracao, 'Licenca', ''),
                  UtilizaSistema = IIF(LEN(C.Valor) > 0, 'SIM', 'NÂO'),
                  URL = CONCAT('https://', DB_NAME(), '/', REPLACE(C.Configuracao, 'Licenca', ''))
           FROM Sistema.Configuracoes AS C
           WHERE C.Configuracao LIKE '%Licenca%'
                 AND C.Configuracao NOT LIKE '%Data%'
                 AND IIF(LEN(C.Valor) > 0, 'SIM', 'NÂO') = 'SIM'
          )
    SELECT *
    FROM Dados R
    WHERE R.Sistema IN ( 'GestaoTCU', 'Siscont', 'PortalTransparencia', 'Licitacao', 'Sispat', 'ComprasContratos',
                         'Sialm', 'Sispad', 'Siscaf', 'Sisdoc'
                       );
