


CREATE OR ALTER  FUNCTION Contabilidade.GetNivel
(
    @CodigoConta VARCHAR(200)
)
RETURNS INT AS 
    BEGIN
        DECLARE @posicao SMALLINT = CHARINDEX('.', @CodigoConta) + 1;
        DECLARE @Nivel SMALLINT = 0;

        WHILE(CHARINDEX('.', @CodigoConta) > 0)
            BEGIN
                SET @CodigoConta = (
                                       SELECT SUBSTRING(@CodigoConta, @posicao, LEN(@CodigoConta))
                                   );
                SET @posicao = CHARINDEX('.', @CodigoConta) + 1;

                SELECT @Nivel += 1;
            END;

        RETURN @Nivel;
    END;
