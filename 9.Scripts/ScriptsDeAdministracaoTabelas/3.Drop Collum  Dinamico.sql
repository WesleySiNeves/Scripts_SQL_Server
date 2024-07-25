create or alter procedure dbo.RemoverColuna 
(@SchemaName varchar(100),
@TableName varchar(100), @ColumnName varchar(140))
as begin 

---- Definir variáveis para o schema, tabela e campo
--DECLARE @SchemaName NVARCHAR(128) = 'SeuSchema'
--DECLARE @TableName NVARCHAR(128) = 'SuaTabela'
--DECLARE @ColumnName NVARCHAR(128) = 'SeuCampo'

-- Variáveis auxiliares
DECLARE @ConstraintName NVARCHAR(128)
DECLARE @SQL NVARCHAR(MAX)


-- Remover FK, se existir
SELECT @ConstraintName = fk.name
FROM sys.foreign_keys AS fk
INNER JOIN sys.foreign_key_columns AS fkc ON fk.object_id = fkc.constraint_object_id
INNER JOIN sys.columns AS c ON c.object_id = fkc.parent_object_id AND c.column_id = fkc.parent_column_id
INNER JOIN sys.tables AS t ON t.object_id = fk.parent_object_id
INNER JOIN sys.schemas AS s ON t.schema_id = s.schema_id
WHERE s.name = @SchemaName AND t.name = @TableName AND c.name = @ColumnName

IF @ConstraintName IS NOT NULL
BEGIN
    SET @SQL = 'ALTER TABLE [' + @SchemaName + '].[' + @TableName + '] DROP CONSTRAINT [' + @ConstraintName + ']'
    EXEC sp_executesql @SQL
    PRINT 'Foreign Key constraint ' + @ConstraintName + ' removida.'
END

-- Remover Default Constraint, se existir
SELECT @ConstraintName = dc.name
FROM sys.default_constraints AS dc
INNER JOIN sys.columns AS c ON c.object_id = dc.parent_object_id AND c.column_id = dc.parent_column_id
INNER JOIN sys.tables AS t ON t.object_id = dc.parent_object_id
INNER JOIN sys.schemas AS s ON t.schema_id = s.schema_id
WHERE s.name = @SchemaName AND t.name = @TableName AND c.name = @ColumnName

IF @ConstraintName IS NOT NULL
BEGIN
    SET @SQL = 'ALTER TABLE [' + @SchemaName + '].[' + @TableName + '] DROP CONSTRAINT [' + @ConstraintName + ']'
    EXEC sp_executesql @SQL
    PRINT 'Default constraint ' + @ConstraintName + ' removida.'
END


if(exists(select * from 
sys.tables AS t 
INNER JOIN sys.schemas AS s ON t.schema_id = s.schema_id
INNER JOIN sys.columns AS c ON c.object_id = t.object_id
where s.name =@SchemaName and t.name = @TableName and c.name = @ColumnName))
	begin 

-- Remover a coluna
SET @SQL = 'ALTER TABLE [' + @SchemaName + '].[' + @TableName + '] DROP COLUMN [' + @ColumnName + ']'
EXEC sp_executesql @SQL
PRINT 'Coluna ' + @ColumnName + ' removida da tabela ' + @SchemaName + '.' + @TableName + '.'

	end




end