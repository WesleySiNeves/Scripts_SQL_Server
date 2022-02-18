DECLARE @Campo1 VARCHAR(5) ='17:00';
DECLARE @Campo2 VARCHAR(5) ='17:10';


            SELECT Convert(varchar(5),DateAdd(second, 
                                 DateDiff(second, Cast(@Campo1 as time(0)), Cast(@Campo2 as time(0))), 
                                 0),
                         108)
       