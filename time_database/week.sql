CREATE TABLE [time].[week]
(
	[key] INT IDENTITY(1, 1) NOT NULL
    , [id] NVARCHAR(32) NOT NULL
    , [name] NVARCHAR(128) NULL
	, [month] INT NOT NULL
    , [modified_timestamp] DATETIME NULL CONSTRAINT [DF_week_modified_timestamp] DEFAULT GETUTCDATE()
    , CONSTRAINT [PK_week_key] PRIMARY KEY ([key])
	, CONSTRAINT [AK_week_id] UNIQUE ([id])
	, CONSTRAINT [FK_week_month] FOREIGN KEY ([month]) REFERENCES [time].[month]([key]) ON DELETE CASCADE
)
