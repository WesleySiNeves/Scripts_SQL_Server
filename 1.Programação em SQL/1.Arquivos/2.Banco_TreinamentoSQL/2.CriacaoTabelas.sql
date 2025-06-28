
-- =============================================
-- Modelo de Dados para E-commerce - Vendas de Produtos
-- Autor: Sistema de Treinamento SQL
-- Data: 2024
-- Descrição: Estrutura completa para sistema de vendas online
-- =============================================

-- Criação do banco de dados
CREATE DATABASE EcommerceDB;
GO

USE EcommerceDB;
GO

-- =============================================
-- 1. TABELA DE CATEGORIAS
-- Armazena as categorias dos produtos
-- =============================================
CREATE TABLE Categorias (
    CategoriaID INT IDENTITY(1,1) PRIMARY KEY,
    NomeCategoria NVARCHAR(100) NOT NULL,
    Descricao NVARCHAR(500),
    Ativo BIT DEFAULT 1,
    DataCriacao DATETIME2 DEFAULT GETDATE(),
    DataAtualizacao DATETIME2 DEFAULT GETDATE()
);

-- =============================================
-- 2. TABELA DE FORNECEDORES
-- Armazena informações dos fornecedores
-- =============================================
CREATE TABLE Fornecedores (
    FornecedorID INT IDENTITY(1,1) PRIMARY KEY,
    NomeFornecedor NVARCHAR(150) NOT NULL,
    CNPJ NVARCHAR(18) UNIQUE,
    Email NVARCHAR(100),
    Telefone NVARCHAR(20),
    Endereco NVARCHAR(200),
    Cidade NVARCHAR(100),
    Estado NVARCHAR(2),
    CEP NVARCHAR(10),
    Ativo BIT DEFAULT 1,
    DataCriacao DATETIME2 DEFAULT GETDATE()
);

-- =============================================
-- 3. TABELA DE PRODUTOS
-- Armazena informações dos produtos
-- =============================================
CREATE TABLE Produtos (
    ProdutoID INT IDENTITY(1,1) PRIMARY KEY,
    NomeProduto NVARCHAR(200) NOT NULL,
    Descricao NVARCHAR(1000),
    CategoriaID INT NOT NULL,
    FornecedorID INT NOT NULL,
    CodigoBarras NVARCHAR(50),
    PrecoCompra DECIMAL(10,2) NOT NULL,
    PrecoVenda DECIMAL(10,2) NOT NULL,
    EstoqueAtual INT DEFAULT 0,
    EstoqueMinimo INT DEFAULT 0,
    Peso DECIMAL(8,3),
    Dimensoes NVARCHAR(50), -- Ex: "10x20x30 cm"
    ImagemURL NVARCHAR(500),
    Ativo BIT DEFAULT 1,
    DataCriacao DATETIME2 DEFAULT GETDATE(),
    DataAtualizacao DATETIME2 DEFAULT GETDATE(),
    
    -- Chaves estrangeiras
    CONSTRAINT FK_Produtos_Categorias FOREIGN KEY (CategoriaID) REFERENCES Categorias(CategoriaID),
    CONSTRAINT FK_Produtos_Fornecedores FOREIGN KEY (FornecedorID) REFERENCES Fornecedores(FornecedorID)
);

-- =============================================
-- 4. TABELA DE CLIENTES
-- Armazena informações dos clientes
-- =============================================
CREATE TABLE Clientes (
    ClienteID INT IDENTITY(1,1) PRIMARY KEY,
    NomeCompleto NVARCHAR(150) NOT NULL,
    Email NVARCHAR(100) UNIQUE NOT NULL,
    CPF NVARCHAR(14) UNIQUE,
    CNPJ NVARCHAR(18) UNIQUE,
    TipoCliente CHAR(1) CHECK (TipoCliente IN ('F', 'J')), -- F=Físico, J=Jurídico
    Telefone NVARCHAR(20),
    DataNascimento DATE,
    Genero CHAR(1) CHECK (Genero IN ('M', 'F', 'O')), -- M=Masculino, F=Feminino, O=Outro
    Ativo BIT DEFAULT 1,
    DataCriacao DATETIME2 DEFAULT GETDATE(),
    DataUltimoLogin DATETIME2
);

-- =============================================
-- 5. TABELA DE ENDEREÇOS DOS CLIENTES
-- Permite múltiplos endereços por cliente
-- =============================================
CREATE TABLE EnderecosClientes (
    EnderecoID INT IDENTITY(1,1) PRIMARY KEY,
    ClienteID INT NOT NULL,
    TipoEndereco NVARCHAR(20) NOT NULL, -- Ex: "Residencial", "Comercial", "Entrega"
    Logradouro NVARCHAR(200) NOT NULL,
    Numero NVARCHAR(10),
    Complemento NVARCHAR(100),
    Bairro NVARCHAR(100),
    Cidade NVARCHAR(100) NOT NULL,
    Estado NVARCHAR(2) NOT NULL,
    CEP NVARCHAR(10) NOT NULL,
    EnderecoPrincipal BIT DEFAULT 0,
    DataCriacao DATETIME2 DEFAULT GETDATE(),
    
    -- Chave estrangeira
    CONSTRAINT FK_EnderecosClientes_Clientes FOREIGN KEY (ClienteID) REFERENCES Clientes(ClienteID)
);

-- =============================================
-- 6. TABELA DE VENDAS (PEDIDOS)
-- Armazena o cabeçalho das vendas
-- =============================================
CREATE TABLE Vendas (
    VendaID INT IDENTITY(1,1) PRIMARY KEY,
    ClienteID INT NOT NULL,
    NumeroPedido NVARCHAR(20) UNIQUE NOT NULL,
    DataVenda DATETIME2 DEFAULT GETDATE(),
    StatusVenda NVARCHAR(20) DEFAULT 'Pendente', -- Pendente, Confirmado, Enviado, Entregue, Cancelado
    SubTotal DECIMAL(12,2) NOT NULL,
    ValorDesconto DECIMAL(12,2) DEFAULT 0,
    ValorFrete DECIMAL(10,2) DEFAULT 0,
    ValorTotal DECIMAL(12,2) NOT NULL,
    FormaPagamento NVARCHAR(50), -- Ex: "Cartão de Crédito", "PIX", "Boleto"
    EnderecoEntregaID INT,
    DataEntregaPrevista DATE,
    DataEntregaRealizada DATE,
    Observacoes NVARCHAR(500),
    
    -- Chaves estrangeiras
    CONSTRAINT FK_Vendas_Clientes FOREIGN KEY (ClienteID) REFERENCES Clientes(ClienteID),
    CONSTRAINT FK_Vendas_EnderecosClientes FOREIGN KEY (EnderecoEntregaID) REFERENCES EnderecosClientes(EnderecoID)
);

-- =============================================
-- 7. TABELA DE ITENS DA VENDA
-- Armazena os produtos vendidos em cada pedido
-- =============================================
CREATE TABLE ItensVenda (
    ItemVendaID INT IDENTITY(1,1) PRIMARY KEY,
    VendaID INT NOT NULL,
    ProdutoID INT NOT NULL,
    Quantidade INT NOT NULL,
    PrecoUnitario DECIMAL(10,2) NOT NULL,
    PercentualDesconto DECIMAL(5,2) DEFAULT 0,
    ValorDesconto DECIMAL(10,2) DEFAULT 0,
    SubTotal DECIMAL(12,2) NOT NULL, -- Quantidade * PrecoUnitario - ValorDesconto
    
    -- Chaves estrangeiras
    CONSTRAINT FK_ItensVenda_Vendas FOREIGN KEY (VendaID) REFERENCES Vendas(VendaID),
    CONSTRAINT FK_ItensVenda_Produtos FOREIGN KEY (ProdutoID) REFERENCES Produtos(ProdutoID)
);

-- =============================================
-- 8. TABELA DE ESTOQUE (MOVIMENTAÇÕES)
-- Controla entrada e saída de produtos
-- =============================================
CREATE TABLE MovimentacaoEstoque (
    MovimentacaoID INT IDENTITY(1,1) PRIMARY KEY,
    ProdutoID INT NOT NULL,
    TipoMovimentacao CHAR(1) NOT NULL CHECK (TipoMovimentacao IN ('E', 'S')), -- E=Entrada, S=Saída
    Quantidade INT NOT NULL,
    QuantidadeAnterior INT NOT NULL,
    QuantidadeAtual INT NOT NULL,
    Motivo NVARCHAR(100), -- Ex: "Compra", "Venda", "Ajuste", "Devolução"
    VendaID INT NULL, -- Referência à venda (quando aplicável)
    DataMovimentacao DATETIME2 DEFAULT GETDATE(),
    Usuario NVARCHAR(100),
    
    -- Chave estrangeira
    CONSTRAINT FK_MovimentacaoEstoque_Produtos FOREIGN KEY (ProdutoID) REFERENCES Produtos(ProdutoID),
    CONSTRAINT FK_MovimentacaoEstoque_Vendas FOREIGN KEY (VendaID) REFERENCES Vendas(VendaID)
);

-- =============================================
-- 9. TABELA DE CARRINHO DE COMPRAS
-- Armazena itens temporários antes da finalização
-- =============================================
CREATE TABLE CarrinhoCompras (
    CarrinhoID INT IDENTITY(1,1) PRIMARY KEY,
    ClienteID INT NOT NULL,
    ProdutoID INT NOT NULL,
    Quantidade INT NOT NULL,
    DataAdicao DATETIME2 DEFAULT GETDATE(),
    
    -- Chaves estrangeiras
    CONSTRAINT FK_CarrinhoCompras_Clientes FOREIGN KEY (ClienteID) REFERENCES Clientes(ClienteID),
    CONSTRAINT FK_CarrinhoCompras_Produtos FOREIGN KEY (ProdutoID) REFERENCES Produtos(ProdutoID)
);

-- =============================================
-- 10. TABELA DE AVALIAÇÕES DOS PRODUTOS
-- Permite que clientes avaliem produtos comprados
-- =============================================
CREATE TABLE AvaliacoesProdutos (
    AvaliacaoID INT IDENTITY(1,1) PRIMARY KEY,
    ProdutoID INT NOT NULL,
    ClienteID INT NOT NULL,
    VendaID INT NOT NULL,
    Nota INT CHECK (Nota BETWEEN 1 AND 5),
    Comentario NVARCHAR(1000),
    DataAvaliacao DATETIME2 DEFAULT GETDATE(),
    Aprovado BIT DEFAULT 0,
    
    -- Chaves estrangeiras
    CONSTRAINT FK_AvaliacoesProdutos_Produtos FOREIGN KEY (ProdutoID) REFERENCES Produtos(ProdutoID),
    CONSTRAINT FK_AvaliacoesProdutos_Clientes FOREIGN KEY (ClienteID) REFERENCES Clientes(ClienteID),
    CONSTRAINT FK_AvaliacoesProdutos_Vendas FOREIGN KEY (VendaID) REFERENCES Vendas(VendaID)
);

-- =============================================
-- ÍNDICES PARA OTIMIZAÇÃO DE PERFORMANCE
-- =============================================

-- Índices na tabela Produtos
CREATE INDEX IX_Produtos_CategoriaID ON Produtos(CategoriaID);
CREATE INDEX IX_Produtos_FornecedorID ON Produtos(FornecedorID);
CREATE INDEX IX_Produtos_Ativo ON Produtos(Ativo);
CREATE INDEX IX_Produtos_CodigoBarras ON Produtos(CodigoBarras);

-- Índices na tabela Vendas
CREATE INDEX IX_Vendas_ClienteID ON Vendas(ClienteID);
CREATE INDEX IX_Vendas_DataVenda ON Vendas(DataVenda);
CREATE INDEX IX_Vendas_StatusVenda ON Vendas(StatusVenda);
CREATE INDEX IX_Vendas_NumeroPedido ON Vendas(NumeroPedido);

-- Índices na tabela ItensVenda
CREATE INDEX IX_ItensVenda_VendaID ON ItensVenda(VendaID);
CREATE INDEX IX_ItensVenda_ProdutoID ON ItensVenda(ProdutoID);

-- Índices na tabela Clientes
CREATE INDEX IX_Clientes_Email ON Clientes(Email);
CREATE INDEX IX_Clientes_CPF ON Clientes(CPF);
CREATE INDEX IX_Clientes_Ativo ON Clientes(Ativo);

-- Índices na tabela MovimentacaoEstoque
CREATE INDEX IX_MovimentacaoEstoque_ProdutoID ON MovimentacaoEstoque(ProdutoID);
CREATE INDEX IX_MovimentacaoEstoque_DataMovimentacao ON MovimentacaoEstoque(DataMovimentacao);
CREATE INDEX IX_MovimentacaoEstoque_TipoMovimentacao ON MovimentacaoEstoque(TipoMovimentacao);

-- =============================================
-- TRIGGERS PARA AUTOMAÇÃO
-- =============================================
GO
-- Trigger para atualizar estoque após venda
CREATE TRIGGER TR_ItensVenda_AtualizaEstoque
ON ItensVenda
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Atualiza o estoque dos produtos vendidos
    UPDATE p
    SET EstoqueAtual = p.EstoqueAtual - i.Quantidade,
        DataAtualizacao = GETDATE()
    FROM Produtos p
    INNER JOIN inserted i ON p.ProdutoID = i.ProdutoID;
    
    -- Registra a movimentação de estoque
    INSERT INTO MovimentacaoEstoque (ProdutoID, TipoMovimentacao, Quantidade, QuantidadeAnterior, QuantidadeAtual, Motivo, VendaID, Usuario)
    SELECT 
        i.ProdutoID,
        'S', -- Saída
        i.Quantidade,
        p.EstoqueAtual + i.Quantidade, -- Quantidade anterior
        p.EstoqueAtual, -- Quantidade atual
        'Venda',
        i.VendaID,
        SYSTEM_USER
    FROM inserted i
    INNER JOIN Produtos p ON i.ProdutoID = p.ProdutoID;
END;
GO

-- Trigger para atualizar data de modificação em Produtos
CREATE TRIGGER TR_Produtos_AtualizaDataModificacao
ON Produtos
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    
    UPDATE Produtos
    SET DataAtualizacao = GETDATE()
    WHERE ProdutoID IN (SELECT ProdutoID FROM inserted);
END;
GO

-- =============================================
-- VIEWS ÚTEIS PARA RELATÓRIOS
-- =============================================

-- View para relatório de vendas com detalhes
CREATE VIEW VW_RelatorioVendas AS
SELECT 
    v.VendaID,
    v.NumeroPedido,
    v.DataVenda,
    c.NomeCompleto AS Cliente,
    c.Email AS EmailCliente,
    v.StatusVenda,
    v.SubTotal,
    v.ValorDesconto,
    v.ValorFrete,
    v.ValorTotal,
    v.FormaPagamento,
    COUNT(iv.ItemVendaID) AS QuantidadeItens
FROM Vendas v
INNER JOIN Clientes c ON v.ClienteID = c.ClienteID
LEFT JOIN ItensVenda iv ON v.VendaID = iv.VendaID
GROUP BY v.VendaID, v.NumeroPedido, v.DataVenda, c.NomeCompleto, c.Email, 
         v.StatusVenda, v.SubTotal, v.ValorDesconto, v.ValorFrete, v.ValorTotal, v.FormaPagamento;
GO

-- View para produtos com estoque baixo
CREATE VIEW VW_ProdutosEstoqueBaixo AS
SELECT 
    p.ProdutoID,
    p.NomeProduto,
    c.NomeCategoria,
    f.NomeFornecedor,
    p.EstoqueAtual,
    p.EstoqueMinimo,
    p.PrecoVenda
FROM Produtos p
INNER JOIN Categorias c ON p.CategoriaID = c.CategoriaID
INNER JOIN Fornecedores f ON p.FornecedorID = f.FornecedorID
WHERE p.EstoqueAtual <= p.EstoqueMinimo
  AND p.Ativo = 1;
GO

-- View para top produtos mais vendidos
CREATE VIEW VW_TopProdutosMaisVendidos AS
SELECT TOP 50
    p.ProdutoID,
    p.NomeProduto,
    c.NomeCategoria,
    SUM(iv.Quantidade) AS TotalVendido,
    SUM(iv.SubTotal) AS TotalFaturamento,
    AVG(CAST(av.Nota AS DECIMAL(3,2))) AS MediaAvaliacao,
    COUNT(av.AvaliacaoID) AS QuantidadeAvaliacoes
FROM Produtos p
INNER JOIN Categorias c ON p.CategoriaID = c.CategoriaID
INNER JOIN ItensVenda iv ON p.ProdutoID = iv.ProdutoID
INNER JOIN Vendas v ON iv.VendaID = v.VendaID
LEFT JOIN AvaliacoesProdutos av ON p.ProdutoID = av.ProdutoID AND av.Aprovado = 1
WHERE v.StatusVenda IN ('Confirmado', 'Enviado', 'Entregue')
GROUP BY p.ProdutoID, p.NomeProduto, c.NomeCategoria
ORDER BY TotalVendido DESC;
GO

-- =============================================
-- PROCEDURES ÚTEIS
-- =============================================

-- Procedure para inserir novo produto
CREATE PROCEDURE SP_InserirProduto
    @NomeProduto NVARCHAR(200),
    @Descricao NVARCHAR(1000),
    @CategoriaID INT,
    @FornecedorID INT,
    @CodigoBarras NVARCHAR(50),
    @PrecoCompra DECIMAL(10,2),
    @PrecoVenda DECIMAL(10,2),
    @EstoqueInicial INT = 0,
    @EstoqueMinimo INT = 0,
    @Peso DECIMAL(8,3) = NULL,
    @Dimensoes NVARCHAR(50) = NULL,
    @ImagemURL NVARCHAR(500) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @ProdutoID INT;
    
    -- Insere o produto
    INSERT INTO Produtos (NomeProduto, Descricao, CategoriaID, FornecedorID, CodigoBarras, 
                         PrecoCompra, PrecoVenda, EstoqueAtual, EstoqueMinimo, Peso, Dimensoes, ImagemURL)
    VALUES (@NomeProduto, @Descricao, @CategoriaID, @FornecedorID, @CodigoBarras,
            @PrecoCompra, @PrecoVenda, @EstoqueInicial, @EstoqueMinimo, @Peso, @Dimensoes, @ImagemURL);
    
    SET @ProdutoID = SCOPE_IDENTITY();
    
    -- Registra movimentação de estoque inicial (se houver)
    IF @EstoqueInicial > 0
    BEGIN
        INSERT INTO MovimentacaoEstoque (ProdutoID, TipoMovimentacao, Quantidade, QuantidadeAnterior, QuantidadeAtual, Motivo, Usuario)
        VALUES (@ProdutoID, 'E', @EstoqueInicial, 0, @EstoqueInicial, 'Estoque Inicial', SYSTEM_USER);
    END
    
    SELECT @ProdutoID AS ProdutoID;
END;
GO

-- =============================================
-- DADOS DE EXEMPLO PARA TESTES
-- =============================================

-- Inserir categorias de exemplo
INSERT INTO Categorias (NomeCategoria, Descricao) VALUES
('Eletrônicos', 'Produtos eletrônicos e tecnologia'),
('Roupas', 'Vestuário masculino e feminino'),
('Casa e Jardim', 'Produtos para casa e decoração'),
('Livros', 'Livros e material educativo'),
('Esportes', 'Artigos esportivos e fitness');

-- Inserir fornecedores de exemplo
INSERT INTO Fornecedores (NomeFornecedor, CNPJ, Email, Telefone, Cidade, Estado) VALUES
('TechSupply Ltda', '12.345.678/0001-90', 'contato@techsupply.com', '(11) 1234-5678', 'São Paulo', 'SP'),
('Moda Brasil S.A.', '98.765.432/0001-10', 'vendas@modabrasil.com', '(21) 9876-5432', 'Rio de Janeiro', 'RJ'),
('Casa & Cia', '11.222.333/0001-44', 'pedidos@casaecia.com', '(31) 1111-2222', 'Belo Horizonte', 'MG');

PRINT 'Modelo de dados para E-commerce criado com sucesso!';
PRINT 'Tabelas criadas: Categorias, Fornecedores, Produtos, Clientes, EnderecosClientes,';
PRINT 'Vendas, ItensVenda, MovimentacaoEstoque, CarrinhoCompras, AvaliacoesProdutos';
PRINT 'Índices, Triggers, Views e Procedures também foram criados.';
PRINT 'Dados de exemplo inseridos para testes.';

-- =============================================
-- INSERÇÃO DE DADOS DE EXEMPLO COMPLETOS
-- =============================================

-- Inserir produtos de exemplo
INSERT INTO Produtos (NomeProduto, Descricao, CategoriaID, FornecedorID, CodigoBarras, PrecoCompra, PrecoVenda, EstoqueAtual, EstoqueMinimo, Peso, Dimensoes, ImagemURL) VALUES
('Smartphone Samsung Galaxy S23', 'Smartphone Android com 128GB de armazenamento', 1, 1, '7891234567890', 800.00, 1200.00, 50, 10, 0.195, '15x7x0.8 cm', 'https://exemplo.com/galaxy-s23.jpg'),
('Notebook Dell Inspiron 15', 'Notebook com Intel i5, 8GB RAM, 256GB SSD', 1, 1, '7891234567891', 1500.00, 2200.00, 25, 5, 2.100, '35x25x2 cm', 'https://exemplo.com/dell-inspiron.jpg'),
('Camiseta Polo Masculina', 'Camiseta polo 100% algodão, tamanho M', 2, 2, '7891234567892', 25.00, 45.00, 100, 20, 0.200, '30x40x1 cm', 'https://exemplo.com/polo-m.jpg'),
('Calça Jeans Feminina', 'Calça jeans skinny, tamanho 38', 2, 2, '7891234567893', 40.00, 80.00, 75, 15, 0.500, '35x45x2 cm', 'https://exemplo.com/jeans-f.jpg'),
('Mesa de Jantar 6 Lugares', 'Mesa de madeira maciça com 6 cadeiras', 3, 3, '7891234567894', 600.00, 1200.00, 10, 2, 45.000, '180x90x75 cm', 'https://exemplo.com/mesa-jantar.jpg'),
('Livro: Programação em SQL', 'Guia completo para aprender SQL Server', 4, 3, '7891234567895', 30.00, 60.00, 200, 50, 0.400, '21x14x3 cm', 'https://exemplo.com/livro-sql.jpg'),
('Tênis de Corrida Nike', 'Tênis esportivo para corrida, tamanho 42', 5, 1, '7891234567896', 120.00, 250.00, 80, 20, 0.800, '30x12x10 cm', 'https://exemplo.com/tenis-nike.jpg'),
('Bicicleta Mountain Bike', 'Bicicleta aro 29 com 21 marchas', 5, 3, '7891234567897', 800.00, 1500.00, 15, 3, 15.000, '180x60x110 cm', 'https://exemplo.com/bike-mtb.jpg');

-- Inserir clientes de exemplo
INSERT INTO Clientes (NomeCompleto, Email, CPF, CNPJ, TipoCliente, Telefone, DataNascimento, Genero) VALUES
('João Silva Santos', 'joao.silva@email.com', '123.456.789-01', NULL, 'F', '(11) 99999-1111', '1985-03-15', 'M'),
('Maria Oliveira Costa', 'maria.oliveira@email.com', '987.654.321-02', NULL, 'F', '(21) 88888-2222', '1990-07-22', 'F'),
('Pedro Souza Lima', 'pedro.souza@email.com', '456.789.123-03', NULL, 'F', '(31) 77777-3333', '1988-12-10', 'M'),
('Ana Paula Ferreira', 'ana.ferreira@email.com', '789.123.456-04', NULL, 'F', '(41) 66666-4444', '1992-05-18', 'F'),
('Empresa Tech Solutions Ltda', 'contato@techsolutions.com', NULL, '12.345.678/0001-99', 'J', '(11) 5555-5555', NULL, NULL),
('Carlos Roberto Alves', 'carlos.alves@email.com', '321.654.987-05', NULL, 'F', '(51) 44444-6666', '1980-09-25', 'M'),
('Juliana Mendes Rocha', 'juliana.mendes@email.com', '654.987.321-06', NULL, 'F', '(61) 33333-7777', '1995-01-30', 'F');

-- Inserir endereços dos clientes
INSERT INTO EnderecosClientes (ClienteID, TipoEndereco, Logradouro, Numero, Complemento, Bairro, Cidade, Estado, CEP, EnderecoPrincipal) VALUES
(1, 'Residencial', 'Rua das Flores', '123', 'Apto 45', 'Centro', 'São Paulo', 'SP', '01234-567', 1),
(2, 'Residencial', 'Av. Copacabana', '456', NULL, 'Copacabana', 'Rio de Janeiro', 'RJ', '22070-001', 1),
(3, 'Residencial', 'Rua da Liberdade', '789', 'Casa 2', 'Liberdade', 'Belo Horizonte', 'MG', '30112-000', 1),
(4, 'Residencial', 'Rua XV de Novembro', '321', 'Bloco B Apto 12', 'Centro', 'Curitiba', 'PR', '80020-310', 1),
(5, 'Comercial', 'Av. Paulista', '1000', 'Sala 1501', 'Bela Vista', 'São Paulo', 'SP', '01310-100', 1),
(6, 'Residencial', 'Rua dos Andradas', '654', NULL, 'Centro Histórico', 'Porto Alegre', 'RS', '90020-007', 1),
(7, 'Residencial', 'SQN 308 Bloco A', '25', 'Apto 304', 'Asa Norte', 'Brasília', 'DF', '70747-010', 1);

-- Inserir vendas de exemplo
INSERT INTO Vendas (ClienteID, NumeroPedido, DataVenda, StatusVenda, SubTotal, ValorDesconto, ValorFrete, ValorTotal, FormaPagamento, EnderecoEntregaID, DataEntregaPrevista, Observacoes) VALUES
(1, 'PED-2024-001', '2024-01-15 10:30:00', 'Entregue', 1200.00, 0.00, 25.00, 1225.00, 'Cartão de Crédito', 1, '2024-01-20', 'Entrega rápida solicitada'),
(2, 'PED-2024-002', '2024-01-16 14:15:00', 'Enviado', 125.00, 5.00, 15.00, 135.00, 'PIX', 2, '2024-01-22', NULL),
(3, 'PED-2024-003', '2024-01-17 09:45:00', 'Confirmado', 2200.00, 100.00, 50.00, 2150.00, 'Boleto', 3, '2024-01-25', 'Pagamento à vista com desconto'),
(4, 'PED-2024-004', '2024-01-18 16:20:00', 'Entregue', 330.00, 30.00, 20.00, 320.00, 'Cartão de Débito', 4, '2024-01-23', NULL),
(5, 'PED-2024-005', '2024-01-19 11:10:00', 'Pendente', 1500.00, 0.00, 80.00, 1580.00, 'Transferência', 5, '2024-01-30', 'Aguardando confirmação do pagamento'),
(6, 'PED-2024-006', '2024-01-20 13:30:00', 'Enviado', 250.00, 0.00, 18.00, 268.00, 'PIX', 6, '2024-01-26', NULL),
(7, 'PED-2024-007', '2024-01-21 15:45:00', 'Confirmado', 60.00, 0.00, 12.00, 72.00, 'Cartão de Crédito', 7, '2024-01-28', 'Presente - embalar com cuidado');

-- Inserir itens das vendas
INSERT INTO ItensVenda (VendaID, ProdutoID, Quantidade, PrecoUnitario, PercentualDesconto, ValorDesconto, SubTotal) VALUES
-- Venda 1: Smartphone
(1, 1, 1, 1200.00, 0.00, 0.00, 1200.00),
-- Venda 2: Camiseta Polo + Calça Jeans
(2, 3, 1, 45.00, 0.00, 0.00, 45.00),
(2, 4, 1, 80.00, 6.25, 5.00, 75.00),
-- Venda 3: Notebook
(3, 2, 1, 2200.00, 4.55, 100.00, 2100.00),
-- Venda 4: Camiseta Polo + Tênis
(4, 3, 2, 45.00, 0.00, 0.00, 90.00),
(4, 7, 1, 250.00, 4.00, 10.00, 240.00),
-- Venda 5: Bicicleta
(5, 8, 1, 1500.00, 0.00, 0.00, 1500.00),
-- Venda 6: Tênis
(6, 7, 1, 250.00, 0.00, 0.00, 250.00),
-- Venda 7: Livro
(7, 6, 1, 60.00, 0.00, 0.00, 60.00);

-- Inserir movimentações de estoque (entradas iniciais)
INSERT INTO MovimentacaoEstoque (ProdutoID, TipoMovimentacao, Quantidade, QuantidadeAnterior, QuantidadeAtual, Motivo, VendaID, Usuario) VALUES
-- Entradas iniciais de estoque
(1, 'E', 50, 0, 50, 'Estoque Inicial', NULL, 'ADMIN'),
(2, 'E', 25, 0, 25, 'Estoque Inicial', NULL, 'ADMIN'),
(3, 'E', 100, 0, 100, 'Estoque Inicial', NULL, 'ADMIN'),
(4, 'E', 75, 0, 75, 'Estoque Inicial', NULL, 'ADMIN'),
(5, 'E', 10, 0, 10, 'Estoque Inicial', NULL, 'ADMIN'),
(6, 'E', 200, 0, 200, 'Estoque Inicial', NULL, 'ADMIN'),
(7, 'E', 80, 0, 80, 'Estoque Inicial', NULL, 'ADMIN'),
(8, 'E', 15, 0, 15, 'Estoque Inicial', NULL, 'ADMIN'),
-- Saídas por vendas (algumas já processadas pelo trigger)
(1, 'S', 1, 50, 49, 'Venda', 1, 'SYSTEM'),
(3, 'S', 1, 100, 99, 'Venda', 2, 'SYSTEM'),
(4, 'S', 1, 75, 74, 'Venda', 2, 'SYSTEM'),
(2, 'S', 1, 25, 24, 'Venda', 3, 'SYSTEM'),
(3, 'S', 2, 99, 97, 'Venda', 4, 'SYSTEM'),
(7, 'S', 1, 80, 79, 'Venda', 4, 'SYSTEM'),
(8, 'S', 1, 15, 14, 'Venda', 5, 'SYSTEM'),
(7, 'S', 1, 79, 78, 'Venda', 6, 'SYSTEM'),
(6, 'S', 1, 200, 199, 'Venda', 7, 'SYSTEM');

-- Inserir itens no carrinho de compras
INSERT INTO CarrinhoCompras (ClienteID, ProdutoID, Quantidade, DataAdicao) VALUES
-- Cliente 1 tem itens no carrinho
(1, 5, 1, '2024-01-22 10:15:00'), -- Mesa de Jantar
(1, 6, 2, '2024-01-22 10:20:00'), -- Livros
-- Cliente 3 tem itens no carrinho
(3, 7, 1, '2024-01-21 16:30:00'), -- Tênis
(3, 3, 3, '2024-01-21 16:35:00'), -- Camisetas
-- Cliente 4 tem itens no carrinho
(4, 8, 1, '2024-01-20 14:45:00'), -- Bicicleta
-- Cliente 6 tem itens no carrinho
(6, 1, 1, '2024-01-22 09:20:00'), -- Smartphone
(6, 4, 2, '2024-01-22 09:25:00'); -- Calças Jeans

-- Inserir avaliações dos produtos
INSERT INTO AvaliacoesProdutos (ProdutoID, ClienteID, VendaID, Nota, Comentario, DataAvaliacao, Aprovado) VALUES
-- Avaliações de produtos já entregues
(1, 1, 1, 5, 'Excelente smartphone! Muito rápido e com ótima qualidade de câmera.', '2024-01-25 14:30:00', 1),
(3, 2, 2, 4, 'Camiseta de boa qualidade, tecido macio e bom caimento.', '2024-01-28 16:45:00', 1),
(4, 2, 2, 5, 'Calça jeans perfeita! Exatamente como esperava.', '2024-01-28 16:50:00', 1),
(3, 4, 4, 4, 'Boa camiseta, mas poderia ter mais opções de cores.', '2024-01-29 10:20:00', 1),
(7, 4, 4, 5, 'Tênis muito confortável para corrida. Recomendo!', '2024-01-29 10:25:00', 1),
-- Algumas avaliações ainda não aprovadas
(1, 5, 1, 3, 'Produto bom, mas chegou com pequeno arranhão na tela.', '2024-01-26 11:15:00', 0),
(7, 6, 6, 5, 'Tênis excelente! Muito confortável e bonito.', '2024-01-30 13:40:00', 1);

PRINT '';
PRINT '============================================='; 
PRINT 'DADOS DE EXEMPLO INSERIDOS COM SUCESSO!';
PRINT '============================================='; 
PRINT 'Produtos: 8 registros inseridos';
PRINT 'Clientes: 7 registros inseridos';
PRINT 'Endereços: 7 registros inseridos';
PRINT 'Vendas: 7 registros inseridos';
PRINT 'Itens de Venda: 9 registros inseridos';
PRINT 'Movimentações de Estoque: 17 registros inseridos';
PRINT 'Carrinho de Compras: 7 registros inseridos';
PRINT 'Avaliações: 7 registros inseridos';
PRINT '';
PRINT 'O banco de dados está pronto para uso e testes!';
PRINT 'Execute as views criadas para visualizar relatórios:';
PRINT '- SELECT * FROM VW_RelatorioVendas';
PRINT '- SELECT * FROM VW_ProdutosEstoqueBaixo';
PRINT '- SELECT * FROM VW_TopProdutosMaisVendidos';