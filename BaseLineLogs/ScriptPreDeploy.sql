IF (NOT EXISTS
(
    SELECT *
    FROM sys.tables AS T
    WHERE T.name = 'SistemasEspelhamentos'
)
   )
BEGIN

    CREATE SEQUENCE Log.Seq_SistemasEspelhamentos
    AS TINYINT
    START WITH 0
    INCREMENT BY 1
    MINVALUE 0
    NO CYCLE
    NO CACHE;
    
	CREATE TABLE Log.SistemasEspelhamentos
    (
        IdSistemaEspelhamento TINYINT NOT NULL CONSTRAINT DEF_SistemasEspelhamentos DEFAULT (NEXT VALUE FOR Log.Seq_SistemasEspelhamentos),
        CodSistema UNIQUEIDENTIFIER NOT NULL,
        Nome VARCHAR(100),
        Descricao VARCHAR(200) CONSTRAINT PK_SistemasEspelhamentos PRIMARY KEY (IdSistemaEspelhamento), 
		CONSTRAINT Unique_SistemasEspelhamentosCodsistema UNIQUE (Codsistema),
        CONSTRAINT FK_SistemasEspelhamentosCodsistema FOREIGN KEY (Codsistema) REFERENCES Sistema.Sistemas (CodSistema) 
    );



    INSERT INTO Log.SistemasEspelhamentos
    (
        Codsistema,
        Nome,
        Descricao
    )
    SELECT S.CodSistema,
           S.Nome,
           S.Descricao
    FROM Sistema.Sistemas AS S
	WHERE NOT EXISTS(SELECT * FROM Log.SistemasEspelhamentos AS SE
						WHERE S.CodSistema = SE.CodSistema)


END;


DELETE FROM Sistema.Configuracoes WHERE Configuracoes.Configuracao ='ExpurgoEmExecucao'