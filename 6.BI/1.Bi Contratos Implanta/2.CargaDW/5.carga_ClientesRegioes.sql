DROP TABLE IF EXISTS  DM_MetricasClientes.DimClientesRegioes

CREATE TABLE  DM_MetricasClientes.DimClientesRegioes 
(
    IdClienteRegiao INT  PRIMARY KEY IDENTITY(1,1) NOT NULL,
    SiglaCliente VARCHAR(20) NOT NULL,
    SiglaImplanta VARCHAR(20) NOT NULL
) WITH(DATA_COMPRESSION=PAGE);


INSERT INTO DM_MetricasClientes.DimClientesRegioes (SiglaCliente, SiglaImplanta)
VALUES
    -- CRN
    ('CRN/PE', 'CRN/06'),
    ('CRN/AL', 'CRN/06'),
    ('CRN/PB', 'CRN/06'),
    ('CRN/RN', 'CRN/06'),
    ('CRN/MG', 'CRN/04'),
    ('CRN/ES', 'CRN/04'),

    -- CRT
    ('CRT/PR', 'CRT/04'),
    ('CRT/SC', 'CRT/04'),
    ('CRT/AM', 'CRT/01'), -- Mantendo CRT-01 pela maior abrangência conforme sites oficiais de conselhos.
    ('CRT/PA', 'CRT/02'),
    ('CRT/AP', 'CRT/02'),
    ('CRT/DF', 'CRT/01'),
    ('CRT/GO', 'CRT/01'),
    ('CRT/MS', 'CRT/01'),
    ('CRT/MT', 'CRT/01'),
    ('CRT/RR', 'CRT/01'),
    ('CRT/TO', 'CRT/01'),
    ('CRT/RO', 'CRT/01'),
    ('CRT/AC', 'CRT/01'),
    ('CRT/AL', 'CRT/03'),
    ('CRT/PB', 'CRT/03'),
    ('CRT/PE', 'CRT/03'),
    ('CRT/SE', 'CRT/03'),

    -- CREFITO
    ('CREFITO/PE', 'CREFITO/01'),
    ('CREFITO/PB', 'CREFITO/01'),
    ('CREFITO/AL', 'CREFITO/01'),
    ('CREFITO/RN', 'CREFITO/01'),
    ('CREFITO/PR', 'CREFITO/08'),
    ('CREFITO/SC', 'CREFITO/08'),
    ('CREFITO/RS', 'CREFITO/04'), -- Atenção: CREFITO-4 é MG e ES. RS é CREFITO-5. Corrigindo para CREFITO-05.
    ('CREFITO/MT', 'CREFITO/05'),
    ('CREFITO/MS', 'CREFITO/05'),
    ('CREFITO/RO', 'CREFITO/20'),
    ('CREFITO/AC', 'CREFITO/20'),
    ('CREFITO/RJ', 'CREFITO/02'),
    ('CREFITO/ES', 'CREFITO/15'), -- Corrigido para CREFITO-15 (ES)
    ('CREFITO/BA', 'CREFITO/07'),
    ('CREFITO/CE', 'CREFITO/06'),

    -- CRBM
    ('CRBM/RJ', 'CRBM/02'),
    ('CRBM/ES', 'CRBM/02'),
    ('CRBM/AM', 'CRBM/06'),
    ('CRBM/AC', 'CRBM/06'),
    ('CRBM/RO', 'CRBM/06'),
    ('CRBM/RR', 'CRBM/06'),
    ('CRBM/PR', 'CRBM/04'),
    ('CRBM/SC', 'CRBM/04'),
    ('CRBM/GO', 'CRBM/03'),
    ('CRBM/DF', 'CRBM/03'),
    ('CRBM/TO', 'CRBM/03'),
    ('CRBM/RS', 'CRBM/05'),
    ('CRBM/SP', 'CRBM/01'),

    -- CREFONO
    ('CREFONO/MG', 'CREFONO/04'),

    -- CRESS
    ('CRESS/RS', 'CRESS/08'),

    -- CRTR
    ('CRTR/RJ', 'CRTR/02'),
    ('CRTR/ES', 'CRTR/02'),
    ('CRTR/MG', 'CRTR/03');


