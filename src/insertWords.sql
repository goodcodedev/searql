
-- For indexing
-- First adding missing DictionaryWord
-- Then adding WordBigram
-- Then adding WordInstance

-- Create a temporary tables to aid with multiple inserts
DROP TABLE IF EXISTS #InputWord;
DROP TABLE IF EXISTS #InputWordBigram;
CREATE TABLE #InputWord (
	Word varchar(50) NOT NULL,
	WordId int NULL,
	WasAdded bit NULL,
	WordPos int NOT NULL
);
CREATE TABLE #InputWordBigram (
	Bigram varchar(2) NOT NULL,
	BigramId int NULL,
	WordId int NOT NULL,
	BigramPos int NOT NULL
);

WITH Input AS (
	SELECT LOWER(@words) AS Search
),
-- Split words by ' '. Recursively select the next word until string is empty
QueryWord (Word, Rest, WordPos) AS (
	SELECT
		CASE SpaceIndex WHEN 0 THEN Search ELSE LEFT(Search, SpaceIndex - 1) END AS Word,
		CASE SpaceIndex WHEN 0 THEN '' ELSE SUBSTRING(Search, SpaceIndex + 1, LEN(Search) - SpaceIndex) END AS Rest,
		1 as WordPos
	FROM Input
	CROSS APPLY (SELECT CHARINDEX(' ', Search, 1) AS SpaceIndex) AS Calc
	UNION ALL
	SELECT
		CASE SpaceIndex WHEN 0 THEN prev.Rest ELSE LEFT(prev.Rest, SpaceIndex - 1) END AS Word,
		CASE SpaceIndex WHEN 0 THEN '' ELSE SUBSTRING(prev.Rest, SpaceIndex + 1, LEN(prev.Rest) - SpaceIndex) END AS Rest,
		prev.WordPos + 1 AS WordPos
	FROM QueryWord prev
	CROSS APPLY (SELECT CHARINDEX(' ', prev.Rest, 1) AS SpaceIndex) AS Calc
	WHERE Rest <> ''
)
INSERT INTO #InputWord (Word, WordId, WordPos)
SELECT QueryWord.Word, DictionaryWord.Id, QueryWord.WordPos
FROM QueryWord
LEFT JOIN DictionaryWord ON DictionaryWord.Word = QueryWord.Word
WHERE LEN(QueryWord.Word) >= 2
;

-- Insert missing DictionaryWord(s)
INSERT INTO DictionaryWord (Word, WordLength)
SELECT Word, Len(Word)
FROM #InputWord
WHERE WordId IS NULL
GROUP BY Word;
-- Then fill in new id's and mark the words as added
UPDATE #InputWord SET
	WordId = DictionaryWord.Id,
	WasAdded = 1
FROM #InputWord
INNER JOIN DictionaryWord ON DictionaryWord.Word = #InputWord.Word
WHERE #InputWord.WordId IS NULL;


-- Collect word bigrams for new words

WITH NewWords (Word, WordId) AS (
	SELECT Word, WordId
	FROM #InputWord
	WHERE #InputWord.WasAdded = 1
),
QueryBigram (Bigram, Rest, WordId, BigramPos) AS (
	SELECT
		SUBSTRING(Word, 1, 2) AS Bigram,
		SUBSTRING(Word, 2, LEN(Word) - 1) AS Rest,
		WordId,
		1 AS BigramPos
	FROM NewWords
	WHERE LEN(Word) >= 2
	UNION ALL
	SELECT
		SUBSTRING(prev.Rest, 1, 2) AS Bigram,
		SUBSTRING(prev.Rest, 2, LEN(prev.Rest) - 1) AS Rest,
		WordId,
		prev.BigramPos + 1 AS BigramPos
	FROM QueryBigram prev
	WHERE LEN(prev.Rest) >= 2
)
INSERT INTO #InputWordBigram (Bigram, BigramId, WordId, BigramPos)
SELECT QueryBigram.Bigram, Existing.Id, WordId, BigramPos
FROM QueryBigram
LEFT JOIN Bigram AS Existing ON Existing.Bigram = QueryBigram.Bigram;

-- Insert missing bigrams
INSERT INTO Bigram (Bigram)
SELECT Bigram
FROM #InputWordBigram
WHERE BigramId IS NULL
GROUP BY Bigram;

-- Add inn missing id's
UPDATE #InputWordBigram SET
	BigramId = Bigram.Id
FROM #InputWordBigram
INNER JOIN Bigram ON Bigram.Bigram = #InputWordBigram.Bigram
WHERE #InputWordBigram.BigramId IS NULL;

-- Add WordBigrams
INSERT INTO WordBigram (WordId, BigramId, BigramPos)
SELECT WordId, BigramId, BigramPos FROM #InputWordBigram;

-- Add word instances
INSERT INTO WordInstance (WordId, EntityId, FieldId, WordPos)
SELECT WordId, @entityId, @fieldId, WordPos
FROM #InputWord