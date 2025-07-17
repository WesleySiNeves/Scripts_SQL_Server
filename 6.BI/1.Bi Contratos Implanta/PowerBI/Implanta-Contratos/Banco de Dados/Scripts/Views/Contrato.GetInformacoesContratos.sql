CREATE OR ALTER VIEW Contrato.VwGetInformacoesContratos
AS
SELECT c.IdContrato,
       --c.Numero,
       c.Codigo,
       c.DataInicioVigencia,
       c.DataFinalVigencia,
       c.DataRescisao,
       --c.NumeroProtocolo,
       --c.NumeroProcesso,
       c.IdPessoaContratado,
       ISNULL(c.IdLicitacao, '00000000-0000-0000-0000-000000000000') AS IdLicitacao,
       c.IdResponsavel,
       c.IdUnidade,
       ISNULL(ir.Nome, 'Não informado') AS IndiceReajuste,
       --c.Objeto,
       --c.Observacao,
       --c.Termo,
       IIF(c.Aditivo = 0, 'Não', 'Sim') AS Aditivo,
       c.Valor,
       c.NumeroParcelas,
       ISNULL(c.IdContratoAditivado, '00000000-0000-0000-0000-000000000000') IdContratoAditivado,
       c.LimiteAcrescimo,
       IIF(c.Acrescimo = 0, 'Não', 'Sim') AS Acrescimo,
       IIF(c.Reajuste = 0, 'Não', 'Sim') AS Reajuste,
       IIF(c.Reducao = 0, 'Não', 'Sim') AS Reducao,
       IIF(c.Prazo = 0, 'Não', 'Sim') AS Prazo,
       IIF(c.Outros = 0, 'Não', 'Sim') AS Outros,
       c.NumeroAditivo,
       c.ValorParcela,
       c.DataPublicacao,
       ISNULL(c.IdModalidadeContrato, '00000000-0000-0000-0000-000000000000') AS IdModalidadeContrato,
       ISNULL(c.IdGestor, '00000000-0000-0000-0000-000000000000') AS IdGestor,
       ISNULL(c.IdUnidadeGestor, '00000000-0000-0000-0000-000000000000') AS IdUnidadeGestor,
       c.IdTipoContrato,
       c.DataAssinatura,
       StatusAndamento = 
	   CASE WHEN DataRescisao IS NOT NULL AND DataRescisao <= GETDATE()
	  THEN 'Rescindido'
					 WHEN DataInicioVigencia >= GETDATE()  THEN 'À Iniciar' 
					 WHEN  CAST(GETDATE() AS DATE) > DataFinalVigencia   THEN 'Vencido'
					 ELSE 'Vigente'
					 END,
		StatusAssinado = CASE WHEN DataAssinatura IS NULL THEN 'Não Assinado' 
		 ELSE 'Assinado' END
FROM Contrato.Contratos c
    LEFT JOIN Contrato.IndicesReajustes ir
        ON ir.IdIndiceReajuste = c.IdIndiceReajuste;
