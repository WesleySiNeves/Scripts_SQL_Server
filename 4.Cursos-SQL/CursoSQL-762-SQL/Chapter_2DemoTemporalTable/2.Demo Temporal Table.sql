

/* ==================================================================
--Data: 04/06/2018 
--Observação:  Formas de se criar tabelas temporais
Há três maneiras de criar uma tabela temporal com controle da versão do sistema relacionadas ao modo 
como a tabela de histórico é especificada:

Tabela temporal com uma tabela de histórico anônimo: especifique o esquema da tabela atual e deixe o sistema 
criar a tabela de histórico correspondente com o nome gerado automaticamente.

Tabela temporal com uma tabela de histórico padrão: especifique o nome do esquema de tabela de histórico e o 
nome da tabela e deixe o sistema criar tabela de histórico nesse esquema.

Tabela temporal com uma tabela de histórico definida pelo usuário criada antecipadamente: crie a tabela 
de histórico que melhor atenda às suas necessidades e faça referência a essa tabela durante a criação da tabela temporal.
 
-- ==================================================================
*/

--1)

/*
Uma tabela temporal com controle da versão do sistema deve ter uma chave primária definida e ter exatamente um 
PERIOD FOR SYSTEM_TIME definido com duas colunas datetime2, declaradas como GENERATED ALWAYS AS ROW START / END

Supõe-se que as colunas PERIOD sempre são não anuláveis, mesmo se a nulidade não for especificada. 
Se as colunas PERIOD forem definidas explicitamente como anuláveis, a instrução CREATE TABLE falhará.
*/

CREATE TABLE Department (
    DeptID INT NOT NULL PRIMARY KEY CLUSTERED,
    DeptName VARCHAR(50) NOT NULL,
    ManagerID INT NULL,
    ParentDeptID INT NULL,
    StartDate DATETIME2 GENERATED ALWAYS AS ROW START NOT NULL,
    EndDate DATETIME2 GENERATED ALWAYS AS ROW END NOT NULL,
    PERIOD FOR SYSTEM_TIME(StartDate, EndDate)) WITH(SYSTEM_VERSIONING =ON ,DATA_COMPRESSION =PAGE)
	;