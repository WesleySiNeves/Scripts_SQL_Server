SELECT *,
sys.fn_PhysLocFormatter(%%physloc%%) AS FisicalLocation
 FROM  Sales.Customers AS C