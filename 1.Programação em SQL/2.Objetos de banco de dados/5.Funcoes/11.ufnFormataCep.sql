

CREATE FUNCTION FormataCep
    (
      @cepNaoFormatado VARCHAR(20)
    )
RETURNS VARCHAR(20)
AS
    BEGIN
        DECLARE @cep AS VARCHAR(20);
        SET @cep = @cepNaoFormatado;

        SET @cep = REPLACE(REPLACE(@cep, '.', ''), '-', '');
        SET @cep = SUBSTRING(@cep, 1, 2) + '.' + SUBSTRING(@cep, 3, 3) + '-'
            + SUBSTRING(@cep, 6, LEN(@cep));

        RETURN @cep;
    END;
