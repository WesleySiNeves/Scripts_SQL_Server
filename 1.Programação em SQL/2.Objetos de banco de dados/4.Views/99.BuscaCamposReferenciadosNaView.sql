--SELECT * FROM  sys.views AS V

DECLARE @NomeView NVARCHAR(200) = 'Contabilidade.VwGetLancamentosEMovimentosDosExercicios';


SELECT OBJECT_NAME(OBJECT_ID(@NomeView)),
       SD.object_id,
       --SD.column_id,
       Dep.*,
       SD.is_selected,
       SD.is_updated
FROM sys.sql_dependencies AS SD
    OUTER APPLY
(
    SELECT [OBJETO] = OBJECT_NAME(C.object_id),
           [Coluna] = C.name,
           C.column_id,
           C.system_type_id
    FROM sys.objects AS O
        JOIN sys.columns AS C
            ON O.object_id = C.object_id
    WHERE O.object_id = SD.referenced_major_id
          AND C.column_id = SD.referenced_minor_id
) Dep
WHERE SD.object_id = OBJECT_ID(@NomeView);

