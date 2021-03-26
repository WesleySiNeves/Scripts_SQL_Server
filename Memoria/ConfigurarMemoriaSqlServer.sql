
EXEC sp_configure @configname = 'show advanced options', -- varchar(35)
                 @configvalue = 1  -- int


EXEC sp_configure @configname = 'Ad Hoc Distributed Queries', -- varchar(35)
                 @configvalue = 1  -- int



EXEC sp_configure @configname = 'max server memory (MB)', -- varchar(35)
                 @configvalue = 8192  -- int  -- 8 GB de memoria maxima


RECONFIGURE WITH OVERRIDE

