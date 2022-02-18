---------------------------------------------------------------------
-- TK 70-461 - Chapter 07 -  Querying Full-Text Data
-- Exercises
---------------------------------------------------------------------

---------------------------------------------------------------------
-- Lesson 01 - Creating Full-Text Catalogs and Indexes
---------------------------------------------------------------------

---------------------------------------------------------------------
-- Practice - Creating a Full-Text Index
---------------------------------------------------------------------

-- Exercise 1 Creating a Table and Full-Text Components

-- 3.
USE TSQL2012;
GO

-- 4. Check whether Full-Text is installed
SELECT SERVERPROPERTY('IsFullTextInstalled');
GO

-- 6. Table for documents
CREATE TABLE dbo.Documents
(
  id INT IDENTITY(1,1) NOT NULL,
  title NVARCHAR(100) NOT NULL,
  doctype NCHAR(4) NOT NULL,
  docexcerpt NVARCHAR(1000) NOT NULL,
  doccontent VARBINARY(MAX) NOT NULL,
  CONSTRAINT PK_Documents 
   PRIMARY KEY CLUSTERED(id)
);
GO

-- 7. Insert data
INSERT INTO dbo.Documents
(title, doctype, docexcerpt, doccontent)
SELECT N'Columnstore Indices and Batch Processing', 
 N'docx',
 N'You should use a columnstore index on your fact tables,
   putting all columns of a fact table in a columnstore index. 
   In addition to fact tables, very large dimensions could benefit 
   from columnstore indices as well. 
   Do not use columnstore indices for small dimensions. ',
 bulkcolumn
FROM OPENROWSET(BULK 'C:\TK461\ColumnstoreIndicesAndBatchProcessing.docx', 
                SINGLE_BLOB) AS doc;
INSERT INTO dbo.Documents
(title, doctype, docexcerpt, doccontent)
SELECT N'Introduction to Data Mining', 
 N'docx',
 N'Using Data Mining is becoming more a necessity for every company 
   and not an advantage of some rare companies anymore. ',
 bulkcolumn
FROM OPENROWSET(BULK 'C:\TK461\IntroductionToDataMining.docx', 
                SINGLE_BLOB) AS doc;
INSERT INTO dbo.Documents
(title, doctype, docexcerpt, doccontent)
SELECT N'Why Is Bleeding Edge a Different Conference', 
 N'docx',
 N'During high level presentations attendees encounter many questions. 
   For the third year, we are continuing with the breakfast Q&A session. 
   It is very popular, and for two years now, 
   we could not accommodate enough time for all questions and discussions! ',
 bulkcolumn
FROM OPENROWSET(BULK 'C:\TK461\WhyIsBleedingEdgeADifferentConference.docx', 
                SINGLE_BLOB) AS doc;
INSERT INTO dbo.Documents
(title, doctype, docexcerpt, doccontent)
SELECT N'Additivity of Measures', 
 N'docx',
 N'Additivity of measures is not exactly a data warehouse design problem. 
   However, you have to realize which aggregate functions you will use 
   in reports for which measure, and which aggregate functions 
   you will use when aggregating over which dimension.',
 bulkcolumn
FROM OPENROWSET(BULK 'C:\TK461\AdditivityOfMeasures.docx', 
                SINGLE_BLOB) AS doc;
GO

/*
SELECT *
FROM dbo.Documents;
GO
*/

-- 8. Search property list
CREATE SEARCH PROPERTY LIST WordSearchPropertyList;
GO
ALTER SEARCH PROPERTY LIST WordSearchPropertyList
 ADD 'Authors' 
 WITH (PROPERTY_SET_GUID = 'F29F85E0-4FF9-1068-AB91-08002B27B3D9', 
       PROPERTY_INT_ID = 4, 
       PROPERTY_DESCRIPTION = 'System.Authors - authors of a given item.');
GO

-- 9. Stopwords list
CREATE FULLTEXT STOPLIST SQLStopList;
GO
ALTER FULLTEXT STOPLIST SQLStopList
 ADD 'SQL' LANGUAGE 'English';
GO

-- 10. Check the Stopwords list
SELECT w.stoplist_id,
 l.name,
 w.stopword,
 w.language
FROM sys.fulltext_stopwords AS w
 INNER JOIN sys.fulltext_stoplists AS l
  ON w.stoplist_id = l.stoplist_id;
GO

-- 11. Test parsing
-- Check the correct stoplist id
SELECT * 
FROM sys.dm_fts_parser
(N'"Additivity of measures is not exactly a data warehouse design problem. 
   However, you have to realize which aggregate functions you will use 
   in reports for which measure, and which aggregate functions 
   you will use when aggregating over which dimension."', 1033, 5, 0);
SELECT * 
FROM sys.dm_fts_parser
('FORMSOF(INFLECTIONAL,'+ 'function' + ')', 1033, 5, 0);
GO

-- Exercise 2 Installing a Semantic Database and Creating a Full-Text Index

-- 1. Check whether Semantic Language Statistics Database is installed
SELECT * 
FROM sys.fulltext_semantic_language_statistics_database;
GO

-- Install Semantic Language Statistics Database
-- Run the SemanticLanguageDatabase.msi from D:\x64\Setup

-- 2. Attach the database
CREATE DATABASE semanticsdb ON
 (FILENAME = 'C:\Program Files\Microsoft Semantic Language Database\semanticsdb.mdf'),
 (FILENAME = 'C:\Program Files\Microsoft Semantic Language Database\semanticsdb_log.ldf')
 FOR ATTACH;
GO

-- 3. Register it
EXEC sp_fulltext_semantic_register_language_statistics_db
 @dbname = N'semanticsdb';
GO

-- 4. Check whether Semantic Language Statistics Database is installed
/* Check again
SELECT * 
FROM sys.fulltext_semantic_language_statistics_database;
GO
*/

-- 5. Full-text catalog
CREATE FULLTEXT CATALOG DocumentsFtCatalog;
GO

-- 6. Full-text index
CREATE FULLTEXT INDEX ON dbo.Documents
( 
  docexcerpt Language 1033, 
  doccontent TYPE COLUMN doctype
  Language 1033
  STATISTICAL_SEMANTICS
)
KEY INDEX PK_Documents
ON DocumentsFtCatalog
WITH STOPLIST = SQLStopList, 
     SEARCH PROPERTY LIST = WordSearchPropertyList, 
	 CHANGE_TRACKING AUTO;
GO

---------------------------------------------------------------------
-- Lesson 02 - Using the CONTAINS and FREETEXT Predicates
---------------------------------------------------------------------

---------------------------------------------------------------------
-- Practice - The CONTAINS and FREETEXT Predicates
---------------------------------------------------------------------

-- Exercise 1 Use the CONTAINS and FREETEXT Predicates

-- 2.
USE TSQL2012;

-- 3. Simple query
SELECT id, title, docexcerpt
FROM dbo.Documents
WHERE CONTAINS(docexcerpt, N'data');

-- 4. Logical operators - OR
SELECT id, title, docexcerpt
FROM dbo.Documents
WHERE CONTAINS(docexcerpt, N'data OR index');

-- 5. Logical operators - AND NOT
SELECT id, title, docexcerpt
FROM dbo.Documents
WHERE CONTAINS(docexcerpt, N'data AND NOT mining');

-- 6. Logical operators - parentheses
SELECT id, title, docexcerpt
FROM dbo.Documents
WHERE CONTAINS(docexcerpt, N'data OR (fact AND warehouse)');

-- 7. Phrase
SELECT id, title, docexcerpt
FROM dbo.Documents
WHERE CONTAINS(docexcerpt, N'"data warehouse"');

-- 8. Prefix
SELECT id, title, docexcerpt
FROM dbo.Documents
WHERE CONTAINS(docexcerpt, N'"add*"');

-- 9. Simple proximity
SELECT id, title, docexcerpt
FROM dbo.Documents
WHERE CONTAINS(docexcerpt, N'NEAR(problem, data)');

-- 10. Proximity with max distance
SELECT id, title, docexcerpt
FROM dbo.Documents
WHERE CONTAINS(docexcerpt, N'NEAR((problem, data),5)');
SELECT id, title, docexcerpt
FROM dbo.Documents
WHERE CONTAINS(docexcerpt, N'NEAR((problem, data),1)');

-- 11. Proximity with max distance and order
SELECT id, title, docexcerpt
FROM dbo.Documents
WHERE CONTAINS(docexcerpt, N'NEAR((problem, data),5, TRUE)');

-- 12. Inflectional forms
-- The next query does not return any rows
SELECT id, title, docexcerpt
FROM dbo.Documents
WHERE CONTAINS(docexcerpt, N'presentation');
-- The next query returns a row
SELECT id, title, docexcerpt
FROM dbo.Documents
WHERE CONTAINS(docexcerpt, N'FORMSOF(INFLECTIONAL, presentation)');
GO

-- Exercise 2 Use Synonyms

-- Thesaurus
-- 1. Edit the US English thesaurus file tsenu.xml to have the following content:
/*
<XML ID="Microsoft Search Thesaurus">
    <thesaurus xmlns="x-schema:tsSchema.xml">
	<diacritics_sensitive>0</diacritics_sensitive>
        <expansion>
            <sub>Internet Explorer</sub>
            <sub>IE</sub>
            <sub>IE5</sub>
        </expansion>
        <replacement>
            <pat>NT5</pat>
            <pat>W2K</pat>
            <sub>Windows 2000</sub>
        </replacement>
        <expansion>
            <sub>run</sub>
            <sub>jog</sub>
        </expansion>
        <expansion>
            <sub>need</sub>
            <sub>necessity</sub>
        </expansion>
    </thesaurus>
</XML>
*/

-- 2. Load the US English file
EXEC sys.sp_fulltext_load_thesaurus_file 1033;
GO

-- 3. Synonyms
-- The next query does not return any rows
SELECT id, title, docexcerpt
FROM dbo.Documents
WHERE CONTAINS(docexcerpt, N'need');
-- The next query returns a row
SELECT id, title, docexcerpt
FROM dbo.Documents
WHERE CONTAINS(docexcerpt, N'FORMSOF(THESAURUS, need)');

-- 4. Document properties
SELECT id, title, docexcerpt
FROM dbo.Documents
WHERE CONTAINS(PROPERTY(doccontent,'Authors'), 'Dejan');

-- 5. FREETEXT
SELECT id, title, doctype, docexcerpt
FROM dbo.Documents
WHERE FREETEXT(docexcerpt, N'data presentation need');
GO


---------------------------------------------------------------------
-- Lesson 03 - Using the Full-Text and 
--             Semantic Search Table-Valued Functions
---------------------------------------------------------------------

---------------------------------------------------------------------
-- Practice - Full-Text and Semantic Search Functions
---------------------------------------------------------------------

-- Exercise 1 Use the Full-Text Search Functions

-- 2.
USE TSQL2012;

-- 3. Rank with CONTAINSTABLE
SELECT D.id, D.title, CT.[RANK], D.docexcerpt
FROM CONTAINSTABLE(dbo.Documents, docexcerpt, 
      N'data OR level') AS CT
 INNER JOIN dbo.Documents AS D
  ON CT.[KEY] = D.id
ORDER BY CT.[RANK] DESC;

-- 4. Rank with FREETEXTTABLE
SELECT D.id, D.title, FT.[RANK], D.docexcerpt
FROM FREETEXTTABLE (dbo.Documents, docexcerpt, 
      N'data level') AS FT
 INNER JOIN dbo.Documents AS D
  ON FT.[KEY] = D.id
ORDER BY FT.[RANK] DESC;

-- 5. Weighted terms
SELECT D.id, D.title, CT.[RANK], D.docexcerpt
FROM CONTAINSTABLE
      (dbo.Documents, docexcerpt, 
       N'ISABOUT(data weight(0.8), level weight(0.2))') AS CT
 INNER JOIN dbo.Documents AS D
  ON CT.[KEY] = D.id
ORDER BY CT.[RANK] DESC;

-- 6. Proximity term
SELECT D.id, D.title, CT.[RANK]
FROM CONTAINSTABLE (dbo.Documents, doccontent, 
      N'NEAR((data, row), 30)') AS CT
 INNER JOIN dbo.Documents AS D
  ON CT.[KEY] = D.id
ORDER BY CT.[RANK] DESC;

-- Exercise 2 Use the Semantic Search Functions

-- 1. Top 20 semantic key phrases
SELECT TOP (20)
 D.id, D.title, SKT.keyphrase, SKT.score
FROM SEMANTICKEYPHRASETABLE
      (dbo.Documents, doccontent) AS SKT
 INNER JOIN dbo.Documents AS D
  ON SKT.document_key = D.id
ORDER BY SKT.score DESC;

-- 2. Documents that are similar to document 1
SELECT SST.matched_document_key, 
 D.title, SST.score
FROM SEMANTICSIMILARITYTABLE
     (dbo.Documents, doccontent, 1) AS SST
 INNER JOIN dbo.Documents AS D
  ON SST.matched_document_key = D.id
ORDER BY SST.score DESC;

-- 3. Semantic search key phrases that are common to two documents
SELECT SSDT.keyphrase, SSDT.score
FROM SEMANTICSIMILARITYDETAILSTABLE
      (dbo.Documents, doccontent, 1,
       doccontent, 4) AS SSDT
ORDER BY SSDT.score DESC;
GO

-- 4. Clean up
DROP TABLE dbo.Documents;
DROP FULLTEXT CATALOG DocumentsFtCatalog;
DROP SEARCH PROPERTY LIST WordSearchPropertyList;
DROP FULLTEXT STOPLIST SQLStopList;
GO
