

/**/
IF(NOT EXISTS(SELECT * FROM  sys.schemas AS S
		WHERE S.name ='Espelhamento'))
		BEGIN
			CREATE SCHEMA Espelhamento				


		END