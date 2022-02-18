CREATE DATABASE [OnlineStore]
ON PRIMARY(
              NAME = N'OnlineStore_Primary',
              FILENAME = N'D:\SQLData\OnlineStore_Primary.mdf',
              SIZE = 100MB
          ),
   FILEGROUP [Archive](
                          NAME = N'OnlineStore_Archive',
                          FILENAME = N'E:\SQLData\OnlineStore_Archive.ndf',
                          SIZE = 1TB
                      ),
   FILEGROUP [CompletedOrders](
                                  NAME = N'OnlineStore_CompletedOrders',
                                  FILENAME = N'F:\SQLData\OnlineStore_
CompletedOrders.ndf',
                                  SIZE = 200GB
                              ),
   FILEGROUP [Data](
                       NAME = N'OnlineStore_Data',
                       FILENAME = N'G:\SQLData\OnlineStore_Data.ndf',
                       SIZE = 10GB
                   ),
   FILEGROUP [Orders](
                         NAME = N'OnlineStore_Orders',
                         FILENAME = N'H:\SQLData\OnlineStore_Orders.ndf',
                         SIZE = 20GB
                     )
LOG ON(
          NAME = N'OnlineStore_Log',
          FILENAME = N'L:\SQLLog\OnlineStore_Log.ldf',
          SIZE = 1GB
      );
GO

ALTER DATABASE [OnlineStore] MODIFY FILEGROUP [Data] DEFAULT;

/* ==================================================================
--Data: 16/01/2020 
--Autor :Wesley Neves
--Observação: Suponha que você fez os seguintes backups:

Imagem Backup completo

Imagem Backup diferencial

Imagem Backup de log

Suponha que todas as unidades D, E, F, G e H falharam. Somente a unidade L que contém o log de transações sobreviveu. Você precisa recuperar o banco de dados o mais rápido possível, para que os usuários possam fazer pedidos.

Use as etapas a seguir para executar uma restauração fragmentada do banco de dados [OnlineStore]:
 
-- ==================================================================
*/

-- Back up orphaned transaction log to minimize data loss
USE [master];
GO

BACKUP LOG [OnlineStore]
TO  DISK = 'B:\SQLBackup\OnlineStore_ORPHANEDLOG.bak'
WITH NO_TRUNCATE;

-- Start partial-restore sequence
USE [master];
GO

RESTORE DATABASE [OnlineStore] FILEGROUP = 'PRIMARY'
FROM DISK = 'B:\SQLBackup\OnlineStore_FULL.bak'
WITH NORECOVERY,
     PARTIAL;
GO

RESTORE DATABASE [OnlineStore] FILEGROUP = 'PRIMARY'
FROM DISK = 'B:\SQLBackup\OnlineStore_DIFF.bak'
WITH NORECOVERY;
GO

RESTORE DATABASE [OnlineStore] FILEGROUP = 'PRIMARY'
FROM DISK = 'B:\SQLBackup\OnlineStore_LOG.bak'
WITH NORECOVERY;
GO

RESTORE DATABASE [OnlineStore] FILEGROUP = 'PRIMARY'
FROM DISK = 'B:\SQLBackup\OnlineStore_ORPHANEDLOG.bak'
WITH NORECOVERY;
GO

RESTORE DATABASE [OnlineStore] WITH RECOVERY;

/* ==================================================================
--Data: 16/01/2020 
--Autor :Wesley Neves
--Observação: Restaure e recupere o grupo de arquivos [Orders] e coloque-o online, conforme mostrado na
 
-- ==================================================================
*/
USE [master];
GO

-- Restore Orders filegroup and bring it online
RESTORE DATABASE [OnlineStore] FILEGROUP = 'Orders'
FROM DISK = 'B:\SQLBackup\OnlineStore_FULL.bak'
WITH NORECOVERY;
GO

RESTORE DATABASE [OnlineStore] FILEGROUP = 'Orders'
FROM DISK = 'B:\SQLBackup\OnlineStore_DIFF.bak'
WITH NORECOVERY;
GO

RESTORE DATABASE [OnlineStore] FILEGROUP = 'Orders'
FROM DISK = 'B:\SQLBackup\OnlineStore_LOG.bak'
WITH NORECOVERY;
GO

RESTORE DATABASE [OnlineStore] FILEGROUP = 'Orders'
FROM DISK = 'B:\SQLBackup\OnlineStore_ORPHANEDLOG.bak'
WITH NORECOVERY;
GO

RESTORE DATABASE [OnlineStore] WITH RECOVERY;

/* ==================================================================
--Data: 16/01/2020 
--Autor :Wesley Neves
--Observação: 
 
-- ==================================================================
*/
USE [OnlineStore];
GO

-- Check to see if [Orders] filegroup is online
SELECT file_id, name, type_desc, state_desc FROM sys.database_files;
GO

-- Ensure users can query the critical tables
SELECT * FROM [Orders];

/* ==================================================================
--Data: 16/01/2020 
--Autor :Wesley Neves
--Observação: Restore and recover the [Data] and [CompletedOrders] filegroups, as shown
 
-- ==================================================================
*/
USE [master];
GO

RESTORE DATABASE [OnlineStore] FILEGROUP = 'Data',
                               FILEGROUP = 'CompletedOrders'
FROM DISK = 'B:\SQLBackup\
OnlineStore_FULL.bak'
WITH NORECOVERY;
GO

RESTORE DATABASE [OnlineStore] FILEGROUP = 'Data',
                               FILEGROUP = 'CompletedOrders'
FROM DISK = 'B:\SQLBackup\
OnlineStore_DIFF.bak'
WITH NORECOVERY;
GO

RESTORE DATABASE [OnlineStore] FILEGROUP = 'Data',
                               FILEGROUP = 'CompletedOrders'
FROM DISK = 'B:\SQLBackup\
OnlineStore_LOG.bak'
WITH NORECOVERY;
GO

RESTORE DATABASE [OnlineStore] FILEGROUP = 'Data',
                               FILEGROUP = 'CompletedOrders'
FROM DISK = 'B:\SQLBackup\
OnlineStore_ORPHANEDLOG.bak'
WITH NORECOVERY;
GO

RESTORE DATABASE [OnlineStore] WITH RECOVERY;
GO

/* ==================================================================
--Data: 16/01/2020 
--Autor :Wesley Neves
--Observação: Restore and recover the final 1TB [Archive] filegroup, as shown
 
-- ==================================================================
*/

USE [master];
GO

RESTORE DATABASE [OnlineStore] FILEGROUP = 'Archive'
FROM DISK = 'B:\SQLBackup\OnlineStore_FULL.bak'
WITH NORECOVERY;
GO

RESTORE DATABASE [OnlineStore] FILEGROUP = 'Archive'
FROM DISK = 'B:\SQLBackup\OnlineStore_DIFF.bak'
WITH NORECOVERY;
GO

RESTORE DATABASE [OnlineStore] FILEGROUP = 'Archive'
FROM DISK = 'B:\SQLBackup\OnlineStore_LOG.bak'
WITH NORECOVERY;
GO

RESTORE DATABASE [OnlineStore] FILEGROUP = 'Archive'
FROM DISK = 'B:\SQLBackup\OnlineStore_ORPHANEDLOG.bak'
WITH NORECOVERY;
GO

RESTORE DATABASE [OnlineStore] WITH RECOVERY;
GO

/* ==================================================================
--Data: 16/01/2020 
--Autor :Wesley Neves
--Observação: Como alternativa, suponha que apenas a unidade E que contém os [CompletedOrders] falhou. O restante do banco de dados [OnlineSales] é bom e acessível.

1. Nesse caso, recupere e restaure o grupo de arquivos [CompletedOrders] enquanto o restante do banco de dados estiver disponível, 
conforme mostrado na Listagem 2-28 . Isso é chamado de disponibilidade parcial .
 
-- ==================================================================
*/


USE [master];
GO
-- Take the [CompletedOrders] file offline
ALTER DATABASE MODIFY  = OnlineStore_CompletedOrders OFFLINE);
GO
-- Back up orphaned transaction log to minimize data loss
BACKUP LOG [OnlineStore] TO DISK = 'B:\SQLBackup\OnlineStore_ORPHANEDLOG.bak' WITH
NO_TRUNCATE;
GO
--
RESTORE DATABASE [OnlineStore]
FILEGROUP = 'CompletedOrders' FROM DISK = 'B:\SQLBackup\OnlineStore_FULL.bak' WITH
NORECOVERY;
GO
RESTORE DATABASE [OnlineStore]
FILEGROUP = 'CompletedOrders' FROM DISK = 'B:\SQLBackup\OnlineStore_DIFF.bak' WITH
NORECOVERY;
GO
RESTORE DATABASE [OnlineStore]
FILEGROUP = 'CompletedOrders' FROM DISK = 'B:\SQLBackup\OnlineStore_LOG.bak' WITH
NORECOVERY;
GO
RESTORE DATABASE [OnlineStore]
FILEGROUP = 'CompletedOrders' FROM DISK = 'B:\SQLBackup\OnlineStore_ORPHANEDLOG.
bak' WITH NORECOVERY;
GO
RESTORE DATABASE [OnlineStore] WITH RECOVERY
GO