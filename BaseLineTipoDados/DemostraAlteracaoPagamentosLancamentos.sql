--15.2-implanta



SELECT P.IdPagamento,
       P.Numero,
       P.DataPagamento,
       L.Numero
  FROM Despesa.Pagamentos AS P
  JOIN Despesa.PagamentosLancamentos AS PL
    ON P.IdPagamento   = PL.IdPagamento
  JOIN Contabilidade.Lancamentos AS L
    ON PL.IdLancamento = L.IdLancamento
 WHERE P.IdPagamento = '59903995-50A6-4331-B4AE-0035A9D4420C';



CREATE TABLE [Despesa].[PagamentosLancamentos2]
(
[IdPagamentoLancamento] [uniqueidentifier] NOT NULL ROWGUIDCOL CONSTRAINT [DEF_DespesaPagamentosLancamentos2IdPagamentoLancamento] DEFAULT (newsequentialid()),
[IdPagamento] [uniqueidentifier] NOT NULL,
[IdLancamento] [uniqueidentifier] NOT NULL
) ON [PRIMARY]
GO
ALTER TABLE [Despesa].[PagamentosLancamentos2] ADD CONSTRAINT [PK_DespesaPagamentosLancamentos2] PRIMARY KEY CLUSTERED ([IdPagamentoLancamento]) WITH (FILLFACTOR=30)
GO
CREATE NONCLUSTERED INDEX [IdxPagamentosLancamentos2IdLancamento] ON [Despesa].[PagamentosLancamentos2] ([IdLancamento])
GO
CREATE NONCLUSTERED INDEX [IX_PagamentosLancamentos2_IdPagamento] ON [Despesa].[PagamentosLancamentos2] ([IdPagamento]) INCLUDE ([IdLancamento]) WITH (FILLFACTOR=90)
GO
ALTER TABLE [Despesa].[PagamentosLancamentos2] ADD CONSTRAINT [FK_PagamentosLancamentos2IdLancamento_LancamentosIdLancamento] FOREIGN KEY ([IdLancamento]) REFERENCES [Contabilidade].[Lancamentos] ([IdLancamento])
GO
ALTER TABLE [Despesa].[PagamentosLancamentos2] ADD CONSTRAINT [FK_PagamentosLancamentos2IdPagamento_PagamentosIdPagamento] FOREIGN KEY ([IdPagamento]) REFERENCES [Despesa].[Pagamentos] ([IdPagamento])
GO



INSERT INTO Despesa.PagamentosLancamentos2 (IdPagamentoLancamento,
                                            IdPagamento,
                                            IdLancamento)
SELECT * FROM Despesa.PagamentosLancamentos AS PL
 

 ALTER TABLE Despesa.PagamentosLancamentos2  DROP CONSTRAINT DEF_DespesaPagamentosLancamentos2IdPagamentoLancamento

 ALTER TABLE Despesa.PagamentosLancamentos2  DROP CONSTRAINT PK_DespesaPagamentosLancamentos2

  ALTER TABLE Despesa.PagamentosLancamentos2 DROP COLUMN IdPagamentoLancamento


  SELECT * FROM Despesa.PagamentosLancamentos2 AS PL

  ALTER TABLE Despesa.PagamentosLancamentos2 ADD CONSTRAINT PK_DespesaPagamentosLancamentos2 PRIMARY KEY(IdPagamento,IdLancamento)


  SELECT * FROM Despesa.Pagamentos AS P

  SELECT P.IdPagamento,
       P.Numero,
       P.DataPagamento,
       L.Numero
  FROM Despesa.Pagamentos AS P
  JOIN Despesa.PagamentosLancamentos AS PL
    ON P.IdPagamento   = PL.IdPagamento
  JOIN Contabilidade.Lancamentos AS L
    ON PL.IdLancamento = L.IdLancamento
 WHERE P.IdPagamento = '59903995-50A6-4331-B4AE-0035A9D4420C';


 SELECT * FROM  Despesa.PagamentosLancamentos AS PL;
  SELECT * FROM  Despesa.PagamentosLancamentos2 AS PL2
 
 ALTER TABLE Despesa.PagamentosLancamentos REBUILD
 ALTER TABLE Despesa.PagamentosLancamentos2 REBUILD
  
ALTER INDEX PK_DespesaPagamentosLancamentos ON Despesa.PagamentosLancamentos REBUILD

ALTER INDEX PK_DespesaPagamentosLancamentos2 ON Despesa.PagamentosLancamentos2 REBUILD

 EXEC [HealthCheck].[uspGetSizeOfObjets] @objname = N'Despesa.PagamentosLancamentos'; -- nvarchar(776)

 EXEC [HealthCheck].[uspGetSizeOfObjets] @objname = N'Despesa.PagamentosLancamentos2'; -- nvarchar(776)
                                         