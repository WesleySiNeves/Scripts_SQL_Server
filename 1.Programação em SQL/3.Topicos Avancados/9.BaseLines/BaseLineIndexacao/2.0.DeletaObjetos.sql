



DROP FUNCTION IF EXISTS HealthCheck.ufnIndexMedia;

DROP TABLE IF EXISTS HealthCheck.SnapShotIndexHistory 
DROP TABLE IF EXISTS HealthCheck.SnapShotIndex 
DROP PROCEDURE IF EXISTS HealthCheck.uspAllIndex
DROP PROCEDURE IF EXISTS HealthCheck.uspAutoCreateIndex
DROP PROCEDURE IF EXISTS HealthCheck.uspAutoHealthCheck
DROP PROCEDURE IF EXISTS HealthCheck.uspAutoManegerStats
DROP PROCEDURE IF EXISTS HealthCheck.uspDeleteDuplicateIndex
DROP PROCEDURE IF EXISTS HealthCheck.uspIndexDesfrag
DROP PROCEDURE IF EXISTS HealthCheck.uspInefficientIndex
DROP PROCEDURE IF EXISTS HealthCheck.uspMissingIndex
DROP PROCEDURE IF EXISTS HealthCheck.uspSnapShotClear
DROP PROCEDURE IF EXISTS HealthCheck.uspSnapShotIndex
DROP PROCEDURE IF EXISTS HealthCheck.uspUnusedIndex
DROP PROCEDURE IF EXISTS HealthCheck.uspUpdateStats
DROP PROCEDURE IF EXISTS HealthCheck.uspDeleteOverlappingStats

DROP PROCEDURE IF EXISTS HealthCheck.uspIndexMedia




IF(EXISTS(SELECT 1 FROM sys.schemas AS S
WHERE S.name ='HealthCheck'))
BEGIN
		
EXEC('DROP SCHEMA HealthCheck');
END




