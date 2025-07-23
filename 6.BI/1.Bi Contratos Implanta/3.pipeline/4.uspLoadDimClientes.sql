


CREATE OR ALTER PROCEDURE Shared.uspLoadDimClientes
AS
BEGIN

    BEGIN TRY

	DECLARE @quantidadeRegistros INT =
				(
					SELECT
						COUNT(1)
					FROM
						Staging.ClientesProdutosCIGAM
				);

	DROP TABLE IF EXISTS #DadosCLientes;

	DROP TABLE IF EXISTS #NovosClientes;

	DROP TABLE IF EXISTS #SourceClientes;


	CREATE TABLE #NovosClientes
		(
			[IdCliente]             UNIQUEIDENTIFIER,
			[IdConselhoFederal]     UNIQUEIDENTIFIER,
			[SiglaConselhoRegional] VARCHAR(30),
			[Conselho]              VARCHAR(30),
			[UF]                    VARCHAR(2),
			[Nome]        VARCHAR(403)
		);

	CREATE TABLE #SourceClientes
		(
			[IdCliente]            UNIQUEIDENTIFIER,
			[SkConselhoFederal]    SMALLINT,
			[NomeCliente]          VARCHAR(8000),
			[SiglaCliente]         VARCHAR(250),
			[SiglaImplanta]        VARCHAR(250) NULL,
			[SkCategoria]          SMALLINT,
			[UF]                   VARCHAR(250),
			[TipoCliente]          VARCHAR(22),
			[ClienteAtivoImplanta] BIT 
		);


		;WITH DadosNovosClientes
		AS (   SELECT DISTINCT
					  SiglaCliente,
					  SUBSTRING(SiglaCliente, 0, CHARINDEX('/', SiglaCliente)) AS Conselho,
					  UF    = IIF( CHARINDEX('/', SiglaCliente) > 0,SUBSTRING(SiglaCliente, CHARINDEX('/', SiglaCliente) + 1, 2),'BR')
			   FROM
					  Staging.ClientesProdutosCIGAM
			   WHERE
					  SiglaCliente NOT IN
						  (
							  SELECT
								  SiglaConselhoRegional
							  FROM
								  Implanta.Clientes
						  ))

						  INSERT INTO #NovosClientes
		SELECT
			NEWID()           AS IdCliente,
			vinculo.IdConselhoFederal,
			R.SiglaCliente    AS SiglaConselhoRegional,
			R.Conselho,
			R.UF,
			CONCAT(vinculo.Nome, '/', R.UF) AS Nome
			FROM
				DadosNovosClientes R
				OUTER APPLY
				(
					SELECT TOP 1
						   SUBSTRING(cli.Nome, 0, CHARINDEX('/', cli.Nome)) AS Nome,
						   cli.IdConselhoFederal
					FROM
						   Implanta.Clientes cli
					WHERE
						   cli.SiglaConselhoRegional LIKE CONCAT('%', R.Conselho, '%')
				)                  vinculo;
		
				INSERT INTO Implanta.Clientes
					(
						IdCliente,
						IdConselhoFederal,
						SiglaConselhoRegional,
						Nome
					)
				SELECT IdCliente,
					   IdConselhoFederal,
					   SiglaConselhoRegional,
					   Nome FROM #NovosClientes
	 

			;WITH DadosClientesImplanta AS (
			SELECT c.IdCliente,
					   c.IdConselhoFederal,
					   cfed.SkConselhoFederal,
                  
						cfed.Sigla AS SiglaFederal,
						 NomeCliente = REPLACE(
												REPLACE(REPLACE(c.Nome, 'Cons.', 'Conselho'), 'Reg.', 'Regional'),
												'Med.',
												'Medicina'
											),
					   c.SiglaConselhoRegional AS SiglaCliente,
                   
					   cfed.SkCategoria
				FROM Implanta.Clientes c
					JOIN Shared.DimConselhosFederais cfed
						ON cfed.IdConselhoFederal = c.IdConselhoFederal
			),
			Resumo AS (
			SELECT
						cli.IdCliente,
						cli.SkConselhoFederal,
						cli.NomeCliente,
						cli.SiglaCliente,
						cli.SkCategoria,
						UF      = CASE
									  WHEN CHARINDEX('/', cli.SiglaCliente) = 0
										  THEN
										  'BR'
									  WHEN CHARINDEX('/', cli.SiglaCliente) > 0
										  THEN
										  SUBSTRING(cli.SiglaCliente, CHARINDEX('/', cli.SiglaCliente) + 1)
								  END,
						ISNULL(   CASE
									  WHEN cli.NomeCliente LIKE '%conselho%'
										   OR cli.NomeCliente LIKE 'CR%'
										   OR cli.NomeCliente LIKE 'CF%'
										  THEN
										  'Conselho'
									  WHEN cli.NomeCliente LIKE '%OAB%'
										   OR cli.NomeCliente LIKE '%Advocaci%'
										   OR cli.NomeCliente LIKE '%Advoga%'
										  THEN
										  'Ordem dos Advogados'
									  WHEN cli.NomeCliente LIKE '%Prefeitura%'
										  THEN
										  'Prefeitura'
									  WHEN cli.NomeCliente LIKE '%Serviço%'
										   OR cli.NomeCliente LIKE '%Servico%'
										  THEN
										  'Sistema S'
									  WHEN cli.NomeCliente LIKE '%Sindicato%'
										  THEN
										  'sindicato'
									  WHEN cli.NomeCliente LIKE '%MÚSICOS%'
										  THEN
										  'conselho'
									  WHEN cli.NomeCliente LIKE '%Economista%'
										  THEN
										  'conselho'
									  WHEN cli.NomeCliente LIKE '%Ministério Público%'
										  THEN
										  'M.Público'
									  WHEN cli.NomeCliente LIKE '%Cooperativa%'
										  THEN
										  'Cooperativa'
									  ELSE
										  NULL
								  END, 'Sem Categoria'
							  ) AS TipoCliente,
							  IIF(@quantidadeRegistros > 0 AND cliCigam.SiglaCliente IS NULL,0,1) AS ClienteAtivoImplanta
				FROM
						DadosClientesImplanta cli
					LEFT JOIN
						(
							SELECT DISTINCT
								   SiglaCliente
							FROM
								   Staging.ClientesProdutosCIGAM -- Talvez aqui no futuro colocar um where Situacao ='?'
						)              cliCigam
							ON cliCigam.SiglaCliente = cli.SiglaCliente
							WHERE cli.IdCliente <> '00000000-0000-0000-0000-000000000000' -- Implanta Informatica
		
			)
			INSERT INTO #SourceClientes
			    (
			        IdCliente,
			        SkConselhoFederal,
			        NomeCliente,
			        SiglaCliente,
			        SkCategoria,
			        UF,
			        TipoCliente,
			        ClienteAtivoImplanta
			    )
			SELECT R.IdCliente,
				   R.SkConselhoFederal,
				   R.NomeCliente,
				   R.SiglaCliente,
				   R.SkCategoria,
				   R.UF,
				   R.TipoCliente,
				   R.ClienteAtivoImplanta FROM Resumo R

			
			UPDATE target SET target.SiglaImplanta = REPLACE(IIF(TipoCliente ='Conselho' AND UF ='BR', CONCAT(REPLACE(SiglaCliente,'/BR',''),'-BR'),SiglaCliente),'-','/')
		 FROM #SourceClientes target	
		
			
			
			UPDATE cli SET cli.SiglaImplanta =regiao.SiglaImplanta FROM #SourceClientes cli
			JOIN  DM_MetricasClientes.DimClientesRegioes regiao ON regiao.SiglaCliente = cli.SiglaCliente
			

        -- =============================================
        -- IMPLEMENTAÇÃO SCD TIPO 2 PARA DIMENSÃO CLIENTES
        -- =============================================
        
        PRINT 'Iniciando processo SCD Tipo 2 para DimClientes...';
        
        -- 1. Identificar registros que mudaram (necessitam nova versão)
        DROP TABLE IF EXISTS #ClientesAlterados;
        CREATE TABLE #ClientesAlterados
        (
            SiglaCliente VARCHAR(250),
            SkClienteAtual INT,
            IdCliente UNIQUEIDENTIFIER,
            NovoNome VARCHAR(250),
			NovaSiglaImplanta VARCHAR(50),
            NovoTipoCliente VARCHAR(22),
            NovoSkConselhoFederal SMALLINT,
            NovoUF VARCHAR(250),
            NovoClienteAtivoImplanta BIT
        );
        
        -- Identificar clientes que sofreram alterações
        INSERT INTO #ClientesAlterados
        (
            SiglaCliente,
            SkClienteAtual,
            IdCliente,
            NovoNome,
			NovaSiglaImplanta,
            NovoTipoCliente,
            NovoSkConselhoFederal,
            NovoUF,
            NovoClienteAtivoImplanta
        )
        SELECT 
            src.SiglaCliente,
            dim.SkCliente,
            src.IdCliente,
            src.NomeCliente,
			src.SiglaImplanta,
            src.TipoCliente,
            src.SkConselhoFederal,
            src.UF,
            src.ClienteAtivoImplanta
        FROM #SourceClientes src
        INNER JOIN Shared.DimClientes dim ON src.SiglaCliente = dim.SiglaCliente
                                          AND dim.VersaoAtual = 1
        WHERE (
            ISNULL(src.NomeCliente, '') <> ISNULL(dim.Nome, '') OR
            ISNULL(src.TipoCliente, '') <> ISNULL(dim.TipoCliente, '') OR
            ISNULL(src.SkConselhoFederal, 0) <> ISNULL(dim.SkConselhoFederal, 0) OR
            ISNULL(src.UF, '') <> ISNULL(dim.Estado, '') OR
            ISNULL(src.ClienteAtivoImplanta, 0) <> ISNULL(dim.ClienteAtivoImplanta, 0)
        );
        
        DECLARE @ClientesAlterados INT = @@ROWCOUNT;
        PRINT 'Clientes identificados para atualização (SCD): ' + CAST(@ClientesAlterados AS VARCHAR(10));
        
        -- 2. Fechar versões antigas (definir DataFimVersao e VersaoAtual = 0)
        UPDATE dim
        SET 
            DataFimVersao = GETDATE(),
            VersaoAtual = 0,
            DataAtualizacao = GETDATE()
        FROM Shared.DimClientes dim
        INNER JOIN #ClientesAlterados alt ON dim.SkCliente = alt.SkClienteAtual;
        
        PRINT 'Versões antigas fechadas: ' + CAST(@@ROWCOUNT AS VARCHAR(10));
        
		
		
        -- 3. Inserir novas versões para registros alterados
        INSERT INTO Shared.DimClientes
        (
            IdCliente,
            SkConselhoFederal,
            Nome,
            SiglaCliente,
			SiglaImplanta,
            Estado,
            TipoCliente,
            Ativo,
            ClienteAtivoImplanta,
            DataInicioVersao,
            DataFimVersao,
            VersaoAtual,
            DataCarga,
            DataAtualizacao
        )
        SELECT 
            alt.IdCliente,
            alt.NovoSkConselhoFederal,
            alt.NovoNome,
            alt.SiglaCliente,
			alt.NovaSiglaImplanta,
            alt.NovoUF,
            alt.NovoTipoCliente,
            1, -- Ativo
            alt.NovoClienteAtivoImplanta,
            GETDATE(), -- DataInicioVersao
            NULL, -- DataFimVersao (NULL = versão atual)
            1, -- VersaoAtual
            GETDATE(), -- DataCarga
            GETDATE() -- DataAtualizacao
        FROM #ClientesAlterados alt;
        
        PRINT 'Novas versões inseridas: ' + CAST(@@ROWCOUNT AS VARCHAR(10));
        
        -- 4. Inserir novos clientes (que não existem na dimensão)
        INSERT INTO Shared.DimClientes
        (
            IdCliente,
            SkConselhoFederal,
            Nome,
            SiglaCliente,
			SiglaImplanta,
            Estado,
            TipoCliente,
            Ativo,
            ClienteAtivoImplanta,
            DataInicioVersao,
            DataFimVersao,
            VersaoAtual,
            DataCarga,
            DataAtualizacao
        )
        SELECT 
            src.IdCliente,
            src.SkConselhoFederal,
            src.NomeCliente,
			src.SiglaCliente,
			src.SiglaImplanta,
            src.UF,
            src.TipoCliente,
            1, -- Ativo
            src.ClienteAtivoImplanta,
            GETDATE(), -- DataInicioVersao
            NULL, -- DataFimVersao (NULL = versão atual)
            1, -- VersaoAtual
            GETDATE(), -- DataCarga
            GETDATE() -- DataAtualizacao
        FROM #SourceClientes src
        WHERE NOT EXISTS (
            SELECT 1 
            FROM Shared.DimClientes dim 
            WHERE dim.SiglaCliente = src.SiglaCliente
        );
        
        DECLARE @NovosClientes INT = @@ROWCOUNT;
        PRINT 'Novos clientes inseridos: ' + CAST(@NovosClientes AS VARCHAR(10));
        
        -- 5. Desativar clientes que não estão mais na origem (opcional)
        -- Comentado para preservar histórico, mas pode ser ativado se necessário
        /*
        UPDATE dim
        SET 
            DataFimVersao = GETDATE(),
            VersaoAtual = 0,
            Ativo = 0,
            DataAtualizacao = GETDATE()
        FROM Shared.DimClientes dim
        WHERE dim.VersaoAtual = 1
          AND NOT EXISTS (
              SELECT 1 
              FROM #SourceClientes src 
              WHERE src.SiglaCliente = dim.SiglaCliente
          );
        */
        
        -- Limpeza de tabelas temporárias
        DROP TABLE IF EXISTS #ClientesAlterados;
        
        PRINT 'Processo SCD Tipo 2 para DimClientes concluído com sucesso!';
        PRINT 'Resumo: ' + CAST(@NovosClientes AS VARCHAR(10)) + ' novos clientes, ' + 
              CAST(@ClientesAlterados AS VARCHAR(10)) + ' clientes atualizados (SCD)';
        


    END TRY
    BEGIN CATCH
        -- Tratamento de erros melhorado
        DECLARE @ErrorNumber INT = ERROR_NUMBER();
        DECLARE @ErrorLine INT = ERROR_LINE();
        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        DECLARE @ErrorSeverity INT = ERROR_SEVERITY();
        DECLARE @ErrorState INT = ERROR_STATE();
        DECLARE @ErrorProcedure NVARCHAR(128) = ERROR_PROCEDURE();

        -- Log detalhado do erro
        PRINT '========== ERRO NA EXECUÇÃO DA PROCEDURE ==========';
        PRINT 'Procedure: ' + ISNULL(@ErrorProcedure, 'Shared.uspLoadDimClientes');
        PRINT 'Número do Erro: ' + CAST(@ErrorNumber AS VARCHAR(MAX));
        PRINT 'Linha do Erro: ' + CAST(@ErrorLine AS VARCHAR(MAX));
        PRINT 'Mensagem: ' + @ErrorMessage;
        PRINT 'Severidade: ' + CAST(@ErrorSeverity AS VARCHAR(MAX));
        PRINT 'Estado: ' + CAST(@ErrorState AS VARCHAR(MAX));

        PRINT '==================================================';

        -- Re-lança o erro para o cliente
        RAISERROR(@ErrorMessage, @ErrorSeverity, @ErrorState);

    END CATCH;
END;


