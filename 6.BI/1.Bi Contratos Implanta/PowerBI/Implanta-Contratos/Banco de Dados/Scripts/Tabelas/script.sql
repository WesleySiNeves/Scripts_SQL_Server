
DROP TABLE IF EXISTS Contrato.D_Unidades


CREATE TABLE Contrato.D_Unidades
(
  SKIdUnidade INT NOT NULL PRIMARY KEY IDENTITY(1,1),
  IdUnidade UNIQUEIDENTIFIER NOT NULL ,
  NomeUnidade VARCHAR(200) NOT NULL,
  
)
WITH (DATA_COMPRESSION =PAGE)

CREATE UNIQUE NONCLUSTERED INDEX 
Unq_ContratoUnidadesIdUnidade ON Contrato.D_Unidades(IdUnidade)
 
 



DROP TABLE IF EXISTS Contrato.D_Unidades


CREATE TABLE Contrato.D_Unidades
(
  SKIdUnidade INT NOT NULL PRIMARY KEY IDENTITY(1,1),
  IdUnidade UNIQUEIDENTIFIER NOT NULL ,
  NomeUnidade VARCHAR(200) NOT NULL,
  
)
WITH (DATA_COMPRESSION =PAGE)

CREATE UNIQUE NONCLUSTERED INDEX 
Unq_ContratoUnidadesIdUnidade ON Contrato.D_Unidades(IdUnidade)
 
 

INSERT INTO Contrato.D_Unidades
VALUES
( '{00000000-0000-0000-0000-000000000000}', 'Não informada' ),
( '{814f145f-c900-41c8-baf7-0211332ea104}', 'Comissão Eleitoral Federal' ),
( '{43f3d9d3-dcf8-4fae-a7d8-0399ad6ebf6a}', 'GIE - Gerência de infraestrutura' ),
( '{45ac45d9-5c1b-49b7-ba3a-0779f0b1aae8}', 'GER-N/NE - Gerência Regional Norte-Nordeste' ),
( '{8dfe1324-e4a2-4623-9344-1d88da900b49}', 'GPT - Gerência de Programação e Tecnologia' ),
( '{f80cb55f-88e4-49a5-8e29-1e9ac736ed7b}', 'SAF - Superintendência Administrativa e Financeira' ),
( '{5dd329aa-ed36-4662-b9bf-2331d4e2c300}', 'GPE - Gerência de Planejamento Estratégico ' ),
( '{4eef9f25-dec5-48ec-ad48-286606a27fcd}', 'SINFRA - Setor de Infraestrutura da TI, Modernização' ),
( '{a813e9b9-206d-4bc2-836b-3887910207cc}', 'GABI - Gabinete ' ),
( '{16911aa0-4445-4090-82e6-3acc094164ca}', 'SEPAT - Setor de Patrocínio' ),
( '{feb20eab-06e5-47ed-b450-630bd5f3647f}', 'AGS - Advocacia Geral do Sistema' ),
( '{97e87d7a-79d9-4248-87bb-79ff28666240}', 'GRI - Gerência de Relações Institucionais e Inteligência ' ),
( '{ca6d0a8e-6498-47b5-97b3-8681c8ffddb7}', 'CONT - Controladoria' ),
( '{86c8bf2d-e38b-4dc9-806f-a211ca5e9779}', 'SEPAD - Setor de Passagens e Diárias ' ),
( '{68f6c24a-4ae3-47f6-aad9-a7cbb6443651}', 'GIT - Gerência de Inovação e Transformação' ),
( '{d8a52f44-a3fe-4827-b6d0-ab128f4ab843}', 'GFI - Gerência Financeira' ),
( '{b24ef1db-ced7-4790-9263-aca0a94b26de}', 'GAP - Gerência de Administração de Pessoas' ),
( '{8b554f1a-4ba3-42fd-ab0e-bdf8635bb7bc}', 'SEPRO - Setor de Protocolo' ),
( '{7cd7d789-ae53-4949-bc6c-be0aeee6b916}', 'SES - Superintendência de Estratégia do Sistema' ),
( '{14f6686d-a4de-4fc3-ae99-bf7882daa338}', 'GCO - Gerência de Comunicação' ),
( '{0ac12265-387e-4c06-887e-ca090d829a5c}', 'GCD  - Gerência de Cultura Organizacional e Desenvolvimento' ),
( '{c69465d1-fbde-4c05-8915-cb1ab0790937}', 'GEC - Gerência de Contratações' ),
( '{102c64c5-008d-4426-a85f-d392c6a0a228}', 'GER/CO/SE/S - Gerência Regional Sul Sudeste e Cento Oeste' ),
( '{940823ef-fc1d-40d9-91f1-e320c6f2d4eb}', 'ADJUD - Advocacia Judicial' ),
( '{4b2fa7c2-69e8-4185-9546-f33d6922ee97}', 'AUDI - Auditoria' ),
( '{a465c3c3-e084-4f47-af9a-feea7bbc45fe}', 'GEV - Geréncia de Eventos ' )






-- tabela D_ModalidadeContratos
DROP TABLE IF EXISTS Contrato.D_ModalidadeContratos;

CREATE TABLE Contrato.D_ModalidadeContratos
(
  SKModalidadeContrato INT NOT NULL PRIMARY KEY IDENTITY(1,1),
  IdModalidadeContrato UNIQUEIDENTIFIER NOT NULL ,
  NomeModalidade VARCHAR(200) NOT NULL,
  
)
WITH (DATA_COMPRESSION =PAGE)

CREATE UNIQUE NONCLUSTERED INDEX 
Unq_ContratoModalidadeContratos ON Contrato.D_ModalidadeContratos(IdModalidadeContrato)
 

INSERT INTO Contrato.D_ModalidadeContratos
([IdModalidadeContrato], [NomeModalidade])
VALUES
( '{00000000-0000-0000-0000-000000000000}', 'Não informada' ),
( '{2ab67a03-b9d5-454a-81da-04a224704b67}', 'Apólice' ),
( '{3b6ae962-0ba8-4c0c-961a-8326ea86aed8}', 'Inexigibilidade de Licitação' ),
( '{fa453ffe-7b3c-41f0-a14c-aab27b95d227}', 'Dispensa de Licitação' ),
( '{30f3c099-d064-47e7-8a33-ec4ce3d9ec28}', 'Administrativo' ) 



--Tabela tipo de contratos
DROP TABLE IF EXISTS Contrato.D_TiposContratos;

CREATE TABLE Contrato.D_TiposContratos
(
  SKIdTipoContrato INT NOT NULL PRIMARY KEY IDENTITY(1,1),
  IdTipoContrato UNIQUEIDENTIFIER NOT NULL ,
  NomeTipoContrato VARCHAR(200) NOT NULL,
  
)
WITH (DATA_COMPRESSION =PAGE)

CREATE UNIQUE NONCLUSTERED INDEX 
Unq_ContratoTiposContratosIdTipoContrato 
ON Contrato.D_TiposContratos(IdTipoContrato)
 

 INSERT INTO Contrato.D_TiposContratos
VALUES
( '{00000000-0000-0000-0000-000000000000}', 'Não informada' ),
( '{6f6f8c17-c245-423e-b6c0-13e41c4cef1b}', 'Nota de Empenho' ),
( '{8dd85963-d664-4827-a93b-5c088e7e91f1}', 'Ata de Registro de Preços' ),
( '{b350dec5-fc10-4d07-9b73-c84879219797}', 'Patrocínio ' ),
( '{54acb05a-3d78-4bfe-860e-e97a8ad26753}', 'Administrativo' )

