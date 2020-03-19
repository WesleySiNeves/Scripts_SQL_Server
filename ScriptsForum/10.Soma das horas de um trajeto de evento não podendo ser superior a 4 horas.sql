
/*
ID  -     Data   -   Quant_Horas  - Km - Evento
146 - 2017-03-23 - 00:50:00.00000 - 0   - 1
147 - 2017-04-07 - 00:20:00.00000 - 0   - 2
149 - 2017-04-07 - 03:00:00.00000 - 49 - 4
150 - 2017-04-07 - 01:00:00.00000 - 0   - 6
151 - 2017-04-07 - 00:15:00.00000 - 5   - 4
152 - 2017-04-07 - 02:25:00.00000 - 13 - 2
153 - 2017-04-07 - 00:00:00.00000 - 0   - 9
*/
DECLARE @TBL_Tempo_Jornada TABLE
    (
      IdEmpregado INT ,
      id INT ,
      Data DATE ,
      QuantidaeHoras TIME ,
      Km INT ,
      Evento INT
    );

INSERT INTO @TBL_Tempo_Jornada
        ( IdEmpregado ,
          id ,
          Data ,
          QuantidaeHoras ,
          Km ,
          Evento
        )
    SELECT 1 ,
            146 ,
            '2017-03-23' ,
            '00:50:00.00000' ,
            0 ,
            1
    UNION ALL
    SELECT 1 ,
            147 ,
            '2017-04-07' ,
            '00:20:00.00000' ,
            0 ,
            2
    UNION ALL
    SELECT 1 ,
            149 ,
            '2017-04-07' ,
            '03:00:00.00000' ,
            49 ,
            4
    UNION ALL
    SELECT 2 ,
            150 ,
            '2017-04-07' ,
            '01:00:00.00000' ,
            0 ,
            6
    UNION ALL
    SELECT 2 ,
            151 ,
            '2017-04-07' ,
            '00:15:00.00000' ,
            5 ,
            4
    UNION ALL
    SELECT 2 ,
            152 ,
            '2017-04-07' ,
            '02:25:00.00000' ,
            13 ,
            2
    UNION ALL
    SELECT 1 ,
            153 ,
            '2017-04-07' ,
            '00:00:00.00000' ,
            0 ,
            9;




;WITH    Dados ( IdEmpregado, HorasTrabalhadas )
          AS ( SELECT IdEmpregado ,
                    SUM(DATEDIFF(MINUTE, '0:00:00', QuantidaeHoras))
                FROM @TBL_Tempo_Jornada
                GROUP BY IdEmpregado
             ),
        Formatacao
          AS ( SELECT IdEmpregado = IdEmpregado ,
                    HorasTrabalhadas = RTRIM(HorasTrabalhadas / 60) + ':'
                    + RIGHT('0' + RTRIM(HorasTrabalhadas % 60), 2)
                FROM Dados
             )
    SELECT Formatacao.IdEmpregado ,
            Formatacao.HorasTrabalhadas ,
            PassouDoLimite = IIF(CAST(REPLACE(Formatacao.HorasTrabalhadas, ':',
                                              '.') AS DECIMAL(18, 2)) > 4, 'Sim', 'Não')
        FROM Formatacao;



