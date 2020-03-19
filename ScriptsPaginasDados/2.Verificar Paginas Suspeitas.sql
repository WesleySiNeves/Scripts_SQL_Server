/*Quando da algum erro de paginas suspeitas o Sql quarda essas informações nessa tabela*/
SELECT database_id ,
       file_id ,
       page_id ,
       event_type ,
       error_count ,
       last_update_date FROM msdb.dbo.suspect_pages AS SP
