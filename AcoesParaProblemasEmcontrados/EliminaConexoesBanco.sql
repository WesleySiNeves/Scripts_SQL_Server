
DECLARE @Metodo TINYINT = 1;
DECLARE @Database VARCHAR(50) = '15-implanta';


IF @Metodo = 1
    BEGIN
    
        DECLARE @sql AS VARCHAR(20) ,
            @spid AS INT;
        SELECT  @spid = MIN(spid)
        FROM    master..sysprocesses
        WHERE   dbid = DB_ID(@Database)
                AND spid != @@spid;    

        WHILE ( @spid IS NOT NULL )
            BEGIN
                PRINT 'Killing process ' + CAST(@spid AS VARCHAR) + ' ...';
                SET @sql = 'kill ' + CAST(@spid AS VARCHAR);
                EXEC (@sql);

                SELECT  @spid = MIN(spid)
                FROM    master..sysprocesses
                WHERE   dbid = DB_ID(@Database)
                        AND spid != @@spid;
            END; 

        PRINT 'Process completed...';

    END;

IF @Metodo = 2
    BEGIN
        ALTER DATABASE Implanta  SET OFFLINE WITH ROLLBACK IMMEDIATE;


        ALTER DATABASE Implanta
        SET ONLINE;

    END;
