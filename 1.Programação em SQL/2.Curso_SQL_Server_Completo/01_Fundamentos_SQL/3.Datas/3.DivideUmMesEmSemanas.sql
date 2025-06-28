DECLARE @startDate DATETIME= '09/01/2013';
DECLARE @endDate DATETIME= '11/30/2013';
DECLARE @WEEKCOUNT INT;
DECLARE @magic INT;

SELECT  @WEEKCOUNT = DATEDIFF(WEEK, @startDate, @endDate);
SELECT  @magic = CASE WHEN @WEEKCOUNT < 8 THEN @WEEKCOUNT
                      ELSE ( MONTH(@endDate) - MONTH(@startDate) ) + 1
                 END;
WITH    CTESplit
          AS ( SELECT   1 AS weekcount ,
                        CASE WHEN @WEEKCOUNT < 8
                             THEN DATEADD(dd,
                                          -( DATEPART(dw, @startDate) ) + 1,
                                          @startDate)
                             ELSE DATEADD(dd, -( DAY(@startDate) - 1 ),
                                          @startDate)
                        END [WeekStart] ,
                        CASE WHEN @WEEKCOUNT < 8
                             THEN DATEADD(dd,
                                          7 - ( DATEPART(dw, @startDate) ) + 1,
                                          @startDate)
                             ELSE DATEADD(s, -1,
                                          DATEADD(mm,
                                                  DATEDIFF(m, 0, @startDate)
                                                  + 1, 0))
                        END [WeekEnd]
               UNION ALL
               SELECT   a.weekcount + 1 AS weekcount ,
                        CASE WHEN @WEEKCOUNT < 8
                             THEN DATEADD(dd,
                                          -( DATEPART(dw,
                                                      @startDate + ( 7
                                                              * ( a.weekcount
                                                              + 1 ) )) ) + 2,
                                          @startDate + ( 7 * ( a.weekcount + 1 ) ))
                             ELSE DATEADD(dd,
                                          -( DAY(@startDate + ( 30
                                                              * ( a.weekcount
                                                              + 1 ) )) - 1 ),
                                          @startDate + ( 30 * ( a.weekcount
                                                              + 1 ) ))
                        END [WeekStart] ,
                        CASE WHEN @WEEKCOUNT < 8
                             THEN DATEADD(dd,
                                          7 - ( DATEPART(dw,
                                                         @startDate + ( 7
                                                              * ( a.weekcount
                                                              + 1 ) )) ) + 1,
                                          @startDate + ( 7 * ( a.weekcount + 1 ) ))
                             ELSE DATEADD(s, -1,
                                          DATEADD(mm,
                                                  DATEDIFF(m, 0,
                                                           @startDate + ( 30
                                                              * ( a.weekcount
                                                              + 1 ) )) + 1, 0))
                        END [WeekEnd]
               FROM     CTESplit a
               WHERE    ( a.weekcount + 1 ) <= @magic
             )
    SELECT  CTESplit.weekcount ,
            CTESplit.WeekStart ,
            CTESplit.WeekEnd
    FROM    CTESplit;