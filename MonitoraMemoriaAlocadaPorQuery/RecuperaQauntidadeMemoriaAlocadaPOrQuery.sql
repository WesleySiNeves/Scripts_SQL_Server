;WITH Dados
   AS (SELECT DEQMG.session_id,
              DEQMG.granted_memory_kb,
              [granted_memory MB] = (DEQMG.granted_memory_kb / 1024),
              DEQMG.used_memory_kb,
              [used_memory MB] = (DEQMG.used_memory_kb / 1024),
              DEQMG.ideal_memory_kb,
              [ideal_memory_ MB] = (DEQMG.ideal_memory_kb / 1024),
              DEQMG.query_cost,
              DEQMG.timeout_sec,
              query = DEQMG.sql_handle
       FROM sys.dm_exec_query_memory_grants AS DEQMG
       WHERE DEQMG.session_id <> @@SPID
      )
SELECT R.session_id,
       R.granted_memory_kb,
       R.[granted_memory MB],
       R.used_memory_kb,
       R.[used_memory MB],
       R.ideal_memory_kb,
       R.[ideal_memory_ MB],
       R.query_cost,
       R.timeout_sec,
       DEST.text
FROM Dados R
     OUTER APPLY sys.dm_exec_sql_text(R.query) AS DEST;


