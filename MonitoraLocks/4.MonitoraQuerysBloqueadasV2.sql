
-- Funciona no SQL 2000 e versões superiores
SELECT  A.spid ,
        SUBSTRING(A.nt_username, 1, 20) AS Nt_UserName ,
        A.blocked ,
        CASE WHEN A.blocked = 0
                  AND ( ISNULL(C.Qt_Block_By, 0) > 0 ) THEN 'Blocker'
             WHEN A.blocked = 0
                  AND ( ISNULL(C.Qt_Block_By, 0) <= 0 ) THEN 'None'
             WHEN A.blocked = A.spid THEN 'Itself'
             ELSE 'Blk by other'
        END Type_block ,
        A.waittime / 1000 [WaitTime(s)] ,
        D.name DataBaseName ,
        SUBSTRING(A.program_name, 1, 20) AS Programa ,
        Qt_Blocked = ISNULL(B.Qt_Blocked, 0) ,
        Qt_Block_By = ISNULL(C.Qt_Block_By, 0)
FROM    sys.sysprocesses A
        JOIN sys.sysdatabases D ON A.dbid = D.dbid
        LEFT JOIN ( SELECT  spid ,
                            COUNT(*) Qt_Blocked
                    FROM    sys.sysprocesses
                    WHERE   ( blocked <> 0 )
                            AND ( blocked <> spid )
                    GROUP BY spid
                  ) B ON A.spid = B.spid
        LEFT JOIN ( SELECT  blocked ,
                            COUNT(*) Qt_Block_By
                    FROM    sys.sysprocesses
                    GROUP BY blocked
                  ) C ON A.spid = C.blocked
                         AND A.blocked <> A.spid
WHERE   A.spid >= 50      --  Conexões de usuário
ORDER BY CASE WHEN A.blocked = 0
                   AND ( ISNULL(C.Qt_Block_By, 0) > 0 ) THEN 'Blocker'
              WHEN A.blocked = 0
                   AND ( ISNULL(C.Qt_Block_By, 0) <= 0 ) THEN 'None'
              WHEN A.blocked = A.spid THEN 'Itself'
              ELSE 'Blk by other'
         END ,
        Qt_Blocked ,
        Qt_Block_By ,
        A.waittime DESC;
						 

--Aqui vc consegue recuperar a query gerada pela spid

--DBCC INPUTBUFFER(@NumeroSpid)