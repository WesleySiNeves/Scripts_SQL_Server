IF (NOT EXISTS (
               SELECT 1
               FROM sys.tables AS T
                    JOIN
                    sys.schemas AS S ON T.schema_id = S.schema_id
               WHERE T.name = 'Servers'
                     AND S.name = 'Monitorar'
               )
   )
BEGIN

    CREATE TABLE Monitorar.Servers (
                                   IdServer   INT          IDENTITY(1, 1) PRIMARY KEY,
                                   ServerName VARCHAR(256) NOT NULL,
                                   IdPocation VARCHAR(30),
                                   );

END;




IF (NOT EXISTS (
               SELECT 1
               FROM sys.tables AS T
                    JOIN
                    sys.schemas AS S ON T.schema_id = S.schema_id
               WHERE T.name = 'BaseDados'
                     AND S.name = 'Monitorar'
               )
   )
BEGIN
    CREATE TABLE Monitorar.BaseDados (
                                     id          INT IDENTITY(1, 1) PRIMARY KEY,
                                     IdServer    INT NOT NULL,
                                     Database_id INT,
                                     Name        VARCHAR(256),
                                     CreateData  DATETIME2(7)
                                     );

END;

IF (NOT EXISTS (
               SELECT 1
               FROM sys.tables AS T
                    JOIN
                    sys.schemas AS S ON T.schema_id = S.schema_id
               WHERE T.name = 'Contador'
                     AND S.name = 'Monitorar'
               )
   )
BEGIN

    CREATE TABLE Monitorar.Contador (
                                    IdContador   INT IDENTITY PRIMARY KEY,
                                    NomeContador VARCHAR(50)
                                    );

    INSERT INTO Monitorar.Contador (
                                   NomeContador
                                   )
    SELECT 'BatchRequests';
    INSERT INTO Monitorar.Contador (
                                   NomeContador
                                   )
    SELECT 'User_Connection';
    INSERT INTO Monitorar.Contador (
                                   NomeContador
                                   )
    SELECT 'CPU';
    INSERT INTO Monitorar.Contador (
                                   NomeContador
                                   )
    SELECT 'Page Life Expectancy';
END;





IF (NOT EXISTS (
               SELECT 1
               FROM sys.tables AS T
                    JOIN
                    sys.schemas AS S ON T.schema_id = S.schema_id
               WHERE T.name = 'RegistrosContador'
                     AND S.name = 'Monitorar'
               )
   )
BEGIN
    --SELECT * FROM Contador
    CREATE TABLE Monitorar.RegistrosContador (
                                             [IdRegistroContador] [INT]      IDENTITY(1, 1) NOT NULL,
                                             [DataExecucao]       [DATETIME] NULL,
                                             [IdContador]         [INT]      NULL,
                                             [Valor]              [INT]      NULL,
                                             CONSTRAINT FK01_Registro_Contador
                                                 FOREIGN KEY (IdContador)
                                                 REFERENCES Monitorar.Contador (IdContador)
                                             ) ON [PRIMARY];
END;



GO
USE [Monitor];
GO


/****** Object:  StoredProcedure [dbo].[spCarregarContadoresSQL]    Script Date: 14/09/2018 12:17:31 ******/
SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

CREATE OR ALTER PROCEDURE Monitorar.[spCarregarContadoresSQL] (@DataReferencia DATETIME)
AS
BEGIN



    DECLARE @BatchRequests INT,
            @User_Connection INT,
            @CPU INT,
            @PLE INT;

    DECLARE @RequestsPerSecondSample1 BIGINT;
    DECLARE @RequestsPerSecondSample2 BIGINT;

    SELECT @RequestsPerSecondSample1 = dm_os_performance_counters.cntr_value
    FROM sys.dm_os_performance_counters
    WHERE dm_os_performance_counters.counter_name = 'Batch Requests/sec';
    WAITFOR DELAY '00:00:05';
    SELECT @RequestsPerSecondSample2 = dm_os_performance_counters.cntr_value
    FROM sys.dm_os_performance_counters
    WHERE dm_os_performance_counters.counter_name = 'Batch Requests/sec';
    SELECT @BatchRequests = (@RequestsPerSecondSample2 - @RequestsPerSecondSample1) / 5;

    SELECT @User_Connection = dm_os_performance_counters.cntr_value
    FROM sys.dm_os_performance_counters
    WHERE dm_os_performance_counters.counter_name = 'User Connections';

    SELECT TOP (1)
        @CPU = (y.SQLProcessUtilization + (100 - y.SystemIdle - y.SQLProcessUtilization))
    FROM (
         SELECT x.record.value('(./Record/@id)[1]', 'int') AS record_id,
                x.record.value('(./Record/SchedulerMonitorEvent/SystemHealth/SystemIdle)[1]', 'int') AS [SystemIdle],
                x.record.value('(./Record/SchedulerMonitorEvent/SystemHealth/ProcessUtilization)[1]', 'int') AS [SQLProcessUtilization],
                x.timestamp
         FROM (
              SELECT dm_os_ring_buffers.timestamp,
                     CONVERT(XML, dm_os_ring_buffers.record) AS [record]
              FROM sys.dm_os_ring_buffers
              WHERE dm_os_ring_buffers.ring_buffer_type = N'RING_BUFFER_SCHEDULER_MONITOR'
                    AND record LIKE '%<SystemHealth>%'
              ) AS x
         ) AS y;


    SELECT @PLE = dm_os_performance_counters.cntr_value
    FROM sys.dm_os_performance_counters
    WHERE dm_os_performance_counters.counter_name = 'Page life expectancy'
          AND dm_os_performance_counters.object_name LIKE '%Buffer Manager%';



    INSERT INTO Monitorar.RegistrosContador
    SELECT GETDATE(),
           1,
           @BatchRequests;

    INSERT INTO Monitorar.RegistrosContador
    SELECT GETDATE(),
           2,
           @User_Connection;

    INSERT INTO Monitorar.RegistrosContador
    SELECT GETDATE(),
           3,
           @CPU;

    INSERT INTO Monitorar.RegistrosContador
    SELECT GETDATE(),
           4,
           @PLE;



END;



GO
 

 CREATE OR ALTER FUNCTION Monitorar.GetContadoresMonitorados(@DataReferencia DATETIME = NULL)
  RETURNS TABLE RETURN 
  WITH Dados AS 
  (
    SELECT C.IdContador,
           C.NomeContador,
           RC.DataExecucao,
		   MaxData = MAX(RC.DataExecucao) OVER(PARTITION BY C.IdContador),
           RC.Valor
    FROM Monitorar.RegistrosContador AS RC
         JOIN
         Monitorar.Contador AS C ON RC.IdContador = C.IdContador
  )
  SELECT R.IdContador,
         R.NomeContador,
         R.DataExecucao,
         R.Valor FROM Dados R
		 WHERE R.DataExecucao = R.MaxData
    --ORDER BY
    --    R.IdContador,
    --    R.DataExecucao
		