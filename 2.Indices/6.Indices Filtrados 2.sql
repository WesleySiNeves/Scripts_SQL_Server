USE Implanta_CRFSP
 --DROP INDEX IdXLancamento ON Agenda.LancamentosFinanceiros

--CREATE UNIQUE  NONCLUSTERED INDEX IdXLancamento ON Agenda.LancamentosFinanceiros(IdLancamentoIntegracao) 
--WHERE IdLancamentoIntegracao IS NOT NULL


INSERT INTO Agenda.LancamentosFinanceiros
        ( IdLancamentoFinanceiro ,
          IdPlanoContaFinanceiroOrigem ,
          IdPlanoContaFinanceiroDestino ,
          IdPessoa ,
          DocumentoNumero ,
          PrevisaoData ,
          PrevisaoValor ,
          EfetivacaoData ,
          EfetivacaoValor ,
          CompensacaoData ,
          ProcessoNumero ,
          Historico ,
          TipoMovimento ,
          IdFormaPagamento ,
          IdTipoDocumento ,
          IdLancamentoIntegracao ,
          Origem ,
          NumeroFormaPagamento ,
          DataModificacao
        )
VALUES  ( NEWID() , -- IdLancamentoFinanceiro - uniqueidentifier
          'E9931AF5-2FB9-4664-94FD-9C3147F2DA16' , -- IdPlanoContaFinanceiroOrigem - uniqueidentifier
          '34BAF5E0-725A-4D0C-8B2A-800E73C7BE87' , -- IdPlanoContaFinanceiroDestino - uniqueidentifier
          'CAB1F9EB-BC11-4721-A61F-DCD55922861D' , -- IdPessoa - uniqueidentifier
          '3854' , -- DocumentoNumero - varchar(30)
          '2017-03-31 14:55:55.000' , -- PrevisaoData - datetime
          20855.47 , -- PrevisaoValor - numeric
          '2017-03-30 00:00:00.000' , -- EfetivacaoData - datetime
          20855.47 , -- EfetivacaoValor - numeric
          NULL, -- CompensacaoData - datetime
          '073/2017' , -- ProcessoNumero - varchar(20)
          'Pago a HOLD COMUNICACAO E SERVICOS RIBEIRAO PRETO LTDA - EPP, liquidação  do empenho 466, Cheque 337864, Nota Fiscal 3854 ref' , -- Historico - varchar(max)
          1 , -- TipoMovimento - int
          'C0797555-7E67-464C-B4BB-1101A5B4524F' , -- IdFormaPagamento - uniqueidentifier
          'C624DCAF-5E44-4237-913E-A331701CC208' , -- IdTipoDocumento - uniqueidentifier
          '12B14E4E-2FD2-4E99-AE85-350F2AD3BDD6' , -- IdLancamentoIntegracao - uniqueidentifier
          'Pagamento nº 2407' , -- Origem - varchar(100)
          '337864' , -- NumeroFormaPagamento - varchar(30)
          '2017-05-03 10:45:08.550'  -- DataModificacao - datetime
        )



