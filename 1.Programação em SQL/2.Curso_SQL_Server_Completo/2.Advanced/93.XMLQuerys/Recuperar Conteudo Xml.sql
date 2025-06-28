DECLARE @Xml XML;

SET @Xml
    = '<div class="ExternalClass274A96B0-F1B4-44C4-9956-D5330361F716">Linha 1</div>
		<div class="ExternalClass274A96B0-F1B4-44C4-9956-D5330361F716">Linha 2</div>
		<div class="ExternalClass274A96B0-F1B4-44C4-9956-D5330361F716">Linha 3</div>
		<div class="ExternalClass274A96B0-F1B4-44C4-9956-D5330361F716">Linha 4</div>';


SELECT Divs.div.value('.', 'varchar(100)') AS [Conteudos]
  FROM @Xml.nodes('/div') AS Divs(div);