



CREATE FUNCTION [Helper].[ufnMesPorExtenso] (@numeroMes INT)
RETURNS VARCHAR(MAX)
BEGIN
    DECLARE @Retorno VARCHAR(MAX) = '';

    SET @Retorno
        = CHOOSE(
              @numeroMes,
              'Janeiro',
              'Fevereiro',
              'Mar�o',
              'Abril',
              'Maio',
              'Junho',
              'Julho',
              'Agosto',
              'Setembro',
              'Outubro',
              'Novembro',
              'Dezembro');

    RETURN @Retorno;
END;


GO


