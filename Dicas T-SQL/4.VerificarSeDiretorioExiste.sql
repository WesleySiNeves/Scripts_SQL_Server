DECLARE @output INT;
EXEC @output = XP_CMDSHELL 'DIR "D:\Geral\Logs Recuperados\crea-ba\crea-ba.implanta.net.br_Log-031_Logs.csv" /B',
                           NO_OUTPUT;
IF @output = 1
    PRINT 'File Donot exists';
ELSE
    PRINT 'File exists';