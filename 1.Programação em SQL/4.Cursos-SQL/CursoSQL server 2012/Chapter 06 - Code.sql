---------------------------------------------------------------------
-- TK 70-461 - Chapter 06 - Querying Full-Text Data
-- Code
---------------------------------------------------------------------

USE TSQL2012;
GO
SET NOCOUNT ON;
GO

---------------------------------------------------------------------
-- Lesson 01 - Creating Full-Text Catalogs and Indexes
---------------------------------------------------------------------

-- Check whether Full-Text and Semantic search is installed
SELECT SERVERPROPERTY('IsFullTextInstalled');
GO

-- Check the filters with sys.sp_help_fulltext_system_components
EXEC sys.sp_help_fulltext_system_components 'filter'; 
GO

-- Check the filters through sys.fulltext_document_types
SELECT document_type, path
FROM sys.fulltext_document_types;
GO

-- Download and install Office 2010 filter pack
-- Next, load them
EXEC sys.sp_fulltext_service 'load_os_resources', 1;
GO
-- Restart SQL Server
-- Check the filters again
EXEC sys.sp_help_fulltext_system_components 'filter'; 
GO
-- Office 2010 filters should be installed

-- Check the languages
SELECT lcid, name
FROM sys.fulltext_languages
ORDER BY name; 
GO

-- Check the stoplists
SELECT stoplist_id, name
FROM sys.fulltext_stoplists;
SELECT stoplist_id, stopword, language
FROM sys.fulltext_stopwords;
GO

-- Loading a thesaurus file for US English
EXEC sys.sp_fulltext_load_thesaurus_file 1033; 
GO
