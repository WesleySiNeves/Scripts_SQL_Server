
/* ==================================================================
--Data: 05/09/2018 
--Autor :Wesley Neves
--Observação: Esse Script Precisa de dois passos, 
1) executar esse script primeiro , ele gerará um outro script
2)rodar o script gerado para obter os dados a serem inseridos ou alterados
 
-- ==================================================================
*/

DECLARE @TblName VARCHAR(MAX)= 'Empenhos' ,
    @tblSchema VARCHAR(MAX)= 'Despesa' ,
    @Tipo CHAR(1)= 'I' ,
    @pkColunm VARCHAR(80);


SELECT  @pkColunm = COLUMN_NAME
FROM    INFORMATION_SCHEMA.KEY_COLUMN_USAGE
WHERE   OBJECTPROPERTY(OBJECT_ID(CONSTRAINT_SCHEMA + '.' + CONSTRAINT_NAME), 'IsPrimaryKey') = 1
        AND TABLE_NAME = @TblName
        AND TABLE_SCHEMA = @tblSchema;


IF OBJECT_ID('TEMPDB..#a') IS NOT NULL
    DROP TABLE #a;

CREATE TABLE #a
    (
      id INT IDENTITY(1, 1) ,
      ColType INT ,
      ColName VARCHAR(128) ,
      Computed BIT
    );

INSERT  #a
        ( ColType ,
          ColName ,
          Computed
        )
        SELECT  CASE WHEN DATA_TYPE LIKE '%char%' THEN 1
                     ELSE 0
                END ,
                COLUMN_NAME ,
                COLUMNPROPERTY(OBJECT_ID(TABLE_SCHEMA + '.' + TABLE_NAME), COLUMN_NAME, 'IsComputed')
        FROM    INFORMATION_SCHEMA.COLUMNS
        WHERE   TABLE_NAME = @TblName
                AND TABLE_SCHEMA = @tblSchema
        ORDER BY ORDINAL_POSITION;
	
IF NOT EXISTS ( SELECT  *
                FROM    #a )
    BEGIN
        RAISERROR('No columns found for table %s', 16,-1, @TblName);
        RETURN;
    END;

DECLARE @id INT ,
    @maxid INT ,
    @cmd1 VARCHAR(MAX) ,
    @cmd2 VARCHAR(MAX) ,
    @cmd3 VARCHAR(MAX) ,
    @isComputed BIT;

SELECT  @id = 0 ,
        @maxid = MAX(id)
FROM    #a;

SELECT  @cmd1 = 'SELECT '' INSERT INTO ' + @tblSchema + '.' + @TblName + ' ( ';
SELECT  @cmd2 = ' + '' select '' + ';
SELECT  @cmd3 = 'SELECT '' UPDATE ' + @tblSchema + '.' + @TblName + ' SET ';

WHILE @id < @maxid
    BEGIN
        SELECT  @id = MIN(id)
        FROM    #a
        WHERE   id > @id;

        SELECT  @isComputed = Computed
        FROM    #a
        WHERE   id = @id;

        SELECT  @cmd1 = @cmd1 + CASE WHEN @isComputed = 0 THEN ColName + ','
                                     ELSE ''
                                END
        FROM    #a
        WHERE   id = @id;

        SELECT  @cmd2 = @cmd2 + CASE WHEN @isComputed = 0
                                     THEN ' case when ' + ColName + ' is null ' + ' then ''null'' ' + ' else ' + CASE WHEN ColType = 1
                                                                                                                      THEN +'CHAR(39) + REPLACE('+ColName+', CHAR(39), CHAR(39)+CHAR(39))' 
                                                                                                                           + '+ char(39)'
                                                                                                                      ELSE '+ CHAR(39) + convert(varchar(max),'
                                                                                                                           + 'REPLACE( '+ColName+', CHAR(39), CHAR(39)+CHAR(39))'  + ') + char(39)'
                                                                                                                 END + ' end + '','' + '
                                     ELSE ''
                                END
        FROM    #a
        WHERE   id = @id;

        SELECT  @cmd3 = @cmd3 + CASE WHEN @isComputed = 0
                                     THEN CASE WHEN @id > 1 THEN ''
                                               ELSE ''
                                          END + ColName + CASE WHEN @id > 1 THEN ''
                                                               ELSE ''
                                                          END + ' = ' + CHAR(39) + CHAR(43) + ' case when ' + ColName + ' is null ' + ' then ''null'' '
                                          + ' else ' + CASE WHEN ColType = 1 THEN +'CHAR(39) + REPLACE('+ColName+', CHAR(39), CHAR(39)+CHAR(39))'+  + '+ char(39)'
                                                            ELSE '+ CHAR(39) + convert(varchar(max),' + REPLACE( ColName, CHAR(39), CHAR(39)+CHAR(39)) + ') + char(39)'
                                                       END + CASE WHEN @id < @maxid THEN ' end + '', '
                                                                  ELSE ' end + '' WHERE ' + @pkColunm + ' = '' + CHAR(39) +  convert(varchar(max),  '
                                                                       + @pkColunm + ') + CHAR(39)  '
                                                             END
                                     ELSE ''
                                END
        FROM    #a
        WHERE   id = @id;

    END;



SELECT  @cmd1 = LEFT(@cmd1, LEN(@cmd1) - 1) + ' ) '' ';
SELECT  @cmd2 = LEFT(@cmd2, LEN(@cmd2) - 8) + ' FROM ' + @tblSchema + '.' + @TblName;
SELECT  @cmd3 = @cmd3 + ' FROM ' + @tblSchema + '.' + @TblName;


IF @Tipo = 'I'
    SELECT  @cmd1 + @cmd2;
ELSE
    SELECT  @cmd3;

