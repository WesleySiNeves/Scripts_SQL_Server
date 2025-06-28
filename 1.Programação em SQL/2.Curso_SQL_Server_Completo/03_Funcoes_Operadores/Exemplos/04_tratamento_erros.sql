-- =====================================================
-- CURSO SQL SERVER - MÓDULO 03: FUNÇÕES E OPERADORES
-- Arquivo: 04_tratamento_erros.sql
-- Tópico: Tratamento de Erros e Exceções
-- =====================================================

-- ÍNDICE:
-- 1. Estrutura TRY-CATCH
-- 2. RAISERROR vs THROW
-- 3. Funções de Informação de Erro
-- 4. Tratamento em Procedures
-- 5. Transações e Rollback
-- 6. Exercícios Práticos

-- =====================================================
-- 1. ESTRUTURA TRY-CATCH
-- =====================================================

-- Exemplo 1: Estrutura básica TRY-CATCH
BEGIN TRY
    -- Código que pode gerar erro
    DECLARE @divisor INT = 0;
    DECLARE @resultado INT = 10 / @divisor; -- Divisão por zero
    PRINT 'Esta linha não será executada';
END TRY
BEGIN CATCH
    -- Tratamento do erro
    PRINT 'Erro capturado!';
    PRINT 'Número do erro: ' + CAST(ERROR_NUMBER() AS VARCHAR(10));
    PRINT 'Mensagem: ' + ERROR_MESSAGE();
END CATCH

PRINT 'Execução continua após o bloco TRY-CATCH';

-- Exemplo 2: TRY-CATCH com diferentes tipos de erro
BEGIN TRY
    -- Teste 1: Conversão inválida
    DECLARE @numero INT = CAST('ABC' AS INT);
END TRY
BEGIN CATCH
    PRINT 'Erro de conversão capturado:';
    PRINT 'Erro: ' + CAST(ERROR_NUMBER() AS VARCHAR(10)) + ' - ' + ERROR_MESSAGE();
END CATCH

BEGIN TRY
    -- Teste 2: Tabela inexistente
    SELECT * FROM TabelaInexistente;
END TRY
BEGIN CATCH
    PRINT 'Erro de objeto inexistente capturado:';
    PRINT 'Erro: ' + CAST(ERROR_NUMBER() AS VARCHAR(10)) + ' - ' + ERROR_MESSAGE();
END CATCH

-- Exemplo 3: TRY-CATCH aninhado
BEGIN TRY
    PRINT 'Início do TRY externo';
    
    BEGIN TRY
        PRINT 'Início do TRY interno';
        DECLARE @erro INT = 1/0; -- Erro no TRY interno
    END TRY
    BEGIN CATCH
        PRINT 'CATCH interno: ' + ERROR_MESSAGE();
        -- Re-lançar o erro para o TRY externo
        THROW;
    END CATCH
    
    PRINT 'Esta linha não será executada';
END TRY
BEGIN CATCH
    PRINT 'CATCH externo: ' + ERROR_MESSAGE();
END CATCH

-- =====================================================
-- 2. RAISERROR vs THROW
-- =====================================================

-- Exemplo 1: Diferenças básicas entre RAISERROR e THROW
PRINT '=== TESTE COM RAISERROR ===';
RAISERROR('Esta é uma mensagem de erro com RAISERROR', 16, 1);
PRINT 'Execução continua após RAISERROR'; -- Esta linha É executada

DECLARE @inicio INT = 0;
DECLARE @termino INT = 3;

WHILE (@inicio <= @termino)
BEGIN
    PRINT 'Contador RAISERROR: ' + CAST(@inicio AS VARCHAR(10));
    SET @inicio = @inicio + 1;
END

PRINT '=== TESTE COM THROW ===';
-- THROW 50000, 'Esta é uma mensagem de erro com THROW', 1;
-- PRINT 'Esta linha NÃO seria executada'; -- THROW para a execução

-- Exemplo 2: RAISERROR com diferentes severidades
PRINT '=== RAISERROR COM DIFERENTES SEVERIDADES ===';

-- Severidade 10 (informação) - não para a execução
RAISERROR('Mensagem informativa', 10, 1);
PRINT 'Continua após severidade 10';

-- Severidade 16 (erro do usuário) - não para a execução
RAISERROR('Erro do usuário', 16, 1);
PRINT 'Continua após severidade 16';

-- Exemplo 3: RAISERROR com formatação
DECLARE @usuario VARCHAR(50) = 'João';
DECLARE @tentativas INT = 3;
DECLARE @data DATETIME = GETDATE();

RAISERROR('Usuário %s falhou no login. Tentativas restantes: %d. Data: %s', 
          16, 1, @usuario, @tentativas, @data);

-- Exemplo 4: THROW com captura
BEGIN TRY
    THROW 50001, 'Erro personalizado com THROW', 1;
END TRY
BEGIN CATCH
    PRINT 'THROW capturado:';
    PRINT 'Número: ' + CAST(ERROR_NUMBER() AS VARCHAR(10));
    PRINT 'Mensagem: ' + ERROR_MESSAGE();
    PRINT 'Severidade: ' + CAST(ERROR_SEVERITY() AS VARCHAR(10));
    PRINT 'Estado: ' + CAST(ERROR_STATE() AS VARCHAR(10));
END CATCH

-- Exemplo 5: RAISERROR para debug (WITH NOWAIT)
PRINT '=== DEBUG COM RAISERROR ===';
RAISERROR ('Iniciando processamento...', 0, 1) WITH NOWAIT;
WAITFOR DELAY '00:00:02'; -- Simula processamento
RAISERROR ('Processamento 50% completo...', 0, 1) WITH NOWAIT;
WAITFOR DELAY '00:00:02';
RAISERROR ('Processamento finalizado!', 0, 1) WITH NOWAIT;

-- =====================================================
-- 3. FUNÇÕES DE INFORMAÇÃO DE ERRO
-- =====================================================

-- Exemplo 1: Todas as funções de erro
BEGIN TRY
    -- Forçar um erro
    INSERT INTO TabelaInexistente VALUES (1, 'Teste');
END TRY
BEGIN CATCH
    SELECT ERROR_NUMBER() AS NumeroErro,
           ERROR_SEVERITY() AS Severidade,
           ERROR_STATE() AS Estado,
           ERROR_PROCEDURE() AS Procedimento,
           ERROR_LINE() AS Linha,
           ERROR_MESSAGE() AS Mensagem;
END CATCH

-- Exemplo 2: Criando uma função para log de erros
IF OBJECT_ID('TEMPDB..#LogErros') IS NOT NULL
    DROP TABLE #LogErros;

CREATE TABLE #LogErros (
    Id INT IDENTITY(1,1),
    DataHora DATETIME DEFAULT GETDATE(),
    NumeroErro INT,
    Severidade INT,
    Estado INT,
    Procedimento VARCHAR(128),
    Linha INT,
    Mensagem VARCHAR(4000),
    Usuario VARCHAR(128) DEFAULT SUSER_SNAME()
);

-- Procedure para registrar erros
IF OBJECT_ID('TEMPDB..#sp_RegistrarErro') IS NOT NULL
    DROP PROCEDURE #sp_RegistrarErro;
GO

CREATE PROCEDURE #sp_RegistrarErro
AS
BEGIN
    INSERT INTO #LogErros (NumeroErro, Severidade, Estado, Procedimento, Linha, Mensagem)
    VALUES (ERROR_NUMBER(), ERROR_SEVERITY(), ERROR_STATE(), 
            ERROR_PROCEDURE(), ERROR_LINE(), ERROR_MESSAGE());
END
GO

-- Testando o log de erros
BEGIN TRY
    DECLARE @teste INT = CAST('Texto' AS INT);
END TRY
BEGIN CATCH
    EXEC #sp_RegistrarErro;
END CATCH

BEGIN TRY
    SELECT 1/0;
END TRY
BEGIN CATCH
    EXEC #sp_RegistrarErro;
END CATCH

-- Visualizar log de erros
SELECT * FROM #LogErros;

DROP TABLE #LogErros;

-- =====================================================
-- 4. TRATAMENTO EM PROCEDURES
-- =====================================================

-- Exemplo 1: Procedure com validação de parâmetros
IF OBJECT_ID('TEMPDB..#sp_ProcessarVenda') IS NOT NULL
    DROP PROCEDURE #sp_ProcessarVenda;
GO

CREATE PROCEDURE #sp_ProcessarVenda
    @IdCliente INT,
    @IdProduto INT,
    @Quantidade INT,
    @Preco DECIMAL(10,2)
AS
BEGIN
    BEGIN TRY
        -- Validações de entrada
        IF (@IdCliente IS NULL OR @IdCliente <= 0)
        BEGIN
            THROW 50000, 'O parâmetro @IdCliente é obrigatório e deve ser maior que zero', 1;
        END
        
        IF (@IdProduto IS NULL OR @IdProduto <= 0)
        BEGIN
            THROW 50001, 'O parâmetro @IdProduto é obrigatório e deve ser maior que zero', 1;
        END
        
        IF (@Quantidade IS NULL OR @Quantidade <= 0)
        BEGIN
            THROW 50002, 'O parâmetro @Quantidade é obrigatório e deve ser maior que zero', 1;
        END
        
        IF (@Preco IS NULL OR @Preco <= 0)
        BEGIN
            THROW 50003, 'O parâmetro @Preco é obrigatório e deve ser maior que zero', 1;
        END
        
        -- Simular processamento
        DECLARE @Total DECIMAL(10,2) = @Quantidade * @Preco;
        
        PRINT 'Venda processada com sucesso!';
        PRINT 'Cliente: ' + CAST(@IdCliente AS VARCHAR(10));
        PRINT 'Produto: ' + CAST(@IdProduto AS VARCHAR(10));
        PRINT 'Quantidade: ' + CAST(@Quantidade AS VARCHAR(10));
        PRINT 'Total: R$ ' + CAST(@Total AS VARCHAR(20));
        
    END TRY
    BEGIN CATCH
        -- Log do erro
        PRINT 'Erro ao processar venda:';
        PRINT 'Erro: ' + CAST(ERROR_NUMBER() AS VARCHAR(10)) + ' - ' + ERROR_MESSAGE();
        
        -- Re-lançar o erro para quem chamou a procedure
        THROW;
    END CATCH
END
GO

-- Testando a procedure
PRINT '=== TESTE 1: Parâmetros válidos ===';
BEGIN TRY
    EXEC #sp_ProcessarVenda @IdCliente = 1, @IdProduto = 100, @Quantidade = 2, @Preco = 50.00;
END TRY
BEGIN CATCH
    PRINT 'Erro capturado no chamador: ' + ERROR_MESSAGE();
END CATCH

PRINT '=== TESTE 2: Cliente inválido ===';
BEGIN TRY
    EXEC #sp_ProcessarVenda @IdCliente = 0, @IdProduto = 100, @Quantidade = 2, @Preco = 50.00;
END TRY
BEGIN CATCH
    PRINT 'Erro capturado no chamador: ' + ERROR_MESSAGE();
END CATCH

PRINT '=== TESTE 3: Quantidade inválida ===';
BEGIN TRY
    EXEC #sp_ProcessarVenda @IdCliente = 1, @IdProduto = 100, @Quantidade = -1, @Preco = 50.00;
END TRY
BEGIN CATCH
    PRINT 'Erro capturado no chamador: ' + ERROR_MESSAGE();
END CATCH

-- =====================================================
-- 5. TRANSAÇÕES E ROLLBACK
-- =====================================================

-- Exemplo 1: Transação com rollback em caso de erro
IF OBJECT_ID('TEMPDB..#Contas') IS NOT NULL
    DROP TABLE #Contas;

CREATE TABLE #Contas (
    Id INT PRIMARY KEY,
    Nome VARCHAR(50),
    Saldo DECIMAL(10,2)
);

INSERT INTO #Contas VALUES 
(1, 'João', 1000.00),
(2, 'Maria', 500.00);

-- Procedure para transferência com tratamento de erro
IF OBJECT_ID('TEMPDB..#sp_Transferencia') IS NOT NULL
    DROP PROCEDURE #sp_Transferencia;
GO

CREATE PROCEDURE #sp_Transferencia
    @ContaOrigem INT,
    @ContaDestino INT,
    @Valor DECIMAL(10,2)
AS
BEGIN
    BEGIN TRANSACTION;
    
    BEGIN TRY
        -- Validações
        IF NOT EXISTS (SELECT 1 FROM #Contas WHERE Id = @ContaOrigem)
        BEGIN
            THROW 50010, 'Conta de origem não encontrada', 1;
        END
        
        IF NOT EXISTS (SELECT 1 FROM #Contas WHERE Id = @ContaDestino)
        BEGIN
            THROW 50011, 'Conta de destino não encontrada', 1;
        END
        
        IF @Valor <= 0
        BEGIN
            THROW 50012, 'Valor deve ser maior que zero', 1;
        END
        
        -- Verificar saldo
        DECLARE @SaldoOrigem DECIMAL(10,2);
        SELECT @SaldoOrigem = Saldo FROM #Contas WHERE Id = @ContaOrigem;
        
        IF @SaldoOrigem < @Valor
        BEGIN
            THROW 50013, 'Saldo insuficiente', 1;
        END
        
        -- Realizar transferência
        UPDATE #Contas SET Saldo = Saldo - @Valor WHERE Id = @ContaOrigem;
        UPDATE #Contas SET Saldo = Saldo + @Valor WHERE Id = @ContaDestino;
        
        COMMIT TRANSACTION;
        PRINT 'Transferência realizada com sucesso!';
        
    END TRY
    BEGIN CATCH
        ROLLBACK TRANSACTION;
        
        PRINT 'Erro na transferência:';
        PRINT 'Erro: ' + CAST(ERROR_NUMBER() AS VARCHAR(10)) + ' - ' + ERROR_MESSAGE();
        
        THROW; -- Re-lançar o erro
    END CATCH
END
GO

-- Testando transferências
PRINT '=== SALDOS INICIAIS ===';
SELECT * FROM #Contas;

PRINT '=== TESTE 1: Transferência válida ===';
BEGIN TRY
    EXEC #sp_Transferencia @ContaOrigem = 1, @ContaDestino = 2, @Valor = 200.00;
END TRY
BEGIN CATCH
    PRINT 'Erro: ' + ERROR_MESSAGE();
END CATCH

SELECT * FROM #Contas;

PRINT '=== TESTE 2: Saldo insuficiente ===';
BEGIN TRY
    EXEC #sp_Transferencia @ContaOrigem = 2, @ContaDestino = 1, @Valor = 1000.00;
END TRY
BEGIN CATCH
    PRINT 'Erro: ' + ERROR_MESSAGE();
END CATCH

SELECT * FROM #Contas;

PRINT '=== TESTE 3: Conta inexistente ===';
BEGIN TRY
    EXEC #sp_Transferencia @ContaOrigem = 1, @ContaDestino = 999, @Valor = 100.00;
END TRY
BEGIN CATCH
    PRINT 'Erro: ' + ERROR_MESSAGE();
END CATCH

SELECT * FROM #Contas;

DROP TABLE #Contas;

-- =====================================================
-- 6. TRATAMENTO AVANÇADO E BOAS PRÁTICAS
-- =====================================================

-- Exemplo 1: Função para formatação de erros
IF OBJECT_ID('TEMPDB..#fn_FormatarErro') IS NOT NULL
    DROP FUNCTION #fn_FormatarErro;
GO

CREATE FUNCTION #fn_FormatarErro()
RETURNS VARCHAR(4000)
AS
BEGIN
    DECLARE @ErrorMessage VARCHAR(4000);
    
    SET @ErrorMessage = 
        'Erro ' + CAST(ERROR_NUMBER() AS VARCHAR(10)) + 
        ' (Severidade ' + CAST(ERROR_SEVERITY() AS VARCHAR(10)) + 
        ', Estado ' + CAST(ERROR_STATE() AS VARCHAR(10)) + ')' +
        CASE 
            WHEN ERROR_PROCEDURE() IS NOT NULL 
            THEN ' na procedure ' + ERROR_PROCEDURE() + ', linha ' + CAST(ERROR_LINE() AS VARCHAR(10))
            ELSE ' na linha ' + CAST(ERROR_LINE() AS VARCHAR(10))
        END +
        ': ' + ERROR_MESSAGE();
    
    RETURN @ErrorMessage;
END
GO

-- Testando a função de formatação
BEGIN TRY
    SELECT 1/0;
END TRY
BEGIN CATCH
    SELECT dbo.#fn_FormatarErro() AS ErroFormatado;
END CATCH

-- Exemplo 2: Tratamento de erros específicos
BEGIN TRY
    -- Simular diferentes tipos de erro
    DECLARE @tipo_erro INT = 2;
    
    IF @tipo_erro = 1
        SELECT 1/0; -- Divisão por zero
    ELSE IF @tipo_erro = 2
        INSERT INTO TabelaInexistente VALUES (1); -- Objeto inexistente
    ELSE IF @tipo_erro = 3
        DECLARE @x INT = CAST('ABC' AS INT); -- Conversão inválida
END TRY
BEGIN CATCH
    DECLARE @ErrorNumber INT = ERROR_NUMBER();
    
    -- Tratamento específico por tipo de erro
    IF @ErrorNumber = 8134 -- Divisão por zero
    BEGIN
        PRINT 'Erro de divisão por zero detectado';
        PRINT 'Ação: Verificar valores dos divisores';
    END
    ELSE IF @ErrorNumber = 208 -- Objeto inexistente
    BEGIN
        PRINT 'Erro de objeto inexistente detectado';
        PRINT 'Ação: Verificar se a tabela/view existe';
    END
    ELSE IF @ErrorNumber = 245 -- Conversão inválida
    BEGIN
        PRINT 'Erro de conversão detectado';
        PRINT 'Ação: Verificar formato dos dados';
    END
    ELSE
    BEGIN
        PRINT 'Erro não tratado especificamente:';
        PRINT ERROR_MESSAGE();
    END
END CATCH

-- =====================================================
-- 7. EXERCÍCIOS PRÁTICOS
-- =====================================================

/*
EXERCÍCIO 1:
Crie uma procedure que valide um CPF e lance erros específicos
para diferentes tipos de problemas (formato, dígitos, etc.)

EXERCÍCIO 2:
Implemente um sistema de log de erros que registre:
- Data/hora do erro
- Usuário que executou
- Procedure/função onde ocorreu
- Mensagem de erro
- Parâmetros passados

EXERCÍCIO 3:
Crie uma procedure para inserção em lote que:
- Use transação
- Trate erros individualmente
- Continue processando outros registros em caso de erro
- Retorne relatório de sucessos/falhas

EXERCÍCIO 4:
Implemente um mecanismo de retry automático para operações
que podem falhar temporariamente (deadlocks, timeouts)

EXERCÍCIO 5:
Crie uma função que converta códigos de erro do SQL Server
em mensagens amigáveis para o usuário final
*/

-- =====================================================
-- SOLUÇÕES DOS EXERCÍCIOS
-- =====================================================

-- SOLUÇÃO 1: Validação de CPF
/*
CREATE PROCEDURE sp_ValidarCPF
    @CPF VARCHAR(14)
AS
BEGIN
    BEGIN TRY
        -- Remover formatação
        DECLARE @CPFLimpo VARCHAR(11) = REPLACE(REPLACE(REPLACE(@CPF, '.', ''), '-', ''), ' ', '');
        
        -- Validações
        IF LEN(@CPFLimpo) <> 11
            THROW 50001, 'CPF deve ter 11 dígitos', 1;
            
        IF ISNUMERIC(@CPFLimpo) = 0
            THROW 50002, 'CPF deve conter apenas números', 1;
            
        -- Verificar sequência repetida
        IF @CPFLimpo IN ('00000000000', '11111111111', '22222222222')
            THROW 50003, 'CPF inválido - sequência repetida', 1;
            
        -- Aqui viria a validação dos dígitos verificadores
        PRINT 'CPF válido: ' + @CPF;
        
    END TRY
    BEGIN CATCH
        PRINT 'Erro na validação do CPF:';
        PRINT ERROR_MESSAGE();
        THROW;
    END CATCH
END
*/

-- SOLUÇÃO 2: Sistema de log
/*
CREATE TABLE LogErros (
    Id BIGINT IDENTITY(1,1) PRIMARY KEY,
    DataHora DATETIME2 DEFAULT SYSDATETIME(),
    Usuario VARCHAR(128) DEFAULT SUSER_SNAME(),
    Aplicacao VARCHAR(128) DEFAULT APP_NAME(),
    NumeroErro INT,
    Severidade INT,
    Estado INT,
    Procedimento VARCHAR(128),
    Linha INT,
    Mensagem VARCHAR(4000),
    Parametros VARCHAR(MAX)
);

CREATE PROCEDURE sp_LogError
    @Parametros VARCHAR(MAX) = NULL
AS
BEGIN
    INSERT INTO LogErros (NumeroErro, Severidade, Estado, Procedimento, Linha, Mensagem, Parametros)
    VALUES (ERROR_NUMBER(), ERROR_SEVERITY(), ERROR_STATE(), 
            ERROR_PROCEDURE(), ERROR_LINE(), ERROR_MESSAGE(), @Parametros);
END
*/