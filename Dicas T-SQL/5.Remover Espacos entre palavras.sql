DECLARE @texto VARCHAR(MAX) ='"Drogaria        Ara�jo"'

SELECT replace(replace(replace(@texto,' ','<>'),'><',''),'<>',' ')