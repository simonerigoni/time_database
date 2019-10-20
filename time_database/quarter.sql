CREATE TABLE [time].[quarter]
(
	[key] INT IDENTITY(1, 1) NOT NULL
    , [id] NVARCHAR(32) NOT NULL
    , [name] NVARCHAR(128) NULL
	, [half] INT NOT NULL
    , [modified_timestamp] DATETIME NULL CONSTRAINT [DF_quarter_modified_timestamp] DEFAULT GETUTCDATE()
    , CONSTRAINT [PK_quarter_key] PRIMARY KEY ([key])
	, CONSTRAINT [AK_quarter_id] UNIQUE ([id])
	, CONSTRAINT [FK_quarter_year] FOREIGN KEY ([half]) REFERENCES [time].[half]([key]) ON DELETE CASCADE
)
