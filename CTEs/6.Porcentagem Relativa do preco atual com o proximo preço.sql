DECLARE @Tabela TABLE (
    Prcprdcab_descricao INT,
    Produto INT,
    Sigla_Cor VARCHAR(20),
    Preco DECIMAL(18, 2),
    Ipi INT,
    Icms INT,
    PRCPRD_ADICIONAL INT,
    LP_PRCPRD_COMPRIMENTO INT,
    LP_PRCPRD_ALTURA INT,
    LP_PRCPRD_PROFUNDIDADE INT,
    PRECOFAB INT,
    PRECOFABADC INT,
    PRECOFABADCCMP INT,
    PRECOFABADCALT INT,
    PRECOFABADCPRF INT,
    id INT,
    BaseCodigo VARCHAR(20));

INSERT INTO @Tabela (Prcprdcab_descricao,
                     Produto,
                     Sigla_Cor,
                     Preco,
                     Ipi,
                     Icms,
                     PRCPRD_ADICIONAL,
                     LP_PRCPRD_COMPRIMENTO,
                     LP_PRCPRD_ALTURA,
                     LP_PRCPRD_PROFUNDIDADE,
                     PRECOFAB,
                     PRECOFABADC,
                     PRECOFABADCCMP,
                     PRECOFABADCALT,
                     PRECOFABADCPRF,
                     id,
                     BaseCodigo)
VALUES (712, 01004, 'sem cor', 2.67, 0, 0, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 7798021, 'Eletrofrio'),
(712, 01005, 'sem cor', 2.59, 0, 0, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 7798022, 'Eletrofrio'),
(712, 01013, 'sem cor', 3, 0, 0, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 7798023, 'Eletrofrio'),
(801, 01004, 'sem cor', 2.70, 0, 0, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 8239225, 'Eletrofrio'),
(801, 01005, 'sem cor', 2.61, 0, 0, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 8239226, 'Eletrofrio'),
(801, 01013, 'sem cor', 5, 0, 0, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 8239227, 'Eletrofrio');


WITH Dados
  AS (SELECT T.Prcprdcab_descricao,
             T.Produto,
             T.Sigla_Cor,
             T.Ipi,
             T.Icms,
             T.id,
             T.BaseCodigo,
             T.Preco,
             [Total Geral dos Preços] = SUM(T.Preco) OVER (PARTITION BY T.Prcprdcab_descricao),
			 [proximo preco do produto] = LEAD(T.Preco,1,T.Preco) OVER(PARTITION BY  T.Prcprdcab_descricao ORDER BY T.Produto,T.Preco)
        FROM @Tabela AS T
		WHERE T.Prcprdcab_descricao =712
		)
SELECT R.Prcprdcab_descricao,
       R.Produto,
       R.Sigla_Cor,
       R.Ipi,
       R.Icms,
       R.id,
       R.BaseCodigo,
       R.Preco,
       R.[Total Geral dos Preços],
       [Porcentagem relativa do preco sobre o geral] = CONCAT(CAST(((R.Preco / R.[Total Geral dos Preços]) * 100) AS DECIMAL(18, 2)), ' %'),
	   R.[proximo preco do produto],
	   ----https://pt.wikihow.com/Calcular-a-Porcentagem-de-Redu%C3%A7%C3%A3o-de-Custos
	   [Porcentagem relativa do preco atual sobre o proximo preço do produto] = CONCAT( CAST(((( r.Preco -r.[proximo preco do produto]) /R.Preco ) *100 ) AS DECIMAL(18,2)),' %' ) 

  FROM Dados R;

  --  conforme o artigo temos as seguinte fases
  -- ==================================================================
  --Observação:
  --1)  Determine o preço original do produto ou serviço
  --2) Determine o novo preço do produto ou serviço
  --3)  Determine a diferença entre os dois preços
  --4) Divida a diferença entre ambos pelo preço original.
  --5) Multiplique o número decimal por 100
  -- ==================================================================

