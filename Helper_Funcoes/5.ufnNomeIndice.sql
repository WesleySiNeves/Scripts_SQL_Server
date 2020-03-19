


CREATE FUNCTION Helper.index_name (
                               @object_id INT,
                               @index_id  INT
                               )
RETURNS sysname
AS
BEGIN
    RETURN (
           SELECT indexes.name
           FROM sys.indexes
           WHERE indexes.object_id = @object_id
                 AND indexes.index_id = @index_id
           );
END;
GO
