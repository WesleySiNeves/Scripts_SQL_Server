/*
One of the primary values of using STORED PROCEDURE objects as your interface to
your data is that you can fix poorly-written code without changing compiled code of the
interface. The biggest win is that often it is non-trivial code that generates the Transact-
SQL in the procedural programming language.
For example, say you have the following table and seed data:
*/

CREATE TABLE Examples.Player
(
    PlayerId INT NOT NULL
        CONSTRAINT PKPlayer PRIMARY KEY,
    TeamId INT NOT NULL, --not implemented reference to Team Table
    PlayerNumber CHAR(2) NOT NULL,
    CONSTRAINT AKPlayer
        UNIQUE
        (
            TeamId,
            PlayerNumber
        )
);

INSERT INTO Examples.Player(PlayerId, TeamId, PlayerNumber)
VALUES (1,1,'18'),(2,1,'45'),(3,1,'40');


/*
A programmer has written the following procedure shown in Listing 2-2 to fetch a player
with a given number on any team, but did not understand how to write a set-based query

*/
GO
CREATE PROCEDURE Examples.Player_GetByPlayerNumber (@PlayerNumber CHAR(2))
AS
SET NOCOUNT ON;
DECLARE @PlayerList TABLE (PlayerId INT NOT NULL);
DECLARE @Cursor CURSOR,
        @Loop_PlayerId INT,
        @Loop_PlayerNumber CHAR(2);
SET @Cursor = CURSOR FAST_FORWARD FOR
(
SELECT PlayerId,
       PlayerNumber
FROM Examples.Player

);


OPEN @Cursor;

WHILE (1 = 1)
BEGIN
    FETCH NEXT FROM @Cursor
    INTO @Loop_PlayerId,
         @Loop_PlayerNumber;
    IF @@FETCH_STATUS <> 0
        BREAK;
    IF @PlayerNumber = @Loop_PlayerNumber
        INSERT INTO @PlayerList
        (
            PlayerId
        )
        VALUES (@Loop_PlayerId);
END;
SELECT Player.PlayerId,
       Player.TeamId
FROM Examples.Player
    JOIN @PlayerList AS PlayerList
        ON PlayerList.PlayerId = Player.PlayerId;


--Execute

EXECUTE Examples.Player_GetByPlayerNumber @PlayerNumber = '18';

GO
ALTER PROCEDURE Examples.Player_GetByPlayerNumber (@PlayerNumber CHAR(2))
AS
SET NOCOUNT ON;
SELECT Player.PlayerId,
       Player.TeamId
FROM Examples.Player
WHERE PlayerNumber = @PlayerNumber;


--Comando de execução
EXECUTE Examples.Player_GetByPlayerNumber @PlayerNumber = '18';



USE WideWorldImporters


