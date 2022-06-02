

CREATE FUNCTION Contabilidade.ufnBuscaCodigoContaPai (@codigoConta VARCHAR(128))
RETURNS VARCHAR(128)
AS
BEGIN

    RETURN IIF(
               (SUBSTRING(@codigoConta, 0, LEN(@codigoConta) - CHARINDEX('.', REVERSE(@codigoConta)) + 1)) = @codigoConta,
               NULL,
               (SUBSTRING(@codigoConta, 0, LEN(@codigoConta) - CHARINDEX('.', REVERSE(@codigoConta)) + 1)));
END;


GO



CREATE FUNCTION Contabilidade.ufnBuscaIdPlanoContaPai (@codigoConta VARCHAR(128))
RETURNS UNIQUEIDENTIFIER
AS
BEGIN
    RETURN (   SELECT PC.IdPlanoConta
                 FROM Contabilidade.PlanoContas AS PC
                WHERE PC.Codigo = Contabilidade.ufnBuscaCodigoContaPai(@codigoConta))
END;


GO



SELECT PC.IdPlanoConta,
       PC.IdPlanoContaPai,
       PC.Grupo,
       PC.Codigo,
	   [Codigo Pai] =Contabilidade.ufnBuscaCodigoContaPai(pc.Codigo),
	   [IdPai] = Contabilidade.ufnBuscaIdPlanoContaPai(pc.Codigo),
       PC.CodigoResumido,
       PC.Nome,
       PC.Sistema,
       PC.Repasse,
       PC.Agrupador,
       PC.AtributoFinanceiro,
       PC.AtributoPermanenteCredito,
       PC.AtributoPermanenteDebito FROM  Contabilidade.PlanoContas AS PC
	   
	   


GO





