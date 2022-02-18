IF (NOT EXISTS (
               SELECT I.name,
                      C.*
               FROM sys.indexes AS I
                    JOIN
                    sys.index_columns AS IC ON I.object_id = IC.object_id
                                               AND I.index_id = IC.index_id
                    JOIN
                    sys.columns AS C ON I.object_id = C.object_id
               WHERE I.object_id = 3531096
                     AND C.name = 'IdPlanoContaBanco'
                     AND I.type > 1
                     AND IC.key_ordinal = 1
               )
   )
BEGIN
    CREATE NONCLUSTERED INDEX [IX_ReceitaRecebimentosIdPlanoContaBancoDeducaoValor]
        ON Receita.Recebimentos (IdPlanoContaBanco, Deducao, Valor)
        INCLUDE (IdRecebimento, IdPlanoConta, DataRecebimento);
END;
IF (NOT EXISTS (
               SELECT I.name,
                      C.*
               FROM sys.indexes AS I
                    JOIN
                    sys.index_columns AS IC ON I.object_id = IC.object_id
                                               AND I.index_id = IC.index_id
                    JOIN
                    sys.columns AS C ON I.object_id = C.object_id
               WHERE I.object_id = 25767149
                     AND C.name = 'IdEmpenho'
                     AND I.type > 1
                     AND IC.key_ordinal = 1
               )
   )
BEGIN
    CREATE NONCLUSTERED INDEX [IX_DespesaAnulacoesIdEmpenho]
        ON Despesa.Anulacoes (IdEmpenho);
END;
IF (NOT EXISTS (
               SELECT I.name,
                      C.*
               FROM sys.indexes AS I
                    JOIN
                    sys.index_columns AS IC ON I.object_id = IC.object_id
                                               AND I.index_id = IC.index_id
                    JOIN
                    sys.columns AS C ON I.object_id = C.object_id
               WHERE I.object_id = 57767263
                     AND C.name = 'IdAnulacao'
                     AND I.type > 1
                     AND IC.key_ordinal = 1
               )
   )
BEGIN
    CREATE NONCLUSTERED INDEX [IX_DespesaAnulacoesCentroCustosIdAnulacao]
        ON Despesa.AnulacoesCentroCustos (IdAnulacao)
        INCLUDE (IdCentroCusto, Valor);
END;
IF (NOT EXISTS (
               SELECT I.name,
                      C.*
               FROM sys.indexes AS I
                    JOIN
                    sys.index_columns AS IC ON I.object_id = IC.object_id
                                               AND I.index_id = IC.index_id
                    JOIN
                    sys.columns AS C ON I.object_id = C.object_id
               WHERE I.object_id = 76579361
                     AND C.name = 'IdRegistroEmpresa'
                     AND I.type > 1
                     AND IC.key_ordinal = 1
               )
   )
BEGIN
    CREATE NONCLUSTERED INDEX [IX_ResponsabilidadesTecnicas_IdRegistroEmpresa]
        ON Registro.ResponsabilidadesTecnicas (IdRegistroEmpresa)
        INCLUDE
    (IdResponsabilidadeTecnica,
     DataInicio,
     DataTermino,
     IdResponsabilidadeTipo,
     IdResponsabilidadeSetor,
     Observacao,
     IdRegistroProfissional,
     DataAtualizacao,
     NomeUsuarioCriacao,
     DataCriacao,
     NomeUnidadeCriacao,
     NomeUsuarioAtualizacao,
     NomeUnidadeAtualizacao
    )   ;
END;
IF (NOT EXISTS (
               SELECT I.name,
                      C.*
               FROM sys.indexes AS I
                    JOIN
                    sys.index_columns AS IC ON I.object_id = IC.object_id
                                               AND I.index_id = IC.index_id
                    JOIN
                    sys.columns AS C ON I.object_id = C.object_id
               WHERE I.object_id = 76579361
                     AND C.name = 'IdRegistroProfissional'
                     AND I.type > 1
                     AND IC.key_ordinal = 1
               )
   )
BEGIN
    CREATE NONCLUSTERED INDEX [IX_ResponsabilidadesTecnicas_IdRegistroProfissional]
        ON Registro.ResponsabilidadesTecnicas (IdRegistroProfissional)
        INCLUDE
    (IdResponsabilidadeTecnica,
     DataInicio,
     DataTermino,
     IdResponsabilidadeTipo,
     IdResponsabilidadeSetor,
     Observacao,
     DataAtualizacao,
     NomeUsuarioCriacao,
     DataCriacao,
     NomeUnidadeCriacao,
     NomeUsuarioAtualizacao,
     NomeUnidadeAtualizacao,
     IdRegistroEmpresa
    )   ;
END;
IF (NOT EXISTS (
               SELECT I.name,
                      C.*
               FROM sys.indexes AS I
                    JOIN
                    sys.index_columns AS IC ON I.object_id = IC.object_id
                                               AND I.index_id = IC.index_id
                    JOIN
                    sys.columns AS C ON I.object_id = C.object_id
               WHERE I.object_id = 87007391
                     AND C.name = 'IdTipoProcesso'
                     AND I.type > 1
                     AND IC.key_ordinal = 1
               )
   )
BEGIN
    CREATE NONCLUSTERED INDEX [IX_Processos_IdTipoProcessoIdClassificacaoProcesso]
        ON Processo.Processos (IdTipoProcesso, IdClassificacaoProcesso)
        INCLUDE (IdProcesso, NumeroProcesso, IdEtapa);
END;
IF (NOT EXISTS (
               SELECT I.name,
                      C.*
               FROM sys.indexes AS I
                    JOIN
                    sys.index_columns AS IC ON I.object_id = IC.object_id
                                               AND I.index_id = IC.index_id
                    JOIN
                    sys.columns AS C ON I.object_id = C.object_id
               WHERE I.object_id = 87007391
                     AND C.name = 'IdTipoProcesso'
                     AND I.type > 1
                     AND IC.key_ordinal = 1
               )
   )
BEGIN
    CREATE NONCLUSTERED INDEX [nci_wi_Processos_1929AB0E8C5DDEE8BAAA2A70CC571F7C]
        ON Processo.Processos (IdTipoProcesso)
        INCLUDE (IdEtapa, DataVencimentoPorProcessoClassificacao, DataVencimentoPorEtapa);
END;
IF (NOT EXISTS (
               SELECT I.name,
                      C.*
               FROM sys.indexes AS I
                    JOIN
                    sys.index_columns AS IC ON I.object_id = IC.object_id
                                               AND I.index_id = IC.index_id
                    JOIN
                    sys.columns AS C ON I.object_id = C.object_id
               WHERE I.object_id = 103671417
                     AND C.name = 'CPFCNPJ'
                     AND I.type > 1
                     AND IC.key_ordinal = 1
               )
   )
BEGIN
    CREATE NONCLUSTERED INDEX [IX_Pessoas_CPFCNPJ]
        ON Cadastro.Pessoas (CPFCNPJ);
END;
IF (NOT EXISTS (
               SELECT I.name,
                      C.*
               FROM sys.indexes AS I
                    JOIN
                    sys.index_columns AS IC ON I.object_id = IC.object_id
                                               AND I.index_id = IC.index_id
                    JOIN
                    sys.columns AS C ON I.object_id = C.object_id
               WHERE I.object_id = 103671417
                     AND C.name = 'NomeRazaoSocial'
                     AND I.type > 1
                     AND IC.key_ordinal = 1
               )
   )
BEGIN
    CREATE NONCLUSTERED INDEX [IX_Pessoas_NomeRazaoSocialEstrangeiroAtivoCPFCNPJ]
        ON Cadastro.Pessoas (NomeRazaoSocial, Estrangeiro, Ativo, CPFCNPJ);
END;
IF (NOT EXISTS (
               SELECT I.name,
                      C.*
               FROM sys.indexes AS I
                    JOIN
                    sys.index_columns AS IC ON I.object_id = IC.object_id
                                               AND I.index_id = IC.index_id
                    JOIN
                    sys.columns AS C ON I.object_id = C.object_id
               WHERE I.object_id = 103671417
                     AND C.name = 'TipoPessoaFisica'
                     AND I.type > 1
                     AND IC.key_ordinal = 1
               )
   )
BEGIN
    CREATE NONCLUSTERED INDEX [IX_PessoasTipoPessoaFisica]
        ON Cadastro.Pessoas (TipoPessoaFisica)
        INCLUDE (IdPessoa);
END;
IF (NOT EXISTS (
               SELECT I.name,
                      C.*
               FROM sys.indexes AS I
                    JOIN
                    sys.index_columns AS IC ON I.object_id = IC.object_id
                                               AND I.index_id = IC.index_id
                    JOIN
                    sys.columns AS C ON I.object_id = C.object_id
               WHERE I.object_id = 103671417
                     AND C.name = 'NomeRazaoSocial'
                     AND I.type > 1
                     AND IC.key_ordinal = 1
               )
   )
BEGIN
    CREATE NONCLUSTERED INDEX [IX_Pessoas_NomeRazaoSocial]
        ON Cadastro.Pessoas (NomeRazaoSocial)
        INCLUDE (TipoPessoaFisica, CPFCNPJ, FlagsBitwisePessoa, VisivelSomenteSiscaf, Ativo, EspecializacaoValor);
END;
IF (NOT EXISTS (
               SELECT I.name,
                      C.*
               FROM sys.indexes AS I
                    JOIN
                    sys.index_columns AS IC ON I.object_id = IC.object_id
                                               AND I.index_id = IC.index_id
                    JOIN
                    sys.columns AS C ON I.object_id = C.object_id
               WHERE I.object_id = 119007505
                     AND C.name = 'IdProcesso'
                     AND I.type > 1
                     AND IC.key_ordinal = 1
               )
   )
BEGIN
    CREATE NONCLUSTERED INDEX [IdxProcessoAdmIdProcesso]
        ON Processo.ProcessosAdministrativos (IdProcesso);
END;
IF (NOT EXISTS (
               SELECT I.name,
                      C.*
               FROM sys.indexes AS I
                    JOIN
                    sys.index_columns AS IC ON I.object_id = IC.object_id
                                               AND I.index_id = IC.index_id
                    JOIN
                    sys.columns AS C ON I.object_id = C.object_id
               WHERE I.object_id = 119007505
                     AND C.name = 'IdPessoaInstrutor'
                     AND I.type > 1
                     AND IC.key_ordinal = 1
               )
   )
BEGIN
    CREATE NONCLUSTERED INDEX [IdxProcessoAdmInstrutor]
        ON Processo.ProcessosAdministrativos (IdPessoaInstrutor);
END;
IF (NOT EXISTS (
               SELECT I.name,
                      C.*
               FROM sys.indexes AS I
                    JOIN
                    sys.index_columns AS IC ON I.object_id = IC.object_id
                                               AND I.index_id = IC.index_id
                    JOIN
                    sys.columns AS C ON I.object_id = C.object_id
               WHERE I.object_id = 119007505
                     AND C.name = 'IdPessoaRelator'
                     AND I.type > 1
                     AND IC.key_ordinal = 1
               )
   )
BEGIN
    CREATE NONCLUSTERED INDEX [IdxProcessoAdmRelator]
        ON Processo.ProcessosAdministrativos (IdPessoaRelator);
END;
IF (NOT EXISTS (
               SELECT I.name,
                      C.*
               FROM sys.indexes AS I
                    JOIN
                    sys.index_columns AS IC ON I.object_id = IC.object_id
                                               AND I.index_id = IC.index_id
                    JOIN
                    sys.columns AS C ON I.object_id = C.object_id
               WHERE I.object_id = 128159652
                     AND C.name = 'IdPessoaJuridica'
                     AND I.type > 1
                     AND IC.key_ordinal = 1
               )
   )
BEGIN
    CREATE NONCLUSTERED INDEX [IX_RegistroEmpresasIdPessoaJuridica]
        ON Registro.Empresas (IdPessoaJuridica);
END;
IF (NOT EXISTS (
               SELECT I.name,
                      C.*
               FROM sys.indexes AS I
                    JOIN
                    sys.index_columns AS IC ON I.object_id = IC.object_id
                                               AND I.index_id = IC.index_id
                    JOIN
                    sys.columns AS C ON I.object_id = C.object_id
               WHERE I.object_id = 135671531
                     AND C.name = 'IdAreaAtuacao'
                     AND I.type > 1
                     AND IC.key_ordinal = 1
               )
   )
BEGIN
    CREATE NONCLUSTERED INDEX [IX_PessoasAreasAtuacoes]
        ON Cadastro.PessoasAreasAtuacoes (IdAreaAtuacao, IdPessoa);
END;
IF (NOT EXISTS (
               SELECT I.name,
                      C.*
               FROM sys.indexes AS I
                    JOIN
                    sys.index_columns AS IC ON I.object_id = IC.object_id
                                               AND I.index_id = IC.index_id
                    JOIN
                    sys.columns AS C ON I.object_id = C.object_id
               WHERE I.object_id = 135671531
                     AND C.name = 'IdPessoa'
                     AND I.type > 1
                     AND IC.key_ordinal = 1
               )
   )
BEGIN
    CREATE NONCLUSTERED INDEX [IX_PessoasAreasAtuacoes_IdPessoaIdPessoaAreaAtuacao]
        ON Cadastro.PessoasAreasAtuacoes (IdPessoa, IdPessoaAreaAtuacao);
END;
IF (NOT EXISTS (
               SELECT I.name,
                      C.*
               FROM sys.indexes AS I
                    JOIN
                    sys.index_columns AS IC ON I.object_id = IC.object_id
                                               AND I.index_id = IC.index_id
                    JOIN
                    sys.columns AS C ON I.object_id = C.object_id
               WHERE I.object_id = 143339575
                     AND C.name = 'IdPessoa'
                     AND I.type > 1
                     AND IC.key_ordinal = 1
               )
   )
BEGIN
    CREATE NONCLUSTERED INDEX [IX_Documentos_IdPessoa]
        ON Documento.Documentos (IdPessoa);
END;
IF (NOT EXISTS (
               SELECT I.name,
                      C.*
               FROM sys.indexes AS I
                    JOIN
                    sys.index_columns AS IC ON I.object_id = IC.object_id
                                               AND I.index_id = IC.index_id
                    JOIN
                    sys.columns AS C ON I.object_id = C.object_id
               WHERE I.object_id = 143339575
                     AND C.name = 'IdPessoa'
                     AND I.type > 1
                     AND IC.key_ordinal = 1
               )
   )
BEGIN
    CREATE NONCLUSTERED INDEX [IX_Documentos_IdPessoaDetalhado]
        ON Documento.Documentos (IdPessoa)
        INCLUDE
    (IdTipoDocumento,
     IdOrigem,
     IdFormaEntrega,
     IdNivelSigilo,
     IdSituacaoDocumento,
     ComplementoRemetenteDestinatario,
     NumeroDocumento,
     NumeroDocumentoAutomatico,
     NumeroDocumentoObservacao,
     NumeroProtocolo,
     NumeroProtocoloAutomatico,
     NumeroProtocoloObservacao,
     DataDocumento,
     DataPrevisao,
     Assunto,
     CaminhoFisico,
     CaminhoEletronico,
     PalavrasChaves,
     Observacoes,
     NomeUsuarioCriacao,
     DataCriacao,
     DataAtualizacao,
     NomeUnidadeCriacao,
     NomeUsuarioAtualizacao,
     NomeUnidadeAtualizacao,
     NumeroProtocoloExterno,
     IdPessoaConselhoOrigem,
     OrigemCriacaoSistema,
     OrigemCriacaoModulo
    )   ;
END;
IF (NOT EXISTS (
               SELECT I.name,
                      C.*
               FROM sys.indexes AS I
                    JOIN
                    sys.index_columns AS IC ON I.object_id = IC.object_id
                                               AND I.index_id = IC.index_id
                    JOIN
                    sys.columns AS C ON I.object_id = C.object_id
               WHERE I.object_id = 143339575
                     AND C.name = 'NumeroDocumento'
                     AND I.type > 1
                     AND IC.key_ordinal = 1
               )
   )
BEGIN
    CREATE NONCLUSTERED INDEX [IX_Documentos_NumeroDocumento]
        ON Documento.Documentos (NumeroDocumento);
END;
IF (NOT EXISTS (
               SELECT I.name,
                      C.*
               FROM sys.indexes AS I
                    JOIN
                    sys.index_columns AS IC ON I.object_id = IC.object_id
                                               AND I.index_id = IC.index_id
                    JOIN
                    sys.columns AS C ON I.object_id = C.object_id
               WHERE I.object_id = 143339575
                     AND C.name = 'NumeroProtocoloAutomatico'
                     AND I.type > 1
                     AND IC.key_ordinal = 1
               )
   )
BEGIN
    CREATE NONCLUSTERED INDEX [IX_Documentos_NumeroProtocoloAutomatico]
        ON Documento.Documentos (NumeroProtocoloAutomatico)
        INCLUDE (NumeroProtocolo, DataCriacao);
END;
IF (NOT EXISTS (
               SELECT I.name,
                      C.*
               FROM sys.indexes AS I
                    JOIN
                    sys.index_columns AS IC ON I.object_id = IC.object_id
                                               AND I.index_id = IC.index_id
                    JOIN
                    sys.columns AS C ON I.object_id = C.object_id
               WHERE I.object_id = 143339575
                     AND C.name = 'NumeroProtocolo'
                     AND I.type > 1
                     AND IC.key_ordinal = 1
               )
   )
BEGIN
    CREATE NONCLUSTERED INDEX [IX_Documentos_NumeroProtocoloNumeroProtocoloAutomatico]
        ON Documento.Documentos (NumeroProtocolo, NumeroProtocoloAutomatico);
END;
IF (NOT EXISTS (
               SELECT I.name,
                      C.*
               FROM sys.indexes AS I
                    JOIN
                    sys.index_columns AS IC ON I.object_id = IC.object_id
                                               AND I.index_id = IC.index_id
                    JOIN
                    sys.columns AS C ON I.object_id = C.object_id
               WHERE I.object_id = 151007619
                     AND C.name = 'IdProcesso'
                     AND I.type > 1
                     AND IC.key_ordinal = 1
               )
   )
BEGIN
    CREATE NONCLUSTERED INDEX [Idx_ProcessoAndamento_IdProcesso]
        ON Processo.ProcessosAndamentos (IdProcesso);
END;
IF (NOT EXISTS (
               SELECT I.name,
                      C.*
               FROM sys.indexes AS I
                    JOIN
                    sys.index_columns AS IC ON I.object_id = IC.object_id
                                               AND I.index_id = IC.index_id
                    JOIN
                    sys.columns AS C ON I.object_id = C.object_id
               WHERE I.object_id = 167671645
                     AND C.name = 'IdPessoa'
                     AND I.type > 1
                     AND IC.key_ordinal = 1
               )
   )
BEGIN
    CREATE NONCLUSTERED INDEX [UNQ_CadastroPessoasFisicasIdPessoa]
        ON Cadastro.PessoasFisicas (IdPessoa);
END;
IF (NOT EXISTS (
               SELECT I.name,
                      C.*
               FROM sys.indexes AS I
                    JOIN
                    sys.index_columns AS IC ON I.object_id = IC.object_id
                                               AND I.index_id = IC.index_id
                    JOIN
                    sys.columns AS C ON I.object_id = C.object_id
               WHERE I.object_id = 175339689
                     AND C.name = 'IdArquivoAnexo'
                     AND I.type > 1
                     AND IC.key_ordinal = 1
               )
   )
BEGIN
    CREATE NONCLUSTERED INDEX [nci_wi_DocumentosAssinaturas_E9528CAE75BB7C4126546D631F05DF0F]
        ON Documento.DocumentosAssinaturas (IdArquivoAnexo);
END;
IF (NOT EXISTS (
               SELECT I.name,
                      C.*
               FROM sys.indexes AS I
                    JOIN
                    sys.index_columns AS IC ON I.object_id = IC.object_id
                                               AND I.index_id = IC.index_id
                    JOIN
                    sys.columns AS C ON I.object_id = C.object_id
               WHERE I.object_id = 180911716
                     AND C.name = 'IdProcessoPessoaPrincipal'
                     AND I.type > 1
                     AND IC.key_ordinal = 1
               )
   )
BEGIN
    CREATE NONCLUSTERED INDEX [IX_FiscalizacaoProcessosEnquadramentosLegaisIdProcessoPessoaPrincipal]
        ON Fiscalizacao.ProcessosEnquadramentosLegais (IdProcessoPessoaPrincipal);
END;
IF (NOT EXISTS (
               SELECT I.name,
                      C.*
               FROM sys.indexes AS I
                    JOIN
                    sys.index_columns AS IC ON I.object_id = IC.object_id
                                               AND I.index_id = IC.index_id
                    JOIN
                    sys.columns AS C ON I.object_id = C.object_id
               WHERE I.object_id = 180911716
                     AND C.name = 'IdProcesso'
                     AND I.type > 1
                     AND IC.key_ordinal = 1
               )
   )
BEGIN
    CREATE NONCLUSTERED INDEX [IX_ProcessosEnquadramentosLegais_IdProcesso]
        ON Fiscalizacao.ProcessosEnquadramentosLegais (IdProcesso);
END;
IF (NOT EXISTS (
               SELECT I.name,
                      C.*
               FROM sys.indexes AS I
                    JOIN
                    sys.index_columns AS IC ON I.object_id = IC.object_id
                                               AND I.index_id = IC.index_id
                    JOIN
                    sys.columns AS C ON I.object_id = C.object_id
               WHERE I.object_id = 182291709
                     AND C.name = 'RestoAPagar'
                     AND I.type > 1
                     AND IC.key_ordinal = 1
               )
   )
BEGIN
    CREATE NONCLUSTERED INDEX [IX_Pagamentos_RestoAPagarEstorno]
        ON Despesa.Pagamentos (RestoAPagar, Estorno)
        INCLUDE
    (IdPagamento,
     IdLiquidacao,
     IdSaidaFinanceira,
     Numero,
     DataPagamento,
     NumeroProcesso,
     DataCadastro,
     Valor,
     ValorLiquido,
     ValorEstornado,
     Tipo,
     ConsiderarDirf
    )   ;
END;
IF (NOT EXISTS (
               SELECT I.name,
                      C.*
               FROM sys.indexes AS I
                    JOIN
                    sys.index_columns AS IC ON I.object_id = IC.object_id
                                               AND I.index_id = IC.index_id
                    JOIN
                    sys.columns AS C ON I.object_id = C.object_id
               WHERE I.object_id = 182291709
                     AND C.name = 'IdLiquidacao'
                     AND I.type > 1
                     AND IC.key_ordinal = 1
               )
   )
BEGIN
    CREATE NONCLUSTERED INDEX [IX_DespesaPagamentosIdLiquidacao]
        ON Despesa.Pagamentos (IdLiquidacao);
END;
IF (NOT EXISTS (
               SELECT I.name,
                      C.*
               FROM sys.indexes AS I
                    JOIN
                    sys.index_columns AS IC ON I.object_id = IC.object_id
                                               AND I.index_id = IC.index_id
                    JOIN
                    sys.columns AS C ON I.object_id = C.object_id
               WHERE I.object_id = 182291709
                     AND C.name = 'Numero'
                     AND I.type > 1
                     AND IC.key_ordinal = 1
               )
   )
BEGIN
    CREATE NONCLUSTERED INDEX [IX_DespesaPagamentosNumeroEstorno]
        ON Despesa.Pagamentos (Numero, Estorno);
END;
IF (NOT EXISTS (
               SELECT I.name,
                      C.*
               FROM sys.indexes AS I
                    JOIN
                    sys.index_columns AS IC ON I.object_id = IC.object_id
                                               AND I.index_id = IC.index_id
                    JOIN
                    sys.columns AS C ON I.object_id = C.object_id
               WHERE I.object_id = 182291709
                     AND C.name = 'Estorno'
                     AND I.type > 1
                     AND IC.key_ordinal = 1
               )
   )
BEGIN
    CREATE NONCLUSTERED INDEX [missing_index_46_45]
        ON Despesa.Pagamentos (Estorno, ConsiderarDirf)
        INCLUDE (Numero, DataPagamento, Valor);
END;
IF (NOT EXISTS (
               SELECT I.name,
                      C.*
               FROM sys.indexes AS I
                    JOIN
                    sys.index_columns AS IC ON I.object_id = IC.object_id
                                               AND I.index_id = IC.index_id
                    JOIN
                    sys.columns AS C ON I.object_id = C.object_id
               WHERE I.object_id = 182291709
                     AND C.name = 'Estorno'
                     AND I.type > 1
                     AND IC.key_ordinal = 1
               )
   )
BEGIN
    CREATE NONCLUSTERED INDEX [missing_index_67_66]
        ON Despesa.Pagamentos (Estorno, Tipo)
        INCLUDE (IdSaidaFinanceira, DataPagamento, Valor, ValorEstornado);
END;
IF (NOT EXISTS (
               SELECT I.name,
                      C.*
               FROM sys.indexes AS I
                    JOIN
                    sys.index_columns AS IC ON I.object_id = IC.object_id
                                               AND I.index_id = IC.index_id
                    JOIN
                    sys.columns AS C ON I.object_id = C.object_id
               WHERE I.object_id = 182291709
                     AND C.name = 'IdSaidaFinanceira'
                     AND I.type > 1
                     AND IC.key_ordinal = 1
               )
   )
BEGIN
    CREATE NONCLUSTERED INDEX [missing_index_69_68]
        ON Despesa.Pagamentos (IdSaidaFinanceira, Estorno)
        INCLUDE (DataPagamento, ValorEstornado);
END;
IF (NOT EXISTS (
               SELECT I.name,
                      C.*
               FROM sys.indexes AS I
                    JOIN
                    sys.index_columns AS IC ON I.object_id = IC.object_id
                                               AND I.index_id = IC.index_id
                    JOIN
                    sys.columns AS C ON I.object_id = C.object_id
               WHERE I.object_id = 183007733
                     AND C.name = 'IdProcessoAndamento'
                     AND I.type > 1
                     AND IC.key_ordinal = 1
               )
   )
BEGIN
    CREATE NONCLUSTERED INDEX [nci_wi_ProcessosAndamentosDocumentos_827C28B5955ED621668A43A379A367EB]
        ON Processo.ProcessosAndamentosDocumentos (IdProcessoAndamento)
        INCLUDE (IdDocumento, IdModelo);
END;
IF (NOT EXISTS (
               SELECT I.name,
                      C.*
               FROM sys.indexes AS I
                    JOIN
                    sys.index_columns AS IC ON I.object_id = IC.object_id
                                               AND I.index_id = IC.index_id
                    JOIN
                    sys.columns AS C ON I.object_id = C.object_id
               WHERE I.object_id = 215007847
                     AND C.name = 'IdProcessoAndamento'
                     AND I.type > 1
                     AND IC.key_ordinal = 1
               )
   )
BEGIN
    CREATE NONCLUSTERED INDEX [IX_ProcessoProcessosAndamentosEnquadramentosLegaisIdProcessoAndamento]
        ON Processo.ProcessosAndamentosEnquadramentosLegais (IdProcessoAndamento)
        INCLUDE (IdProcessoAndamentoEnquadramentoLegal);
END;
IF (NOT EXISTS (
               SELECT I.name,
                      C.*
               FROM sys.indexes AS I
                    JOIN
                    sys.index_columns AS IC ON I.object_id = IC.object_id
                                               AND I.index_id = IC.index_id
                    JOIN
                    sys.columns AS C ON I.object_id = C.object_id
               WHERE I.object_id = 215007847
                     AND C.name = 'IdProcessoEnquadramentoLegal'
                     AND I.type > 1
                     AND IC.key_ordinal = 1
               )
   )
BEGIN
    CREATE NONCLUSTERED INDEX [missing_index_94_93]
        ON Processo.ProcessosAndamentosEnquadramentosLegais (IdProcessoEnquadramentoLegal);
END;
IF (NOT EXISTS (
               SELECT I.name,
                      C.*
               FROM sys.indexes AS I
                    JOIN
                    sys.index_columns AS IC ON I.object_id = IC.object_id
                                               AND I.index_id = IC.index_id
                    JOIN
                    sys.columns AS C ON I.object_id = C.object_id
               WHERE I.object_id = 233103921
                     AND C.name = 'Entidade'
                     AND I.type > 1
                     AND IC.key_ordinal = 1
               )
   )
BEGIN
    CREATE NONCLUSTERED INDEX [IDX_ArquivosAnexos_EntidadeIdEntidade]
        ON Sistema.ArquivosAnexos (Entidade, IdEntidade);
END;
IF (NOT EXISTS (
               SELECT I.name,
                      C.*
               FROM sys.indexes AS I
                    JOIN
                    sys.index_columns AS IC ON I.object_id = IC.object_id
                                               AND I.index_id = IC.index_id
                    JOIN
                    sys.columns AS C ON I.object_id = C.object_id
               WHERE I.object_id = 233103921
                     AND C.name = 'Entidade'
                     AND I.type > 1
                     AND IC.key_ordinal = 1
               )
   )
BEGIN
    CREATE NONCLUSTERED INDEX [IX_ArquivosAnexos_Entidade]
        ON Sistema.ArquivosAnexos (Entidade)
        INCLUDE (IdEntidade);
END;
IF (NOT EXISTS (
               SELECT I.name,
                      C.*
               FROM sys.indexes AS I
                    JOIN
                    sys.index_columns AS IC ON I.object_id = IC.object_id
                                               AND I.index_id = IC.index_id
                    JOIN
                    sys.columns AS C ON I.object_id = C.object_id
               WHERE I.object_id = 233103921
                     AND C.name = 'IdEntidade'
                     AND I.type > 1
                     AND IC.key_ordinal = 1
               )
   )
BEGIN
    CREATE NONCLUSTERED INDEX [IX_ArquivosAnexos_IdEntidade]
        ON Sistema.ArquivosAnexos (IdEntidade);
END;
IF (NOT EXISTS (
               SELECT I.name,
                      C.*
               FROM sys.indexes AS I
                    JOIN
                    sys.index_columns AS IC ON I.object_id = IC.object_id
                                               AND I.index_id = IC.index_id
                    JOIN
                    sys.columns AS C ON I.object_id = C.object_id
               WHERE I.object_id = 233103921
                     AND C.name = 'IdEntidade'
                     AND I.type > 1
                     AND IC.key_ordinal = 1
               )
   )
BEGIN
    CREATE NONCLUSTERED INDEX [IX_ArquivosAnexos_IdEntidadeEntidade]
        ON Sistema.ArquivosAnexos (IdEntidade, Entidade);
END;
IF (NOT EXISTS (
               SELECT I.name,
                      C.*
               FROM sys.indexes AS I
                    JOIN
                    sys.index_columns AS IC ON I.object_id = IC.object_id
                                               AND I.index_id = IC.index_id
                    JOIN
                    sys.columns AS C ON I.object_id = C.object_id
               WHERE I.object_id = 233103921
                     AND C.name = 'Entidade'
                     AND I.type > 1
                     AND IC.key_ordinal = 1
               )
   )
BEGIN
    CREATE NONCLUSTERED INDEX [nci_wi_ArquivosAnexos_29EE6813E2E8DF0B6CA8C4AD44ED3D87]
        ON Sistema.ArquivosAnexos (Entidade, IdArquivoAnexoGrupo)
        INCLUDE
    (IdEntidade,
     Nome,
     ContentType,
     Tamanho,
     Conteudo,
     Compactado,
     DataCadastro,
     Titulo,
     Descricao,
     Ordem,
     NomeUsuarioCriacao,
     DataCriacao,
     NomeUnidadeCriacao,
     NomeUsuarioAtualizacao,
     DataAtualizacao,
     NomeUnidadeAtualizacao,
     CodigoAutenticacao,
     ConteudoEmStorageExterno,
     UrlStorageExterno,
     NomeIdentificadorStorageExterno,
     Origem,
     DataValidade,
     Publico
    )   ;
END;
IF (NOT EXISTS (
               SELECT I.name,
                      C.*
               FROM sys.indexes AS I
                    JOIN
                    sys.index_columns AS IC ON I.object_id = IC.object_id
                                               AND I.index_id = IC.index_id
                    JOIN
                    sys.columns AS C ON I.object_id = C.object_id
               WHERE I.object_id = 239339917
                     AND C.name = 'IdDocumento'
                     AND I.type > 1
                     AND IC.key_ordinal = 1
               )
   )
BEGIN
    CREATE NONCLUSTERED INDEX [nci_wi_DocumentosDigitalizacoes_967C6F3D4B60E87361AECC059E3E861A]
        ON Documento.DocumentosDigitalizacoes (IdDocumento, IdArquivoAnexoGrupo)
        INCLUDE
    (DataAtualizacao,
     DataCriacao,
     NomeUsuarioAtualizacao,
     NomeUsuarioCriacao,
     NomeUnidadeAtualizacao,
     NomeUnidadeCriacao
    )   ;
END;
IF (NOT EXISTS (
               SELECT I.name,
                      C.*
               FROM sys.indexes AS I
                    JOIN
                    sys.index_columns AS IC ON I.object_id = IC.object_id
                                               AND I.index_id = IC.index_id
                    JOIN
                    sys.columns AS C ON I.object_id = C.object_id
               WHERE I.object_id = 271340031
                     AND C.name = 'IdDocumento'
                     AND I.type > 1
                     AND IC.key_ordinal = 1
               )
   )
BEGIN
    CREATE NONCLUSTERED INDEX [UNQ_DocumentoDocumentosDocumentacoesRequeridasIdDocumentoIdDocumentacaoRequerida]
        ON Documento.DocumentosDocumentacoesRequeridas (IdDocumento, IdDocumentacaoRequerida);
END;
IF (NOT EXISTS (
               SELECT I.name,
                      C.*
               FROM sys.indexes AS I
                    JOIN
                    sys.index_columns AS IC ON I.object_id = IC.object_id
                                               AND I.index_id = IC.index_id
                    JOIN
                    sys.columns AS C ON I.object_id = C.object_id
               WHERE I.object_id = 285960095
                     AND C.name = 'Ordem'
                     AND I.type > 1
                     AND IC.key_ordinal = 1
               )
   )
BEGIN
    CREATE NONCLUSTERED INDEX [UNQ_PatrimonioControleExecucaoDepreciacaoAutomaticaOrdem]
        ON Patrimonio.ControleExecucaoDepreciacaoAutomatica (Ordem);
END;
IF (NOT EXISTS (
               SELECT I.name,
                      C.*
               FROM sys.indexes AS I
                    JOIN
                    sys.index_columns AS IC ON I.object_id = IC.object_id
                                               AND I.index_id = IC.index_id
                    JOIN
                    sys.columns AS C ON I.object_id = C.object_id
               WHERE I.object_id = 310292165
                     AND C.name = 'IdCentroCusto'
                     AND I.type > 1
                     AND IC.key_ordinal = 1
               )
   )
BEGIN
    CREATE NONCLUSTERED INDEX [IX_DespesaPagamentosCentroCustosIdCentroCusto]
        ON Despesa.PagamentosCentroCustos (IdCentroCusto)
        INCLUDE (IdPagamento, Valor);
END;
IF (NOT EXISTS (
               SELECT I.name,
                      C.*
               FROM sys.indexes AS I
                    JOIN
                    sys.index_columns AS IC ON I.object_id = IC.object_id
                                               AND I.index_id = IC.index_id
                    JOIN
                    sys.columns AS C ON I.object_id = C.object_id
               WHERE I.object_id = 310292165
                     AND C.name = 'IdPagamento'
                     AND I.type > 1
                     AND IC.key_ordinal = 1
               )
   )
BEGIN
    CREATE NONCLUSTERED INDEX [IX_DespesaPagamentosCentroCustosIdPagamento]
        ON Despesa.PagamentosCentroCustos (IdPagamento)
        INCLUDE (IdPagamentoCentroCusto, IdCentroCusto, Valor);
END;
IF (NOT EXISTS (
               SELECT I.name,
                      C.*
               FROM sys.indexes AS I
                    JOIN
                    sys.index_columns AS IC ON I.object_id = IC.object_id
                                               AND I.index_id = IC.index_id
                    JOIN
                    sys.columns AS C ON I.object_id = C.object_id
               WHERE I.object_id = 343672272
                     AND C.name = 'IdPessoa'
                     AND I.type > 1
                     AND IC.key_ordinal = 1
               )
   )
BEGIN
    CREATE NONCLUSTERED INDEX [UNQ_CadastroPessoasJuridicasIdPessoa]
        ON Cadastro.PessoasJuridicas (IdPessoa);
END;
IF (NOT EXISTS (
               SELECT I.name,
                      C.*
               FROM sys.indexes AS I
                    JOIN
                    sys.index_columns AS IC ON I.object_id = IC.object_id
                                               AND I.index_id = IC.index_id
                    JOIN
                    sys.columns AS C ON I.object_id = C.object_id
               WHERE I.object_id = 375008417
                     AND C.name = 'IdDocumento'
                     AND I.type > 1
                     AND IC.key_ordinal = 1
               )
   )
BEGIN
    CREATE NONCLUSTERED INDEX [UNQ_ProcessoProcessosDocumentosIdDocumento]
        ON Processo.ProcessosDocumentos (IdDocumento);
END;
IF (NOT EXISTS (
               SELECT I.name,
                      C.*
               FROM sys.indexes AS I
                    JOIN
                    sys.index_columns AS IC ON I.object_id = IC.object_id
                                               AND I.index_id = IC.index_id
                    JOIN
                    sys.columns AS C ON I.object_id = C.object_id
               WHERE I.object_id = 381244413
                     AND C.name = 'Nome'
                     AND I.type > 1
                     AND IC.key_ordinal = 1
               )
   )
BEGIN
    CREATE NONCLUSTERED INDEX [IX_Bairros_NomeIdCidadeAtivo]
        ON Corporativo.Bairros (Nome)
        INCLUDE (IdCidade, Ativo);
END;
IF (NOT EXISTS (
               SELECT I.name,
                      C.*
               FROM sys.indexes AS I
                    JOIN
                    sys.index_columns AS IC ON I.object_id = IC.object_id
                                               AND I.index_id = IC.index_id
                    JOIN
                    sys.columns AS C ON I.object_id = C.object_id
               WHERE I.object_id = 393104491
                     AND C.name = 'CodSistema'
                     AND I.type > 1
                     AND IC.key_ordinal = 1
               )
   )
BEGIN
    CREATE NONCLUSTERED INDEX [IX_Configuracoes_CodSistemaModuloConfiguracaoAno]
        ON Sistema.Configuracoes (CodSistema, Modulo, Configuracao, Ano)
        INCLUDE (Valor);
END;
IF (NOT EXISTS (
               SELECT I.name,
                      C.*
               FROM sys.indexes AS I
                    JOIN
                    sys.index_columns AS IC ON I.object_id = IC.object_id
                                               AND I.index_id = IC.index_id
                    JOIN
                    sys.columns AS C ON I.object_id = C.object_id
               WHERE I.object_id = 393104491
                     AND C.name = 'Configuracao'
                     AND I.type > 1
                     AND IC.key_ordinal = 1
               )
   )
BEGIN
    CREATE NONCLUSTERED INDEX [IX_Configuracoes_Configuracao]
        ON Sistema.Configuracoes (Configuracao, Ano)
        INCLUDE (Valor);
END;
IF (NOT EXISTS (
               SELECT I.name,
                      C.*
               FROM sys.indexes AS I
                    JOIN
                    sys.index_columns AS IC ON I.object_id = IC.object_id
                                               AND I.index_id = IC.index_id
                    JOIN
                    sys.columns AS C ON I.object_id = C.object_id
               WHERE I.object_id = 423008588
                     AND C.name = 'IdProcesso'
                     AND I.type > 1
                     AND IC.key_ordinal = 1
               )
   )
BEGIN
    CREATE NONCLUSTERED INDEX [IdxProcessoEticoIdProcesso]
        ON Processo.ProcessosEticos (IdProcesso);
END;
IF (NOT EXISTS (
               SELECT I.name,
                      C.*
               FROM sys.indexes AS I
                    JOIN
                    sys.index_columns AS IC ON I.object_id = IC.object_id
                                               AND I.index_id = IC.index_id
                    JOIN
                    sys.columns AS C ON I.object_id = C.object_id
               WHERE I.object_id = 423008588
                     AND C.name = 'IdPessoaInstrutor'
                     AND I.type > 1
                     AND IC.key_ordinal = 1
               )
   )
BEGIN
    CREATE NONCLUSTERED INDEX [IdxProcessoEticoInstrutor]
        ON Processo.ProcessosEticos (IdPessoaInstrutor);
END;
IF (NOT EXISTS (
               SELECT I.name,
                      C.*
               FROM sys.indexes AS I
                    JOIN
                    sys.index_columns AS IC ON I.object_id = IC.object_id
                                               AND I.index_id = IC.index_id
                    JOIN
                    sys.columns AS C ON I.object_id = C.object_id
               WHERE I.object_id = 423008588
                     AND C.name = 'IdPessoaRelator'
                     AND I.type > 1
                     AND IC.key_ordinal = 1
               )
   )
BEGIN
    CREATE NONCLUSTERED INDEX [IdxProcessoEticoRelator]
        ON Processo.ProcessosEticos (IdPessoaRelator);
END;
IF (NOT EXISTS (
               SELECT I.name,
                      C.*
               FROM sys.indexes AS I
                    JOIN
                    sys.index_columns AS IC ON I.object_id = IC.object_id
                                               AND I.index_id = IC.index_id
                    JOIN
                    sys.columns AS C ON I.object_id = C.object_id
               WHERE I.object_id = 432720594
                     AND C.name = 'CodigoRelatorio'
                     AND I.type > 1
                     AND IC.key_ordinal = 1
               )
   )
BEGIN
    CREATE NONCLUSTERED INDEX [UNQ_ContabilidadeDemonstracoesContabeisGestaoTCUCodigoRelatorioExercicio]
        ON Contabilidade.DemonstracoesContabeisGestaoTCU (CodigoRelatorio, Exercicio);
END;
IF (NOT EXISTS (
               SELECT I.name,
                      C.*
               FROM sys.indexes AS I
                    JOIN
                    sys.index_columns AS IC ON I.object_id = IC.object_id
                                               AND I.index_id = IC.index_id
                    JOIN
                    sys.columns AS C ON I.object_id = C.object_id
               WHERE I.object_id = 455008702
                     AND C.name = 'IdProcesso'
                     AND I.type > 1
                     AND IC.key_ordinal = 1
               )
   )
BEGIN
    CREATE NONCLUSTERED INDEX [IX_ProcessosFiscalizacoes_IdProcesso]
        ON Processo.ProcessosFiscalizacoes (IdProcesso)
        INCLUDE (IdProcessoFiscalizacao, IdSituacaoFiscalizacao, IdPessoaFiscal, IdMotivoFiscalizacao);
END;
IF (NOT EXISTS (
               SELECT I.name,
                      C.*
               FROM sys.indexes AS I
                    JOIN
                    sys.index_columns AS IC ON I.object_id = IC.object_id
                                               AND I.index_id = IC.index_id
                    JOIN
                    sys.columns AS C ON I.object_id = C.object_id
               WHERE I.object_id = 509244869
                     AND C.name = 'CodigoIBGE'
                     AND I.type > 1
                     AND IC.key_ordinal = 1
               )
   )
BEGIN
    CREATE NONCLUSTERED INDEX [IX_Cidades_CodigoIBGE]
        ON Corporativo.Cidades (CodigoIBGE);
END;
IF (NOT EXISTS (
               SELECT I.name,
                      C.*
               FROM sys.indexes AS I
                    JOIN
                    sys.index_columns AS IC ON I.object_id = IC.object_id
                                               AND I.index_id = IC.index_id
                    JOIN
                    sys.columns AS C ON I.object_id = C.object_id
               WHERE I.object_id = 509244869
                     AND C.name = 'IdEstado'
                     AND I.type > 1
                     AND IC.key_ordinal = 1
               )
   )
BEGIN
    CREATE NONCLUSTERED INDEX [IX_Cidades_IdEstadoAtivo]
        ON Corporativo.Cidades (IdEstado, Ativo)
        INCLUDE (Nome, CodigoIBGE, CodigoDistritoIbge, NomeUsuarioChancela, DataChancela, Populacao);
END;
IF (NOT EXISTS (
               SELECT I.name,
                      C.*
               FROM sys.indexes AS I
                    JOIN
                    sys.index_columns AS IC ON I.object_id = IC.object_id
                                               AND I.index_id = IC.index_id
                    JOIN
                    sys.columns AS C ON I.object_id = C.object_id
               WHERE I.object_id = 509244869
                     AND C.name = 'Ativo'
                     AND I.type > 1
                     AND IC.key_ordinal = 1
               )
   )
BEGIN
    CREATE NONCLUSTERED INDEX [missing_index_124_123]
        ON Corporativo.Cidades (Ativo)
        INCLUDE (Nome);
END;
IF (NOT EXISTS (
               SELECT I.name,
                      C.*
               FROM sys.indexes AS I
                    JOIN
                    sys.index_columns AS IC ON I.object_id = IC.object_id
                                               AND I.index_id = IC.index_id
                    JOIN
                    sys.columns AS C ON I.object_id = C.object_id
               WHERE I.object_id = 519008930
                     AND C.name = 'IdProcesso'
                     AND I.type > 1
                     AND IC.key_ordinal = 1
               )
   )
BEGIN
    CREATE NONCLUSTERED INDEX [IX_ProcessosJuridicos_IdProcesso]
        ON Processo.ProcessosJuridicos (IdProcesso);
END;
IF (NOT EXISTS (
               SELECT I.name,
                      C.*
               FROM sys.indexes AS I
                    JOIN
                    sys.index_columns AS IC ON I.object_id = IC.object_id
                                               AND I.index_id = IC.index_id
                    JOIN
                    sys.columns AS C ON I.object_id = C.object_id
               WHERE I.object_id = 519672899
                     AND C.name = 'IdPessoa'
                     AND I.type > 1
                     AND IC.key_ordinal = 1
               )
   )
BEGIN
    CREATE NONCLUSTERED INDEX [IX_PessoasJuridicasResponsaveis_IdPessoa]
        ON Cadastro.PessoasJuridicasResponsaveis (IdPessoa);
END;
IF (NOT EXISTS (
               SELECT I.name,
                      C.*
               FROM sys.indexes AS I
                    JOIN
                    sys.index_columns AS IC ON I.object_id = IC.object_id
                                               AND I.index_id = IC.index_id
                    JOIN
                    sys.columns AS C ON I.object_id = C.object_id
               WHERE I.object_id = 519672899
                     AND C.name = 'IdPessoaJuridica'
                     AND I.type > 1
                     AND IC.key_ordinal = 1
               )
   )
BEGIN
    CREATE NONCLUSTERED INDEX [IX_PessoasJuridicasResponsaveis_IdPessoaJuridica]
        ON Cadastro.PessoasJuridicasResponsaveis (IdPessoaJuridica);
END;
IF (NOT EXISTS (
               SELECT I.name,
                      C.*
               FROM sys.indexes AS I
                    JOIN
                    sys.index_columns AS IC ON I.object_id = IC.object_id
                                               AND I.index_id = IC.index_id
                    JOIN
                    sys.columns AS C ON I.object_id = C.object_id
               WHERE I.object_id = 528056967
                     AND C.name = 'IdPessoa'
                     AND I.type > 1
                     AND IC.key_ordinal = 1
               )
   )
BEGIN
    CREATE NONCLUSTERED INDEX [nci_wi_DadosConselhos_3B098D9669DCFBCFF3AD8508E15E784F]
        ON Registro.DadosConselhos (IdPessoa, IdInspetoria);
END;
IF (NOT EXISTS (
               SELECT I.name,
                      C.*
               FROM sys.indexes AS I
                    JOIN
                    sys.index_columns AS IC ON I.object_id = IC.object_id
                                               AND I.index_id = IC.index_id
                    JOIN
                    sys.columns AS C ON I.object_id = C.object_id
               WHERE I.object_id = 528056967
                     AND C.name = 'IdInspetoria'
                     AND I.type > 1
                     AND IC.key_ordinal = 1
               )
   )
BEGIN
    CREATE NONCLUSTERED INDEX [missing_index_172_171]
        ON Registro.DadosConselhos (IdInspetoria)
        INCLUDE (IdPessoa);
END;
IF (NOT EXISTS (
               SELECT I.name,
                      C.*
               FROM sys.indexes AS I
                    JOIN
                    sys.index_columns AS IC ON I.object_id = IC.object_id
                                               AND I.index_id = IC.index_id
                    JOIN
                    sys.columns AS C ON I.object_id = C.object_id
               WHERE I.object_id = 529436960
                     AND C.name = 'IdEntidade'
                     AND I.type > 1
                     AND IC.key_ordinal = 1
               )
   )
BEGIN
    CREATE NONCLUSTERED INDEX [IX_Ocorrencias_IdEntidade]
        ON Ocorrencia.Ocorrencias (IdEntidade);
END;
IF (NOT EXISTS (
               SELECT I.name,
                      C.*
               FROM sys.indexes AS I
                    JOIN
                    sys.index_columns AS IC ON I.object_id = IC.object_id
                                               AND I.index_id = IC.index_id
                    JOIN
                    sys.columns AS C ON I.object_id = C.object_id
               WHERE I.object_id = 543341000
                     AND C.name = 'IdDocumento'
                     AND I.type > 1
                     AND IC.key_ordinal = 1
               )
   )
BEGIN
    CREATE NONCLUSTERED INDEX [missing_index_83_82]
        ON Documento.DocumentosRegistros (IdDocumento)
        INCLUDE (IdRegistro, TipoVinculo);
END;
IF (NOT EXISTS (
               SELECT I.name,
                      C.*
               FROM sys.indexes AS I
                    JOIN
                    sys.index_columns AS IC ON I.object_id = IC.object_id
                                               AND I.index_id = IC.index_id
                    JOIN
                    sys.columns AS C ON I.object_id = C.object_id
               WHERE I.object_id = 575341114
                     AND C.name = 'IdTramitacao'
                     AND I.type > 1
                     AND IC.key_ordinal = 1
               )
   )
BEGIN
    CREATE NONCLUSTERED INDEX [missing_index_113_112]
        ON Documento.DocumentosTramitacoes (IdTramitacao);
END;
IF (NOT EXISTS (
               SELECT I.name,
                      C.*
               FROM sys.indexes AS I
                    JOIN
                    sys.index_columns AS IC ON I.object_id = IC.object_id
                                               AND I.index_id = IC.index_id
                    JOIN
                    sys.columns AS C ON I.object_id = C.object_id
               WHERE I.object_id = 578817124
                     AND C.name = 'IdPessoa'
                     AND I.type > 1
                     AND IC.key_ordinal = 1
               )
   )
BEGIN
    CREATE NONCLUSTERED INDEX [IX_Lancamentos_IdPessoa]
        ON DividaAtiva.Lancamentos (IdPessoa);
END;
IF (NOT EXISTS (
               SELECT I.name,
                      C.*
               FROM sys.indexes AS I
                    JOIN
                    sys.index_columns AS IC ON I.object_id = IC.object_id
                                               AND I.index_id = IC.index_id
                    JOIN
                    sys.columns AS C ON I.object_id = C.object_id
               WHERE I.object_id = 583673127
                     AND C.name = 'IdPessoa'
                     AND I.type > 1
                     AND IC.key_ordinal = 1
               )
   )
BEGIN
    CREATE NONCLUSTERED INDEX [IX_PessoasTiposEntidades]
        ON Cadastro.PessoasTiposEntidades (IdPessoa, IdTipoEntidade);
END;
IF (NOT EXISTS (
               SELECT I.name,
                      C.*
               FROM sys.indexes AS I
                    JOIN
                    sys.index_columns AS IC ON I.object_id = IC.object_id
                                               AND I.index_id = IC.index_id
                    JOIN
                    sys.columns AS C ON I.object_id = C.object_id
               WHERE I.object_id = 585105175
                     AND C.name = 'CodConfiguracao'
                     AND I.type > 1
                     AND IC.key_ordinal = 1
               )
   )
BEGIN
    CREATE NONCLUSTERED INDEX [IX_ConfiguracoesUsuarios_CodConfiguracao_IdPessoa]
        ON Sistema.ConfiguracoesUsuarios (CodConfiguracao, IdPessoa)
        INCLUDE (Valor);
END;
IF (NOT EXISTS (
               SELECT I.name,
                      C.*
               FROM sys.indexes AS I
                    JOIN
                    sys.index_columns AS IC ON I.object_id = IC.object_id
                                               AND I.index_id = IC.index_id
                    JOIN
                    sys.columns AS C ON I.object_id = C.object_id
               WHERE I.object_id = 610153269
                     AND C.name = 'DataEnvio'
                     AND I.type > 1
                     AND IC.key_ordinal = 1
               )
   )
BEGIN
    CREATE NONCLUSTERED INDEX [IX_Tramitacoes_DataEnvioIdEntidadeEntidade]
        ON Tramitacao.Tramitacoes (DataEnvio, IdEntidade, Entidade)
        INCLUDE
    (IdTramitacao,
     IdUnidadeOrigem,
     IdUsuarioOrigem,
     IdUnidadeDestino,
     IdUsuarioDestino,
     IdPrioridade,
     IdSituacaoTramitacao,
     DataPrevisao,
     TramitacaoLote,
     NumeroLote,
     Andamento,
     Pendencia,
     DataCriacao,
     NomeUsuarioCriacao,
     NomeUnidadeCriacao,
     DataAtualizacao,
     NomeUsuarioAtualizacao,
     NomeUnidadeAtualizacao,
     ReceberNotificacaoRecebimento
    )   ;
END;
IF (NOT EXISTS (
               SELECT I.name,
                      C.*
               FROM sys.indexes AS I
                    JOIN
                    sys.index_columns AS IC ON I.object_id = IC.object_id
                                               AND I.index_id = IC.index_id
                    JOIN
                    sys.columns AS C ON I.object_id = C.object_id
               WHERE I.object_id = 610153269
                     AND C.name = 'IdEntidade'
                     AND I.type > 1
                     AND IC.key_ordinal = 1
               )
   )
BEGIN
    CREATE NONCLUSTERED INDEX [IX_Tramitacoes_IdEntidade]
        ON Tramitacao.Tramitacoes (IdEntidade);
END;
IF (NOT EXISTS (
               SELECT I.name,
                      C.*
               FROM sys.indexes AS I
                    JOIN
                    sys.index_columns AS IC ON I.object_id = IC.object_id
                                               AND I.index_id = IC.index_id
                    JOIN
                    sys.columns AS C ON I.object_id = C.object_id
               WHERE I.object_id = 610153269
                     AND C.name = 'IdEntidade'
                     AND I.type > 1
                     AND IC.key_ordinal = 1
               )
   )
BEGIN
    CREATE NONCLUSTERED INDEX [IX_Tramitacoes_IdEntidadeEntidade]
        ON Tramitacao.Tramitacoes (IdEntidade, Entidade);
END;
IF (NOT EXISTS (
               SELECT I.name,
                      C.*
               FROM sys.indexes AS I
                    JOIN
                    sys.index_columns AS IC ON I.object_id = IC.object_id
                                               AND I.index_id = IC.index_id
                    JOIN
                    sys.columns AS C ON I.object_id = C.object_id
               WHERE I.object_id = 610817238
                     AND C.name = 'IdLancamento'
                     AND I.type > 1
                     AND IC.key_ordinal = 1
               )
   )
BEGIN
    CREATE NONCLUSTERED INDEX [IX_LancamentosCertidoes_IdLancamento]
        ON DividaAtiva.LancamentosCertidoes (IdLancamento)
        INCLUDE (IdLancamentoCertidao, IdCertidao);
END;
IF (NOT EXISTS (
               SELECT I.name,
                      C.*
               FROM sys.indexes AS I
                    JOIN
                    sys.index_columns AS IC ON I.object_id = IC.object_id
                                               AND I.index_id = IC.index_id
                    JOIN
                    sys.columns AS C ON I.object_id = C.object_id
               WHERE I.object_id = 618485282
                     AND C.name = 'IdTipoRequerimento'
                     AND I.type > 1
                     AND IC.key_ordinal = 1
               )
   )
BEGIN
    CREATE NONCLUSTERED INDEX [IX_PlenariaRequerimentosIdTipoRequerimentoIdSituacaoRequerimento]
        ON Plenaria.Requerimentos (IdTipoRequerimento, IdSituacaoRequerimento)
        INCLUDE (IdRequerimento);
END;
IF (NOT EXISTS (
               SELECT I.name,
                      C.*
               FROM sys.indexes AS I
                    JOIN
                    sys.index_columns AS IC ON I.object_id = IC.object_id
                                               AND I.index_id = IC.index_id
                    JOIN
                    sys.columns AS C ON I.object_id = C.object_id
               WHERE I.object_id = 624057309
                     AND C.name = 'IdRegistro'
                     AND I.type > 1
                     AND IC.key_ordinal = 1
               )
   )
BEGIN
    CREATE NONCLUSTERED INDEX [IX_EleicoesUrnasVotantes_IdRegistro]
        ON Registro.EleicoesUrnasVotantes (IdRegistro)
        INCLUDE
    (IdEleicaoUrnaVotante,
     IdEleicaoUrna,
     IdSituacao,
     Justificativa,
     NomeUsuarioCriacao,
     NomeUnidadeCriacao,
     DataCriacao,
     DataVotacao
    )   ;
END;
IF (NOT EXISTS (
               SELECT I.name,
                      C.*
               FROM sys.indexes AS I
                    JOIN
                    sys.index_columns AS IC ON I.object_id = IC.object_id
                                               AND I.index_id = IC.index_id
                    JOIN
                    sys.columns AS C ON I.object_id = C.object_id
               WHERE I.object_id = 650485396
                     AND C.name = 'IdRequerimento'
                     AND I.type > 1
                     AND IC.key_ordinal = 1
               )
   )
BEGIN
    CREATE NONCLUSTERED INDEX [IX_RequerimentosPlenarias_IdRequerimento]
        ON Plenaria.RequerimentosPlenarias (IdRequerimento);
END;
IF (NOT EXISTS (
               SELECT I.name,
                      C.*
               FROM sys.indexes AS I
                    JOIN
                    sys.index_columns AS IC ON I.object_id = IC.object_id
                                               AND I.index_id = IC.index_id
                    JOIN
                    sys.columns AS C ON I.object_id = C.object_id
               WHERE I.object_id = 679009500
                     AND C.name = 'IdProcesso'
                     AND I.type > 1
                     AND IC.key_ordinal = 1
               )
   )
BEGIN
    CREATE NONCLUSTERED INDEX [IX_ProcessosPessoasPrincipais_IdProcesso]
        ON Processo.ProcessosPessoasPrincipais (IdProcesso);
END;
IF (NOT EXISTS (
               SELECT I.name,
                      C.*
               FROM sys.indexes AS I
                    JOIN
                    sys.index_columns AS IC ON I.object_id = IC.object_id
                                               AND I.index_id = IC.index_id
                    JOIN
                    sys.columns AS C ON I.object_id = C.object_id
               WHERE I.object_id = 679009500
                     AND C.name = 'IdPessoa'
                     AND I.type > 1
                     AND IC.key_ordinal = 1
               )
   )
BEGIN
    CREATE NONCLUSTERED INDEX [nci_wi_ProcessosPessoasPrincipais_1277C2B60CE552DAA44644BF08DE961F]
        ON Processo.ProcessosPessoasPrincipais (IdPessoa, IdProcesso);
END;
IF (NOT EXISTS (
               SELECT I.name,
                      C.*
               FROM sys.indexes AS I
                    JOIN
                    sys.index_columns AS IC ON I.object_id = IC.object_id
                                               AND I.index_id = IC.index_id
                    JOIN
                    sys.columns AS C ON I.object_id = C.object_id
               WHERE I.object_id = 682485510
                     AND C.name = 'IdRequerimento'
                     AND I.type > 1
                     AND IC.key_ordinal = 1
               )
   )
BEGIN
    CREATE NONCLUSTERED INDEX [IX_PlenariaRequerimentosRegistrosSituacoesIdRequerimento]
        ON Plenaria.RequerimentosRegistrosSituacoes (IdRequerimento);
END;
IF (NOT EXISTS (
               SELECT I.name,
                      C.*
               FROM sys.indexes AS I
                    JOIN
                    sys.index_columns AS IC ON I.object_id = IC.object_id
                                               AND I.index_id = IC.index_id
                    JOIN
                    sys.columns AS C ON I.object_id = C.object_id
               WHERE I.object_id = 682485510
                     AND C.name = 'IdRegistroSituacao'
                     AND I.type > 1
                     AND IC.key_ordinal = 1
               )
   )
BEGIN
    CREATE NONCLUSTERED INDEX [IX_RequerimentosRegistrosSituacoes]
        ON Plenaria.RequerimentosRegistrosSituacoes (IdRegistroSituacao)
        INCLUDE (IdRequerimento);
END;
IF (NOT EXISTS (
               SELECT I.name,
                      C.*
               FROM sys.indexes AS I
                    JOIN
                    sys.index_columns AS IC ON I.object_id = IC.object_id
                                               AND I.index_id = IC.index_id
                    JOIN
                    sys.columns AS C ON I.object_id = C.object_id
               WHERE I.object_id = 711009614
                     AND C.name = 'IdDebito'
                     AND I.type > 1
                     AND IC.key_ordinal = 1
               )
   )
BEGIN
    CREATE NONCLUSTERED INDEX [IX_ProcessoProcessosPessoasPrincipaisDebitosIdDebito]
        ON Processo.ProcessosPessoasPrincipaisDebitos (IdDebito)
        INCLUDE (IdProcessoPessoaPrincipalDebito);
END;
IF (NOT EXISTS (
               SELECT I.name,
                      C.*
               FROM sys.indexes AS I
                    JOIN
                    sys.index_columns AS IC ON I.object_id = IC.object_id
                                               AND I.index_id = IC.index_id
                    JOIN
                    sys.columns AS C ON I.object_id = C.object_id
               WHERE I.object_id = 711009614
                     AND C.name = 'IdProcessoPessoaPrincipal'
                     AND I.type > 1
                     AND IC.key_ordinal = 1
               )
   )
BEGIN
    CREATE NONCLUSTERED INDEX [IX_ProcessoProcessosPessoasPrincipaisDebitosIdProcessoPessoaPrincipal]
        ON Processo.ProcessosPessoasPrincipaisDebitos (IdProcessoPessoaPrincipal);
END;
IF (NOT EXISTS (
               SELECT I.name,
                      C.*
               FROM sys.indexes AS I
                    JOIN
                    sys.index_columns AS IC ON I.object_id = IC.object_id
                                               AND I.index_id = IC.index_id
                    JOIN
                    sys.columns AS C ON I.object_id = C.object_id
               WHERE I.object_id = 738817694
                     AND C.name = 'IdDebito'
                     AND I.type > 1
                     AND IC.key_ordinal = 1
               )
   )
BEGIN
    CREATE NONCLUSTERED INDEX [IX_DividaAtivaLancamentosDebitosIdDebitoAtivo]
        ON DividaAtiva.LancamentosDebitos (IdDebito, Ativo);
END;
IF (NOT EXISTS (
               SELECT I.name,
                      C.*
               FROM sys.indexes AS I
                    JOIN
                    sys.index_columns AS IC ON I.object_id = IC.object_id
                                               AND I.index_id = IC.index_id
                    JOIN
                    sys.columns AS C ON I.object_id = C.object_id
               WHERE I.object_id = 738817694
                     AND C.name = 'IdLancamento'
                     AND I.type > 1
                     AND IC.key_ordinal = 1
               )
   )
BEGIN
    CREATE NONCLUSTERED INDEX [IX_LancamentosDebitos_IdLancamentoAtivo]
        ON DividaAtiva.LancamentosDebitos (IdLancamento, Ativo);
END;
IF (NOT EXISTS (
               SELECT I.name,
                      C.*
               FROM sys.indexes AS I
                    JOIN
                    sys.index_columns AS IC ON I.object_id = IC.object_id
                                               AND I.index_id = IC.index_id
                    JOIN
                    sys.columns AS C ON I.object_id = C.object_id
               WHERE I.object_id = 738817694
                     AND C.name = 'IdLancamento'
                     AND I.type > 1
                     AND IC.key_ordinal = 1
               )
   )
BEGIN
    CREATE NONCLUSTERED INDEX [IX_LancamentosDebitos_IdLancamento]
        ON DividaAtiva.LancamentosDebitos (IdLancamento)
        INCLUDE
    (IdDebito,
     IdProcedimentoAtraso,
     Ativo,
     DataVencimentoOriginal,
     IdDebitoSituacaoPagamento,
     IdDebitoSituacaoParcelamento,
     DataCancelamento,
     ValorPrincipal,
     ValorAmortizado,
     ValorPago,
     ValorDevido,
     ValorAtualizacaoMonetaria,
     ValorJuros,
     ValorMulta,
     ValorAcrescimo,
     ValorDesconto,
     ValorTotal,
     Original,
     IdNaturezaLancamento,
     DataCriacao
    )   ;
END;
IF (NOT EXISTS (
               SELECT I.name,
                      C.*
               FROM sys.indexes AS I
                    JOIN
                    sys.index_columns AS IC ON I.object_id = IC.object_id
                                               AND I.index_id = IC.index_id
                    JOIN
                    sys.columns AS C ON I.object_id = C.object_id
               WHERE I.object_id = 738817694
                     AND C.name = 'IdDebito'
                     AND I.type > 1
                     AND IC.key_ordinal = 1
               )
   )
BEGIN
    CREATE NONCLUSTERED INDEX [IX_LancamentosDebitos_IdDebitoAtivo]
        ON DividaAtiva.LancamentosDebitos (IdDebito, Ativo)
        INCLUDE (IdLancamento);
END;
IF (NOT EXISTS (
               SELECT I.name,
                      C.*
               FROM sys.indexes AS I
                    JOIN
                    sys.index_columns AS IC ON I.object_id = IC.object_id
                                               AND I.index_id = IC.index_id
                    JOIN
                    sys.columns AS C ON I.object_id = C.object_id
               WHERE I.object_id = 770153839
                     AND C.name = 'IdTramitacao'
                     AND I.type > 1
                     AND IC.key_ordinal = 1
               )
   )
BEGIN
    CREATE NONCLUSTERED INDEX [IX_TramitacoesRecebimentos_IdTramitacao]
        ON Tramitacao.TramitacoesRecebimentos (IdTramitacao);
END;
IF (NOT EXISTS (
               SELECT I.name,
                      C.*
               FROM sys.indexes AS I
                    JOIN
                    sys.index_columns AS IC ON I.object_id = IC.object_id
                                               AND I.index_id = IC.index_id
                    JOIN
                    sys.columns AS C ON I.object_id = C.object_id
               WHERE I.object_id = 770817808
                     AND C.name = 'IdDocumento'
                     AND I.type > 1
                     AND IC.key_ordinal = 1
               )
   )
BEGIN
    CREATE NONCLUSTERED INDEX [IX_DividaAtivaLancamentosDocumentosIdDocumento]
        ON DividaAtiva.LancamentosDocumentos (IdDocumento);
END;
IF (NOT EXISTS (
               SELECT I.name,
                      C.*
               FROM sys.indexes AS I
                    JOIN
                    sys.index_columns AS IC ON I.object_id = IC.object_id
                                               AND I.index_id = IC.index_id
                    JOIN
                    sys.columns AS C ON I.object_id = C.object_id
               WHERE I.object_id = 807009956
                     AND C.name = 'IdProcessoPessoaPrincipal'
                     AND I.type > 1
                     AND IC.key_ordinal = 1
               )
   )
BEGIN
    CREATE NONCLUSTERED INDEX [IX_ProcessosPessoasPrincipaisRegistros_IdProcessoPessoaPrincipal]
        ON Processo.ProcessosPessoasPrincipaisRegistros (IdProcessoPessoaPrincipal)
        INCLUDE (IdRegistro);
END;
IF (NOT EXISTS (
               SELECT I.name,
                      C.*
               FROM sys.indexes AS I
                    JOIN
                    sys.index_columns AS IC ON I.object_id = IC.object_id
                                               AND I.index_id = IC.index_id
                    JOIN
                    sys.columns AS C ON I.object_id = C.object_id
               WHERE I.object_id = 832058050
                     AND C.name = 'IdPessoa'
                     AND I.type > 1
                     AND IC.key_ordinal = 1
               )
   )
BEGIN
    CREATE NONCLUSTERED INDEX [IX_FormacoesAcademicas_IdPessoa]
        ON Registro.FormacoesAcademicas (IdPessoa);
END;
IF (NOT EXISTS (
               SELECT I.name,
                      C.*
               FROM sys.indexes AS I
                    JOIN
                    sys.index_columns AS IC ON I.object_id = IC.object_id
                                               AND I.index_id = IC.index_id
                    JOIN
                    sys.columns AS C ON I.object_id = C.object_id
               WHERE I.object_id = 834818036
                     AND C.name = 'IdLancamento'
                     AND I.type > 1
                     AND IC.key_ordinal = 1
               )
   )
BEGIN
    CREATE NONCLUSTERED INDEX [IX_DividaAtivaLancamentosRegistrosIdLancamento]
        ON DividaAtiva.LancamentosRegistros (IdLancamento)
        INCLUDE (IdLancamentoRegistro, IdRegistro);
END;
IF (NOT EXISTS (
               SELECT I.name,
                      C.*
               FROM sys.indexes AS I
                    JOIN
                    sys.index_columns AS IC ON I.object_id = IC.object_id
                                               AND I.index_id = IC.index_id
                    JOIN
                    sys.columns AS C ON I.object_id = C.object_id
               WHERE I.object_id = 864058164
                     AND C.name = 'IdFormacaoAcademica'
                     AND I.type > 1
                     AND IC.key_ordinal = 1
               )
   )
BEGIN
    CREATE NONCLUSTERED INDEX [IX_FormacoesAcademicasDocumentos_IdFormacaoAcademica]
        ON Registro.FormacoesAcademicasDocumentos (IdFormacaoAcademica)
        INCLUDE
    (IdFormacaoAcademicaDocumento,
     IdEntidadeRegistro,
     IdTipoDocumento,
     Livro,
     FolhaRegistro,
     NumeroRegistro,
     DataExpedicao,
     DataRegistro,
     DataEntrega
    )   ;
END;
IF (NOT EXISTS (
               SELECT I.name,
                      C.*
               FROM sys.indexes AS I
                    JOIN
                    sys.index_columns AS IC ON I.object_id = IC.object_id
                                               AND I.index_id = IC.index_id
                    JOIN
                    sys.columns AS C ON I.object_id = C.object_id
               WHERE I.object_id = 865438157
                     AND C.name = 'IdPessoa'
                     AND I.type > 1
                     AND IC.key_ordinal = 1
               )
   )
BEGIN
    CREATE NONCLUSTERED INDEX [IX_Senhas_IdPessoa]
        ON Online.Senhas (IdPessoa);
END;
IF (NOT EXISTS (
               SELECT I.name,
                      C.*
               FROM sys.indexes AS I
                    JOIN
                    sys.index_columns AS IC ON I.object_id = IC.object_id
                                               AND I.index_id = IC.index_id
                    JOIN
                    sys.columns AS C ON I.object_id = C.object_id
               WHERE I.object_id = 866818150
                     AND C.name = 'IdLancamento'
                     AND I.type > 1
                     AND IC.key_ordinal = 1
               )
   )
BEGIN
    CREATE NONCLUSTERED INDEX [nci_wi_LancamentosSituacoesHistoricos_CB6B45A2CE97C45BE336703B8EEBC1CE]
        ON DividaAtiva.LancamentosSituacoesHistoricos (IdLancamento)
        INCLUDE (IdSituacao, DataSituacao);
END;
IF (NOT EXISTS (
               SELECT I.name,
                      C.*
               FROM sys.indexes AS I
                    JOIN
                    sys.index_columns AS IC ON I.object_id = IC.object_id
                                               AND I.index_id = IC.index_id
                    JOIN
                    sys.columns AS C ON I.object_id = C.object_id
               WHERE I.object_id = 873770170
                     AND C.name = 'IdConciliacaoBancaria'
                     AND I.type > 1
                     AND IC.key_ordinal = 1
               )
   )
BEGIN
    CREATE NONCLUSTERED INDEX [IX_DespesaConciliacoesBancariasArquivosExtratoLancamentosIdConciliacaoBancaria]
        ON Despesa.ConciliacoesBancariasArquivosExtratoLancamentos (IdConciliacaoBancaria)
        INCLUDE (IdArquivoExtratoLancamento);
END;
IF (NOT EXISTS (
               SELECT I.name,
                      C.*
               FROM sys.indexes AS I
                    JOIN
                    sys.index_columns AS IC ON I.object_id = IC.object_id
                                               AND I.index_id = IC.index_id
                    JOIN
                    sys.columns AS C ON I.object_id = C.object_id
               WHERE I.object_id = 880722190
                     AND C.name = 'IdLancamento'
                     AND I.type > 1
                     AND IC.key_ordinal = 1
               )
   )
BEGIN
    CREATE NONCLUSTERED INDEX [IX_ContabilidadeMovimentosIdLancamento]
        ON Contabilidade.Movimentos (IdLancamento)
        INCLUDE (IdMovimento, IdPlanoConta, Credito, NumeroProcesso, NumeroDocumento, Valor, Historico);
END;
IF (NOT EXISTS (
               SELECT I.name,
                      C.*
               FROM sys.indexes AS I
                    JOIN
                    sys.index_columns AS IC ON I.object_id = IC.object_id
                                               AND I.index_id = IC.index_id
                    JOIN
                    sys.columns AS C ON I.object_id = C.object_id
               WHERE I.object_id = 887674210
                     AND C.name = 'DataAtualizacao'
                     AND I.type > 1
                     AND IC.key_ordinal = 1
               )
   )
BEGIN
    CREATE NONCLUSTERED INDEX [IX_CadastroTelefonesDataAtualizacao]
        ON Cadastro.Telefones (DataAtualizacao)
        INCLUDE
    (IdPessoa,
     Telefone,
     Tipo,
     NomeUsuarioCriacao,
     DataCriacao,
     NomeUnidadeCriacao,
     NomeUsuarioAtualizacao,
     NomeUnidadeAtualizacao
    )   ;
END;
IF (NOT EXISTS (
               SELECT I.name,
                      C.*
               FROM sys.indexes AS I
                    JOIN
                    sys.index_columns AS IC ON I.object_id = IC.object_id
                                               AND I.index_id = IC.index_id
                    JOIN
                    sys.columns AS C ON I.object_id = C.object_id
               WHERE I.object_id = 887674210
                     AND C.name = 'IdPessoa'
                     AND I.type > 1
                     AND IC.key_ordinal = 1
               )
   )
BEGIN
    CREATE NONCLUSTERED INDEX [IX_Telefones_IdPessoa]
        ON Cadastro.Telefones (IdPessoa);
END;
IF (NOT EXISTS (
               SELECT I.name,
                      C.*
               FROM sys.indexes AS I
                    JOIN
                    sys.index_columns AS IC ON I.object_id = IC.object_id
                                               AND I.index_id = IC.index_id
                    JOIN
                    sys.columns AS C ON I.object_id = C.object_id
               WHERE I.object_id = 920390348
                     AND C.name = 'Cancelado'
                     AND I.type > 1
                     AND IC.key_ordinal = 1
               )
   )
BEGIN
    CREATE NONCLUSTERED INDEX [IX_Pagamentos]
        ON Financeiro.Pagamentos (Cancelado, Estorno, IdFormaPagamento)
        INCLUDE (IdPessoa, DataPagamento, DataCredito, ValorPagamento, NomeUsuarioCriacao, ValorExcedente);
END;
IF (NOT EXISTS (
               SELECT I.name,
                      C.*
               FROM sys.indexes AS I
                    JOIN
                    sys.index_columns AS IC ON I.object_id = IC.object_id
                                               AND I.index_id = IC.index_id
                    JOIN
                    sys.columns AS C ON I.object_id = C.object_id
               WHERE I.object_id = 920390348
                     AND C.name = 'NossoNumero'
                     AND I.type > 1
                     AND IC.key_ordinal = 1
               )
   )
BEGIN
    CREATE NONCLUSTERED INDEX [nci_wi_Pagamentos_FD75C134130EBE3694F54D1E68BB0F84]
        ON Financeiro.Pagamentos (NossoNumero, NomeUsuarioCriacao);
END;
IF (NOT EXISTS (
               SELECT I.name,
                      C.*
               FROM sys.indexes AS I
                    JOIN
                    sys.index_columns AS IC ON I.object_id = IC.object_id
                                               AND I.index_id = IC.index_id
                    JOIN
                    sys.columns AS C ON I.object_id = C.object_id
               WHERE I.object_id = 927342368
                     AND C.name = 'IdUnidade'
                     AND I.type > 1
                     AND IC.key_ordinal = 1
               )
   )
BEGIN
    CREATE NONCLUSTERED INDEX [IX_DocumentoTiposDocumentosUnidadesIdUnidade]
        ON Documento.TiposDocumentosUnidades (IdUnidade)
        INCLUDE (IdTipoDocumento);
END;
IF (NOT EXISTS (
               SELECT I.name,
                      C.*
               FROM sys.indexes AS I
                    JOIN
                    sys.index_columns AS IC ON I.object_id = IC.object_id
                                               AND I.index_id = IC.index_id
                    JOIN
                    sys.columns AS C ON I.object_id = C.object_id
               WHERE I.object_id = 927342368
                     AND C.name = 'IdTipoDocumento'
                     AND I.type > 1
                     AND IC.key_ordinal = 1
               )
   )
BEGIN
    CREATE NONCLUSTERED INDEX [IX_TiposDocumentosUnidades_IdTipoDocumento]
        ON Documento.TiposDocumentosUnidades (IdTipoDocumento)
        INCLUDE (IdTipoDocumentoUnidade, IdUnidade);
END;
IF (NOT EXISTS (
               SELECT I.name,
                      C.*
               FROM sys.indexes AS I
                    JOIN
                    sys.index_columns AS IC ON I.object_id = IC.object_id
                                               AND I.index_id = IC.index_id
                    JOIN
                    sys.columns AS C ON I.object_id = C.object_id
               WHERE I.object_id = 935010412
                     AND C.name = 'IdPessoa'
                     AND I.type > 1
                     AND IC.key_ordinal = 1
               )
   )
BEGIN
    CREATE NONCLUSTERED INDEX [IX_ProcessosPessoasSecundarias_IdPessoa]
        ON Processo.ProcessosPessoasSecundarias (IdPessoa)
        INCLUDE (IdProcesso);
END;
IF (NOT EXISTS (
               SELECT I.name,
                      C.*
               FROM sys.indexes AS I
                    JOIN
                    sys.index_columns AS IC ON I.object_id = IC.object_id
                                               AND I.index_id = IC.index_id
                    JOIN
                    sys.columns AS C ON I.object_id = C.object_id
               WHERE I.object_id = 935010412
                     AND C.name = 'IdProcesso'
                     AND I.type > 1
                     AND IC.key_ordinal = 1
               )
   )
BEGIN
    CREATE NONCLUSTERED INDEX [IX_ProcessosPessoasSecundarias_IdProcesso]
        ON Processo.ProcessosPessoasSecundarias (IdProcesso)
        INCLUDE (IdPessoa);
END;
IF (NOT EXISTS (
               SELECT I.name,
                      C.*
               FROM sys.indexes AS I
                    JOIN
                    sys.index_columns AS IC ON I.object_id = IC.object_id
                                               AND I.index_id = IC.index_id
                    JOIN
                    sys.columns AS C ON I.object_id = C.object_id
               WHERE I.object_id = 937770398
                     AND C.name = 'IdSaidaFinanceira'
                     AND I.type > 1
                     AND IC.key_ordinal = 1
               )
   )
BEGIN
    CREATE NONCLUSTERED INDEX [IX_DespesaConciliacoesBancariasSaidasFinanceirasIdSaidaFinanceira]
        ON Despesa.ConciliacoesBancariasSaidasFinanceiras (IdSaidaFinanceira);
END;
IF (NOT EXISTS (
               SELECT I.name,
                      C.*
               FROM sys.indexes AS I
                    JOIN
                    sys.index_columns AS IC ON I.object_id = IC.object_id
                                               AND I.index_id = IC.index_id
                    JOIN
                    sys.columns AS C ON I.object_id = C.object_id
               WHERE I.object_id = 944722418
                     AND C.name = 'IdConselho'
                     AND I.type > 1
                     AND IC.key_ordinal = 1
               )
   )
BEGIN
    CREATE NONCLUSTERED INDEX [UNQ_ContabilidadePeriodosContabilizacoesIdConselho]
        ON Contabilidade.PeriodosContabilizacoes (IdConselho);
END;
IF (NOT EXISTS (
               SELECT I.name,
                      C.*
               FROM sys.indexes AS I
                    JOIN
                    sys.index_columns AS IC ON I.object_id = IC.object_id
                                               AND I.index_id = IC.index_id
                    JOIN
                    sys.columns AS C ON I.object_id = C.object_id
               WHERE I.object_id = 956582496
                     AND C.name = 'Nome'
                     AND I.type > 1
                     AND IC.key_ordinal = 1
               )
   )
BEGIN
    CREATE NONCLUSTERED INDEX [UNQ_RegistroTiposInscricoesNomeProfissional]
        ON Registro.TiposInscricoes (Nome, Profissional);
END;
IF (NOT EXISTS (
               SELECT I.name,
                      C.*
               FROM sys.indexes AS I
                    JOIN
                    sys.index_columns AS IC ON I.object_id = IC.object_id
                                               AND I.index_id = IC.index_id
                    JOIN
                    sys.columns AS C ON I.object_id = C.object_id
               WHERE I.object_id = 992722589
                     AND C.name = 'Agrupador'
                     AND I.type > 1
                     AND IC.key_ordinal = 1
               )
   )
BEGIN
    CREATE NONCLUSTERED INDEX [IX_ContabilidadePlanoContasAgrupadorCodigo]
        ON Contabilidade.PlanoContas (Agrupador, Codigo);
END;
IF (NOT EXISTS (
               SELECT I.name,
                      C.*
               FROM sys.indexes AS I
                    JOIN
                    sys.index_columns AS IC ON I.object_id = IC.object_id
                                               AND I.index_id = IC.index_id
                    JOIN
                    sys.columns AS C ON I.object_id = C.object_id
               WHERE I.object_id = 992722589
                     AND C.name = 'IdPlanoContaPai'
                     AND I.type > 1
                     AND IC.key_ordinal = 1
               )
   )
BEGIN
    CREATE NONCLUSTERED INDEX [missing_index_32_31]
        ON Contabilidade.PlanoContas (IdPlanoContaPai);
END;
IF (NOT EXISTS (
               SELECT I.name,
                      C.*
               FROM sys.indexes AS I
                    JOIN
                    sys.index_columns AS IC ON I.object_id = IC.object_id
                                               AND I.index_id = IC.index_id
                    JOIN
                    sys.columns AS C ON I.object_id = C.object_id
               WHERE I.object_id = 995534630
                     AND C.name = 'IdPessoaJuridica'
                     AND I.type > 1
                     AND IC.key_ordinal = 1
               )
   )
BEGIN
    CREATE NONCLUSTERED INDEX [nci_wi_CapitaisSociais_AEFC0344F565BBD365AE5746C1B2DF87]
        ON Registro.CapitaisSociais (IdPessoaJuridica, DataContrato)
        INCLUDE
    (Valor,
     QuantidadeCotas,
     DataAtualizacao,
     NomeUsuarioCriacao,
     DataCriacao,
     NomeUnidadeCriacao,
     NomeUsuarioAtualizacao,
     NomeUnidadeAtualizacao
    )   ;
END;
IF (NOT EXISTS (
               SELECT I.name,
                      C.*
               FROM sys.indexes AS I
                    JOIN
                    sys.index_columns AS IC ON I.object_id = IC.object_id
                                               AND I.index_id = IC.index_id
                    JOIN
                    sys.columns AS C ON I.object_id = C.object_id
               WHERE I.object_id = 1059534858
                     AND C.name = 'Nome'
                     AND I.type > 1
                     AND IC.key_ordinal = 1
               )
   )
BEGIN
    CREATE NONCLUSTERED INDEX [UNQ_RegistroCategoriasNomeProfissional]
        ON Registro.Categorias (Nome, Profissional);
END;
IF (NOT EXISTS (
               SELECT I.name,
                      C.*
               FROM sys.indexes AS I
                    JOIN
                    sys.index_columns AS IC ON I.object_id = IC.object_id
                                               AND I.index_id = IC.index_id
                    JOIN
                    sys.columns AS C ON I.object_id = C.object_id
               WHERE I.object_id = 1065770854
                     AND C.name = 'Exercicio'
                     AND I.type > 1
                     AND IC.key_ordinal = 1
               )
   )
BEGIN
    CREATE NONCLUSTERED INDEX [UNQ_DespesaDemonstracoesProgramacoesOrcamentariasExercicio]
        ON Despesa.DemonstracoesProgramacoesOrcamentarias (Exercicio);
END;
IF (NOT EXISTS (
               SELECT I.name,
                      C.*
               FROM sys.indexes AS I
                    JOIN
                    sys.index_columns AS IC ON I.object_id = IC.object_id
                                               AND I.index_id = IC.index_id
                    JOIN
                    sys.columns AS C ON I.object_id = C.object_id
               WHERE I.object_id = 1080390918
                     AND C.name = 'IdDebito'
                     AND I.type > 1
                     AND IC.key_ordinal = 1
               )
   )
BEGIN
    CREATE NONCLUSTERED INDEX [IX_PagamentosDebitos_IdDebito]
        ON Financeiro.PagamentosDebitos (IdDebito);
END;
IF (NOT EXISTS (
               SELECT I.name,
                      C.*
               FROM sys.indexes AS I
                    JOIN
                    sys.index_columns AS IC ON I.object_id = IC.object_id
                                               AND I.index_id = IC.index_id
                    JOIN
                    sys.columns AS C ON I.object_id = C.object_id
               WHERE I.object_id = 1080390918
                     AND C.name = 'IdDebito'
                     AND I.type > 1
                     AND IC.key_ordinal = 1
               )
   )
BEGIN
    CREATE NONCLUSTERED INDEX [IX_PagamentosDebitos_IdDebitoDetalhado]
        ON Financeiro.PagamentosDebitos (IdDebito)
        INCLUDE
    (IdPagamento,
     ValorTotal,
     ValorJuros,
     ValorMulta,
     ValorPrincipal,
     ValorExcedente,
     ValorRepasseFederal,
     ValorTarifaBancaria,
     ValorLiquido
    )   ;
END;
IF (NOT EXISTS (
               SELECT I.name,
                      C.*
               FROM sys.indexes AS I
                    JOIN
                    sys.index_columns AS IC ON I.object_id = IC.object_id
                                               AND I.index_id = IC.index_id
                    JOIN
                    sys.columns AS C ON I.object_id = C.object_id
               WHERE I.object_id = 1080390918
                     AND C.name = 'IdPagamento'
                     AND I.type > 1
                     AND IC.key_ordinal = 1
               )
   )
BEGIN
    CREATE NONCLUSTERED INDEX [IX_PagamentosDebitos_IdPagamento]
        ON Financeiro.PagamentosDebitos (IdPagamento);
END;
IF (NOT EXISTS (
               SELECT I.name,
                      C.*
               FROM sys.indexes AS I
                    JOIN
                    sys.index_columns AS IC ON I.object_id = IC.object_id
                                               AND I.index_id = IC.index_id
                    JOIN
                    sys.columns AS C ON I.object_id = C.object_id
               WHERE I.object_id = 1080390918
                     AND C.name = 'IdPagamento'
                     AND I.type > 1
                     AND IC.key_ordinal = 1
               )
   )
BEGIN
    CREATE NONCLUSTERED INDEX [IX_PagamentosDebitos_IdPagamentoIdDebito]
        ON Financeiro.PagamentosDebitos (IdPagamento, IdDebito);
END;
IF (NOT EXISTS (
               SELECT I.name,
                      C.*
               FROM sys.indexes AS I
                    JOIN
                    sys.index_columns AS IC ON I.object_id = IC.object_id
                                               AND I.index_id = IC.index_id
                    JOIN
                    sys.columns AS C ON I.object_id = C.object_id
               WHERE I.object_id = 1112391032
                     AND C.name = 'IdPagamento'
                     AND I.type > 1
                     AND IC.key_ordinal = 1
               )
   )
BEGIN
    CREATE NONCLUSTERED INDEX [missing_index_35_34]
        ON Financeiro.PagamentosEmissoes (IdPagamento)
        INCLUDE (IdEmissao);
END;
IF (NOT EXISTS (
               SELECT I.name,
                      C.*
               FROM sys.indexes AS I
                    JOIN
                    sys.index_columns AS IC ON I.object_id = IC.object_id
                                               AND I.index_id = IC.index_id
                    JOIN
                    sys.columns AS C ON I.object_id = C.object_id
               WHERE I.object_id = 1145771139
                     AND C.name = 'Exercicio'
                     AND I.type > 1
                     AND IC.key_ordinal = 1
               )
   )
BEGIN
    CREATE NONCLUSTERED INDEX [IX_Empenhos_ExercicioNumero]
        ON Despesa.Empenhos (Exercicio, Numero);
END;
IF (NOT EXISTS (
               SELECT I.name,
                      C.*
               FROM sys.indexes AS I
                    JOIN
                    sys.index_columns AS IC ON I.object_id = IC.object_id
                                               AND I.index_id = IC.index_id
                    JOIN
                    sys.columns AS C ON I.object_id = C.object_id
               WHERE I.object_id = 1145771139
                     AND C.name = 'IdPessoa'
                     AND I.type > 1
                     AND IC.key_ordinal = 1
               )
   )
BEGIN
    CREATE NONCLUSTERED INDEX [IX_Empenhos_IdPessoaIdPlanoContaNumeroRestoAPagar]
        ON Despesa.Empenhos (IdPessoa, IdPlanoConta, Numero, RestoAPagar, Exercicio);
END;
IF (NOT EXISTS (
               SELECT I.name,
                      C.*
               FROM sys.indexes AS I
                    JOIN
                    sys.index_columns AS IC ON I.object_id = IC.object_id
                                               AND I.index_id = IC.index_id
                    JOIN
                    sys.columns AS C ON I.object_id = C.object_id
               WHERE I.object_id = 1145771139
                     AND C.name = 'IdPlanoConta'
                     AND I.type > 1
                     AND IC.key_ordinal = 1
               )
   )
BEGIN
    CREATE NONCLUSTERED INDEX [missing_index_162_161]
        ON Despesa.Empenhos (IdPlanoConta);
END;
IF (NOT EXISTS (
               SELECT I.name,
                      C.*
               FROM sys.indexes AS I
                    JOIN
                    sys.index_columns AS IC ON I.object_id = IC.object_id
                                               AND I.index_id = IC.index_id
                    JOIN
                    sys.columns AS C ON I.object_id = C.object_id
               WHERE I.object_id = 1159011210
                     AND C.name = 'IdTramitacao'
                     AND I.type > 1
                     AND IC.key_ordinal = 1
               )
   )
BEGIN
    CREATE NONCLUSTERED INDEX [missing_index_12_11]
        ON Processo.ProcessosTramitacoes (IdTramitacao)
        INCLUDE (IdProcesso);
END;
IF (NOT EXISTS (
               SELECT I.name,
                      C.*
               FROM sys.indexes AS I
                    JOIN
                    sys.index_columns AS IC ON I.object_id = IC.object_id
                                               AND I.index_id = IC.index_id
                    JOIN
                    sys.columns AS C ON I.object_id = C.object_id
               WHERE I.object_id = 1159011210
                     AND C.name = 'IdTramitacao'
                     AND I.type > 1
                     AND IC.key_ordinal = 1
               )
   )
BEGIN
    CREATE NONCLUSTERED INDEX [missing_index_111_110]
        ON Processo.ProcessosTramitacoes (IdTramitacao);
END;
IF (NOT EXISTS (
               SELECT I.name,
                      C.*
               FROM sys.indexes AS I
                    JOIN
                    sys.index_columns AS IC ON I.object_id = IC.object_id
                                               AND I.index_id = IC.index_id
                    JOIN
                    sys.columns AS C ON I.object_id = C.object_id
               WHERE I.object_id = 1176391260
                     AND C.name = 'IdPagamento'
                     AND I.type > 1
                     AND IC.key_ordinal = 1
               )
   )
BEGIN
    CREATE NONCLUSTERED INDEX [IX_PagamentosParcelamentosComposicoes_IdPagamento]
        ON Financeiro.PagamentosParcelamentosComposicoes (IdPagamento);
END;
IF (NOT EXISTS (
               SELECT I.name,
                      C.*
               FROM sys.indexes AS I
                    JOIN
                    sys.index_columns AS IC ON I.object_id = IC.object_id
                                               AND I.index_id = IC.index_id
                    JOIN
                    sys.columns AS C ON I.object_id = C.object_id
               WHERE I.object_id = 1176391260
                     AND C.name = 'IdParcelamentoComposicao'
                     AND I.type > 1
                     AND IC.key_ordinal = 1
               )
   )
BEGIN
    CREATE NONCLUSTERED INDEX [nci_wi_PagamentosParcelamentosComposicoes_5A4D2A5B497DFE493D9A678BFF229655]
        ON Financeiro.PagamentosParcelamentosComposicoes (IdParcelamentoComposicao)
        INCLUDE (IdPagamento);
END;
IF (NOT EXISTS (
               SELECT I.name,
                      C.*
               FROM sys.indexes AS I
                    JOIN
                    sys.index_columns AS IC ON I.object_id = IC.object_id
                                               AND I.index_id = IC.index_id
                    JOIN
                    sys.columns AS C ON I.object_id = C.object_id
               WHERE I.object_id = 1176391260
                     AND C.name = 'IdParcelamentoComposicao'
                     AND I.type > 1
                     AND IC.key_ordinal = 1
               )
   )
BEGIN
    CREATE NONCLUSTERED INDEX [IX_PagamentosParcelamentosComposicoes_IdParcelamentoComposicao]
        ON Financeiro.PagamentosParcelamentosComposicoes (IdParcelamentoComposicao);
END;
IF (NOT EXISTS (
               SELECT I.name,
                      C.*
               FROM sys.indexes AS I
                    JOIN
                    sys.index_columns AS IC ON I.object_id = IC.object_id
                                               AND I.index_id = IC.index_id
                    JOIN
                    sys.columns AS C ON I.object_id = C.object_id
               WHERE I.object_id = 1177771253
                     AND C.name = 'IdEmpenho'
                     AND I.type > 1
                     AND IC.key_ordinal = 1
               )
   )
BEGIN
    CREATE NONCLUSTERED INDEX [IX_EmpenhosCentroCustos_IdEmpenho]
        ON Despesa.EmpenhosCentroCustos (IdEmpenho);
END;
IF (NOT EXISTS (
               SELECT I.name,
                      C.*
               FROM sys.indexes AS I
                    JOIN
                    sys.index_columns AS IC ON I.object_id = IC.object_id
                                               AND I.index_id = IC.index_id
                    JOIN
                    sys.columns AS C ON I.object_id = C.object_id
               WHERE I.object_id = 1193107341
                     AND C.name = 'Nome'
                     AND I.type > 1
                     AND IC.key_ordinal = 1
               )
   )
BEGIN
    CREATE NONCLUSTERED INDEX [UNQ_SistemaSistemasNome]
        ON Sistema.Sistemas (Nome);
END;
IF (NOT EXISTS (
               SELECT I.name,
                      C.*
               FROM sys.indexes AS I
                    JOIN
                    sys.index_columns AS IC ON I.object_id = IC.object_id
                                               AND I.index_id = IC.index_id
                    JOIN
                    sys.columns AS C ON I.object_id = C.object_id
               WHERE I.object_id = 1206295357
                     AND C.name = 'IdPessoa'
                     AND I.type > 1
                     AND IC.key_ordinal = 1
               )
   )
BEGIN
    CREATE NONCLUSTERED INDEX [missing_index_71_70]
        ON Despesa.SaidasFinanceiras (IdPessoa)
        INCLUDE (IdPlanoConta, Valor);
END;
IF (NOT EXISTS (
               SELECT I.name,
                      C.*
               FROM sys.indexes AS I
                    JOIN
                    sys.index_columns AS IC ON I.object_id = IC.object_id
                                               AND I.index_id = IC.index_id
                    JOIN
                    sys.columns AS C ON I.object_id = C.object_id
               WHERE I.object_id = 1206295357
                     AND C.name = 'IdPessoa'
                     AND I.type > 1
                     AND IC.key_ordinal = 1
               )
   )
BEGIN
    CREATE NONCLUSTERED INDEX [missing_index_80_79]
        ON Despesa.SaidasFinanceiras (IdPessoa);
END;
IF (NOT EXISTS (
               SELECT I.name,
                      C.*
               FROM sys.indexes AS I
                    JOIN
                    sys.index_columns AS IC ON I.object_id = IC.object_id
                                               AND I.index_id = IC.index_id
                    JOIN
                    sys.columns AS C ON I.object_id = C.object_id
               WHERE I.object_id = 1209771367
                     AND C.name = 'IdEmpenho'
                     AND I.type > 1
                     AND IC.key_ordinal = 1
               )
   )
BEGIN
    CREATE NONCLUSTERED INDEX [IX_DespesaEmpenhosLancamentosIdEmpenho]
        ON Despesa.EmpenhosLancamentos (IdEmpenho);
END;
IF (NOT EXISTS (
               SELECT I.name,
                      C.*
               FROM sys.indexes AS I
                    JOIN
                    sys.index_columns AS IC ON I.object_id = IC.object_id
                                               AND I.index_id = IC.index_id
                    JOIN
                    sys.columns AS C ON I.object_id = C.object_id
               WHERE I.object_id = 1241771481
                     AND C.name = 'IdEmpenho'
                     AND I.type > 1
                     AND IC.key_ordinal = 1
               )
   )
BEGIN
    CREATE NONCLUSTERED INDEX [IX_DespesaEmpenhosModalidadesContratacoesIdEmpenho]
        ON Despesa.EmpenhosModalidadesContratacoes (IdEmpenho)
        INCLUDE (IdEmpenhoModalidadeContracao, IdModalidadeContratacao);
END;
IF (NOT EXISTS (
               SELECT I.name,
                      C.*
               FROM sys.indexes AS I
                    JOIN
                    sys.index_columns AS IC ON I.object_id = IC.object_id
                                               AND I.index_id = IC.index_id
                    JOIN
                    sys.columns AS C ON I.object_id = C.object_id
               WHERE I.object_id = 1247343508
                     AND C.name = 'IdDebito'
                     AND I.type > 1
                     AND IC.key_ordinal = 1
               )
   )
BEGIN
    CREATE NONCLUSTERED INDEX [IX_CancelamentosDebitos_IdDebito]
        ON Financeiro.CancelamentosDebitos (IdDebito);
END;
IF (NOT EXISTS (
               SELECT I.name,
                      C.*
               FROM sys.indexes AS I
                    JOIN
                    sys.index_columns AS IC ON I.object_id = IC.object_id
                                               AND I.index_id = IC.index_id
                    JOIN
                    sys.columns AS C ON I.object_id = C.object_id
               WHERE I.object_id = 1247343508
                     AND C.name = 'IdDebito'
                     AND I.type > 1
                     AND IC.key_ordinal = 1
               )
   )
BEGIN
    CREATE NONCLUSTERED INDEX [IX_CancelamentosDebitos_IdDebitoDetalhado]
        ON Financeiro.CancelamentosDebitos (IdDebito)
        INCLUDE (IdCancelamentoDebito, IdCancelamento, IdDebitoSituacaoAnterior);
END;
IF (NOT EXISTS (
               SELECT I.name,
                      C.*
               FROM sys.indexes AS I
                    JOIN
                    sys.index_columns AS IC ON I.object_id = IC.object_id
                                               AND I.index_id = IC.index_id
                    JOIN
                    sys.columns AS C ON I.object_id = C.object_id
               WHERE I.object_id = 1272391602
                     AND C.name = 'IdParcelamentoTipo'
                     AND I.type > 1
                     AND IC.key_ordinal = 1
               )
   )
BEGIN
    CREATE NONCLUSTERED INDEX [IX_Parcelamentos_IdParcelamentoTipoIdPessoa]
        ON Financeiro.Parcelamentos (IdParcelamentoTipo, IdPessoa);
END;
IF (NOT EXISTS (
               SELECT I.name,
                      C.*
               FROM sys.indexes AS I
                    JOIN
                    sys.index_columns AS IC ON I.object_id = IC.object_id
                                               AND I.index_id = IC.index_id
                    JOIN
                    sys.columns AS C ON I.object_id = C.object_id
               WHERE I.object_id = 1272391602
                     AND C.name = 'IdParcelamentoTipo'
                     AND I.type > 1
                     AND IC.key_ordinal = 1
               )
   )
BEGIN
    CREATE NONCLUSTERED INDEX [IX_Parcelamentos_IdParcelamentoTipoIdPessoaAtivo]
        ON Financeiro.Parcelamentos (IdParcelamentoTipo, IdPessoa, Ativo);
END;
IF (NOT EXISTS (
               SELECT I.name,
                      C.*
               FROM sys.indexes AS I
                    JOIN
                    sys.index_columns AS IC ON I.object_id = IC.object_id
                                               AND I.index_id = IC.index_id
                    JOIN
                    sys.columns AS C ON I.object_id = C.object_id
               WHERE I.object_id = 1272391602
                     AND C.name = 'IdParcelamentoTipo'
                     AND I.type > 1
                     AND IC.key_ordinal = 1
               )
   )
BEGIN
    CREATE NONCLUSTERED INDEX [IX_Parcelamentos_IdParcelamentoTipo]
        ON Financeiro.Parcelamentos (IdParcelamentoTipo, IdPessoa)
        INCLUDE
    (ValorTotal,
     Ativo,
     DataAtualizacao,
     NomeUsuarioCriacao,
     DataCriacao,
     NomeUnidadeCriacao,
     NomeUsuarioAtualizacao,
     NomeUnidadeAtualizacao,
     Observacoes,
     PrioridadeBaixa,
     ValorTotalPrincipal,
     ValorTotalDescontoPrincipal,
     ValorTotalJuros,
     ValorTotalDescontoJuros,
     ValorTotalMulta,
     ValorTotalDescontoMulta,
     ValorTotalAcrescimo,
     ValorTotalJurosSobreParcela,
     DataParcelamento,
     Numero,
     DataNotificacaoInadimplencia,
     ValorTotalAtualizacaoMonetaria,
     ValorTotalDescontoAtualizacaoMonetaria
    )   ;
END;
IF (NOT EXISTS (
               SELECT I.name,
                      C.*
               FROM sys.indexes AS I
                    JOIN
                    sys.index_columns AS IC ON I.object_id = IC.object_id
                                               AND I.index_id = IC.index_id
                    JOIN
                    sys.columns AS C ON I.object_id = C.object_id
               WHERE I.object_id = 1272391602
                     AND C.name = 'IdPessoa'
                     AND I.type > 1
                     AND IC.key_ordinal = 1
               )
   )
BEGIN
    CREATE NONCLUSTERED INDEX [IX_Parcelamentos_IdPessoaAtivo]
        ON Financeiro.Parcelamentos (IdPessoa, Ativo);
END;
IF (NOT EXISTS (
               SELECT I.name,
                      C.*
               FROM sys.indexes AS I
                    JOIN
                    sys.index_columns AS IC ON I.object_id = IC.object_id
                                               AND I.index_id = IC.index_id
                    JOIN
                    sys.columns AS C ON I.object_id = C.object_id
               WHERE I.object_id = 1291867669
                     AND C.name = 'IdDebitoSituacaoPagamento'
                     AND I.type > 1
                     AND IC.key_ordinal = 1
               )
   )
BEGIN
    CREATE NONCLUSTERED INDEX [IX_Debitos_IdDebitoSituacaoPagamento]
        ON Financeiro.Debitos (IdDebitoSituacaoPagamento, IdDebitoSituacaoDividaAtiva)
        INCLUDE (IdPessoa);
END;
IF (NOT EXISTS (
               SELECT I.name,
                      C.*
               FROM sys.indexes AS I
                    JOIN
                    sys.index_columns AS IC ON I.object_id = IC.object_id
                                               AND I.index_id = IC.index_id
                    JOIN
                    sys.columns AS C ON I.object_id = C.object_id
               WHERE I.object_id = 1291867669
                     AND C.name = 'IdDebitoTipo'
                     AND I.type > 1
                     AND IC.key_ordinal = 1
               )
   )
BEGIN
    CREATE NONCLUSTERED INDEX [IX_Debitos_IdDebitoTipoAnoReferencia]
        ON Financeiro.Debitos (IdDebitoTipo, AnoReferencia);
END;
IF (NOT EXISTS (
               SELECT I.name,
                      C.*
               FROM sys.indexes AS I
                    JOIN
                    sys.index_columns AS IC ON I.object_id = IC.object_id
                                               AND I.index_id = IC.index_id
                    JOIN
                    sys.columns AS C ON I.object_id = C.object_id
               WHERE I.object_id = 1291867669
                     AND C.name = 'IdPessoa'
                     AND I.type > 1
                     AND IC.key_ordinal = 1
               )
   )
BEGIN
    CREATE NONCLUSTERED INDEX [IX_Debitos_IdPessoaIdDebitoSituacaoPagamento]
        ON Financeiro.Debitos (IdPessoa, IdDebitoSituacaoPagamento);
END;
IF (NOT EXISTS (
               SELECT I.name,
                      C.*
               FROM sys.indexes AS I
                    JOIN
                    sys.index_columns AS IC ON I.object_id = IC.object_id
                                               AND I.index_id = IC.index_id
                    JOIN
                    sys.columns AS C ON I.object_id = C.object_id
               WHERE I.object_id = 1291867669
                     AND C.name = 'IdPessoa'
                     AND I.type > 1
                     AND IC.key_ordinal = 1
               )
   )
BEGIN
    CREATE NONCLUSTERED INDEX [IX_Debitos_IdPessoa]
        ON Financeiro.Debitos (IdPessoa)
        INCLUDE (DataVencimento);
END;
IF (NOT EXISTS (
               SELECT I.name,
                      C.*
               FROM sys.indexes AS I
                    JOIN
                    sys.index_columns AS IC ON I.object_id = IC.object_id
                                               AND I.index_id = IC.index_id
                    JOIN
                    sys.columns AS C ON I.object_id = C.object_id
               WHERE I.object_id = 1291867669
                     AND C.name = 'IdDebitoTipo'
                     AND I.type > 1
                     AND IC.key_ordinal = 1
               )
   )
BEGIN
    CREATE NONCLUSTERED INDEX [IX_FinanceiroDebitosIdDebitoTipo_IdPessoa_AnoReferencia_IdDebitoSituacaoPagamento]
        ON Financeiro.Debitos (IdDebitoTipo, IdPessoa, AnoReferencia, IdDebitoSituacaoPagamento);
END;
IF (NOT EXISTS (
               SELECT I.name,
                      C.*
               FROM sys.indexes AS I
                    JOIN
                    sys.index_columns AS IC ON I.object_id = IC.object_id
                                               AND I.index_id = IC.index_id
                    JOIN
                    sys.columns AS C ON I.object_id = C.object_id
               WHERE I.object_id = 1291867669
                     AND C.name = 'IdDebitoTipo'
                     AND I.type > 1
                     AND IC.key_ordinal = 1
               )
   )
BEGIN
    CREATE NONCLUSTERED INDEX [nci_wi_Debitos_13FDE04F110F986D44F489FEC79EADC6]
        ON Financeiro.Debitos (IdDebitoTipo)
        INCLUDE
    (IdPessoa,
     AnoReferencia,
     ValorPrincipal,
     ValorAmortizado,
     DataVencimento,
     DataAtualizacao,
     NomeUsuarioCriacao,
     DataCriacao,
     NomeUnidadeCriacao,
     NomeUsuarioAtualizacao,
     NomeUnidadeAtualizacao,
     Observacoes,
     ValorPago,
     GeracaoColetiva,
     DescontoGeracaoColetiva,
     IdDebitoSituacaoPagamento,
     IdDebitoSituacaoParcelamento,
     ValorDevido,
     ValorDescontoPgtoAntecipado,
     PossuiEmissao,
     IdDebitoSituacaoDividaAtiva,
     DataReferencia,
     IdConfiguracaoValoresDT,
     ValorExcedente,
     ValorAmortizadoPelaMargem,
     IdDebitoSituacaoSerasa,
     ValorAmortizadoDescontoPrincipal
    )   ;
END;
IF (NOT EXISTS (
               SELECT I.name,
                      C.*
               FROM sys.indexes AS I
                    JOIN
                    sys.index_columns AS IC ON I.object_id = IC.object_id
                                               AND I.index_id = IC.index_id
                    JOIN
                    sys.columns AS C ON I.object_id = C.object_id
               WHERE I.object_id = 1291867669
                     AND C.name = 'IdPessoa'
                     AND I.type > 1
                     AND IC.key_ordinal = 1
               )
   )
BEGIN
    CREATE NONCLUSTERED INDEX [IX_Debitos_IdPessoaIdDebitoSituacaoParcelamento]
        ON Financeiro.Debitos (IdPessoa, IdDebitoSituacaoParcelamento, IdDebitoSituacaoDividaAtiva);
END;
IF (NOT EXISTS (
               SELECT I.name,
                      C.*
               FROM sys.indexes AS I
                    JOIN
                    sys.index_columns AS IC ON I.object_id = IC.object_id
                                               AND I.index_id = IC.index_id
                    JOIN
                    sys.columns AS C ON I.object_id = C.object_id
               WHERE I.object_id = 1291867669
                     AND C.name = 'IdDebitoSituacaoParcelamento'
                     AND I.type > 1
                     AND IC.key_ordinal = 1
               )
   )
BEGIN
    CREATE NONCLUSTERED INDEX [IX_Debitos_IdDebitoSituacaoParcelamento]
        ON Financeiro.Debitos (IdDebitoSituacaoParcelamento, IdDebitoSituacaoDividaAtiva)
        INCLUDE (IdDebitoTipo, IdPessoa);
END;
IF (NOT EXISTS (
               SELECT I.name,
                      C.*
               FROM sys.indexes AS I
                    JOIN
                    sys.index_columns AS IC ON I.object_id = IC.object_id
                                               AND I.index_id = IC.index_id
                    JOIN
                    sys.columns AS C ON I.object_id = C.object_id
               WHERE I.object_id = 1304391716
                     AND C.name = 'IdDebito'
                     AND I.type > 1
                     AND IC.key_ordinal = 1
               )
   )
BEGIN
    CREATE NONCLUSTERED INDEX [IX_ParcelamentosComposicoes_IdDebito]
        ON Financeiro.ParcelamentosComposicoes (IdDebito)
        INCLUDE (IdParcelamentoParcela);
END;
IF (NOT EXISTS (
               SELECT I.name,
                      C.*
               FROM sys.indexes AS I
                    JOIN
                    sys.index_columns AS IC ON I.object_id = IC.object_id
                                               AND I.index_id = IC.index_id
                    JOIN
                    sys.columns AS C ON I.object_id = C.object_id
               WHERE I.object_id = 1304391716
                     AND C.name = 'IdParcelamentoParcela'
                     AND I.type > 1
                     AND IC.key_ordinal = 1
               )
   )
BEGIN
    CREATE NONCLUSTERED INDEX [IX_ParcelamentosComposicoes_IdParcelamentoParcela]
        ON Financeiro.ParcelamentosComposicoes (IdParcelamentoParcela)
        INCLUDE
    (IdDebito,
     OrdemBaixa,
     PercentualPrincipal,
     ValorPrincipal,
     ValorDescontoPrincipal,
     ValorJuros,
     ValorDescontoJuros,
     ValorMulta,
     ValorDescontoMulta,
     ValorAcrescimo,
     ValorJurosSobreParcela,
     ValorParcela,
     ValorAmortizadoParcela,
     ValorAmortizadoPrincipal,
     ValorAtualizacaoMonetaria,
     ValorExcedente,
     ValorAmortizadoPelaMargem
    )   ;
END;
IF (NOT EXISTS (
               SELECT I.name,
                      C.*
               FROM sys.indexes AS I
                    JOIN
                    sys.index_columns AS IC ON I.object_id = IC.object_id
                                               AND I.index_id = IC.index_id
                    JOIN
                    sys.columns AS C ON I.object_id = C.object_id
               WHERE I.object_id = 1304391716
                     AND C.name = 'ValorAmortizadoPrincipal'
                     AND I.type > 1
                     AND IC.key_ordinal = 1
               )
   )
BEGIN
    CREATE NONCLUSTERED INDEX [IX_ParcelamentosComposicoes_ValorAmortizadoPrincipal]
        ON Financeiro.ParcelamentosComposicoes (ValorAmortizadoPrincipal)
        INCLUDE
    (IdParcelamentoParcela,
     IdDebito,
     OrdemBaixa,
     PercentualPrincipal,
     ValorPrincipal,
     ValorDescontoPrincipal,
     ValorJuros,
     ValorDescontoJuros,
     ValorMulta,
     ValorDescontoMulta,
     ValorAcrescimo,
     ValorJurosSobreParcela,
     ValorParcela,
     ValorAmortizadoParcela,
     ValorAtualizacaoMonetaria,
     ValorExcedente,
     ValorAmortizadoPelaMargem
    )   ;
END;
IF (NOT EXISTS (
               SELECT I.name,
                      C.*
               FROM sys.indexes AS I
                    JOIN
                    sys.index_columns AS IC ON I.object_id = IC.object_id
                                               AND I.index_id = IC.index_id
                    JOIN
                    sys.columns AS C ON I.object_id = C.object_id
               WHERE I.object_id = 1314819746
                     AND C.name = 'IdBairroImplanta'
                     AND I.type > 1
                     AND IC.key_ordinal = 1
               )
   )
BEGIN
    CREATE NONCLUSTERED INDEX [IX_DNEBairrosDNEIdBairroImplanta]
        ON DNE.BairrosDNE (IdBairroImplanta);
END;
IF (NOT EXISTS (
               SELECT I.name,
                      C.*
               FROM sys.indexes AS I
                    JOIN
                    sys.index_columns AS IC ON I.object_id = IC.object_id
                                               AND I.index_id = IC.index_id
                    JOIN
                    sys.columns AS C ON I.object_id = C.object_id
               WHERE I.object_id = 1314819746
                     AND C.name = 'IdLocalidade'
                     AND I.type > 1
                     AND IC.key_ordinal = 1
               )
   )
BEGIN
    CREATE NONCLUSTERED INDEX [IX_DNEBairrosDNEIdLocalidade]
        ON DNE.BairrosDNE (IdLocalidade);
END;
IF (NOT EXISTS (
               SELECT I.name,
                      C.*
               FROM sys.indexes AS I
                    JOIN
                    sys.index_columns AS IC ON I.object_id = IC.object_id
                                               AND I.index_id = IC.index_id
                    JOIN
                    sys.columns AS C ON I.object_id = C.object_id
               WHERE I.object_id = 1399676034
                     AND C.name = 'OrderNumber'
                     AND I.type > 1
                     AND IC.key_ordinal = 1
               )
   )
BEGIN
    CREATE NONCLUSTERED INDEX [IX_CieloTransacoes_OrderNumber]
        ON Cielo.Transacoes (OrderNumber);
END;
IF (NOT EXISTS (
               SELECT I.name,
                      C.*
               FROM sys.indexes AS I
                    JOIN
                    sys.index_columns AS IC ON I.object_id = IC.object_id
                                               AND I.index_id = IC.index_id
                    JOIN
                    sys.columns AS C ON I.object_id = C.object_id
               WHERE I.object_id = 1410820088
                     AND C.name = 'Numero'
                     AND I.type > 1
                     AND IC.key_ordinal = 1
               )
   )
BEGIN
    CREATE NONCLUSTERED INDEX [IX_CaixasPostaisComunitarias]
        ON DNE.CaixasPostaisComunitarias (Numero);
END;
IF (NOT EXISTS (
               SELECT I.name,
                      C.*
               FROM sys.indexes AS I
                    JOIN
                    sys.index_columns AS IC ON I.object_id = IC.object_id
                                               AND I.index_id = IC.index_id
                    JOIN
                    sys.columns AS C ON I.object_id = C.object_id
               WHERE I.object_id = 1432392172
                     AND C.name = 'IdParcelamento'
                     AND I.type > 1
                     AND IC.key_ordinal = 1
               )
   )
BEGIN
    CREATE NONCLUSTERED INDEX [IDX_ParcelamentosParcelas_IdParcelamentoDataVencimento]
        ON Financeiro.ParcelamentosParcelas (IdParcelamento, DataVencimento)
        INCLUDE (IdParcelaSituacaoPagamento);
END;
IF (NOT EXISTS (
               SELECT I.name,
                      C.*
               FROM sys.indexes AS I
                    JOIN
                    sys.index_columns AS IC ON I.object_id = IC.object_id
                                               AND I.index_id = IC.index_id
                    JOIN
                    sys.columns AS C ON I.object_id = C.object_id
               WHERE I.object_id = 1432392172
                     AND C.name = 'DataVencimento'
                     AND I.type > 1
                     AND IC.key_ordinal = 1
               )
   )
BEGIN
    CREATE NONCLUSTERED INDEX [IX_ParcelamentosParcelas_DataVencimentoIdParcelaSituacaoPagamento]
        ON Financeiro.ParcelamentosParcelas (DataVencimento, IdParcelaSituacaoPagamento)
        INCLUDE
    (IdParcelamento,
     ValorParcela,
     ValorPrincipal,
     ValorDescontoPrincipal,
     ValorJuros,
     ValorDescontoJuros,
     ValorMulta,
     ValorDescontoMulta,
     ValorAcrescimo,
     ValorJurosSobreParcela,
     NumeroParcela,
     PossuiEmissao,
     UltimoNossoNumero,
     DataUltimoPagamento,
     ValorTotalPago,
     ValorAmortizadoParcela,
     ValorAmortizadoPrincipal,
     ValorAtualizacaoMonetaria,
     ValorExcedente,
     ValorAmortizadoPelaMargem
    )   ;
END;
IF (NOT EXISTS (
               SELECT I.name,
                      C.*
               FROM sys.indexes AS I
                    JOIN
                    sys.index_columns AS IC ON I.object_id = IC.object_id
                                               AND I.index_id = IC.index_id
                    JOIN
                    sys.columns AS C ON I.object_id = C.object_id
               WHERE I.object_id = 1432392172
                     AND C.name = 'IdParcelamento'
                     AND I.type > 1
                     AND IC.key_ordinal = 1
               )
   )
BEGIN
    CREATE NONCLUSTERED INDEX [IX_ParcelamentosParcelas_IdParcelamento]
        ON Financeiro.ParcelamentosParcelas (IdParcelamento);
END;
IF (NOT EXISTS (
               SELECT I.name,
                      C.*
               FROM sys.indexes AS I
                    JOIN
                    sys.index_columns AS IC ON I.object_id = IC.object_id
                                               AND I.index_id = IC.index_id
                    JOIN
                    sys.columns AS C ON I.object_id = C.object_id
               WHERE I.object_id = 1867869721
                     AND C.name = 'TipoSaida'
                     AND I.type > 1
                     AND IC.key_ordinal = 1
               )
   )
BEGIN
    CREATE NONCLUSTERED INDEX [IX_Emissoes_TipoSaidaDataEmissao]
        ON Financeiro.Emissoes (TipoSaida, DataEmissao)
        INCLUDE (IdEmissao, IdPessoa);
END;
IF (NOT EXISTS (
               SELECT I.name,
                      C.*
               FROM sys.indexes AS I
                    JOIN
                    sys.index_columns AS IC ON I.object_id = IC.object_id
                                               AND I.index_id = IC.index_id
                    JOIN
                    sys.columns AS C ON I.object_id = C.object_id
               WHERE I.object_id = 1432392172
                     AND C.name = 'IdParcelamento'
                     AND I.type > 1
                     AND IC.key_ordinal = 1
               )
   )
BEGIN
    CREATE NONCLUSTERED INDEX [IX_ParcelamentosParcelas_IdParcelamentoDetalhado]
        ON Financeiro.ParcelamentosParcelas (IdParcelamento)
        INCLUDE
    (DataVencimento,
     ValorParcela,
     ValorPrincipal,
     ValorDescontoPrincipal,
     ValorJuros,
     ValorDescontoJuros,
     ValorMulta,
     ValorDescontoMulta,
     ValorAcrescimo,
     ValorJurosSobreParcela,
     NumeroParcela,
     PossuiEmissao,
     UltimoNossoNumero,
     DataUltimoPagamento,
     ValorTotalPago,
     ValorAmortizadoParcela,
     ValorAmortizadoPrincipal,
     ValorAtualizacaoMonetaria,
     IdParcelaSituacaoPagamento,
     ValorExcedente,
     ValorAmortizadoPelaMargem
    )   ;
END;
IF (NOT EXISTS (
               SELECT I.name,
                      C.*
               FROM sys.indexes AS I
                    JOIN
                    sys.index_columns AS IC ON I.object_id = IC.object_id
                                               AND I.index_id = IC.index_id
                    JOIN
                    sys.columns AS C ON I.object_id = C.object_id
               WHERE I.object_id = 1432392172
                     AND C.name = 'IdParcelamento'
                     AND I.type > 1
                     AND IC.key_ordinal = 1
               )
   )
BEGIN
    CREATE NONCLUSTERED INDEX [IX_ParcelamentosParcelasIdParcelamento]
        ON Financeiro.ParcelamentosParcelas (IdParcelamento);
END;
IF (NOT EXISTS (
               SELECT I.name,
                      C.*
               FROM sys.indexes AS I
                    JOIN
                    sys.index_columns AS IC ON I.object_id = IC.object_id
                                               AND I.index_id = IC.index_id
                    JOIN
                    sys.columns AS C ON I.object_id = C.object_id
               WHERE I.object_id = 1432392172
                     AND C.name = 'IdParcelaSituacaoPagamento'
                     AND I.type > 1
                     AND IC.key_ordinal = 1
               )
   )
BEGIN
    CREATE NONCLUSTERED INDEX [IX_ParcelamentosParcelas_IdParcelamentoSituacaoPagamento]
        ON Financeiro.ParcelamentosParcelas (IdParcelaSituacaoPagamento);
END;
IF (NOT EXISTS (
               SELECT I.name,
                      C.*
               FROM sys.indexes AS I
                    JOIN
                    sys.index_columns AS IC ON I.object_id = IC.object_id
                                               AND I.index_id = IC.index_id
                    JOIN
                    sys.columns AS C ON I.object_id = C.object_id
               WHERE I.object_id = 1467868296
                     AND C.name = 'IdRegistro'
                     AND I.type > 1
                     AND IC.key_ordinal = 1
               )
   )
BEGIN
    CREATE NONCLUSTERED INDEX [IX_DebitosRegistros_IdRegistro]
        ON Financeiro.DebitosRegistros (IdRegistro)
        INCLUDE (IdDebito);
END;
IF (NOT EXISTS (
               SELECT I.name,
                      C.*
               FROM sys.indexes AS I
                    JOIN
                    sys.index_columns AS IC ON I.object_id = IC.object_id
                                               AND I.index_id = IC.index_id
                    JOIN
                    sys.columns AS C ON I.object_id = C.object_id
               WHERE I.object_id = 1474820316
                     AND C.name = 'CodigoIBGE'
                     AND I.type > 1
                     AND IC.key_ordinal = 1
               )
   )
BEGIN
    CREATE NONCLUSTERED INDEX [missing_index_103_102]
        ON DNE.Localidades (CodigoIBGE);
END;
IF (NOT EXISTS (
               SELECT I.name,
                      C.*
               FROM sys.indexes AS I
                    JOIN
                    sys.index_columns AS IC ON I.object_id = IC.object_id
                                               AND I.index_id = IC.index_id
                    JOIN
                    sys.columns AS C ON I.object_id = C.object_id
               WHERE I.object_id = 1570820658
                     AND C.name = 'CEP'
                     AND I.type > 1
                     AND IC.key_ordinal = 1
               )
   )
BEGIN
    CREATE NONCLUSTERED INDEX [IX_Logradouros_CEP] ON DNE.Logradouros (CEP);
END;
IF (NOT EXISTS (
               SELECT I.name,
                      C.*
               FROM sys.indexes AS I
                    JOIN
                    sys.index_columns AS IC ON I.object_id = IC.object_id
                                               AND I.index_id = IC.index_id
                    JOIN
                    sys.columns AS C ON I.object_id = C.object_id
               WHERE I.object_id = 1570820658
                     AND C.name = 'IdLocalidade'
                     AND I.type > 1
                     AND IC.key_ordinal = 1
               )
   )
BEGIN
    CREATE NONCLUSTERED INDEX [IX_Logradouros_IdLocalidade]
        ON DNE.Logradouros (IdLocalidade)
        INCLUDE
    (IdLogradouro,
     Numero,
     SiglaUF,
     IdBairroInicial,
     IdBairroFinal,
     Nome,
     Complemento,
     CEP,
     Tipo,
     UtilizaTipo,
     Abreviatura,
     DataCadastro,
     Implanta,
     NomeUsuarioChancela,
     DataChancela,
     JustificativaChancela
    )   ;
END;
IF (NOT EXISTS (
               SELECT I.name,
                      C.*
               FROM sys.indexes AS I
                    JOIN
                    sys.index_columns AS IC ON I.object_id = IC.object_id
                                               AND I.index_id = IC.index_id
                    JOIN
                    sys.columns AS C ON I.object_id = C.object_id
               WHERE I.object_id = 1611868809
                     AND C.name = 'IdDebito'
                     AND I.type > 1
                     AND IC.key_ordinal = 1
               )
   )
BEGIN
    CREATE NONCLUSTERED INDEX [IX_DebitosSituacoesHistoricosDividaAtiva_IdDebitoIdDebitoSituacaoDividaAtiva]
        ON Financeiro.DebitosSituacoesHistoricosDividaAtiva (IdDebito, IdDebitoSituacaoDividaAtiva);
END;
IF (NOT EXISTS (
               SELECT I.name,
                      C.*
               FROM sys.indexes AS I
                    JOIN
                    sys.index_columns AS IC ON I.object_id = IC.object_id
                                               AND I.index_id = IC.index_id
                    JOIN
                    sys.columns AS C ON I.object_id = C.object_id
               WHERE I.object_id = 1656392970
                     AND C.name = 'IdProcessamentoArquivoRetorno'
                     AND I.type > 1
                     AND IC.key_ordinal = 1
               )
   )
BEGIN
    CREATE NONCLUSTERED INDEX [IX_FinanceiroProcessamentoArquivosRetornosItens_IdProcessamentoArquivoRetorno]
        ON Financeiro.ProcessamentoArquivosRetornosItens (IdProcessamentoArquivoRetorno)
        INCLUDE
    (IdProcessamentoArquivoRetornoItem,
     Identificado,
     GerouPagamentoSiscaf,
     MotivoRecusaProcessamento,
     NossoNumero,
     ValorPagamento,
     DataPagamento,
     DataCredito,
     Estornado,
     Rejeitado,
     Registrado,
     OcorrenciaArquivoRetornoCodigo,
     IdConvenio,
     ValorRepasseFederal,
     ValorTarifaBancaria,
     SacadoNome,
     SacadoCPFCNPJ,
     OcorrenciaDePagamento,
     Baixado
    )   ;
END;
IF (NOT EXISTS (
               SELECT I.name,
                      C.*
               FROM sys.indexes AS I
                    JOIN
                    sys.index_columns AS IC ON I.object_id = IC.object_id
                                               AND I.index_id = IC.index_id
                    JOIN
                    sys.columns AS C ON I.object_id = C.object_id
               WHERE I.object_id = 1656392970
                     AND C.name = 'OcorrenciaDePagamento'
                     AND I.type > 1
                     AND IC.key_ordinal = 1
               )
   )
BEGIN
    CREATE NONCLUSTERED INDEX [nci_wi_ProcessamentoArquivosRetornosItens_F0015C1E0A91BBADC7267153BC021EE8]
        ON Financeiro.ProcessamentoArquivosRetornosItens (OcorrenciaDePagamento, GerouPagamentoSiscaf)
        INCLUDE (ValorPagamento, DataPagamento, DataCredito);
END;
IF (NOT EXISTS (
               SELECT I.name,
                      C.*
               FROM sys.indexes AS I
                    JOIN
                    sys.index_columns AS IC ON I.object_id = IC.object_id
                                               AND I.index_id = IC.index_id
                    JOIN
                    sys.columns AS C ON I.object_id = C.object_id
               WHERE I.object_id = 1675869037
                     AND C.name = 'IdDebito'
                     AND I.type > 1
                     AND IC.key_ordinal = 1
               )
   )
BEGIN
    CREATE NONCLUSTERED INDEX [IX_DebitosSituacoesPagtoHistoricos_IdDebito]
        ON Financeiro.DebitosSituacoesPagtoHistoricos (IdDebito);
END;
IF (NOT EXISTS (
               SELECT I.name,
                      C.*
               FROM sys.indexes AS I
                    JOIN
                    sys.index_columns AS IC ON I.object_id = IC.object_id
                                               AND I.index_id = IC.index_id
                    JOIN
                    sys.columns AS C ON I.object_id = C.object_id
               WHERE I.object_id = 1688393084
                     AND C.name = 'IdProcessamentoArquivoRetornoItem'
                     AND I.type > 1
                     AND IC.key_ordinal = 1
               )
   )
BEGIN
    CREATE NONCLUSTERED INDEX [IX_FinanceiroProcessamentoArquivosRetornosItensEmissoesIdProcessamentoArquivoRetornoItem]
        ON Financeiro.ProcessamentoArquivosRetornosItensEmissoes (IdProcessamentoArquivoRetornoItem)
        INCLUDE (IdEmissao);
END;
IF (NOT EXISTS (
               SELECT I.name,
                      C.*
               FROM sys.indexes AS I
                    JOIN
                    sys.index_columns AS IC ON I.object_id = IC.object_id
                                               AND I.index_id = IC.index_id
                    JOIN
                    sys.columns AS C ON I.object_id = C.object_id
               WHERE I.object_id = 1712061185
                     AND C.name = 'IdSistemaOrigem'
                     AND I.type > 1
                     AND IC.key_ordinal = 1
               )
   )
BEGIN
    CREATE NONCLUSTERED INDEX [IX_RegistroRegistrosIdSistemaOrigemIdSituacaoDetalhe]
        ON Registro.Registros (IdSistemaOrigem, IdSituacaoDetalhe)
        INCLUDE
    (IdRegistro,
     IdPessoa,
     DataRequerimento,
     IdCategoria,
     IdTipoInscricao,
     NumeroRegistro,
     DataAtualizacao,
     NomeUsuarioCriacao,
     DataCriacao,
     NomeUnidadeCriacao,
     NomeUsuarioAtualizacao,
     NomeUnidadeAtualizacao,
     Observacoes,
     NumeracaoAutomatica,
     Processo,
     Livro,
     Folha,
     Protocolo,
     ProcessoFederal,
     LivroFederal,
     FolhaFederal,
     NumeroRegistroFederal,
     DataFederal,
     ProtocoloFederal,
     DataInscricao,
     NumeroRegistroParteNumerica,
     IdSituacao,
     DataInicioSituacao,
     DataValidadeSituacao,
     RetornarSituacaoAnterior,
     IdSubRegiaoOrigemInscricao,
     NumeroRegistroOrigem,
     IdCategoriaOrigemInscricao,
     IdConselhoOrigemInscricao
    )   ;
END;
IF (NOT EXISTS (
               SELECT I.name,
                      C.*
               FROM sys.indexes AS I
                    JOIN
                    sys.index_columns AS IC ON I.object_id = IC.object_id
                                               AND I.index_id = IC.index_id
                    JOIN
                    sys.columns AS C ON I.object_id = C.object_id
               WHERE I.object_id = 1712061185
                     AND C.name = 'NumeroRegistro'
                     AND I.type > 1
                     AND IC.key_ordinal = 1
               )
   )
BEGIN
    CREATE NONCLUSTERED INDEX [IX_Registros_NumeroRegistro]
        ON Registro.Registros (NumeroRegistro);
END;
IF (NOT EXISTS (
               SELECT I.name,
                      C.*
               FROM sys.indexes AS I
                    JOIN
                    sys.index_columns AS IC ON I.object_id = IC.object_id
                                               AND I.index_id = IC.index_id
                    JOIN
                    sys.columns AS C ON I.object_id = C.object_id
               WHERE I.object_id = 1712061185
                     AND C.name = 'IdPessoa'
                     AND I.type > 1
                     AND IC.key_ordinal = 1
               )
   )
BEGIN
    CREATE NONCLUSTERED INDEX [nci_wi_Registros_FA40C6926D1E61F89AB96860342B3FE4]
        ON Registro.Registros (IdPessoa);
END;
IF (NOT EXISTS (
               SELECT I.name,
                      C.*
               FROM sys.indexes AS I
                    JOIN
                    sys.index_columns AS IC ON I.object_id = IC.object_id
                                               AND I.index_id = IC.index_id
                    JOIN
                    sys.columns AS C ON I.object_id = C.object_id
               WHERE I.object_id = 1712061185
                     AND C.name = 'IdSituacao'
                     AND I.type > 1
                     AND IC.key_ordinal = 1
               )
   )
BEGIN
    CREATE NONCLUSTERED INDEX [missing_index_8_7]
        ON Registro.Registros (IdSituacao, IdSituacaoDetalhe, NumeroRegistro)
        INCLUDE
    (IdPessoa,
     DataRequerimento,
     IdCategoria,
     IdTipoInscricao,
     DataAtualizacao,
     NomeUsuarioCriacao,
     DataCriacao,
     NomeUnidadeCriacao,
     NomeUsuarioAtualizacao,
     NomeUnidadeAtualizacao,
     Observacoes,
     NumeracaoAutomatica,
     Processo,
     Livro,
     Folha,
     Protocolo,
     ProcessoFederal,
     LivroFederal,
     FolhaFederal,
     NumeroRegistroFederal,
     DataFederal,
     ProtocoloFederal,
     DataInscricao,
     IdSistemaOrigem,
     NumeroRegistroParteNumerica,
     DataInicioSituacao,
     DataValidadeSituacao,
     RetornarSituacaoAnterior,
     IdSubRegiaoOrigemInscricao,
     NumeroRegistroOrigem,
     IdCategoriaOrigemInscricao,
     IdConselhoOrigemInscricao
    )   ;
END;
IF (NOT EXISTS (
               SELECT I.name,
                      C.*
               FROM sys.indexes AS I
                    JOIN
                    sys.index_columns AS IC ON I.object_id = IC.object_id
                                               AND I.index_id = IC.index_id
                    JOIN
                    sys.columns AS C ON I.object_id = C.object_id
               WHERE I.object_id = 1718297181
                     AND C.name = 'IdTributoRetido'
                     AND I.type > 1
                     AND IC.key_ordinal = 1
               )
   )
BEGIN
    CREATE NONCLUSTERED INDEX [IX_DespesaTributosMovimentosFinanceirosIdTributoRetido]
        ON Despesa.TributosMovimentosFinanceiros (IdTributoRetido);
END;
IF (NOT EXISTS (
               SELECT I.name,
                      C.*
               FROM sys.indexes AS I
                    JOIN
                    sys.index_columns AS IC ON I.object_id = IC.object_id
                                               AND I.index_id = IC.index_id
                    JOIN
                    sys.columns AS C ON I.object_id = C.object_id
               WHERE I.object_id = 1739869265
                     AND C.name = 'IdDebito'
                     AND I.type > 1
                     AND IC.key_ordinal = 1
               )
   )
BEGIN
    CREATE NONCLUSTERED INDEX [IX_DebitosSituacoesParcelamentosHistoricos_IdDebito]
        ON Financeiro.DebitosSituacoesParcelamentosHistoricos (IdDebito)
        INCLUDE (IdDebitoSituacaoParcelamentoHistorico);
END;
IF (NOT EXISTS (
               SELECT I.name,
                      C.*
               FROM sys.indexes AS I
                    JOIN
                    sys.index_columns AS IC ON I.object_id = IC.object_id
                                               AND I.index_id = IC.index_id
                    JOIN
                    sys.columns AS C ON I.object_id = C.object_id
               WHERE I.object_id = 1808061527
                     AND C.name = 'IdRegistro'
                     AND I.type > 1
                     AND IC.key_ordinal = 1
               )
   )
BEGIN
    CREATE NONCLUSTERED INDEX [IX_RegistrosEspecialidades_IdRegistro]
        ON Registro.RegistrosEspecialidades (IdRegistro);
END;
IF (NOT EXISTS (
               SELECT I.name,
                      C.*
               FROM sys.indexes AS I
                    JOIN
                    sys.index_columns AS IC ON I.object_id = IC.object_id
                                               AND I.index_id = IC.index_id
                    JOIN
                    sys.columns AS C ON I.object_id = C.object_id
               WHERE I.object_id = 1808061527
                     AND C.name = 'IdEspecialidade'
                     AND I.type > 1
                     AND IC.key_ordinal = 1
               )
   )
BEGIN
    CREATE NONCLUSTERED INDEX [missing_index_38_37]
        ON Registro.RegistrosEspecialidades (IdEspecialidade)
        INCLUDE (IdRegistro);
END;
IF (NOT EXISTS (
               SELECT I.name,
                      C.*
               FROM sys.indexes AS I
                    JOIN
                    sys.index_columns AS IC ON I.object_id = IC.object_id
                                               AND I.index_id = IC.index_id
                    JOIN
                    sys.columns AS C ON I.object_id = C.object_id
               WHERE I.object_id = 1846297637
                     AND C.name = 'BaseCalculo'
                     AND I.type > 1
                     AND IC.key_ordinal = 1
               )
   )
BEGIN
    CREATE NONCLUSTERED INDEX [missing_index_48_47]
        ON Despesa.TributosRetidos (BaseCalculo)
        INCLUDE (IdTributo, IdPessoa);
END;
IF (NOT EXISTS (
               SELECT I.name,
                      C.*
               FROM sys.indexes AS I
                    JOIN
                    sys.index_columns AS IC ON I.object_id = IC.object_id
                                               AND I.index_id = IC.index_id
                    JOIN
                    sys.columns AS C ON I.object_id = C.object_id
               WHERE I.object_id = 1846297637
                     AND C.name = 'ValorTributo'
                     AND I.type > 1
                     AND IC.key_ordinal = 1
               )
   )
BEGIN
    CREATE NONCLUSTERED INDEX [missing_index_54_53]
        ON Despesa.TributosRetidos (ValorTributo)
        INCLUDE (IdTributo, IdPessoa, Estornado);
END;
IF (NOT EXISTS (
               SELECT I.name,
                      C.*
               FROM sys.indexes AS I
                    JOIN
                    sys.index_columns AS IC ON I.object_id = IC.object_id
                                               AND I.index_id = IC.index_id
                    JOIN
                    sys.columns AS C ON I.object_id = C.object_id
               WHERE I.object_id = 1851153640
                     AND C.name = 'IdPessoa'
                     AND I.type > 1
                     AND IC.key_ordinal = 1
               )
   )
BEGIN
    CREATE NONCLUSTERED INDEX [IX_Emails_IdPessoa]
        ON Cadastro.Emails (IdPessoa)
        INCLUDE
    (Comercial,
     Email,
     Complemento,
     Publico,
     DataAtualizacao,
     NomeUsuarioCriacao,
     DataCriacao,
     NomeUnidadeCriacao,
     NomeUsuarioAtualizacao,
     NomeUnidadeAtualizacao,
     Correspondencia
    )   ;
END;
IF (NOT EXISTS (
               SELECT I.name,
                      C.*
               FROM sys.indexes AS I
                    JOIN
                    sys.index_columns AS IC ON I.object_id = IC.object_id
                                               AND I.index_id = IC.index_id
                    JOIN
                    sys.columns AS C ON I.object_id = C.object_id
               WHERE I.object_id = 1851153640
                     AND C.name = 'Email'
                     AND I.type > 1
                     AND IC.key_ordinal = 1
               )
   )
BEGIN
    CREATE NONCLUSTERED INDEX [IX_EmailsEmails] ON Cadastro.Emails (Email);
END;
IF (NOT EXISTS (
               SELECT I.name,
                      C.*
               FROM sys.indexes AS I
                    JOIN
                    sys.index_columns AS IC ON I.object_id = IC.object_id
                                               AND I.index_id = IC.index_id
                    JOIN
                    sys.columns AS C ON I.object_id = C.object_id
               WHERE I.object_id = 1867869721
                     AND C.name = 'IdPessoa'
                     AND I.type > 1
                     AND IC.key_ordinal = 1
               )
   )
BEGIN
    CREATE NONCLUSTERED INDEX [IX_Emissoes_IdPessoa]
        ON Financeiro.Emissoes (IdPessoa);
END;
IF (NOT EXISTS (
               SELECT I.name,
                      C.*
               FROM sys.indexes AS I
                    JOIN
                    sys.index_columns AS IC ON I.object_id = IC.object_id
                                               AND I.index_id = IC.index_id
                    JOIN
                    sys.columns AS C ON I.object_id = C.object_id
               WHERE I.object_id = 1867869721
                     AND C.name = 'NossoNumero'
                     AND I.type > 1
                     AND IC.key_ordinal = 1
               )
   )
BEGIN
    CREATE NONCLUSTERED INDEX [IX_Emissoes_NossoNumero]
        ON Financeiro.Emissoes (NossoNumero);
END;
IF (NOT EXISTS (
               SELECT I.name,
                      C.*
               FROM sys.indexes AS I
                    JOIN
                    sys.index_columns AS IC ON I.object_id = IC.object_id
                                               AND I.index_id = IC.index_id
                    JOIN
                    sys.columns AS C ON I.object_id = C.object_id
               WHERE I.object_id = 1867869721
                     AND C.name = 'TipoEmissao'
                     AND I.type > 1
                     AND IC.key_ordinal = 1
               )
   )
BEGIN
    CREATE NONCLUSTERED INDEX [IX_Emissoes_TipoEmissaoDataEmissaoNossoNumero]
        ON Financeiro.Emissoes (TipoEmissao, DataEmissao, NossoNumero)
        INCLUDE (ValorTotal, NomeUsuarioCriacao, TipoSaida);
END;
IF (NOT EXISTS (
               SELECT I.name,
                      C.*
               FROM sys.indexes AS I
                    JOIN
                    sys.index_columns AS IC ON I.object_id = IC.object_id
                                               AND I.index_id = IC.index_id
                    JOIN
                    sys.columns AS C ON I.object_id = C.object_id
               WHERE I.object_id = 1913109906
                     AND C.name = 'CodigoRelatorio'
                     AND I.type > 1
                     AND IC.key_ordinal = 1
               )
   )
BEGIN
    CREATE NONCLUSTERED INDEX [UNQ_TCUDemonstracoesContabeisCodigoRelatorioIdRelatorioTCU]
        ON TCU.DemonstracoesContabeis (CodigoRelatorio, IdRelatorioTCU);
END;
IF (NOT EXISTS (
               SELECT I.name,
                      C.*
               FROM sys.indexes AS I
                    JOIN
                    sys.index_columns AS IC ON I.object_id = IC.object_id
                                               AND I.index_id = IC.index_id
                    JOIN
                    sys.columns AS C ON I.object_id = C.object_id
               WHERE I.object_id = 1942297979
                     AND C.name = 'IdPagamento'
                     AND I.type > 1
                     AND IC.key_ordinal = 1
               )
   )
BEGIN
    CREATE NONCLUSTERED INDEX [IX_DespesaTributosRetidosPagamentosIdPagamento]
        ON Despesa.TributosRetidosPagamentos (IdPagamento);
END;
IF (NOT EXISTS (
               SELECT I.name,
                      C.*
               FROM sys.indexes AS I
                    JOIN
                    sys.index_columns AS IC ON I.object_id = IC.object_id
                                               AND I.index_id = IC.index_id
                    JOIN
                    sys.columns AS C ON I.object_id = C.object_id
               WHERE I.object_id = 1942297979
                     AND C.name = 'IdTributoRetido'
                     AND I.type > 1
                     AND IC.key_ordinal = 1
               )
   )
BEGIN
    CREATE NONCLUSTERED INDEX [missing_index_156_155]
        ON Despesa.TributosRetidosPagamentos (IdTributoRetido);
END;
IF (NOT EXISTS (
               SELECT I.name,
                      C.*
               FROM sys.indexes AS I
                    JOIN
                    sys.index_columns AS IC ON I.object_id = IC.object_id
                                               AND I.index_id = IC.index_id
                    JOIN
                    sys.columns AS C ON I.object_id = C.object_id
               WHERE I.object_id = 1942297979
                     AND C.name = 'IdTributoRetido'
                     AND I.type > 1
                     AND IC.key_ordinal = 1
               )
   )
BEGIN
    CREATE NONCLUSTERED INDEX [missing_index_154_153]
        ON Despesa.TributosRetidosPagamentos (IdTributoRetido)
        INCLUDE (IdPagamento);
END;
IF (NOT EXISTS (
               SELECT I.name,
                      C.*
               FROM sys.indexes AS I
                    JOIN
                    sys.index_columns AS IC ON I.object_id = IC.object_id
                                               AND I.index_id = IC.index_id
                    JOIN
                    sys.columns AS C ON I.object_id = C.object_id
               WHERE I.object_id = 1968062097
                     AND C.name = 'IdRegistro'
                     AND I.type > 1
                     AND IC.key_ordinal = 1
               )
   )
BEGIN
    CREATE NONCLUSTERED INDEX [missing_index_14_13]
        ON Registro.RegistrosProcessos (IdRegistro);
END;
IF (NOT EXISTS (
               SELECT I.name,
                      C.*
               FROM sys.indexes AS I
                    JOIN
                    sys.index_columns AS IC ON I.object_id = IC.object_id
                                               AND I.index_id = IC.index_id
                    JOIN
                    sys.columns AS C ON I.object_id = C.object_id
               WHERE I.object_id = 1968062097
                     AND C.name = 'IdRegistro'
                     AND I.type > 1
                     AND IC.key_ordinal = 1
               )
   )
BEGIN
    CREATE NONCLUSTERED INDEX [missing_index_126_125]
        ON Registro.RegistrosProcessos (IdRegistro)
        INCLUDE (IdProcesso, TipoVinculo);
END;
IF (NOT EXISTS (
               SELECT I.name,
                      C.*
               FROM sys.indexes AS I
                    JOIN
                    sys.index_columns AS IC ON I.object_id = IC.object_id
                                               AND I.index_id = IC.index_id
                    JOIN
                    sys.columns AS C ON I.object_id = C.object_id
               WHERE I.object_id = 1977774103
                     AND C.name = 'IdEmpenho'
                     AND I.type > 1
                     AND IC.key_ordinal = 1
               )
   )
BEGIN
    CREATE NONCLUSTERED INDEX [IX_DespesaLiquidacoesIdEmpenho]
        ON Despesa.Liquidacoes (IdEmpenho);
END;
IF (NOT EXISTS (
               SELECT I.name,
                      C.*
               FROM sys.indexes AS I
                    JOIN
                    sys.index_columns AS IC ON I.object_id = IC.object_id
                                               AND I.index_id = IC.index_id
                    JOIN
                    sys.columns AS C ON I.object_id = C.object_id
               WHERE I.object_id = 1977774103
                     AND C.name = 'RestoAPagar'
                     AND I.type > 1
                     AND IC.key_ordinal = 1
               )
   )
BEGIN
    CREATE NONCLUSTERED INDEX [IX_Liquidacoes_RestoAPagar]
        ON Despesa.Liquidacoes (RestoAPagar)
        INCLUDE (IdLiquidacao, IdEmpenho);
END;
IF (NOT EXISTS (
               SELECT I.name,
                      C.*
               FROM sys.indexes AS I
                    JOIN
                    sys.index_columns AS IC ON I.object_id = IC.object_id
                                               AND I.index_id = IC.index_id
                    JOIN
                    sys.columns AS C ON I.object_id = C.object_id
               WHERE I.object_id = 1977774103
                     AND C.name = 'RestoAPagar'
                     AND I.type > 1
                     AND IC.key_ordinal = 1
               )
   )
BEGIN
    CREATE NONCLUSTERED INDEX [IX_Liquidacoes_RestoAPagarDataLiquidacao]
        ON Despesa.Liquidacoes (RestoAPagar, DataLiquidacao)
        INCLUDE (IdLiquidacao, IdEmpenho, Cancelamento);
END;
IF (NOT EXISTS (
               SELECT I.name,
                      C.*
               FROM sys.indexes AS I
                    JOIN
                    sys.index_columns AS IC ON I.object_id = IC.object_id
                                               AND I.index_id = IC.index_id
                    JOIN
                    sys.columns AS C ON I.object_id = C.object_id
               WHERE I.object_id = 1993110191
                     AND C.name = 'Exercicio'
                     AND I.type > 1
                     AND IC.key_ordinal = 1
               )
   )
BEGIN
    CREATE NONCLUSTERED INDEX [UNQ_TCUDemonstracoesProgramacoesOrcamentariasExercicio]
        ON TCU.DemonstracoesProgramacoesOrcamentarias (Exercicio);
END;
IF (NOT EXISTS (
               SELECT I.name,
                      C.*
               FROM sys.indexes AS I
                    JOIN
                    sys.index_columns AS IC ON I.object_id = IC.object_id
                                               AND I.index_id = IC.index_id
                    JOIN
                    sys.columns AS C ON I.object_id = C.object_id
               WHERE I.object_id = 2000062211
                     AND C.name = 'IdFormacaoAcademica'
                     AND I.type > 1
                     AND IC.key_ordinal = 1
               )
   )
BEGIN
    CREATE NONCLUSTERED INDEX [IX_RegistrosProfissionais_IdFormacaoAcademica]
        ON Registro.RegistrosProfissionais (IdFormacaoAcademica);
END;
IF (NOT EXISTS (
               SELECT I.name,
                      C.*
               FROM sys.indexes AS I
                    JOIN
                    sys.index_columns AS IC ON I.object_id = IC.object_id
                                               AND I.index_id = IC.index_id
                    JOIN
                    sys.columns AS C ON I.object_id = C.object_id
               WHERE I.object_id = 2000062211
                     AND C.name = 'IdRegistro'
                     AND I.type > 1
                     AND IC.key_ordinal = 1
               )
   )
BEGIN
    CREATE NONCLUSTERED INDEX [IX_RegistrosProfissionais_IdRegistro]
        ON Registro.RegistrosProfissionais (IdRegistro)
        INCLUDE (IdFormacaoAcademica);
END;
IF (NOT EXISTS (
               SELECT I.name,
                      C.*
               FROM sys.indexes AS I
                    JOIN
                    sys.index_columns AS IC ON I.object_id = IC.object_id
                                               AND I.index_id = IC.index_id
                    JOIN
                    sys.columns AS C ON I.object_id = C.object_id
               WHERE I.object_id = 2007014231
                     AND C.name = 'Exercicio'
                     AND I.type > 1
                     AND IC.key_ordinal = 1
               )
   )
BEGIN
    CREATE NONCLUSTERED INDEX [UNQ_ReceitaDemonstracoesReceitasExercicio]
        ON Receita.DemonstracoesReceitas (Exercicio);
END;
IF (NOT EXISTS (
               SELECT I.name,
                      C.*
               FROM sys.indexes AS I
                    JOIN
                    sys.index_columns AS IC ON I.object_id = IC.object_id
                                               AND I.index_id = IC.index_id
                    JOIN
                    sys.columns AS C ON I.object_id = C.object_id
               WHERE I.object_id = 2009774217
                     AND C.name = 'IdLiquidacao'
                     AND I.type > 1
                     AND IC.key_ordinal = 1
               )
   )
BEGIN
    CREATE NONCLUSTERED INDEX [IX_DespesaLiquidacoesCentroCustosIdLiquidacaoIdCentroCusto]
        ON Despesa.LiquidacoesCentroCustos (IdLiquidacao, IdCentroCusto);
END;
IF (NOT EXISTS (
               SELECT I.name,
                      C.*
               FROM sys.indexes AS I
                    JOIN
                    sys.index_columns AS IC ON I.object_id = IC.object_id
                                               AND I.index_id = IC.index_id
                    JOIN
                    sys.columns AS C ON I.object_id = C.object_id
               WHERE I.object_id = 2011870234
                     AND C.name = 'IdEmissaoColetiva'
                     AND I.type > 1
                     AND IC.key_ordinal = 1
               )
   )
BEGIN
    CREATE NONCLUSTERED INDEX [IX_EmissoesColetivasHistoricos_IdEmissaoColetiva]
        ON Financeiro.EmissoesColetivasHistoricos (IdEmissaoColetiva);
END;
IF (NOT EXISTS (
               SELECT I.name,
                      C.*
               FROM sys.indexes AS I
                    JOIN
                    sys.index_columns AS IC ON I.object_id = IC.object_id
                                               AND I.index_id = IC.index_id
                    JOIN
                    sys.columns AS C ON I.object_id = C.object_id
               WHERE I.object_id = 2017442261
                     AND C.name = 'IdBemMovel'
                     AND I.type > 1
                     AND IC.key_ordinal = 1
               )
   )
BEGIN
    CREATE NONCLUSTERED INDEX [IX_PatrimonioBensMoveisMovimentosIdBemMovel]
        ON Patrimonio.BensMoveisMovimentos (IdBemMovel)
        INCLUDE (Data);
END;
IF (NOT EXISTS (
               SELECT I.name,
                      C.*
               FROM sys.indexes AS I
                    JOIN
                    sys.index_columns AS IC ON I.object_id = IC.object_id
                                               AND I.index_id = IC.index_id
                    JOIN
                    sys.columns AS C ON I.object_id = C.object_id
               WHERE I.object_id = 2032062325
                     AND C.name = 'IdRegistro'
                     AND I.type > 1
                     AND IC.key_ordinal = 1
               )
   )
BEGIN
    CREATE NONCLUSTERED INDEX [IX_RegistrosSituacoes_IdRegistro]
        ON Registro.RegistrosSituacoes (IdRegistro)
        INCLUDE
    (DataInicioSituacao,
     IdSituacao,
     IdSituacaoDetalhe,
     DataValidade,
     DataPlenaria,
     NumeroPlenaria,
     RetornarSituacaoAnterior,
     Sistema,
     DataAtualizacao,
     NomeUsuarioCriacao,
     DataCriacao,
     NomeUnidadeCriacao,
     NomeUsuarioAtualizacao,
     NomeUnidadeAtualizacao,
     Observacoes,
     IdConselhoDestino,
     NomeUsuarioChancela,
     DataChancela,
     IdTipoInscricao
    )   ;
END;
IF (NOT EXISTS (
               SELECT I.name,
                      C.*
               FROM sys.indexes AS I
                    JOIN
                    sys.index_columns AS IC ON I.object_id = IC.object_id
                                               AND I.index_id = IC.index_id
                    JOIN
                    sys.columns AS C ON I.object_id = C.object_id
               WHERE I.object_id = 2059154381
                     AND C.name = 'IdPessoa'
                     AND I.type > 1
                     AND IC.key_ordinal = 1
               )
   )
BEGIN
    CREATE NONCLUSTERED INDEX [IX_InstituicaoEnsino_IdPessoa]
        ON Cadastro.InstituicoesEnsino (IdPessoa)
        INCLUDE (Codigo);
END;
IF (NOT EXISTS (
               SELECT I.name,
                      C.*
               FROM sys.indexes AS I
                    JOIN
                    sys.index_columns AS IC ON I.object_id = IC.object_id
                                               AND I.index_id = IC.index_id
                    JOIN
                    sys.columns AS C ON I.object_id = C.object_id
               WHERE I.object_id = 2073110476
                     AND C.name = 'Exercicio'
                     AND I.type > 1
                     AND IC.key_ordinal = 1
               )
   )
BEGIN
    CREATE NONCLUSTERED INDEX [UNQ_TCUDemonstracoesReceitasExercicio]
        ON TCU.DemonstracoesReceitas (Exercicio);
END;
IF (NOT EXISTS (
               SELECT I.name,
                      C.*
               FROM sys.indexes AS I
                    JOIN
                    sys.index_columns AS IC ON I.object_id = IC.object_id
                                               AND I.index_id = IC.index_id
                    JOIN
                    sys.columns AS C ON I.object_id = C.object_id
               WHERE I.object_id = 2075870462
                     AND C.name = 'IdDebito'
                     AND I.type > 1
                     AND IC.key_ordinal = 1
               )
   )
BEGIN
    CREATE NONCLUSTERED INDEX [IX_EmissoesDebitos_IdDebito]
        ON Financeiro.EmissoesDebitos (IdDebito);
END;
IF (NOT EXISTS (
               SELECT I.name,
                      C.*
               FROM sys.indexes AS I
                    JOIN
                    sys.index_columns AS IC ON I.object_id = IC.object_id
                                               AND I.index_id = IC.index_id
                    JOIN
                    sys.columns AS C ON I.object_id = C.object_id
               WHERE I.object_id = 2075870462
                     AND C.name = 'IdEmissao'
                     AND I.type > 1
                     AND IC.key_ordinal = 1
               )
   )
BEGIN
    CREATE NONCLUSTERED INDEX [IX_EmissoesDebitos_IdEmissao]
        ON Financeiro.EmissoesDebitos (IdEmissao)
        INCLUDE
    (IdDebito,
     ValorPrincipal,
     ValorAtualizacaoMonetaria,
     ValorJuros,
     ValorMulta,
     ValorAcrescimo,
     ValorTotal,
     IdProcedimentoAtraso
    )   ;
END;
IF (NOT EXISTS (
               SELECT I.name,
                      C.*
               FROM sys.indexes AS I
                    JOIN
                    sys.index_columns AS IC ON I.object_id = IC.object_id
                                               AND I.index_id = IC.index_id
                    JOIN
                    sys.columns AS C ON I.object_id = C.object_id
               WHERE I.object_id = 2077250455
                     AND C.name = 'IdLiquidacao'
                     AND I.type > 1
                     AND IC.key_ordinal = 1
               )
   )
BEGIN
    CREATE NONCLUSTERED INDEX [IX_DespesaAdiantamentosIdLiquidacao]
        ON Despesa.Adiantamentos (IdLiquidacao);
END;
IF (NOT EXISTS (
               SELECT I.name,
                      C.*
               FROM sys.indexes AS I
                    JOIN
                    sys.index_columns AS IC ON I.object_id = IC.object_id
                                               AND I.index_id = IC.index_id
                    JOIN
                    sys.columns AS C ON I.object_id = C.object_id
               WHERE I.object_id = 2077250455
                     AND C.name = 'IdEmpenho'
                     AND I.type > 1
                     AND IC.key_ordinal = 1
               )
   )
BEGIN
    CREATE NONCLUSTERED INDEX [missing_index_16_15]
        ON Despesa.Adiantamentos (IdEmpenho);
END;
IF (NOT EXISTS (
               SELECT I.name,
                      C.*
               FROM sys.indexes AS I
                    JOIN
                    sys.index_columns AS IC ON I.object_id = IC.object_id
                                               AND I.index_id = IC.index_id
                    JOIN
                    sys.columns AS C ON I.object_id = C.object_id
               WHERE I.object_id = 2081442489
                     AND C.name = 'IdBemMovel'
                     AND I.type > 1
                     AND IC.key_ordinal = 1
               )
   )
BEGIN
    CREATE NONCLUSTERED INDEX [IX_PatrimonioBensMoveisReavaliacoesIdBemMovelData]
        ON Patrimonio.BensMoveisReavaliacoes (IdBemMovel, Data)
        INCLUDE (Valor);
END;
IF (NOT EXISTS (
               SELECT I.name,
                      C.*
               FROM sys.indexes AS I
                    JOIN
                    sys.index_columns AS IC ON I.object_id = IC.object_id
                                               AND I.index_id = IC.index_id
                    JOIN
                    sys.columns AS C ON I.object_id = C.object_id
               WHERE I.object_id = 2083642616
                     AND C.name = 'IdPessoa'
                     AND I.type > 1
                     AND IC.key_ordinal = 1
               )
   )
BEGIN
    CREATE NONCLUSTERED INDEX [IX_Enderecos_IdPessoaCorrespondencia]
        ON Cadastro.Enderecos (IdPessoa, Correspondencia)
        INCLUDE
    (IdCidade,
     Logradouro,
     Numero,
     IdBairro,
     Complemento,
     CaixaPostal,
     CEP,
     Atualizado,
     Observacao,
     DataAtualizacao,
     Preferencial,
     Local,
     MalaDireta,
     Publico,
     IdLogradouroDNE,
     NomeUsuarioCriacao,
     DataCriacao,
     NomeUnidadeCriacao,
     NomeUsuarioAtualizacao,
     NomeUnidadeAtualizacao,
     Latitude,
     Longitude
    )   ;
END;
IF (NOT EXISTS (
               SELECT I.name,
                      C.*
               FROM sys.indexes AS I
                    JOIN
                    sys.index_columns AS IC ON I.object_id = IC.object_id
                                               AND I.index_id = IC.index_id
                    JOIN
                    sys.columns AS C ON I.object_id = C.object_id
               WHERE I.object_id = 2083642616
                     AND C.name = 'Local'
                     AND I.type > 1
                     AND IC.key_ordinal = 1
               )
   )
BEGIN
    CREATE NONCLUSTERED INDEX [IX_Enderecos_Local]
        ON Cadastro.Enderecos (Local)
        INCLUDE (IdPessoa, IdCidade, Logradouro);
END;
IF (NOT EXISTS (
               SELECT I.name,
                      C.*
               FROM sys.indexes AS I
                    JOIN
                    sys.index_columns AS IC ON I.object_id = IC.object_id
                                               AND I.index_id = IC.index_id
                    JOIN
                    sys.columns AS C ON I.object_id = C.object_id
               WHERE I.object_id = 2102298549
                     AND C.name = 'IdCertidao'
                     AND I.type > 1
                     AND IC.key_ordinal = 1
               )
   )
BEGIN
    CREATE NONCLUSTERED INDEX [IX_DividaAtivaCertidoesDocumentosIdCertidaoTipoVinculo]
        ON DividaAtiva.CertidoesDocumentos (IdCertidao, TipoVinculo);
END;
IF (NOT EXISTS (
               SELECT I.name,
                      C.*
               FROM sys.indexes AS I
                    JOIN
                    sys.index_columns AS IC ON I.object_id = IC.object_id
                                               AND I.index_id = IC.index_id
                    JOIN
                    sys.columns AS C ON I.object_id = C.object_id
               WHERE I.object_id = 2107870576
                     AND C.name = 'IdEmissao'
                     AND I.type > 1
                     AND IC.key_ordinal = 1
               )
   )
BEGIN
    CREATE NONCLUSTERED INDEX [IX_EmissoesParcelas_IdEmissao]
        ON Financeiro.EmissoesParcelas (IdEmissao)
        INCLUDE
    (IdParcelamentoParcela,
     ValorPrincipal,
     ValorAtualizacaoMonetaria,
     ValorJuros,
     ValorMulta,
     ValorAcrescimo,
     ValorTotal
    )   ;
END;
IF (NOT EXISTS (
               SELECT I.name,
                      C.*
               FROM sys.indexes AS I
                    JOIN
                    sys.index_columns AS IC ON I.object_id = IC.object_id
                                               AND I.index_id = IC.index_id
                    JOIN
                    sys.columns AS C ON I.object_id = C.object_id
               WHERE I.object_id = 2107870576
                     AND C.name = 'IdParcelamentoParcela'
                     AND I.type > 1
                     AND IC.key_ordinal = 1
               )
   )
BEGIN
    CREATE NONCLUSTERED INDEX [IX_EmissoesParcelas_IdParcelamentoParcela]
        ON Financeiro.EmissoesParcelas (IdParcelamentoParcela)
        INCLUDE (IdEmissao);
END;
IF (NOT EXISTS (
               SELECT I.name,
                      C.*
               FROM sys.indexes AS I
                    JOIN
                    sys.index_columns AS IC ON I.object_id = IC.object_id
                                               AND I.index_id = IC.index_id
                    JOIN
                    sys.columns AS C ON I.object_id = C.object_id
               WHERE I.object_id = 2110630562
                     AND C.name = 'IdItem'
                     AND I.type > 1
                     AND IC.key_ordinal = 1
               )
   )
BEGIN
    CREATE NONCLUSTERED INDEX [UNQ_AlmoxarifadoItensRegistrosPrecoIdItem]
        ON Almoxarifado.ItensRegistrosPreco (IdItem);
END;
IF (NOT EXISTS (
               SELECT I.name,
                      C.*
               FROM sys.indexes AS I
                    JOIN
                    sys.index_columns AS IC ON I.object_id = IC.object_id
                                               AND I.index_id = IC.index_id
                    JOIN
                    sys.columns AS C ON I.object_id = C.object_id
               WHERE I.object_id = 2115642730
                     AND C.name = 'IdEndereco'
                     AND I.type > 1
                     AND IC.key_ordinal = 1
               )
   )
BEGIN
    CREATE NONCLUSTERED INDEX [missing_index_136_135]
        ON Cadastro.EnderecosHistoricos (IdEndereco);
END;
IF (NOT EXISTS (
               SELECT I.name,
                      C.*
               FROM sys.indexes AS I
                    JOIN
                    sys.index_columns AS IC ON I.object_id = IC.object_id
                                               AND I.index_id = IC.index_id
                    JOIN
                    sys.columns AS C ON I.object_id = C.object_id
               WHERE I.object_id = 2123154609
                     AND C.name = 'IdCurso'
                     AND I.type > 1
                     AND IC.key_ordinal = 1
               )
   )
BEGIN
    CREATE NONCLUSTERED INDEX [IX_CadastroInstituicoesEnsinoCursosIdCurso]
        ON Cadastro.InstituicoesEnsinoCursos (IdCurso)
        INCLUDE (IdInstituicaoEnsino);
END;
IF (NOT EXISTS (
               SELECT I.name,
                      C.*
               FROM sys.indexes AS I
                    JOIN
                    sys.index_columns AS IC ON I.object_id = IC.object_id
                                               AND I.index_id = IC.index_id
                    JOIN
                    sys.columns AS C ON I.object_id = C.object_id
               WHERE I.object_id = 2123154609
                     AND C.name = 'IdInstituicaoEnsino'
                     AND I.type > 1
                     AND IC.key_ordinal = 1
               )
   )
BEGIN
    CREATE NONCLUSTERED INDEX [missing_index_43_42]
        ON Cadastro.InstituicoesEnsinoCursos (IdInstituicaoEnsino);
END;
IF (NOT EXISTS (
               SELECT I.name,
                      C.*
               FROM sys.indexes AS I
                    JOIN
                    sys.index_columns AS IC ON I.object_id = IC.object_id
                                               AND I.index_id = IC.index_id
                    JOIN
                    sys.columns AS C ON I.object_id = C.object_id
               WHERE I.object_id = 2139870690
                     AND C.name = 'IdEmissaoParcela'
                     AND I.type > 1
                     AND IC.key_ordinal = 1
               )
   )
BEGIN
    CREATE NONCLUSTERED INDEX [IX_EmissoesParcelasComposicoes_IdEmissaoParcela]
        ON Financeiro.EmissoesParcelasComposicoes (IdEmissaoParcela)
        INCLUDE (IdParcelamentoComposicao, IdProcedimentoAtraso);
END;
IF (NOT EXISTS (
               SELECT I.name,
                      C.*
               FROM sys.indexes AS I
                    JOIN
                    sys.index_columns AS IC ON I.object_id = IC.object_id
                                               AND I.index_id = IC.index_id
                    JOIN
                    sys.columns AS C ON I.object_id = C.object_id
               WHERE I.object_id = 2139870690
                     AND C.name = 'IdParcelamentoComposicao'
                     AND I.type > 1
                     AND IC.key_ordinal = 1
               )
   )
BEGIN
    CREATE NONCLUSTERED INDEX [IX_FinanceiroEmissoesParcelasComposicoesIdParcelamentoComposicao]
        ON Financeiro.EmissoesParcelasComposicoes (IdParcelamentoComposicao);
END;