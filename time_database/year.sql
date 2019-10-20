CREATE TABLE [time].[year]
(
	[key] INT IDENTITY(1, 1) NOT NULL
    , [id] NVARCHAR(32) NOT NULL
    , [name] NVARCHAR(128) NULL
    , [modified_timestamp] DATETIME NULL CONSTRAINT [DF_year_modified_timestamp] DEFAULT GETUTCDATE()
    , CONSTRAINT [PK_year_key] PRIMARY KEY ([key])
	, CONSTRAINT [AK_year_id] UNIQUE ([id])
)
