--CREATE TABLE #forum
--    (
--      company VARCHAR(10) ,
--      office INT ,
--      departm INT ,
--      sector INT ,
--      purchase DECIMAL(10, 2) ,
--      checking VARCHAR(10)
--    );
--INSERT  INTO #forum
--VALUES  ( 'PepsiCola', 1, 2, 12, 220.13, 'First' ),
--        ( 'PepsiCola', 1, 2, 18, 224.22, 'First' ),
--        ( 'PepsiCola', 1, 2, 12, 220.13, 'Second' ),
--        ( 'PepsiCola', 1, 2, 18, 227.22, 'Second' ),
--        ( 'PepsiCola', 1, 2, 46, 1550.65, 'Second' );

SELECT * FROM #forum;
WITH    DataGroups
          AS ( SELECT   F.company ,
                        F.office ,
                        F.departm ,
                        F.sector ,
                        F.checking ,
                        purchase = SUM(F.purchase)
               FROM     #forum F
               GROUP BY F.company ,
                        F.office ,
                        F.departm ,
                        F.sector ,
                        F.checking
             ),
			 GroupsLagsValues AS (
			 
			 SELECT 
		    G.company ,
            G.office ,
            G.departm ,
            G.sector ,
            G.checking ,
            G.purchase ,
            LagValue = LAG(G.purchase, 1, 0) OVER ( PARTITION BY G.company,
                                                    G.office, G.departm,
                                                    G.sector ORDER BY G.checking )
    FROM    DataGroups G
			 )
			 SELECT 
			GV.company ,
            GV.office ,
            GV.departm ,
            GV.sector ,
            GV.checking ,
            GV.purchase ,
            GV.LagValue,
			DIRF =IIF(GV.LagValue = 0,0,GV.purchase -GV.LagValue) 
			 FROM GroupsLagsValues GV
    




