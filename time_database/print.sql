CREATE PROCEDURE [dbo].[print]
	@message NVARCHAR(MAX)
AS
	PRINT CAST(@message AS NTEXT)
