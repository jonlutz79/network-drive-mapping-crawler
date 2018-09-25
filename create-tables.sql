use NetworkDrives;

-- Create a new table called 'User' in schema 'dbo'
-- Drop the table if it already exists
IF OBJECT_ID('dbo.User', 'U') IS NOT NULL
DROP TABLE dbo.[User]
GO
-- Create the table in the specified schema
CREATE TABLE dbo.[User]
(
    UserID INT NOT NULL IDENTITY PRIMARY KEY, -- primary key column
    Username [NVARCHAR](50) NOT NULL
);
GO

-- Create a new table called 'UNCPath' in schema 'dbo'
-- Drop the table if it already exists
IF OBJECT_ID('dbo.UNCPath', 'U') IS NOT NULL
DROP TABLE dbo.UNCPath
GO
-- Create the table in the specified schema
CREATE TABLE dbo.UNCPath
(
    UNCPathID INT NOT NULL IDENTITY PRIMARY KEY, -- primary key column
    UNCPath [NVARCHAR](260) NOT NULL,
);
GO

-- Create a new table called 'DriveMapping' in schema 'dbo'
-- Drop the table if it already exists
IF OBJECT_ID('dbo.DriveMapping', 'U') IS NOT NULL
DROP TABLE dbo.DriveMapping
GO
-- Create the table in the specified schema
CREATE TABLE dbo.DriveMapping
(
    DriveMappingID INT NOT NULL IDENTITY PRIMARY KEY, -- primary key column
    UserID INT REFERENCES [User] (UserID),
    DriveLetter NVARCHAR(1) NOT NULL,
    --DriveLetterID INT REFERENCES DriveLetter (DriveLetterID),
    UNCPathID INT REFERENCES UNCPath (UNCPathID),
    IsActive BIT
);
GO