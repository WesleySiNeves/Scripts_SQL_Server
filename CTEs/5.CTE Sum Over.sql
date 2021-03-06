SELECT 
    GRUPO, 
    COUNT(*) AS TOTAL_GRUPO,
    SUM(COUNT(*)) OVER() AS TOTAL_GERAL
FROM vw_frota_media_ch_v V
WHERE CONVERT(VARCHAR(8), CH_DATA_ABERTURA, 112) >= '20170401' 
AND   CONVERT(VARCHAR(8), CH_DATA_ABERTURA, 112) <= '20170430'
GROUP BY GRUPO