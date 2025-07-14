
CREATE TABLE #Senhas
(
    [IdUsuario] UNIQUEIDENTIFIER,
    [Usuario] VARCHAR(50),
    [SenhaHash] VARCHAR(1000),
    [SenhaTipoHash] VARCHAR(50),
    [SenhaAlgoritmo] VARCHAR(50)
);


IF( NOT EXISTS(SELECT * FROM #Senhas))
BEGIN
INSERT INTO #Senhas
SELECT IdUsuario, Usuario, SenhaHash,SenhaTipoHash,SenhaAlgoritmo FROM Acesso.Usuarios
WHERE IdUsuario ='681DADD3-ACA0-48DB-A8EC-0E740FE79422'		
END

SELECT * FROM #Senhas

UPDATE Acesso.Usuarios 
SET  SenhaHash = 'C4CA4238A0B923820DCC509A6F75849B', SenhaTipoHash = NULL,SenhaAlgoritmo = NULL,
TentativasInvalidasLoginBloqueado=0,
TentativasInvalidasLoginQuantidade=0
WHERE IdUsuario ='681DADD3-ACA0-48DB-A8EC-0E740FE79422'

  
UPDATE target
SET target.SenhaHash = source.SenhaHash,
target.SenhaTipoHash= source.SenhaTipoHash,
    target.SenhaAlgoritmo = source.SenhaAlgoritmo,
	target.TentativasInvalidasLoginBloqueado = 0,
	target.TentativasInvalidasLoginQuantidade =0
FROM Acesso.Usuarios target
    JOIN #Senhas source ON source.IdUsuario = target.IdUsuario
	WHERE target.IdUsuario ='681DADD3-ACA0-48DB-A8EC-0E740FE79422'



SELECT * FROM Acesso.Usuarios WHERE IdUsuario ='681DADD3-ACA0-48DB-A8EC-0E740FE79422'
