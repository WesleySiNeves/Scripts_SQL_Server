
/* ==================================================================
--Data: 23/01/2019 
--Autor :Wesley Neves
--Observação: Altera Campo TipoEmissao   [varchar] (50) para Char(1)
SELECT DISTINCT E.TipoEmissao FROM Financeiro.Emissoes AS E
 
-- ==================================================================
*/


IF ( OBJECT_ID('TEMPDB..#DadosFinanceiroEmissoesTipoEmissao') IS NOT NULL )
    DROP TABLE #DadosFinanceiroEmissoesTipoEmissao;	

CREATE TABLE #DadosFinanceiroEmissoesTipoEmissao
    (
       KeyValue VARCHAR(100) UNIQUE,
	   Valor VARCHAR(100)

    );


INSERT  INTO #DadosFinanceiroEmissoesTipoEmissao
(
    KeyValue,
    Valor
)
VALUES
(   'Debito', -- KeyValue - varchar(100)
    'D'  -- Valor - varchar(100)
),
(   'Parcela', -- KeyValue - varchar(100)
    'P'  -- Valor - varchar(100)
)


IF (EXISTS
(
    SELECT T.name,
           C.name AS Coluna,
           T2.name
    FROM sys.tables AS T
        JOIN sys.columns AS C
            ON T.object_id = C.object_id
        JOIN sys.types AS T2
            ON C.user_type_id = T2.user_type_id
    WHERE T.object_id = OBJECT_ID('DNE.Logradouros')
          AND C.name = 'DataCadastro'
          AND T2.name LIKE '%datetime%'
)
   )
BEGIN

SELECT TOP 100 L.DataCadastro FROM DNE.Logradouros AS L

    BEGIN TRAN T_DNELogradouros

	

    DECLARE @AlterEmissoes NVARCHAR(1000)
        = CONCAT('ALTER TABLE DNE.Logradouros ADD DataCadastroNEW DATE;', SPACE(1));

    EXEC sys.sp_executesql @AlterEmissoes;

	

    DECLARE @UpdateTipoEmissaoDebito NVARCHAR(1000)
        = CONCAT(
                    'UPDATE DNE.Logradouros SET Logradouros.DataCadastroNEW = ',
                    CHAR(39),
                    'D',
                    CHAR(39),
                    
                    SPACE(1)
                );

    EXEC sys.sp_executesql @UpdateTipoEmissaoDebito;

    DECLARE @UpdateTipoParcela NVARCHAR(1000)
        = CONCAT(
                    'UPDATE Financeiro.Emissoes SET Emissoes.TipoEmissaoNEW = ',
                    CHAR(39),
                    'P',
                    CHAR(39),
                    ' WHERE',
                    ' Emissoes.TipoEmissao = ',
                    CHAR(39),
                    'Parcela',
                    CHAR(39),
                    '',
                    SPACE(1)
                );

    EXEC sys.sp_executesql @UpdateTipoParcela;



    IF (EXISTS
    (
        SELECT *
        FROM sys.indexes AS I
        WHERE I.object_id = OBJECT_ID('Financeiro.Emissoes')
              AND I.name = 'IX_Emissoes_IdPessoaTipoEmissao'
    )
       )
    BEGIN

	DECLARE @dropIndex NVARCHAR(1000) ='DROP INDEX [IX_Emissoes_IdPessoaTipoEmissao] ON Financeiro.Emissoes;';

       EXEC sys.sp_executesql @dropIndex;
    END;

    ;


    DECLARE @AlterDropCollumTipoEmissao NVARCHAR(1000)
        = CONCAT('ALTER TABLE Financeiro.Emissoes DROP COLUMN TipoEmissao;', SPACE(1));


     EXEC sys.sp_executesql @AlterDropCollumTipoEmissao;



    EXEC sys.sp_rename @objname = N'Financeiro.Emissoes.TipoEmissaoNEW', -- nvarchar(1035)
                       @newname = 'TipoEmissao';                         -- sysname



    DECLARE @AlterAddNotNUll NVARCHAR(1000)
        = CONCAT('ALTER TABLE Financeiro.Emissoes ALTER COLUMN TipoEmissao CHAR(1) NOT NULL', SPACE(1));

    EXEC sys.sp_executesql @AlterAddNotNUll;



    EXEC sys.sp_addextendedproperty  @name = 'MS_Description',
                                    @value = 'D =Debito, P =Parcela',
                                    @level0type = 'Schema',
                                    @level0name = 'Financeiro',
                                    @level1type = 'Table',
                                    @level1name = 'Emissoes',
                                    @level2type = 'Column',
                                    @level2name = 'TipoEmissao';



COMMIT TRAN T_FinanceiroEmissoes


END;



IF (EXISTS
(
    SELECT T.name,
           C.name AS Coluna,
           T2.name
    FROM sys.tables AS T
        JOIN sys.columns AS C
            ON T.object_id = C.object_id
        JOIN sys.types AS T2
            ON C.user_type_id = T2.user_type_id
    WHERE T.object_id = OBJECT_ID('Financeiro.Emissoes')
          AND C.name = 'TipoEmissao'
          AND T2.name = 'varchar'
)
   )
BEGIN

    BEGIN TRAN T_FinanceiroEmissoes


    DECLARE @AlterEmissoes NVARCHAR(1000)
        = CONCAT('ALTER TABLE Financeiro.Emissoes ADD TipoEmissaoNEW CHAR(1);', SPACE(1));

    EXEC sys.sp_executesql @AlterEmissoes;



    DECLARE @UpdateTipoEmissaoDebito NVARCHAR(1000)
        = CONCAT(
                    'UPDATE Financeiro.Emissoes SET Emissoes.TipoEmissaoNEW = ',
                    CHAR(39),
                    'D',
                    CHAR(39),
                    ' WHERE',
                    ' Emissoes.TipoEmissao = ',
                    CHAR(39),
                    'Debito',
                    CHAR(39),
                    '',
                    SPACE(1)
                );

    EXEC sys.sp_executesql @UpdateTipoEmissaoDebito;

    DECLARE @UpdateTipoParcela NVARCHAR(1000)
        = CONCAT(
                    'UPDATE Financeiro.Emissoes SET Emissoes.TipoEmissaoNEW = ',
                    CHAR(39),
                    'P',
                    CHAR(39),
                    ' WHERE',
                    ' Emissoes.TipoEmissao = ',
                    CHAR(39),
                    'Parcela',
                    CHAR(39),
                    '',
                    SPACE(1)
                );

    EXEC sys.sp_executesql @UpdateTipoParcela;



    IF (EXISTS
    (
        SELECT *
        FROM sys.indexes AS I
        WHERE I.object_id = OBJECT_ID('Financeiro.Emissoes')
              AND I.name = 'IX_Emissoes_IdPessoaTipoEmissao'
    )
       )
    BEGIN

	DECLARE @dropIndex NVARCHAR(1000) ='DROP INDEX [IX_Emissoes_IdPessoaTipoEmissao] ON Financeiro.Emissoes;';

       EXEC sys.sp_executesql @dropIndex;
    END;

    ;


    DECLARE @AlterDropCollumTipoEmissao NVARCHAR(1000)
        = CONCAT('ALTER TABLE Financeiro.Emissoes DROP COLUMN TipoEmissao;', SPACE(1));


     EXEC sys.sp_executesql @AlterDropCollumTipoEmissao;



    EXEC sys.sp_rename @objname = N'Financeiro.Emissoes.TipoEmissaoNEW', -- nvarchar(1035)
                       @newname = 'TipoEmissao';                         -- sysname



    DECLARE @AlterAddNotNUll NVARCHAR(1000)
        = CONCAT('ALTER TABLE Financeiro.Emissoes ALTER COLUMN TipoEmissao CHAR(1) NOT NULL', SPACE(1));

    EXEC sys.sp_executesql @AlterAddNotNUll;



    EXEC sys.sp_addextendedproperty  @name = 'MS_Description',
                                    @value = 'D =Debito, P =Parcela',
                                    @level0type = 'Schema',
                                    @level0name = 'Financeiro',
                                    @level1type = 'Table',
                                    @level1name = 'Emissoes',
                                    @level2type = 'Column',
                                    @level2name = 'TipoEmissao';



COMMIT TRAN T_FinanceiroEmissoes


END;



IF (EXISTS
(
    SELECT T.name,
           C.name AS Coluna,
           T2.name
    FROM sys.tables AS T
        JOIN sys.columns AS C
            ON T.object_id = C.object_id
        JOIN sys.types AS T2
            ON C.user_type_id = T2.user_type_id
    WHERE T.object_id = OBJECT_ID('Financeiro.Emissoes')
          AND C.name = 'SituacaoRegistro'
          AND T2.name = 'varchar'
)
   )
BEGIN


BEGIN TRAN T2




    DECLARE @AlterEmissoesSituacaoRegistro NVARCHAR(1000)
        = CONCAT('ALTER TABLE Financeiro.Emissoes ADD SituacaoRegistroNEW TINYINT;', SPACE(1));

    EXEC sys.sp_executesql @AlterEmissoesSituacaoRegistro;


    DECLARE @UpdateTipoEmissaoDebito NVARCHAR(1000)
        = CONCAT(
                    'UPDATE Financeiro.Emissoes SET Emissoes.SituacaoRegistroNEW = ',
                      NULL,
                    ' WHERE',
                    ' Emissoes.SituacaoRegistro = ',
                    CHAR(39),
                    'AguardandoRemessaRegistro',
                    CHAR(39),
                    '',
                    SPACE(1)
                );

    EXEC sys.sp_executesql @UpdateTipoEmissaoDebito;

    DECLARE @UpdateTipoParcela NVARCHAR(1000)
        = CONCAT(
                    'UPDATE Financeiro.Emissoes SET Emissoes.TipoEmissaoNEW = ',
                    CHAR(39),
                    'P',
                    CHAR(39),
                    ' WHERE',
                    ' Emissoes.TipoEmissao = ',
                    CHAR(39),
                    'Parcela',
                    CHAR(39),
                    '',
                    SPACE(1)
                );

    EXEC sys.sp_executesql @UpdateTipoParcela;




    IF (EXISTS
    (
        SELECT *
        FROM sys.indexes AS I
        WHERE I.object_id = OBJECT_ID('Financeiro.Emissoes')
              AND I.name = 'IX_Emissoes_IdPessoaTipoEmissao'
    )
       )
    BEGIN

	DECLARE @dropIndex NVARCHAR(1000) ='DROP INDEX [IX_Emissoes_IdPessoaTipoEmissao] ON Financeiro.Emissoes;';

       EXEC sys.sp_executesql @dropIndex;
    END;

    ;


    DECLARE @AlterDropCollumTipoEmissao NVARCHAR(1000)
        = CONCAT('ALTER TABLE Financeiro.Emissoes DROP COLUMN TipoEmissao;', SPACE(1));


     EXEC sys.sp_executesql @AlterDropCollumTipoEmissao;



    EXEC sys.sp_rename @objname = N'Financeiro.Emissoes.TipoEmissaoNEW', -- nvarchar(1035)
                       @newname = 'TipoEmissao';                         -- sysname



    DECLARE @AlterAddNotNUll NVARCHAR(1000)
        = CONCAT('ALTER TABLE Financeiro.Emissoes ALTER COLUMN TipoEmissao CHAR(1) NOT NULL', SPACE(1));

    EXEC sys.sp_executesql @AlterAddNotNUll;



    EXEC sys.sp_addextendedproperty  @name = 'MS_Description',
                                    @value = 'D =Debito, P =Parcela',
                                    @level0type = 'Schema',
                                    @level0name = 'Financeiro',
                                    @level1type = 'Table',
                                    @level1name = 'Emissoes',
                                    @level2type = 'Column',
                                    @level2name = 'TipoEmissao';



COMMIT TRAN T1
END;




IF (EXISTS
(
    SELECT T.name,
           C.name AS Coluna,
           C.is_nullable,
           T2.name
    FROM sys.tables AS T
        JOIN sys.columns AS C
            ON T.object_id = C.object_id
        JOIN sys.types AS T2
            ON C.user_type_id = T2.user_type_id
    WHERE T.object_id = OBJECT_ID('Processo.ProcessosAdministrativos')
          AND C.name = 'IdTipoSolicitacao'
          AND T2.name = 'uniqueidentifier'
)
   )
BEGIN

    DECLARE @Alter NVARCHAR(1000)
        = CONCAT('ALTER TABLE Processo.ProcessosAdministrativos ADD IdTipoSolicitacaoNew TINYINT;', SPACE(1));

     EXEC sys.sp_executesql  @Alter;

    DECLARE @Update NVARCHAR(1000)
        = CONCAT(
                    'UPDATE Processo.ProcessosAdministrativos SET ProcessosAdministrativos.IdTipoSolicitacaoNew = 0 WHERE',
                    ' ProcessosAdministrativos.IdTipoSolicitacao = ',
                    CHAR(39),
                    '00000000-0000-0000-0000-000000000000',
                    CHAR(39),
                    '',
                    SPACE(1)
                );

     EXEC sys.sp_executesql  @Update;


    DECLARE @DropCollum NVARCHAR(1000)
        = CONCAT('ALTER TABLE Processo.ProcessosAdministrativos DROP COLUMN IdTipoSolicitacao;', SPACE(1));


     EXEC sys.sp_executesql  @DropCollum;


    EXEC sys.sp_rename @objname = N'Processo.ProcessosAdministrativos.IdTipoSolicitacaoNew', -- nvarchar(1035)
                       @newname = 'IdTipoSolicitacao';                                       -- sysname



    DECLARE @AlterNotNull NVARCHAR(1000)
        = CONCAT(
                    'ALTER TABLE Processo.ProcessosAdministrativos ALTER COLUMN IdTipoSolicitacao TINYINT NOT NULL',
                    SPACE(1)
                );


END;


IF (EXISTS
(
    SELECT T.name,
           C.name AS Coluna,
           T2.name
    FROM sys.tables AS T
        JOIN sys.columns AS C
            ON T.object_id = C.object_id
        JOIN sys.types AS T2
            ON C.user_type_id = T2.user_type_id
    WHERE T.object_id = OBJECT_ID('Financeiro.Parcelamentos')
          AND C.name = 'TermoEmitido'
          AND T2.name = 'varchar'
)
   )
BEGIN


    DECLARE @AlterParcelamentos NVARCHAR(1000)
        = CONCAT(' ALTER TABLE Financeiro.Parcelamentos ADD TermoEmitidoNew TINYINT;', SPACE(1));

    EXEC sys.sp_executesql  @AlterParcelamentos;

    DECLARE @UpdateParcelamentosNenhum NVARCHAR(1000)
        = CONCAT(
                    'UPDATE Financeiro.Parcelamentos SET TermoEmitidoNew = 0 WHERE',
                    ' Parcelamentos.TermoEmitido = ',
                    CHAR(39),
                    'Nenhum',
                    CHAR(39),
                    '',
                    SPACE(1)
                );

    EXEC sys.sp_executesql  @UpdateParcelamentosNenhum;


    DECLARE @UpdateParcelamentosConfissaoDivida NVARCHAR(1000)
        = CONCAT(
                    'UPDATE Financeiro.Parcelamentos SET TermoEmitidoNew = 1 WHERE',
                    ' Parcelamentos.TermoEmitido = ',
                    CHAR(39),
                    'ConfissaoDivida',
                    CHAR(39),
                    '',
                    SPACE(1)
                );

    EXEC sys.sp_executesql  @UpdateParcelamentosConfissaoDivida;


    DECLARE @UpdateParcelamentosConfissaoParcelamento NVARCHAR(1000)
        = CONCAT(
                    'UPDATE Financeiro.Parcelamentos SET TermoEmitidoNew = 2 WHERE',
                    ' Parcelamentos.TermoEmitido = ',
                    CHAR(39),
                    'Parcelamento',
                    CHAR(39),
                    '',
                    SPACE(1)
                );

    EXEC sys.sp_executesql  @UpdateParcelamentosConfissaoParcelamento;



    DECLARE @AlterDropCONSTRAINT NVARCHAR(1000)
        = CONCAT(
                    ' ALTER TABLE Financeiro.Parcelamentos DROP CONSTRAINT [DEF_FinanceiroParcelamentosTermoEmitido];',
                    SPACE(1)
                );

    EXEC sys.sp_executesql  @AlterDropCONSTRAINT;


    DECLARE @AlterDropCHECK NVARCHAR(1000)
        = CONCAT(
                    ' ALTER TABLE Financeiro.Parcelamentos DROP CONSTRAINT CHECK_FinanceiroParcelamentosTermoEmitido;',
                    SPACE(1)
                );

    EXEC sys.sp_executesql  @AlterDropCHECK;


    DECLARE @AlterDropIndex NVARCHAR(1000)
        = CONCAT(
                    ' DROP INDEX [IX_FinanceiroParcelamentosIdParcelamentoTipoIdPessoa] ON Financeiro.Parcelamentos;',
                    SPACE(1)
                );


    EXEC sys.sp_executesql  @AlterDropIndex;


    DECLARE @AlterDropCollum NVARCHAR(1000)
        = CONCAT('ALTER TABLE Financeiro.Parcelamentos DROP COLUMN TermoEmitido;', SPACE(1));


    EXEC sys.sp_executesql  @AlterDropCollum;





    EXEC sys.sp_rename @objname = N'Financeiro.Parcelamentos.TermoEmitidoNew', -- nvarchar(1035)
                       @newname = 'TermoEmitido';                              -- sysname


    DECLARE @AlterAddDEFAULT NVARCHAR(1000)
        = CONCAT(
                    'ALTER TABLE Financeiro.Parcelamentos ADD CONSTRAINT [DEF_FinanceiroParcelamentosTermoEmitido] DEFAULT (0) FOR TermoEmitido;',
                    SPACE(1)
                );
    EXEC sys.sp_executesql  @AlterAddDEFAULT;

    DECLARE @AlterAddCHECK NVARCHAR(1000)
        = CONCAT(
                    'ALTER TABLE Financeiro.Parcelamentos ADD CONSTRAINT [CHECK_FinanceiroParcelamentosTermoEmitido] CHECK (Parcelamentos.TermoEmitido IN ( 0, 1, 2 ));',
                    SPACE(1)
                );

    EXEC sys.sp_executesql  @AlterAddCHECK;


    DECLARE @AlterAddNotNUll NVARCHAR(1000)
        = CONCAT('ALTER TABLE Financeiro.Parcelamentos ALTER COLUMN TermoEmitido TINYINT NOT NULL', SPACE(1));

    EXEC sys.sp_executesql  @AlterAddNotNUll;



    EXEC sys.sp_addextendedproperty @name = 'Comentario',
                                    @value = '0 =Nenhum, 1 =ConfissaoDivida, 2 =Parcelamento',
                                    @level0type = 'Schema',
                                    @level0name = 'Financeiro',
                                    @level1type = 'Table',
                                    @level1name = 'Parcelamentos',
                                    @level2type = 'Column',
                                    @level2name = 'TermoEmitido';




END;


--IF (EXISTS
--(
--    SELECT T.name,
--           C.name AS Coluna,
--           T2.name
--    FROM sys.tables AS T
--        JOIN sys.columns AS C
--            ON T.object_id = C.object_id
--        JOIN sys.types AS T2
--            ON C.user_type_id = T2.user_type_id
--    WHERE T.object_id = OBJECT_ID('Financeiro.DebitosSituacoesParcelamentosHistoricos')
--          AND C.name = 'IdDebitoSituacaoParcelamento'
--          AND T2.name = 'UNIQUEIDENTIFIER'
--)
--   )
--BEGIN


   



--END;








--SELECT TOP 100 * FROM Financeiro.Emissoes

--SELECT TOP 100 * FROM Financeiro.ParcelamentosComposicoes AS PC

--SELECT TOP 100 * FROM Financeiro.Emissoes

--SELECT TOP 100 * FROM Financeiro.PagamentosDebitos AS PD


--SELECT TOP 100 * FROM Financeiro.DebitosSituacoesPagtoHistoricos AS DSPH

--SELECT TOP 100 * FROM Financeiro.PagamentosParcelamentosComposicoes AS PPC

--SELECT TOP 100 * FROM Financeiro.ParcelamentosParcelas AS PP

--SELECT    TOP 100  * FROM Financeiro.Debitos AS D

--SELECT TOP 100 * FROM Financeiro.EmissoesDebitos AS ED

--SELECT  DISTINCT EPC.IdProcedimentoAtraso FROM Financeiro.EmissoesParcelasComposicoes AS EPC
