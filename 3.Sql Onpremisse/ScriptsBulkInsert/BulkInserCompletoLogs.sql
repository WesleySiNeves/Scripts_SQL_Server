


GO
	
--TRUNCATE TABLE dbo.TempLogsDetalhes


/*##################################Variaveis que controla a tabela de logs ####################################*/

/*Variavel que controla a cria��o da tabela auxiliar ([Log].[TempLogs]) */
DECLARE @CriarTabelaLog BIT = 0;
DECLARE @CriarTabelaDetalhes BIT = 1;

/*Variavel que controla a INSER��O DE DADOS na tabela auxiliar ([Log].[TempLogs]) */
DECLARE @InserirLog BIT = 0;

/*Variavel que controla a TRUNCAGEM DE DADOS na tabela auxiliar ([Log].[TempLogs]) QUANDO ERRO */
DECLARE @LimpartabelaQuandoErro BIT = 0;



DECLARE @InserirLogDetalhe BIT = 1;




/*Variavel que controla O caminho do arquivo que sera criado quando dr um erro */
DECLARE @pathArquivoErro VARCHAR(MAX)  = N'D:\Geral\LOGSCREACE\Logs Recuperados da Maquina do Paulo\crea-ce\Error\'; 

/*Variavel que controla O caminho dos arquivo que contem os dados da tabela ([dbo].[TempLogs]) */
DECLARE @CaminhoLog NVARCHAR(MAX) = N'D:\Geral\LOGSCREACE\Logs Recuperados da Maquina do Paulo\crea-ce\logs\';

/*Variavel que controla O caminho dos arquivo que contem os dados da tabela ([dbo].TempLogsDetalhes) */
DECLARE @CaminhoLogDetalhe NVARCHAR(MAX) = N'D:\Geral\LOGSCREACE\Logs Recuperados da Maquina do Paulo\crea-ce\detalhes\Validados\';

IF @CriarTabelaLog = 1
   BEGIN
		
		 
         IF NOT EXISTS ( SELECT *
                         FROM   sys.tables AS T
                         WHERE  T.name = 'TempLogs2'
                                AND T.type = 'U' )
            BEGIN
                  CREATE TABLE [dbo].[TempLogs2]
                         (
                           [IdLog] [UNIQUEIDENTIFIER] NOT NULL ,
                           [IdPessoa] [UNIQUEIDENTIFIER] NOT NULL ,
                           [IdEntidade] [UNIQUEIDENTIFIER] NOT NULL ,
                           [Entidade] [VARCHAR](100)
                            COLLATE Latin1_General_CI_AI
                            NOT NULL ,
                           [Acao] [VARCHAR](10) COLLATE Latin1_General_CI_AI
                                                NOT NULL ,
                           [Data] [DATETIME] NOT NULL ,
                           [CodSistema] [UNIQUEIDENTIFIER] NOT NULL ,
                           [IPAdress] [VARCHAR](30)
                            COLLATE Latin1_General_CI_AI
                            NULL
                         ); 
            END;
   END;




IF @CriarTabelaDetalhes = 1
   BEGIN
         IF NOT EXISTS ( SELECT *
                         FROM   sys.tables AS T
                         WHERE  T.name = 'TempLogsDetalhes2'
                                AND T.type = 'U' )
            BEGIN
										
                  CREATE TABLE [dbo].[TempLogsDetalhes2]
                         (
                           [IdLogDetalhe] [UNIQUEIDENTIFIER] NOT NULL ,
                           [IdLog] [UNIQUEIDENTIFIER] NOT NULL ,
                           [Campo] [VARCHAR](100) COLLATE Latin1_General_CI_AI
                                                  NOT NULL ,
                           [ValorOriginal] [VARCHAR](MAX)
                            COLLATE Latin1_General_CI_AI
                            NULL ,
                           [ValorAtual] [VARCHAR](MAX)
                            COLLATE Latin1_General_CI_AI
                            NOT NULL
                         ); 

            END;

       

		
   END;

IF @LimpartabelaQuandoErro = 1
   BEGIN
         IF @InserirLog = 1
            BEGIN
                  TRUNCATE TABLE dbo.TempLogs2;
            END;
     
         IF ( @InserirLogDetalhe = 1 )
            BEGIN
                  TRUNCATE TABLE dbo.[TempLogsDetalhes2];	
            END;
   END;



-- recebe o caminho que vai conter os


  


-- importados (default = ##tabela, coloque o nome da tabela que geralmente via receber

-- os dados das suas importa��es)
DECLARE @tabelaLOG VARCHAR(100) = '[dbo].[TempLogs2]';
DECLARE @tabelaLOGDetalhes VARCHAR(100) = '[dbo].[TempLogsDetalhes2]';

  
SELECT  @pathArquivoErro = CONCAT(@pathArquivoErro, 'error.csv');
SET NOCOUNT ON;


IF ( OBJECT_ID('TEMPDB..#tmp') IS NOT NULL )
   DROP TABLE #tmp;	


CREATE TABLE #tmp
       (
         out VARCHAR(1000) ,
         id INT IDENTITY(1, 1)
       );

-- Declara��o de vari�veis que ser�o usadas no decorrer do processo

DECLARE @arquivo VARCHAR(1000) ,
        @sql VARCHAR(1000) ,
        @cmd VARCHAR(1000) ,
        @min INT ,
        @max INT;


IF @InserirLog = 1
   BEGIN
			-- Forma��o do comando que ser� usado no DOS para listar os arquivos
  
         SELECT @cmd = 'dir "' + @CaminhoLog + '*.csv" /b';

         PRINT @cmd;
--	'DIR "D:\Geral\Logs Recuperados\crea-ba\crea-ba.implanta.net.br_Log-031_Logs.csv" /B'

-- Insere os arquivos dentro da tabela para usar depois

         INSERT INTO #tmp
                ( out )
                EXEC sys.xp_cmdshell @cmd;

-- apaga registros que n�o tem arquivo .txt



         DELETE FROM #tmp
         WHERE  out NOT LIKE '%.csv'
                OR out IS NULL;



-- Altera a tabela para colocar coluna com auto incremento, para controle

	
	
-- Configura��es para repeti��o

         SELECT @min = MIN(id) ,
                @max = MAX(id)
         FROM   #tmp;

	


         WHILE @min <= @max
               BEGIN

-- passa por cada arquivo


                     SELECT @arquivo = out
                     FROM   #tmp
                     WHERE  id = @min;

-- monta a instru��o SQL para fazer o BULK INSERT

                     DECLARE @SQL_BULK1 VARCHAR(MAX);
                     SET @SQL_BULK1 = 'BULK INSERT ' + @tabelaLOG + ' FROM '''
                         + CONCAT(@CaminhoLog, @arquivo) + ''' WITH
        (
        MAXERRORS=0,
        FIELDTERMINATOR = '','',
        ROWTERMINATOR = ''\r'',
		ERRORFILE =''' + @pathArquivoErro + '''
		
        
        )';

                     EXEC (@SQL_BULK1);
   

-- incrementa vari�vel de controle para passar para o pr�ximo arquivo

                     SET @min = @min + 1;

               END;

-- drop da tabela tempor�ria usada

         DROP TABLE #tmp;	
   END;





IF @InserirLogDetalhe = 1
   BEGIN
         SELECT @cmd = 'dir "' + @CaminhoLogDetalhe + '*.csv" /b';

         PRINT @cmd;
--	'DIR "D:\Geral\Logs Recuperados\crea-ba\crea-ba.implanta.net.br_Log-031_Logs.csv" /B'

-- Insere os arquivos dentro da tabela para usar depois

         INSERT INTO #tmp
                ( out )
                EXEC sys.xp_cmdshell @cmd;

-- apaga registros que n�o tem arquivo .txt



         DELETE FROM #tmp
         WHERE  out NOT LIKE '%.csv'
                OR out IS NULL;



-- Altera a tabela para colocar coluna com auto incremento, para controle

	
	
-- Configura��es para repeti��o

         SELECT @min = MIN(id) ,
                @max = MAX(id)
         FROM   #tmp;

	


         WHILE @min <= @max
               BEGIN

-- passa por cada arquivo


                     SELECT @arquivo = out
                     FROM   #tmp
                     WHERE  id = @min;

-- monta a instru��o SQL para fazer o BULK INSERT

                     DECLARE @SQL_BULK2 VARCHAR(MAX);
                     SET @SQL_BULK2 = 'BULK INSERT ' + @tabelaLOGDetalhes
                         + ' FROM ''' + CONCAT(@CaminhoLogDetalhe, @arquivo)
                         + ''' WITH
        (
        MAXERRORS=0,
        FIELDTERMINATOR = '';'',
        ROWTERMINATOR = ''\r'',
		ERRORFILE =''' + @pathArquivoErro + '''
		
        
        )';

                     EXEC (@SQL_BULK2);
   

-- incrementa vari�vel de controle para passar para o pr�ximo arquivo

                     SET @min = @min + 1;

               END;

-- drop da tabela tempor�ria usada

         DROP TABLE #tmp;

   END;




