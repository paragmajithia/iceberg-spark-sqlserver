SELECT 1
GO

IF NOT EXISTS(SELECT 1 FROM sys.databases WHERE name='product-db')
BEGIN
    PRINT '=================   Creating product db database ===================='
    CREATE DATABASE [product-db]
END
ELSE
BEGIN
    PRINT '=================   product-db database already exists ===================='
END
GO

USE [product-db];
GO

IF OBJECT_ID('product', 'U') IS NOT NULL
BEGIN
    PRINT '=================   product Table exists ===================='
END
ELSE
BEGIN
    PRINT '===================== Creating Product table ======================'

    CREATE TABLE product (
        Id INT NOT NULL IDENTITY(1,1),
        Name TEXT NOT NULL,
        Description TEXT NOT NULL,
        PRIMARY KEY (Id)
    );
END
GO


PRINT '===================== Inserting data into table ======================'
IF NOT EXISTS (SELECT Name FROM product WHERE CONVERT(varchar, name) in ('T-Shirt RED' , 'T-Shirt Pink') )
BEGIN
    INSERT INTO [product] (Name, Description)
    VALUES 
    ('T-Shirt RED', 'Its RED'),
    ('T-Shirt Pink', 'Its Pink'); 
END
ELSE
BEGIN
    PRINT '===================== Skipping insertion as row already exists'
END
GO

