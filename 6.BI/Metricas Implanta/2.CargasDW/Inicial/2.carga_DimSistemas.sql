
INSERT INTO [Shared].[DimSistemas]
(
    [IdSistema],
    [Descricao],
    [Area],
    [Ativo]
  
)
SELECT IdSistema,Descricao,Area,Ativo FROM Implanta.Sistemas