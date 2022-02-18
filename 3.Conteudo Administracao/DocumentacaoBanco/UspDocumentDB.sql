CREATE PROCEDURE uspdocumentDB
	@SchemaName VARCHAR(100),
    @tableName         VARCHAR(128),
    @columnName        VARCHAR(128) = NULL,
    @objectDescription VARCHAR(250)
AS
BEGIN
    IF (@columnName IS NULL)
    BEGIN
        IF NOT EXISTS (
                      SELECT *
                      FROM fn_listextendedproperty(NULL, 'user', 'Contabilidade', 'table', DEFAULT, NULL, NULL)
                      WHERE objname = 'Contabilidade.HistoricosPadroes'
                      )
        BEGIN
            EXECUTE sp_addextendedproperty 'Implanta_Description',
                                           @objectDescription,
                                           'user',
                                           dbo,
                                           'table',
                                           @tableName,
                                           DEFAULT,
                                           NULL;
        END;
        ELSE
        BEGIN
            EXECUTE sp_updateextendedproperty 'MY_DESCRIPTION',
                                              @objectDescription,
                                              'user',
                                              dbo,
                                              'table',
                                              @tableName,
                                              DEFAULT,
                                              NULL;
        END;
    END;
    ELSE
    BEGIN
        IF NOT EXISTS (
                      SELECT 1
                      FROM sys.extended_properties AS ep
                           INNER JOIN
                           sys.tables AS t ON ep.major_id = t.object_id
                           INNER JOIN
                           sys.columns AS c ON ep.major_id = c.object_id
                                               AND ep.minor_id = c.column_id
                      WHERE class = 1
                            AND t.name = @tableName
                            AND c.name = @columnName
                      )
        BEGIN
            EXECUTE sp_addextendedproperty 'MY_DESCRIPTION',
                                           @objectDescription,
                                           'user',
                                           dbo,
                                           'table',
                                           @tableName,
                                           'column',
                                           @columnName;
        --EXECUTE   sp_addextendedproperty @name=N'CXC_DESCRIPTION', @value=N@temp3, @level0type=N'user', @level0name=N'dbo', @level1type=N'table', @level1name=N@temp1, @level2type=N'column', @level2name=N@temp2
        END;
        ELSE
        BEGIN
            EXECUTE sp_updateextendedproperty 'MY_DESCRIPTION',
                                              @objectDescription,
                                              'user',
                                              dbo,
                                              'table',
                                              @tableName,
                                              'column',
                                              @columnName;
        END;
    END;
END;
GO