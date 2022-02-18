SELECT *
  FROM Log.LogsJSON AS LJ
 WHERE LJ.IdLogAntigo IN(
                            SELECT L.IdLog FROM Log.Logs AS L
                        );

SELECT *
  FROM Expurgo.LogsJSON AS LJ
 WHERE LJ.IdLogAntigo IN(
                            SELECT L.IdLog FROM Expurgo.Logs AS L
                        );
