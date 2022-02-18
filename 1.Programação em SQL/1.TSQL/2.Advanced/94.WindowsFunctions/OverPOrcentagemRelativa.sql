DECLARE @foo TABLE ( value REAL );

INSERT  INTO @foo
VALUES  ( 50 ),
        ( 10 ),
        ( 10 ),
        ( 30 ),
        ( 50 ),
        ( 25 );

SELECT  value ,
        pct = ( value / SUM(value) OVER ( PARTITION BY 1 ) )
FROM    @foo;