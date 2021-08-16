USE AdventureWorksDW2019
IF OBJECT_ID(N'tempdb..#CoreTable') IS NOT NULL
BEGIN
DROP TABLE #CoreTable
END
GO

SELECT CProd.EnglishProductCategoryName,
SProd.EnglishProductSubcategoryName, 
Prod.EnglishProductName,
CONCAT(CUS.FirstName,' ',CUS.LastName) 'CustomerName',
CUR.CurrencyName,
DSR.SalesReasonName,
ST.SalesTerritoryCountry,
ST.SalesTerritoryRegion,
ST.SalesTerritoryGroup,
DT.FullDateAlternateKey 'ORDER_DATE',
SUM (Isales.OrderQuantity) 'OrderQuantity',
SUM(Isales.TotalProductCost) 'TotalProductCost',
SUM(Isales.SalesAmount) 'SalesAmount',
SUM(Isales.TaxAmt) 'TaxAmt',
SUM(Isales.TotalProductCost)/SUM(Isales.SalesAmount) '%Profit'
INTO #CoreTable
FROM FactInternetSales Isales
LEFT JOIN DimProduct Prod ON Prod.ProductKey=Isales.ProductKey
LEFT JOIN DimProductSubcategory SProd ON Prod.ProductSubcategoryKey = SProd.ProductSubcategoryKey
LEFT JOIN DimProductCategory CProd ON SProd.ProductCategoryKey = CProd.ProductCategoryKey
INNER JOIN DimDate DT ON DT.DateKey = Isales.OrderDateKey
LEFT JOIN DimCurrency Cur ON Cur.CurrencyKey = Isales.CurrencyKey
LEFT JOIN FactInternetSalesReason ISalesR on ISalesR.SalesOrderNumber= Isales.SalesOrderNumber 
		AND ISalesR.SalesOrderLineNumber=Isales.SalesOrderLineNumber
LEFT JOIN DimSalesReason DSR ON DSR.SalesReasonKey=ISalesR.SalesReasonKey
LEFT JOIN DimCustomer CUS ON CUS.CustomerKey=Isales.CustomerKey
LEFT JOIN DimSalesTerritory ST ON ST.SalesTerritoryKey=Isales.SalesTerritoryKey
GROUP BY CProd.EnglishProductCategoryName,
SProd.EnglishProductSubcategoryName, 
Prod.EnglishProductName,
CONCAT(CUS.FirstName,' ',CUS.LastName),
CUR.CurrencyName,
DSR.SalesReasonName,
ST.SalesTerritoryCountry,
ST.SalesTerritoryRegion,
ST.SalesTerritoryGroup,
DT.FullDateAlternateKey
;
/*GET ALL CUSTOMER FROM NORTH AMERICA FROM 
2013
*/
DECLARE @YEAR_ORDER_DATE DATE
SET @YEAR_ORDER_DATE = '2013'
DECLARE @CUSTOMER_GROUP NVARCHAR(MAX)
SET @CUSTOMER_GROUP ='North America'


SELECT EnglishProductCategoryName 'ProductCategoryName',
EnglishProductSubcategoryName 'ProductSubcategoryName',
DATEPART(MM,ORDER_DATE) AS 'Month',
SUM(SalesAmount) AS 'SalesAmount',
SUM(SUM(SalesAmount)) OVER (PARTITION BY EnglishProductSubcategoryName) 'TotalSales_SubCategory',
SUM(SUM(SalesAmount)) OVER (PARTITION BY DATEPART(MM,ORDER_DATE)) 'TotalSales_Month'
FROM #CoreTable
WHERE SalesTerritoryGroup = @CUSTOMER_GROUP
AND CONVERT(DATE,ORDER_DATE) >= CONVERT(DATE,@YEAR_ORDER_DATE)
GROUP BY EnglishProductCategoryName ,
EnglishProductSubcategoryName ,
DATEPART(MM,ORDER_DATE)
ORDER BY ProductCategoryName,EnglishProductSubcategoryName