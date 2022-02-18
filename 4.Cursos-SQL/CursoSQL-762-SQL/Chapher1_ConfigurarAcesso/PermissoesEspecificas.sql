
SELECT * FROM  Sales.Orders AS O

GRANT SELECT ON Sales.Orders TO Isabelle;

DENY SELECT ON Sales.Orders TO Isabelle;

GRANT DELETE ON Sales.Orders TO Isabelle;


DENY DELETE ON Sales.Orders TO Isabelle;
GO
GRANT UPDATE ON Sales.Orders (InternalComments) TO Isabelle;
GO
GRANT UPDATE ON Sales.Orders (DeliveryInstructions) TO Isabelle;
GO
GRANT UPDATE ON Sales.Orders (Comments) TO Isabelle;
GO