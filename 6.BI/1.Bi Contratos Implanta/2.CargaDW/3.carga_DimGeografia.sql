-- Script para popular a tabela DimGeografia com todos os estados brasileiros
-- Inclui BR como registro nacional e todos os estados organizados por região

-- Limpa dados existentes (se houver)
TRUNCATE TABLE Shared.DimGeografia;

-- Insere todos os estados brasileiros organizados por região
INSERT INTO Shared.DimGeografia (Estado, Regiao)
VALUES 
    -- Nacional (Brasil como um todo)
    ('BR', 'Nacional'),
    
    -- Região Norte
    ('AC', 'Norte'),     -- Acre
    ('AP', 'Norte'),     -- Amapá
    ('AM', 'Norte'),     -- Amazonas
    ('PA', 'Norte'),     -- Pará
    ('RO', 'Norte'),     -- Rondônia
    ('RR', 'Norte'),     -- Roraima
    ('TO', 'Norte'),     -- Tocantins
    
    -- Região Nordeste
    ('AL', 'Nordeste'),  -- Alagoas
    ('BA', 'Nordeste'),  -- Bahia
    ('CE', 'Nordeste'),  -- Ceará
    ('MA', 'Nordeste'),  -- Maranhão
    ('PB', 'Nordeste'),  -- Paraíba
    ('PE', 'Nordeste'),  -- Pernambuco
    ('PI', 'Nordeste'),  -- Piauí
    ('RN', 'Nordeste'),  -- Rio Grande do Norte
    ('SE', 'Nordeste'),  -- Sergipe
    
    -- Região Centro-Oeste
    ('DF', 'Centro-Oeste'), -- Distrito Federal
    ('GO', 'Centro-Oeste'), -- Goiás
    ('MT', 'Centro-Oeste'), -- Mato Grosso
    ('MS', 'Centro-Oeste'), -- Mato Grosso do Sul
    
    -- Região Sudeste
    ('ES', 'Sudeste'),   -- Espírito Santo
    ('MG', 'Sudeste'),   -- Minas Gerais
    ('RJ', 'Sudeste'),   -- Rio de Janeiro
    ('SP', 'Sudeste'),   -- São Paulo
    
    -- Região Sul
    ('PR', 'Sul'),       -- Paraná
    ('RS', 'Sul'),       -- Rio Grande do Sul
    ('SC', 'Sul');       -- Santa Catarina

-- Verifica os dados inseridos
SELECT 
    Estado,
    Regiao,
    COUNT(*) OVER (PARTITION BY Regiao) as QtdEstadosPorRegiao
FROM Shared.DimGeografia
ORDER BY 
    CASE 
        WHEN Estado = 'BR' THEN 0  -- BR sempre primeiro
        WHEN Regiao = 'Norte' THEN 1
        WHEN Regiao = 'Nordeste' THEN 2
        WHEN Regiao = 'Centro-Oeste' THEN 3
        WHEN Regiao = 'Sudeste' THEN 4
        WHEN Regiao = 'Sul' THEN 5
    END,
    Estado;

-- Estatísticas finais
SELECT 
    'Total de registros inseridos' as Descricao,
    COUNT(*) as Quantidade
FROM Shared.DimGeografia

UNION ALL

SELECT 
    'Regiões cadastradas' as Descricao,
    COUNT(DISTINCT Regiao) as Quantidade
FROM Shared.DimGeografia;

PRINT 'Carga da DimGeografia concluída com sucesso!';
PRINT 'Total: 28 registros (1 Nacional + 26 Estados + 1 DF)';