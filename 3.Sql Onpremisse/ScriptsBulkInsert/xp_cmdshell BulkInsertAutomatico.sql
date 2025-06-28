


DECLARE @trucaTabelaTemporaria BIT = 0;
/*Variavel que controla a INSERÇÃO DE DADOS na tabela auxiliar ([Log].[TempLogs]) */
DECLARE @InserirLog BIT = 1;
DECLARE @InserirLogDetalhe BIT = 0;
DECLARE @ExtensaoArquivo VARCHAR(10) ='.csv'; -- ===>>>> CAMPO OBRIGATORIO



/*Variavel que controla O caminho do arquivo que sera criado quando dr um erro */
DECLARE @pathArquivoErro VARCHAR(MAX)  = N'D:\Geral\cofen-br\error\'; 

/*Variavel que controla O caminho dos arquivo que contem os dados da tabela ([dbo].[TempLogs]) */
DECLARE @CaminhoLog NVARCHAR(MAX) = N'D:\Geral\cofen-br\Logs\';

/*Variavel que controla O caminho dos arquivo que contem os dados da tabela ([dbo].TempLogsDetalhes) */
DECLARE @CaminhoLogDetalhe NVARCHAR(MAX) = N'D:\Geral\cofen-br\detalhes\';


IF ( NOT EXISTS ( SELECT 1
                    FROM sys.tables AS T
                    WHERE T.name = 'TempLogsDetalhes' )
   )
    BEGIN
        CREATE TABLE [dbo].[TempLogsDetalhes]
            (
              [IdLogDetalhe] [UNIQUEIDENTIFIER] NOT NULL ,
              [IdLog] [UNIQUEIDENTIFIER] NOT NULL ,
              [Campo] [VARCHAR](100) COLLATE Latin1_General_CI_AI
                                     NOT NULL ,
              [ValorOriginal] [VARCHAR](MAX) COLLATE Latin1_General_CI_AI
                                             NULL ,
              [ValorAtual] [VARCHAR](MAX) COLLATE Latin1_General_CI_AI
                                          NULL
            )
        ON  [PRIMARY] TEXTIMAGE_ON [PRIMARY];

	
		
    END;


IF ( NOT EXISTS ( SELECT 1
                    FROM sys.tables AS T
                    WHERE T.name = 'TempLogs' )
   )
    BEGIN
		
        CREATE TABLE [dbo].[TempLogs]
            (
              [IdLog] [UNIQUEIDENTIFIER] NOT NULL ,
              [IdPessoa] [UNIQUEIDENTIFIER] NOT NULL ,
              [IdEntidade] [UNIQUEIDENTIFIER] NOT NULL ,
              [Entidade] [VARCHAR](100) COLLATE Latin1_General_CI_AI
                                        NOT NULL ,
              [Acao] [VARCHAR](10) COLLATE Latin1_General_CI_AI
                                   NOT NULL ,
              [Data] [DATETIME] NOT NULL ,
              [CodSistema] [UNIQUEIDENTIFIER] NOT NULL ,
              [IPAdress] [VARCHAR](30) COLLATE Latin1_General_CI_AI
                                       NULL
            )
        ON  [PRIMARY];



    END;

	IF	@trucaTabelaTemporaria =1
	BEGIN
			TRUNCATE TABLE dbo.TempLogsDetalhes;
			TRUNCATE TABLE dbo.TempLogs;
	END





-- importados (default = ##tabela, coloque o nome da tabela que geralmente via receber

-- os dados das suas importações)
DECLARE @tabelaLOG VARCHAR(100) = '[dbo].[TempLogs]';
DECLARE @tabelaLOGDetalhes VARCHAR(100) = '[dbo].[TempLogsDetalhes]';

  
SELECT @pathArquivoErro = CONCAT(@pathArquivoErro, 'error.csv');
SET NOCOUNT ON;


IF ( OBJECT_ID('TEMPDB..#tmp') IS NOT NULL )
    DROP TABLE #tmp;	


CREATE TABLE #tmp
    (
      out VARCHAR(1000) ,
      id INT IDENTITY(1, 1)
    );

-- Declaração de variáveis que serão usadas no decorrer do processo

DECLARE @arquivo VARCHAR(1000) ,
    @sql VARCHAR(1000) ,
    @cmd VARCHAR(1000) ,
    @min INT ,
    @max INT;


IF @InserirLog = 1
    BEGIN
		-- Formação do comando que será usado no DOS para listar os arquivos
        SELECT @cmd =  CONCAT('dir "', @CaminhoLog,'*',@ExtensaoArquivo,'" /b');

        PRINT @cmd;
--	'DIR "D:\Geral\Logs Recuperados\crea-ba\crea-ba.implanta.net.br_Log-031_Logs.csv" /B'

-- Insere os arquivos dentro da tabela para usar depois

        INSERT INTO #tmp
                ( out )
                EXEC sys.xp_cmdshell @cmd ;





        DELETE FROM #tmp
            WHERE out NOT LIKE '%'+@ExtensaoArquivo
                OR out IS NULL;



-- Altera a tabela para colocar coluna com auto incremento, para controle

	
	
-- Configurações para repetição

        SELECT @min = MIN(id) ,
                @max = MAX(id)
            FROM #tmp;

	


        WHILE( @min <= @max)
            BEGIN
-- passa por cada arquivo
                SELECT @arquivo = out
                    FROM #tmp
                    WHERE id = @min;

-- monta a instrução SQL para fazer o BULK INSERT

                DECLARE @SQL_BULK1 VARCHAR(MAX);
                SET @SQL_BULK1 = 'BULK INSERT ' + @tabelaLOG + ' FROM '''
                    + CONCAT(@CaminhoLog, @arquivo) + ''' WITH
        (
        MAXERRORS=0,
        FIELDTERMINATOR = '','',
        ROWTERMINATOR = ''\r'',
		ERRORFILE =''' + @pathArquivoErro + '''
		
        
        )';

				PRINT @SQL_BULK1;
                EXEC (@SQL_BULK1);
   

-- incrementa variável de controle para passar para o próximo arquivo

                SET @min = @min + 1;

            END;

-- drop da tabela temporária usada

        DROP TABLE #tmp;	
    END;





--IF @InserirLogDetalhe = 1
--    BEGIN
--        SELECT @cmd = 'dir "' + @CaminhoLogDetalhe + '*.csv" /b';

--        PRINT @cmd;
----	'DIR "D:\Geral\Logs Recuperados\crea-ba\crea-ba.implanta.net.br_Log-031_Logs.csv" /B'

---- Insere os arquivos dentro da tabela para usar depois

--        INSERT INTO #tmp
--                ( out )
--                EXEC sys.xp_cmdshell @cmd;

---- apaga registros que não tem arquivo .txt



--        DELETE FROM #tmp
--            WHERE out NOT LIKE '%.csv'
--                OR out IS NULL;



---- Altera a tabela para colocar coluna com auto incremento, para controle

	
	
---- Configurações para repetição

--        SELECT @min = MIN(id) ,
--                @max = MAX(id)
--            FROM #tmp;

	


--        WHILE @min <= @max
--            BEGIN

---- passa por cada arquivo


--                SELECT @arquivo = out
--                    FROM #tmp
--                    WHERE id = @min;

---- monta a instrução SQL para fazer o BULK INSERT

--                DECLARE @SQL_BULK2 VARCHAR(MAX);
--                SET @SQL_BULK2 = 'BULK INSERT ' + @tabelaLOGDetalhes
--                    + ' FROM ''' + CONCAT(@CaminhoLogDetalhe, @arquivo)
--                    + ''' WITH
--        (
--        MAXERRORS=0,
--        FIELDTERMINATOR = '','',
--        ROWTERMINATOR = ''\r'',
--		ERRORFILE =''' + @pathArquivoErro + '''
		
        
--        )';

--                EXEC (@SQL_BULK2);
   

---- incrementa variável de controle para passar para o próximo arquivo

--                SET @min = @min + 1;

--            END;

---- drop da tabela temporária usada

--        DROP TABLE #tmp;

--    END;




