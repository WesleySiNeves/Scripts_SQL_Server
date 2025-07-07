WITH DadosBase
AS (SELECT noticia.Titulo,
           MIN(CAST(noticia.DataInicio AS DATE)) DataInicio,
           MIN(CAST(noticia.DataFim AS DATE)) AS DataFim,
           COUNT(1) TotalDescarte
    FROM Sistema.Noticias noticia
        JOIN Sistema.NoticiasUsuariosDescartes descarte
            ON descarte.IdNoticia = noticia.IdNoticia
    WHERE Titulo IN ( 'Educação Executiva e Consultoria Implanta',
                      'Curso: Governo Aberto – Uma nova abordagem de Transparência Pública e Dados Abertos para Conselhos de Fiscalização Profissional'
                    )
    GROUP BY noticia.Titulo)
SELECT 
		R.Titulo,
       R.DataInicio,
       R.DataFim,
       R.TotalDescarte,
       SUM(Acesso.Quantidade) AS Logins
FROM DadosBase R
    OUTER APPLY
(
    SELECT CAST(DataAcesso AS DATE) Data,
           COUNT( DISTINCT IdPessoa) Quantidade
    FROM Log.Acessos
    WHERE DataAcesso >= R.DataInicio
          AND DataAcesso <= R.DataFim
    GROUP BY CAST(DataAcesso AS DATE)
) Acesso
GROUP BY R.Titulo,
         R.DataInicio,
         R.DataFim,
         R.TotalDescarte;


		 

--SELECT *
--FROM Sistema.Noticias
--WHERE Titulo LIKE '%Educação%';
--SELECT *
--FROM Sistema.Noticias
--WHERE Titulo LIKE '%Curso%';


