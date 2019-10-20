CREATE FUNCTION [time].[get_easter_holidays]
(
	@year INT
)
RETURNS TABLE
AS
RETURN
(
	WITH x AS 
	(
		SELECT [date] = CONVERT(DATE, RTRIM(@year) + '0' + RTRIM([month]) + RIGHT('0' + RTRIM([day]), 2))
		FROM
		(
			SELECT [month], [day] = days_to_sunday + 28 - (31 * ([month] / 4))
			FROM 
			(
				SELECT [month] = 3 + (days_to_sunday + 40) / 44, days_to_sunday
				FROM
				(
					SELECT days_to_sunday = paschal - ((@year + @year / 4 + paschal - 13) % 7)
					FROM
					(
						SELECT paschal = epact - (epact / 28)
						FROM 
						(
							SELECT epact = (24 + 19 * (@year % 19)) % 30
						) AS epact
					) AS paschal
				) AS dts
			) AS m
		) AS d
	)

	SELECT [date], [holiday_name] = N'Easter Sunday' FROM x
	UNION ALL SELECT DATEADD(DAY,-2,[date]), N'Good Friday'   FROM x
	UNION ALL SELECT DATEADD(DAY, 1,[date]), N'Easter Monday' FROM x
)