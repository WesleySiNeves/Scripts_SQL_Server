SELECT
        inc.NomeRazaoSocial,
        inc.CNPJ,
        [CNPJ Existe no Cadastro]         = IIF(emp.CPFCNPJ IS NULL, 'NÂO', 'SIM'),
        ISNULL(emp.CPFCNPJ, '--')         AS CPFCNPJ,
        ISNULL(emp.QuantidadeEmpenhos, 0) AS QuantidadeEmpenhos,
        ISNULL(emp.TotalEmpenhado, 0)     AS TotalEmpenhado,
        ISNULL(emp.TotalLiquidado, 0)     AS TotalLiquidado
FROM
        (
            VALUES
                (
                    'INCORP TECHNOLOGY INFORMATICA LTDA', '41.069.964/0001-73'
                )
        ) AS inc (NomeRazaoSocial, CNPJ)
    LEFT JOIN
        (
            SELECT
                    pe.CPFCNPJ,
                    COUNT(1)            AS QuantidadeEmpenhos,
                    SUM(Valor)          AS TotalEmpenhado,
                    SUM(ValorLiquidado) AS TotalLiquidado
            FROM
                    Despesa.Empenhos emp
                JOIN
                    Cadastro.Pessoas pe
                        ON pe.IdPessoa = emp.IdPessoa
            WHERE
                    pe.CPFCNPJ = '41.069.964/0001-73'
                    AND Exercicio = 2025
                    AND RestoAPagar = 0
            GROUP BY
                    pe.CPFCNPJ
        ) emp
            ON emp.CPFCNPJ = inc.CNPJ;
