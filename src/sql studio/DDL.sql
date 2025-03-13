DROP TABLE IF EXISTS WordInstance;
CREATE TABLE WordInstance (
	Id int IDENTITY(1,1) PRIMARY KEY,
	WordId int NOT NULL,
	EntityId int NOT NULL,
	FieldId varchar(50) NOT NULL,
	WordPos int NOT NULL
);

ALTER TABLE WordInstance DROP CONSTRAINT IF EXISTS FK_DictionaryWord;
ALTER TABLE WordBigram DROP CONSTRAINT IF EXISTS FK_DictionaryWord;

DROP TABLE IF EXISTS DictionaryWord;
CREATE TABLE DictionaryWord (
	Id int IDENTITY(1,1) PRIMARY KEY,
	Word varchar(50) NOT NULL UNIQUE,
	WordLength int NOT NULL
);
ALTER TABLE WordInstance ADD CONSTRAINT FK_InstanceDictionaryWord FOREIGN KEY (WordID) REFERENCES DictionaryWord(Id);

DROP TABLE IF EXISTS WordBigram;
CREATE TABLE WordBigram (
	Id int IDENTITY(1,1) PRIMARY KEY,
	WordId int NOT NULL,
	BigramId int NOT NULL,
	BigramPos int NOT NULL
);
ALTER TABLE WordBigram ADD CONSTRAINT FK_DictionaryWord FOREIGN KEY (WordID) REFERENCES DictionaryWord(Id);
ALTER TABLE WordBigram ADD CONSTRAINT FK_Bigram FOREIGN KEY (BigramId) REFERENCES Bigram(Id);

DROP TABLE IF EXISTS Bigram;
CREATE TABLE Bigram (
	Id int IDENTITY(1,1) PRIMARY KEY,
	Bigram varchar(2) NOT NULL UNIQUE
);