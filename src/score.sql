WITH Input AS (
	SELECT LOWER('orsk') AS Search
),
-- Split words by ' '. Recursively select the next word until string is empty
QueryWords (WordPos, Word, QueryWordLength, Rest) AS (
	SELECT
		1 as WordPos,
		CASE SpaceIndex WHEN 0 THEN Search ELSE LEFT(Search, SpaceIndex - 1) END AS Word,
		Case SpaceIndex WHEN 0 THEN LEN(Search) ELSE SpaceIndex - 1 END AS QueryWordLength,
		CASE SpaceIndex WHEN 0 THEN '' ELSE SUBSTRING(Search, SpaceIndex + 1, LEN(Search) - SpaceIndex) END AS Rest
	FROM Input
	CROSS APPLY (SELECT CHARINDEX(' ', Search, 1) AS SpaceIndex) AS Calc
	UNION ALL
	SELECT
		prev.WordPos + 1 AS WordPos,
		CASE SpaceIndex WHEN 0 THEN prev.Rest ELSE LEFT(prev.Rest, SpaceIndex - 1) END AS Word,
		Case SpaceIndex WHEN 0 THEN LEN(prev.Rest) ELSE SpaceIndex - 1 END AS QueryWordLength,
		CASE SpaceIndex WHEN 0 THEN '' ELSE SUBSTRING(prev.Rest, SpaceIndex + 1, LEN(prev.Rest) - SpaceIndex) END AS Rest
	FROM QueryWords prev
	CROSS APPLY (SELECT CHARINDEX(' ', prev.Rest, 1) AS SpaceIndex) AS Calc
	WHERE Rest <> ''
),
QueryBigrams (QueryWordPos, Bigram, Rest, BigramPos) AS (
	SELECT
		WordPos AS QueryWordPos,
		SUBSTRING(Word, 1, 2) AS Bigram,
		SUBSTRING(Word, 2, LEN(Word) - 1) AS Rest,
		1 AS BigramPos
	FROM QueryWords
	WHERE LEN(Word) >= 2
	UNION ALL
	SELECT
		prev.QueryWordPos,
		SUBSTRING(prev.Rest, 1, 2) AS Bigram,
		SUBSTRING(prev.Rest, 2, LEN(prev.Rest) - 1) AS Rest,
		prev.BigramPos + 1 AS BigramPos
	FROM QueryBigrams prev
	WHERE LEN(prev.Rest) >= 2
),
WordMatches (WordId, QueryWordPos, QueryWordLength, MatchCount, PositionPenalty) AS (
	SELECT
		wb.WordId,
		MAX(qb.QueryWordPos) AS QueryWordPos,
		MAX(qw.QueryWordLength) AS QueryWordLength,
		COUNT(*) AS MatchCount,
		SUM(ABS(qb.BigramPos - wb.BigramPos)) AS PositionPenalty
	FROM QueryBigrams qb
	INNER JOIN Bigram b ON b.Bigram = qb.Bigram
	INNER JOIN WordBigram wb ON wb.BigramId = b.Id
	INNER JOIN QueryWords qw ON qw.WordPos = qb.QueryWordPos
	GROUP BY qb.QueryWordPos, wb.WordId
),
ScoredWords AS (
	SELECT
		m.WordId,
		qw.Word AS QueryWord,
		dw.Word, m.matchCount, m.QueryWordLength, (m.MatchCount / CAST((m.QueryWordLength - 1) AS FLOAT)) as matchratio, (m.PositionPenalty / CAST((m.QueryWordLength + 1) AS FLOAT)) as pospen, (ABS(m.QueryWordLength - dw.WordLength) / CAST(GREATEST(m.QueryWordLength, dw.WordLength) AS FLOAT)) as lenpen,
		(
			-- How much of the query word matched?
			(m.MatchCount / CAST((m.QueryWordLength - 1) AS FLOAT))
			
			-- Average position penalty on bigram matches
			- (m.PositionPenalty / CAST((m.QueryWordLength + 1) AS FLOAT))
			
			-- Word length penalty
			- (ABS(m.QueryWordLength - dw.WordLength) / CAST(GREATEST(m.QueryWordLength, dw.WordLength) AS FLOAT))
			
			-- Exact match bonus
			+ CASE WHEN qw.Word = dw.Word THEN 5 ELSE 0 END
		) AS Score
	FROM WordMatches m
	INNER JOIN DictionaryWord dw ON dw.Id = m.WordId
	INNER JOIN QueryWords qw ON qw.WordPos = m.QueryWordPos
)
SELECT * FROM ScoredWords ORDER BY Score DESC