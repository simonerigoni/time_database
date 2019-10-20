CREATE PROCEDURE [time].[initialize]
	@start_date DATE = N'20000101'
	, @number_of_years INT = 1
	, @country_holiday NVARCHAR(3) = N'ITA'
	, @debug BIT = 0
AS
	/* based on https://www.mssqltips.com/sqlservertip/4054/creating-a-date-dimension-or-calendar-table-in-sql-server/ */

	-- prevent set or regional settings from interfering with interpretation of dates / literals

	SET NOCOUNT ON
	SET DATEFIRST 7
	SET DATEFORMAT mdy
	SET LANGUAGE US_ENGLISH

	IF @start_date = N'20000101'
		SET @start_date = CAST(YEAR(GETUTCDATE()) AS NVARCHAR) + N'0101'

	DECLARE @state INT = 16
		, @severity INT =1
		, @message NVARCHAR(MAX)
		, @sql NVARCHAR(MAX)
		, @cut_off_date DATE = DATEADD(YEAR, @number_of_years, @start_date)

	IF @country_holiday NOT IN (N'ITA', N'USA')
	BEGIN
		SET @message = N'Error: ' + @country_holiday + N'not implemented'
		RAISERROR(@message, @state, @severity)
	END

	-- this is just a holding table for intermediate calculations

	DROP TABLE IF EXISTS [dbo].[#dimension]

	CREATE TABLE [dbo].[#dimension]
	(
		[date] DATE PRIMARY KEY
		, [day] AS DATEPART(DAY, [date])
		, [month] AS DATEPART(MONTH, [date])
		, [first_of_month] AS CONVERT(DATE, DATEADD(MONTH, DATEDIFF(MONTH, 0, [date]), 0))
		, [month_name] AS DATENAME(MONTH, [date])
		, [week] AS DATEPART(WEEK, [date])
		, [ISO_week] AS DATEPART(ISO_WEEK, [date])
		, [day_of_week] AS DATEPART(WEEKDAY, [date])
		, [quarter] AS DATEPART(QUARTER, [date])
		, [year] AS DATEPART(YEAR, [date])
		, [first_of_year] AS CONVERT(DATE, DATEADD(YEAR, DATEDIFF(YEAR, 0, [date]), 0))
		, [style_112] AS CONVERT(CHAR(8), [date], 112)
		, [style_101] AS CONVERT(CHAR(10), [date], 101)
	)

	INSERT [dbo].[#dimension]([date])
	SELECT D
	FROM
	(
		SELECT D = DATEADD(DAY, rn - 1, @start_date)
		FROM 
		(
			SELECT TOP (DATEDIFF(DAY, @start_date, @cut_off_date)) rn = ROW_NUMBER() OVER (ORDER BY S1.[object_id])
			FROM [sys].[all_objects] AS S1
			CROSS JOIN [sys].[all_objects] AS S2
			-- on my system this would support > 5 million days
			ORDER BY S1.[object_id]
		) AS X
	) AS Y

	--SELECT * FROM [dbo].[#dimension]

	DROP TABLE IF EXISTS [dbo].[date_dimension]

	CREATE TABLE [dbo].[date_dimension]
	(
		[date] DATE NOT NULL
		, [day] TINYINT NOT NULL
		, [day_suffix] CHAR(2) NOT NULL
		, [weekday] TINYINT NOT NULL
		, [weekday_name] VARCHAR(10) NOT NULL
		, [is_weekend] BIT NOT NULL
		, [is_holiday] BIT NOT NULL
		, [holiday_text] VARCHAR(64) SPARSE
		, [DOW_in_month] TINYINT NOT NULL
		, [day_of_year] SMALLINT NOT NULL
		, [week_of_month] TINYINT NOT NULL
		, [week_of_year] TINYINT NOT NULL
		, [ISO_week_of_year] TINYINT NOT NULL
		, [month] TINYINT NOT NULL
		, [month_name] VARCHAR(10) NOT NULL
		, [quarter] TINYINT NOT NULL
		, [quarter_name] VARCHAR(6)  NOT NULL
		, [year] INT NOT NULL
		, [MMYYYY] CHAR(6) NOT NULL
		, [month_year] CHAR(7) NOT NULL
		, [first_day_of_month] DATE NOT NULL
		, [last_day_of_month] DATE NOT NULL
		, [first_day_of_quarter] DATE NOT NULL
		, [last_day_of_quarter] DATE NOT NULL
		, [first_day_of_year] DATE NOT NULL
		, [last_day_of_year] DATE NOT NULL
		, [first_day_of_next_month] DATE NOT NULL
		, [first_day_of_next_year] DATE NOT NULL
	)

	INSERT [dbo].[date_dimension] WITH (TABLOCKX)
	SELECT [date] = [date]
		, [day] = CONVERT(TINYINT, [day])
		, [day_suffix] = CONVERT(CHAR(2), CASE
											WHEN [day] / 10 = 1 THEN N'th'
											ELSE 
												CASE RIGHT([day], 1) 
													WHEN N'1' THEN N'st' 
													WHEN N'2' THEN N'nd' 
													WHEN N'3' THEN N'rd' 
													ELSE N'th' 
												END
											END)	
		, [weekday] = CONVERT(TINYINT, [day_of_week])
		, [weekday_name] = CONVERT(VARCHAR(10), DATENAME(WEEKDAY, [date]))
		, [is_weekend] = CONVERT(BIT, CASE WHEN [day_of_Week] IN (1,7) THEN 1 ELSE 0 END)
		, [is_holiday] = CONVERT(BIT, 0)
		, [holiday_text] = CONVERT(VARCHAR(64), NULL)
		, [DOW_in_month] = CONVERT(TINYINT, ROW_NUMBER() OVER (PARTITION BY [first_of_month], [day_of_week] ORDER BY [date]))
		, [day_of_year] = CONVERT(SMALLINT, DATEPART(DAYOFYEAR, [date]))
		, [week_of_month] = CONVERT(TINYINT, DENSE_RANK() OVER (PARTITION BY [year], [month] ORDER BY [week]))
		, [week_of_year] = CONVERT(TINYINT, [Week])
		, [ISO_week_of_year] = CONVERT(TINYINT, [ISO_week])
		, [month] = CONVERT(TINYINT, [Month])
		, [month_name] = CONVERT(VARCHAR(10), [month_name])
		, [quarter] = CONVERT(TINYINT, [Quarter])
		, [quarter_name] = CONVERT(VARCHAR(6), CASE [quarter] 
													WHEN 1 THEN N'First'
													WHEN 2 THEN N'Second'
													WHEN 3 THEN N'Third'
													WHEN 4 THEN N'Fourth' 
												END)
		, [year] = [year]
		, [MMYYYY] = CONVERT(CHAR(6), LEFT([style_101], 2) + LEFT([style_112], 4))
		, [month_year] = CONVERT(CHAR(7), LEFT([month_name], 3) + LEFT([style_112], 4))
		, [first_day_of_month] = [first_of_month]
		, [last_day_of_month] = MAX([date]) OVER (PARTITION BY [year], [month])
		, [first_day_of_quarter] = MIN([date]) OVER (PARTITION BY [year], [quarter])
		, [last_day_of_quarter] = MAX([date]) OVER (PARTITION BY [year], [quarter])
		, [first_day_of_Year] = [first_of_year]
		, [last_day_of_year] = MAX([date]) OVER (PARTITION BY [year])
		, [first_day_of_next_month] = DATEADD(MONTH, 1, [first_of_month])
		, [first_day_of_next_year] = DATEADD(YEAR,  1, [first_of_year])
	FROM [dbo].[#dimension]
	OPTION (MAXDOP 1)

	--SELECT * FROM [dbo].[date_dimension]

	--UPDATE [dbo].[date_dimension] with country holiday
	SET @sql = N'
;WITH X AS 
(
	SELECT [date]
		, [is_holiday]
		, [holiday_text]
		, [first_day_of_year]
		, [DOW_in_month]
		, [month_name]
		, [weekday_name]
		, [day]
		, [last_DOW_in_month] = ROW_NUMBER() OVER 
		(
			PARTITION BY [first_day_of_month], [weekday] 
			ORDER BY [date] DESC
		)
	FROM [dbo].[date_dimension]
)
'

	IF @country_holiday = N'ITA'
	BEGIN
		SET @sql = @sql + N'
UPDATE X SET [is_holiday] = 1
	, [holiday_text] = CASE
		WHEN ([date] = [first_day_of_year]) THEN N''New Year Day'' -- January 1st
		WHEN ([month_name] = N''January'' AND [day] = 6) THEN N''Epiphany'' -- January 6th
		WHEN ([month_name] = N''April'' AND [day] = 25) THEN N''Liberation Day'' -- April 5th
		WHEN ([month_name] = N''May'' AND [day] = 1) THEN N''Labour Day'' -- May 1st
		WHEN ([month_name] = N''June'' AND [day] = 2) THEN N''Republic Day'' -- June 2nd
		WHEN ([month_name] = N''August'' AND [day] = 15) THEN N''Assumption of the Virgin Mary Day'' -- August 15th
		WHEN ([month_name] = N''November'' AND [day] = 1) THEN N''All Saints Day'' -- November 1st
		WHEN ([month_name] = N''December'' AND [day] = 8) THEN N''Immaculate Conception Day'' -- December 8th
		WHEN ([month_name] = N''December'' AND [day] = 25) THEN N''Christmas Day'' -- December 25th
		WHEN ([month_name] = N''December'' AND [day] = 26) THEN N''Saint Stephen Day'' -- December 26th
	END
WHERE ([date] = [first_day_of_year])
	OR ([month_name] = N''January'' AND [day] = 6)
	OR ([month_name] = N''April'' AND [day] = 25)
	OR ([month_name] = N''May'' AND [day] = 1)
	OR ([month_name] = N''June'' AND [day] = 2)
	OR ([month_name] = N''August'' AND [day] = 15)
	OR ([month_name] = N''November'' AND [day] = 1)
	OR ([month_name] = N''December'' AND [day] = 8)
	OR ([month_name] = N''December'' AND [day] = 25)
	OR ([month_name] = N''December'' AND [day] = 26)
'
	END
	ELSE --IF @country_holiday = N'USA'
	BEGIN
		SET @sql = @sql + N'
UPDATE X SET [is_holiday] = 1
	, [holiday_text] = CASE
		WHEN ([date] = [first_day_of_year]) THEN N''New Year Day'' -- January 1st
		WHEN ([DOW_in_month] = 3 AND [month_name] = N''January'' AND [weekday_name] = N''Monday'') THEN N''Martin Luther King Day'' -- 3rd Monday in January
		WHEN ([DOW_in_month] = 3 AND [month_name] = N''February'' AND [weekday_name] = N''Monday'') THEN N''President Day'' -- 3rd Monday in February
		WHEN ([last_DOW_in_month] = 1 AND [month_name] = N''May'' AND [weekday_name] = N''Monday'') THEN N''Memorial Day'' -- last Monday in May
		WHEN ([month_name] = N''July'' AND [day] = 4) THEN N''Independence Day'' -- July 4th
		WHEN ([DOW_in_month] = 1 AND [month_name] = N''September'' AND [weekday_name] = N''Monday'') THEN N''Labour Day'' -- first Monday in September
		WHEN ([DOW_in_month] = 2 AND [month_name] = N''October'' AND [weekday_name] = N''Monday'') THEN N''Columbus Day'' -- second Monday in October
		WHEN ([month_name] = N''November'' AND [day] = 11) THEN N''Veterans Day'' -- November 11th
		WHEN ([DOW_in_month] = 4 AND [month_name] = N''November'' AND [weekday_name] = N''Thursday'') THEN N''Thanksgiving Day'' -- fourth Thursday in November
		WHEN ([month_name] = N''December'' AND [day] = 25) THEN N''Christmas Day''
	END
WHERE ([date] = [first_day_of_year])
		OR ([DOW_in_month] = 3 AND [month_name] = N''January'' AND [weekday_name] = N''Monday'')
		OR ([DOW_in_month] = 3 AND [month_name] = N''February'' AND [weekday_name] = N''Monday'')
		OR ([last_DOW_in_month] = 1 AND [month_name] = N''May'' AND [weekday_name] = N''Monday'')
		OR ([month_name] = N''July'' AND [day] = 4)
		OR ([DOW_in_month] = 1 AND [month_name] = N''September'' AND [weekday_name] = N''Monday'')
		OR ([DOW_in_month] = 2 AND [month_name] = N''October'' AND [weekday_name] = N''Monday'')
		OR ([month_name] = N''November'' AND [day] = 11)
		OR ([DOW_in_month] = 4 AND [month_name] = N''November'' AND [weekday_name] = N''Thursday'')
		OR ([month_name] = N''December'' AND [day] = 25)
'
	END

	EXECUTE sp_executesql @sql

	--UPDATE [dbo].[date_dimension] with Easter holidays

	;WITH X AS 
	(
		SELECT D.[date]
			, D.[is_holiday]
			, D.[holiday_text]
			, H.[holiday_name]
		FROM [dbo].[date_dimension] D
		CROSS APPLY [time].[get_easter_holidays](d.[year]) H
		WHERE D.[date] = H.[date]
	)

	UPDATE X SET [is_holiday] = 1
		, [holiday_text] = [holiday_name]

	--UPDATE with USA shopping holiday (It is a working day so [IsHoliday] = 0 even if it has [HolidayText] not NULL)

	IF @country_holiday = N'USA'
	BEGIN
		UPDATE D SET [is_holiday] = 0
			, [holiday_text] = N'Black Friday'
		FROM [dbo].[date_dimension] D
		INNER JOIN
		(
			SELECT [date]
				, [year]
				, [day_of_year]
			FROM [dbo].[date_dimension] 
			WHERE [holiday_text] = N'Thanksgiving Day'
		) AS SRC 
		ON D.[year] = SRC.[year] 
			AND D.[day_of_year] = SRC.[day_of_year] + 1
	END

	--SELECT * FROM [dbo].[date_dimension]

	SET @sql = N'
MERGE [time].[year] AS T
USING 
(
	SELECT CAST(D.[year] AS NVARCHAR(32)) AS [id]
		, CAST(D.[year] AS NVARCHAR(128)) AS [name]	
	FROM  [dbo].[date_dimension] D
	GROUP BY D.[year]
) AS S
ON (T.[id] = S.[id])
WHEN MATCHED THEN  
	UPDATE SET T.[name] = S.[name] 
WHEN NOT MATCHED BY TARGET THEN
	INSERT ([id], [name]) 
	VALUES (S.[id], S.[name])
WHEN NOT MATCHED BY SOURCE THEN
	DELETE
;
MERGE [time].[half] AS T
USING 
(
	SELECT Y.[key] AS [year]
		, CONCAT(D.[year], N''0'', D.[half]) AS [id]
		, CONCAT(N''H'', D.[half], N'' '', D.[year]) AS [name]
	FROM
	(
		SELECT D.[year],
			D.[half]
		FROM
		(
			SELECT D.[year]
				, CASE 
					WHEN D.[quarter] <= 2 THEN 1
					ELSE 2
				END AS [half]
				, D.[quarter]
			FROM [dbo].[date_dimension] D
			GROUP BY D.[year], D.[quarter]
		) D
		GROUP BY D.[year], D.[half]
	)D
	INNER JOIN [time].[year] Y
		ON D.[year] = Y.[id]
) AS S
ON (T.[id] = S.[id])
WHEN MATCHED THEN  
	UPDATE SET T.[name] = S.[name] 
WHEN NOT MATCHED BY TARGET THEN
	INSERT ([id], [name], [year]) 
	VALUES (S.[id], S.[name], S.[year])
WHEN NOT MATCHED BY SOURCE THEN
	DELETE
;
MERGE [time].[quarter] AS T
USING 
(
	SELECT H.[key] AS [half]
		, CONCAT(D.[year], N''0'', D.[quarter]) AS [id]
		, CONCAT(N''Q'', D.[quarter], N'' '', D.[Year]) AS [name]
	FROM
	(
		SELECT D.[year]
			, CONCAT( D.[year], N''0'', D.[half]) AS [half]
			, D.[quarter]
		FROM
		(
			SELECT D.[year]
				, CASE 
					WHEN D.[quarter] <= 2 THEN 1 
					ELSE 2
				END AS [half]
				, D.[quarter]
			FROM [dbo].[date_dimension] D
			GROUP BY D.[year], D.[quarter]
		) D
	)D
	INNER JOIN [time].[half] H
		ON D.[half] = H.[id]
) AS S
ON (T.[id] = S.[id])
WHEN MATCHED THEN  
	UPDATE SET T.[name] = S.[name] 
WHEN NOT MATCHED BY TARGET THEN
	INSERT ([id], [name], [half]) 
	VALUES (S.[id], S.[name], S.[half])
WHEN NOT MATCHED BY SOURCE THEN
	DELETE
;
MERGE [time].[month] AS T
USING 
(
	SELECT Q.[key] AS [quarter]
		, CASE
			WHEN D.[month] <= 9 
				THEN CONCAT(D.[year], N''0'', D.[month])
				ELSE CONCAT(D.[year], D.[month])
		END AS [id]
		, CONCAT(D.[month_name], N'' '', D.[year]) AS [name]
	FROM
	(
		SELECT D.[year]
			, CONCAT( D.[year], N''0'', D.[quarter]) AS [quarter]
			, D.[month]
			, D.[month_name]
		FROM
		(
			SELECT D.[year]
				, D.[quarter]
				, D.[month]
				, D.[month_name]
			FROM [dbo].[date_dimension] D
			GROUP BY D.[year], D.[quarter], D.[month], D.[month_name]
		) D
	)D
	INNER JOIN [time].[quarter] Q
		ON D.[quarter] = Q.[id]
) AS S
ON (T.[id] = S.[id])
WHEN MATCHED THEN  
	UPDATE SET T.[name] = S.[name] 
WHEN NOT MATCHED BY TARGET THEN
	INSERT ([id], [name], [quarter]) 
	VALUES (S.[id], S.[name], S.[quarter])
WHEN NOT MATCHED BY SOURCE THEN
	DELETE
;
MERGE [time].[week] AS T
USING 
(
	SELECT M.[key] AS [month]
		, CASE
			WHEN D.[week_of_year] <= 9 
				THEN CONCAT( D.[month], N''0'', D.[week_of_year])
				ELSE CONCAT( D.[month], D.[week_of_year])
		END AS [id]
		, CONCAT(N''W'',D.[week_of_year], N'' '', D.[year]) AS [name]
	FROM
	(
		SELECT D.[year]
			, D.[month]
			, D.[week_of_year]
		FROM
		(
			SELECT D.[year]
				, CASE
					WHEN D.[month] <= 9 
						THEN CONCAT( D.[year], N''0'', D.[month])
						ELSE CONCAT( D.[year], D.[month])
				END AS [month]
				, D.[week_of_year]
			FROM [dbo].[date_dimension] D
			GROUP BY D.[year], D.[quarter], D.[month], D.[week_of_year]
		) D
	)D
	INNER JOIN [time].[month] M
		ON D.[month] = M.[id]
) AS S
ON (T.[id] = S.[id])
WHEN MATCHED THEN  
	UPDATE SET T.[name] = S.[name] 
WHEN NOT MATCHED BY TARGET THEN
	INSERT ([id], [name], [month]) 
	VALUES (S.[id], S.[name], S.[month])
WHEN NOT MATCHED BY SOURCE THEN
	DELETE
;
MERGE [time].[Day] AS T
USING 
(
	SELECT W.[key] AS [week]
		, CASE
			WHEN D.[day] <= 9 
				THEN CONCAT( D.[month], N''0'', D.[day])
				ELSE CONCAT( D.[month], D.[day])
		END AS [id]
		, CONCAT( D.[day], D.[day_suffix], N'' '', D.[month_name], N'' '', D.[year]) AS [name]
		, [weekday]
		, [is_weekend]
		, [holiday_text] AS [holiday_name]
	FROM
	(
		SELECT D.[year]
			, D.[month]
			, D.[month_name]
			, CASE
				WHEN D.[week_of_year] <= 9 
					THEN CONCAT(D.[month], N''0'', D.[week_of_year])
					ELSE CONCAT(D.[month], D.[week_of_year])
			END AS [week]
			, D.[day]
			, D.[day_suffix]
			, D.[weekday]
			, D.[is_weekend]
			, D.[holiday_text]
		FROM
		(
			SELECT D.[year]
				, CASE
					WHEN D.[month] <= 9 
						THEN CONCAT(D.[year], N''0'', D.[month])
						ELSE CONCAT(D.[year], D.[month])
				END AS [month]
				, D.[month_name]
				, D.[week_of_year]
				, D.[day]
				, D.[day_suffix]
				, D.[weekday]
				, D.[is_weekend]
				, D.[holiday_text]
			FROM [dbo].[date_dimension] D
			GROUP BY D.[year], D.[quarter], D.[month], D.[month_name], D.[week_of_year], D.[day], D.[day_suffix], D.[weekday], D.[is_weekend], D.[holiday_text]
		) D
	)D
	INNER JOIN [time].[week] W
		ON D.[week] = W.[id]
) AS S
ON (T.[id] = S.[id])
WHEN MATCHED THEN  
	UPDATE SET T.[name] = S.[name]
		, T.[weekday] = S.[weekday]
		, T.[is_weekend] = S.[is_weekend]
		, T.[holiday_name] = S.[holiday_name]
WHEN NOT MATCHED BY TARGET THEN
	INSERT ([id], [name], [week], [weekday], [is_weekend], [holiday_name]) 
	VALUES (S.[id], S.[name], S.[week], S.[weekday], S.[is_weekend], S.[holiday_name])
WHEN NOT MATCHED BY SOURCE THEN
	DELETE
;
'

	IF @debug = 0
	BEGIN
		EXECUTE sp_executesql @sql
		DROP TABLE [dbo].[date_dimension]
		DROP TABLE [#dimension]
	END
	ELSE
	BEGIN
		EXECUTE [dbo].[PRINT] @sql
	END

	SET NOCOUNT OFF