/* Este scripts permite identificar a coluna mais �ndicada a ser tornar chave ou �ndice
cluster em uma tabela. 
Quanto mais pr�ximo de 1 for a seletividade, melhor � a coluna


*** O nome do campo a ser analizado. Neste caso StatusPausa
*** Alterar nome da tabela. Neste caso authors
*/



SELECT  [Qtde. Registros] = COUNT(*) ,
        [Reg. Distintos] = COUNT(DISTINCT DataLancamento) ,
        [Seletividade (quanto > melhor)] = COUNT(DISTINCT CB.DataLancamento)
        / CAST(COUNT(*) AS DEC(8, 2)) ,
        [Densidade/Duplicidade (quanto < melhor)] = 1
        / CAST(COUNT(DISTINCT CB.DataLancamento) AS DEC(8, 2))
FROM    Despesa.ArquivosExtratoLancamentos AS CB;

