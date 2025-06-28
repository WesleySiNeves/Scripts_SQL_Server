DECLARE @source VARBINARY(MAX),
        @encoded VARCHAR(MAX),
        @decoded VARBINARY(MAX);

SET @source = CONVERT(VARBINARY(256), 'Teste de Conversão de Varbinary para base64');
SET @encoded = CAST('' AS XML).value('xs:base64Binary(sql:variable("@source"))', 'varchar(max)');
SET @decoded = CAST('' AS XML).value('xs:base64Binary(sql:variable("@encoded"))', 'varbinary(max)');

SELECT CONVERT(VARCHAR(MAX), @source) AS source_varchar,
       @source AS source_binary,
       @encoded AS encoded,
       @decoded AS decoded_binary,
       CONVERT(VARCHAR(MAX), @decoded) AS decoded_varchar;