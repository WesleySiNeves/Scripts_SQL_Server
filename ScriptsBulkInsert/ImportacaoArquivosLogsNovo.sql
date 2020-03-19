
/*
Comando Basico
--bcp [Implanta_CREASE].[Log].[Logs] in d:\teste\crea-se.implanta.net.br_log-100_Logs.dat -S (local) -N -T -CRAW -r0x0D
--bcp [Implanta_CREASE].[Log].[LogsDetalhes] in d:\teste\crea-se.implanta.net.br_log-100_Detalhes.dat -S (local) -N -T -CRAW -r0x0D
*/

DECLARE @VerQuantidadeResgistrosTabelaLogs BIT = 1;
DECLARE @ApenasGerarComado BIT = 1;
DECLARE @InsereLogs BIT = 1;
DECLARE @InsereDetalhes BIT = 0;

DECLARE @LocalArquivoLog VARCHAR(MAX) = 'D:\Geral\LOGSCREACE\logs\crea-ce.implanta.net.br_log-030_Logs';
DECLARE @LocalArquivoLogDetalhes VARCHAR(MAX) = 'D:\Geral\cofen-br\detalhes\cofen-br.implanta.net.br_log-03_Detalhes';


DECLARE @NomeTabelaLog VARCHAR(MAX)  = '[dbo].[TempLogs]';
DECLARE @NomeTabelaDetalhes VARCHAR(MAX)  = '[dbo].[TempLogsDetalhes]';

DECLARE @QuantidadeRegistrosLogsAtual BIGINT= ( SELECT COUNT(*)
                                                    FROM dbo.TempLogs AS TL
                                              );


/*Comandos Estáticos*/
DECLARE @NomeBase VARCHAR(200)  = CONCAT('[', DB_NAME(), ']');
DECLARE @Extensao CHAR(10) = '.dat';
DECLARE @Espaco CHAR(10) = '';
DECLARE @Comando1 NVARCHAR(MAX) = N'-S (local) -N -T -CRAW -r0x0D';
DECLARE @cmdComandLogs VARCHAR(1000) = CONCAT('bcp ', @NomeBase, '.',
                                              @NomeTabelaLog, ' in ',
                                              @LocalArquivoLog, @Extensao,
                                              @Comando1);
DECLARE @cmdComandLogsDetalhes VARCHAR(1000) = CONCAT('bcp ', @NomeBase, '.',
                                                      @NomeTabelaDetalhes,
                                                      ' in ',
                                                      @LocalArquivoLogDetalhes,
                                                      @Extensao, @Comando1);


 
IF @VerQuantidadeResgistrosTabelaLogs = 1
    BEGIN
		
        SELECT COUNT(*)
            FROM Log.Logs AS [Quantidade Logs];
        SELECT COUNT(*)
            FROM Log.LogsDetalhes AS [Quantidades Logs Detalhes];
    END;


IF @ApenasGerarComado = 1
    BEGIN
        SELECT @cmdComandLogs ,
                @cmdComandLogsDetalhes;		
    END;

IF @InsereLogs = 1
    BEGIN
    
        EXEC sys.xp_cmdshell @cmdComandLogs;

    END;
 
IF @InsereDetalhes = 1
    BEGIN
    
        EXEC sys.xp_cmdshell @cmdComandLogsDetalhes;

    END;


SELECT 'Quantidade de registros na tabela logs Inseridos';


SELECT ( SELECT COUNT(*)
            FROM dbo.TempLogs AS TL
       ) - @QuantidadeRegistrosLogsAtual;


