CREATE TABLE [time].[day]
(
	[key] INT IDENTITY(1, 1) NOT NULL
    , [id] NVARCHAR(32) NOT NULL
    , [name] NVARCHAR(128) NULL
	, [week] INT NOT NULL
	, [weekday] INT NOT NULL
	, [is_weekend] BIT NOT NULL DEFAULT 0
	, [holiday_name] NVARCHAR(128) NULL
    , [modified_timestamp] DATETIME NULL CONSTRAINT [DF_day_modified_timestamp] DEFAULT GETUTCDATE()
    , CONSTRAINT [PK_day_key] PRIMARY KEY ([key])
	, CONSTRAINT [AK_day_id] UNIQUE ([id])
	, CONSTRAINT [FK_day_week] FOREIGN KEY ([week]) REFERENCES [time].[week]([key]) ON DELETE CASCADE
	, CONSTRAINT [CK_day_week_day] CHECK ( [weekday] >= 1 AND [weekday] <= 7)
)
