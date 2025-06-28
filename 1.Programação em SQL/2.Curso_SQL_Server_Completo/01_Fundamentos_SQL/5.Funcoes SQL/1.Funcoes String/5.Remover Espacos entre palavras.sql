DECLARE @texto VARCHAR(MAX) ='"Drogaria        Araújo"'

SELECT replace(replace(replace(@texto,' ','<>'),'><',''),'<>',' ')