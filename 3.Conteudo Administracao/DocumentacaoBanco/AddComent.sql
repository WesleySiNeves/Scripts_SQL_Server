EXEC sp_addextendedproperty 
@name = N'MS_Description', @value = 'R = Receita , E = Empenho',
@level0type = N'Schema', @level0name = 'Contabilidade', 
@level1type = N'Table',  @level1name = 'HistoricosPadroes', 
@level2type = N'Column', @level2name = 'Tipo';



EXEC sp_updateextendedproperty 
@name = N'MS_Description', @value = 'R = Receita , E = Empenho',
@level0type = N'Schema', @level0name = 'Contabilidade', 
@level1type = N'Table',  @level1name = 'HistoricosPadroes', 
@level2type = N'Column', @level2name = 'Tipo';


