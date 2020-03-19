

EXEC sp_configure 'default language', 0

RECONFIGURE 


Exec sp_helplanguage

Exec sp_configure 'default language', 5

Exec sp_defaultlanguage 'sa', 'us_english'
Reconfigure -- "Atualiza" a modificação realizada