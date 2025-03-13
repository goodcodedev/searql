-- Lowercase, and replace tabs and newlines with a space.
WITH Input AS (
	SELECT String, Length
	FROM (SELECT LOWER('Ta  hensyn   til menns og kvinners biologiske trekk, samt kontinuerlig endrede sosiale og kulturelle trekk gjennom hele forskningsprosessen (kjønn).') AS String) AS i
	CROSS APPLY (SELECT LEN(String) AS Length) calc
),
-- Collect start and end position of words
InputWord (Word, Rest, WordPos) AS (
	SELECT
		CASE SpaceIndex WHEN 0 THEN String ELSE LEFT(String, SpaceIndex - 1) END AS Word,
		CASE SpaceIndex WHEN 0 THEN '' ELSE SUBSTRING(String, SpaceIndex + 1, LEN(String) - SpaceIndex) END AS Rest,
		1 as WordPos
	FROM Input
	CROSS APPLY (SELECT CHARINDEX(' ', String, 1) AS SpaceIndex) AS Calc
	UNION ALL
	SELECT
		CASE SpaceIndex WHEN 0 THEN prev.Rest ELSE LEFT(prev.Rest, SpaceIndex - 1) END AS Word,
		CASE SpaceIndex WHEN 0 THEN '' ELSE SUBSTRING(prev.Rest, SpaceIndex + 1, LEN(prev.Rest) - SpaceIndex) END AS Rest,
		prev.WordPos + 1 AS WordPos
	FROM InputWord prev
	CROSS APPLY (SELECT CHARINDEX(' ', prev.Rest, 1) AS SpaceIndex) AS Calc
	WHERE Rest <> ''
)/*,
Chars AS (
	SELECT SUBSTRING(String, 1, 1) AS Char, FilteredChar, 1 AS CurPos, String, Length
	FROM InputWord
	WHERE InputWord.String) > 0
	CROSS APPLY (
	) AS calc
	UNION ALL
	SELECT SUBSTRING(String, CurPos + 1, 1) AS Char, CurPos + 1, String, Length
	FROM InputWord
	WHERE CurPos < Length
),*/

SELECT * FROM InputWord
option (maxrecursion 2000)