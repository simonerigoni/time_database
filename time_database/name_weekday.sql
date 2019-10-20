CREATE VIEW [time].[name_weekday]
AS
	SELECT	1 AS [id], 'Sunday' AS [name]
	UNION ALL SELECT 2 AS [id], 'Monday' AS [name]
	UNION ALL SELECT 3 AS [id], 'Tuesday' AS [name]
	UNION ALL SELECT 4 AS [id], 'Wednesday' AS [name]
	UNION ALL SELECT 5 AS [id], 'Thursday' AS [name]
	UNION ALL SELECT 6 AS [id], 'Friday' AS [name]
	UNION ALL SELECT 7 AS [id], 'Saturday' AS [name]
