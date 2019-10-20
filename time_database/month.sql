CREATE TABLE [time].[month]
(
	[key] INT IDENTITY(1, 1) NOT NULL
    , [id] NVARCHAR(32) NOT NULL
    , [name] NVARCHAR(128) NULL
	, [quarter] INT NOT NULL
    , [modified_timestamp] DATETIME NULL CONSTRAINT [DF_month_modified_timestamp] DEFAULT GETUTCDATE()
    , CONSTRAINT [PK_month_key] PRIMARY KEY ([key])
	, CONSTRAINT [AK_month_id] UNIQUE ([id])
	, CONSTRAINT [FK_month_quarter] FOREIGN KEY ([quarter]) REFERENCES [time].[quarter]([key]) ON DELETE CASCADE
)
