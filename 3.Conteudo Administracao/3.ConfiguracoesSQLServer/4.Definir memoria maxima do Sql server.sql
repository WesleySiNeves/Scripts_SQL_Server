
-- 1 MB 1024
-- 2 MB 2048
-- 3 MB 3072
-- 4 MB 4096



EXEC sys.sp_configure 'max server memory (MB)', '4096';
RECONFIGURE WITH OVERRIDE;

RECONFIGURE ;


--SELECT (1024 *4)