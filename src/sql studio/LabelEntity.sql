DROP TABLE IF EXISTS LabelEntity;
CREATE TABLE LabelEntity (
	Id int IDENTITY(1,1) PRIMARY KEY,
	Label varchar(255) NOT NULL,
	Description varchar(1000) NOT NULL,
	Uri varchar(255) NOT NULL UNIQUE
)

--SELECT *
--FROM DictionaryWord d
--LEFT JOIN WordBigram wb on wb.WordId = d.Id
--LEFT JOIN Bigram b on b.Id = wb.BigramId
--ORDER BY d.Id, BigramPos
--;
--SELECT * FROM Bigram;

--DELETE FROM WordInstance;DELETE FROM WordBigram;DELETE FROM DictionaryWord;DELETE FROM Bigram;