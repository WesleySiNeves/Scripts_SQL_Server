CREATE TABLE dbo.dim
(
    id INT NOT NULL PRIMARY KEY
);
GO

CREATE TABLE dbo.fact
(
    id      INT NOT NULL,
    dimid   INT,
    measure INT
);
GO

CREATE CLUSTERED COLUMNSTORE INDEX idx_col ON dbo.fact;
GO

ALTER TABLE dbo.fact ADD CONSTRAINT pk_fact PRIMARY KEY(id);
GO

ALTER TABLE dbo.fact
ADD CONSTRAINT fk_fact_dim FOREIGN KEY(dimid)REFERENCES dbo.dim(id);
GO