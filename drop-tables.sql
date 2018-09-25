use NetworkDrives;

-- Drop the table 'DriveMapping' in schema 'dbo'
IF EXISTS (
    SELECT *
        FROM sys.tables
        JOIN sys.schemas
            ON sys.tables.schema_id = sys.schemas.schema_id
    WHERE sys.schemas.name = N'dbo'
        AND sys.tables.name = N'DriveMapping'
)
    DROP TABLE dbo.DriveMapping
GO

-- Drop the table 'UNCPath' in schema 'dbo'
IF EXISTS (
    SELECT *
        FROM sys.tables
        JOIN sys.schemas
            ON sys.tables.schema_id = sys.schemas.schema_id
    WHERE sys.schemas.name = N'dbo'
        AND sys.tables.name = N'UNCPath'
)
    DROP TABLE dbo.UNCPath
GO

-- Drop the table 'User' in schema 'dbo'
IF EXISTS (
    SELECT *
        FROM sys.tables
        JOIN sys.schemas
            ON sys.tables.schema_id = sys.schemas.schema_id
    WHERE sys.schemas.name = N'dbo'
        AND sys.tables.name = N'User'
)
    DROP TABLE dbo.[User]
GO