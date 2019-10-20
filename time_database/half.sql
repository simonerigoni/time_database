CREATE TABLE [time].[half]
(
	[key] INT IDENTITY(1, 1) NOT NULL
    , [id] NVARCHAR(32) NOT NULL
    , [name] NVARCHAR(128) NULL
	, [year] INT NOT NULL
    , [modified_timestamp] DATETIME NULL CONSTRAINT [DF_half_modified_timestamp] DEFAULT GETUTCDATE()
    , CONSTRAINT [PK_half_key] PRIMARY KEY ([key])
	, CONSTRAINT [AK_half_id] UNIQUE ([id])
	, CONSTRAINT [FK_half_year] FOREIGN KEY ([year]) REFERENCES [time].[year]([key]) ON DELETE CASCADE
)
