CREATE TABLE Examples.Parameter
(
    ParameterId INT NOT NULL IDENTITY(1, 1)
        CONSTRAINT PKParameter PRIMARY KEY,
    Value1 VARCHAR(20) NOT NULL,
    Value2 VARCHAR(20) NOT NULL,
);



GO

CREATE PROCEDURE Examples.Parameter_Insert
    @Value1 VARCHAR(20) = 'No entry given',
    @Value2 VARCHAR(20) = 'No entry given'
AS
SET NOCOUNT ON;
INSERT INTO Examples.Parameter
(
    Value1,
    Value2
)
VALUES
(@Value1, @Value2);




--using all defaults
EXECUTE Examples.Parameter_Insert;

--by position, @Value1 parameter only
EXECUTE Examples.Parameter_Insert 'Some Entry';
--both columns by position

EXECUTE Examples.Parameter_Insert 'More Entry','More Entry';
-- using the name of the parameter (could also include @Value2);


EXECUTE Examples.Parameter_Insert @Value1 = 'Other Entry';
--starting positionally, but finishing by name

EXECUTE Examples.Parameter_Insert 'Mixed Entry', @Value2 ='Mixed Entry';

--Veja que aqui da erro
EXECUTE Examples.Parameter_Insert @Value1 = 'Remixed Entry', 'Remixed Entry'

/*
Msg 119, Level 15, State 1, Line 46
É necessário passar o parâmetro número 2 e os parâmetros subsequentes 
como '@nome = valor'. Após o formato '@nome = valor' ter sido usado, todos os parâmetros
 subsequentes devem ser passados no formato '@nome = valor'.
*/


/*########################
# OBS: parametros de saida
*/

GO
ALTER PROCEDURE Examples.Parameter_Insert
    @Value1 VARCHAR(20) = 'No entry given',
    @Value2 VARCHAR(20) = 'No entry given' OUTPUT,
    @NewParameterId INT = NULL OUTPUT
AS
SET NOCOUNT ON;
SET @Value1 = UPPER(@Value1);
SET @Value2 = LOWER(@Value2);
INSERT INTO Examples.Parameter
(
    Value1,
    Value2
)
VALUES
(@Value1, @Value2);
SET @NewParameterId = SCOPE_IDENTITY();

SELECT * FROM Examples.Parameter AS P

--Veja que vc precisa declarar as veriaveis para recuperar o valor retornado pela SP
EXEC Examples.Parameter_Insert @Value1 = 'No entry given', -- varchar(20)
                               @Value2 = 'No entry given'  -- varchar(20)


go
DECLARE @Value1 VARCHAR(20) = 'Test',
        @Value2 VARCHAR(20) = 'Test',
        @NewParameterId INT = -200;
EXECUTE Examples.Parameter_Insert @Value1 = @Value1,
                                  @Value2 = @Value2 OUTPUT,
                                  @NewParameterId = @NewParameterId OUTPUT;
SELECT @Value1 AS Value1,
       @Value2 AS Value2,
       @NewParameterId AS NewParameterId;
SELECT *
FROM Examples.Parameter
WHERE ParameterId = @NewParameterId;






