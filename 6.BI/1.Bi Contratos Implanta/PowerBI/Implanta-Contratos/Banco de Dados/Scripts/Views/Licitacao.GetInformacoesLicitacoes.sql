--SELECT * FROM Licitacao.VwGetInformacoesLicitacoes

CREATE OR ALTER VIEW Licitacao.VwGetInformacoesLicitacoes
AS 
SELECT li.IdLicitacao,
	   li.Data,
       li.NumeroProtocolo,
       li.NumeroProcesso,
       li.Codigo,
       li.Numero,
       li.Objeto,
       li.IdModalidade,
	   mo.Nome AS NomeModalidadeLicitacao,
       li.IdTipo,
	   tl.Nome AS NomTipoLicitacao,
       li.IdComissao,
	   com.Nome AS NomeComissao,
       li.IdUnidade,
       li.Observacao,
       li.ModoDisputa FROM Contrato.Contratos co
JOIN Licitacao.Licitacoes li ON li.IdLicitacao = co.IdLicitacao
JOIN Licitacao.Modalidades mo ON mo.IdModalidade = li.IdModalidade
JOIN Licitacao.Tipos tl ON tl.IdTipo = li.IdTipo
JOIN Licitacao.Comissoes com ON com.IdComissao = li.IdComissao
JOIN Cadastro.Unidades uni ON uni.IdUnidade = co.IdUnidade

