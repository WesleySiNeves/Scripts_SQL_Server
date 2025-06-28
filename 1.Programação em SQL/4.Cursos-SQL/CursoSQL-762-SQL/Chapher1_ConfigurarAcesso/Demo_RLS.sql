USE master
DROP DATABASE IF EXISTS Hospital


CREATE DATABASE Hospital;
GO
USE Hospital;


-- Create database schema
CREATE TABLE Patients (
    PatientID INT PRIMARY KEY,
    PatientName NVARCHAR(256),
    Room INT,
    WardID INT,
    StartTime DATETIME,
    EndTime DATETIME
);
CREATE TABLE Staff (
    StaffID INT PRIMARY KEY,
    StaffName NVARCHAR(256),
    DatabasePrincipalID INT
);
CREATE TABLE StaffDuties (
    StaffID INT,
    WardID INT,
    StartTime DATETIME,
   EndTime DATETIME
);
CREATE TABLE Wards (
    WardID INT PRIMARY KEY,
   Ward NVARCHAR(128)
);
GO



-- Create roles for nurses and doctors
CREATE ROLE Nurse;
CREATE ROLE Doctor;
-- Grant permissions to nurses and doctors
GRANT SELECT, UPDATE ON Patients to Nurse;
GRANT SELECT, UPDATE ON Patients to Doctor;
GO



-- Create a user for each doctor and nurse
CREATE USER NurseMarcus WITHOUT LOGIN;
ALTER ROLE Nurse ADD MEMBER NurseMarcus;
INSERT Staff VALUES ( 100, N'Nurse Marcus', DATABASE_PRINCIPAL_ID('NurseMarcus'));
GO
CREATE USER NurseIsabelle WITHOUT LOGIN;
ALTER ROLE Nurse ADD MEMBER NurseIsabelle;
INSERT Staff VALUES ( 101, N'Nurse Isabelle', DATABASE_PRINCIPAL_ID('NurseIsabelle') );
GO
CREATE USER DoctorChristopher WITHOUT LOGIN
ALTER ROLE Doctor ADD MEMBER DoctorChristopher
INSERT Staff VALUES ( 200, 'Doctor Christopher', DATABASE_PRINCIPAL_ID('DoctorChristopher'));
GO
CREATE USER DoctorSofia WITHOUT LOGIN
ALTER ROLE Doctor ADD MEMBER DoctorSofia
INSERT Staff VALUES ( 201, N'Doctor Sofia', DATABASE_PRINCIPAL_ID('DoctorSofia'));
GO
-- Insert ward data
INSERT Wards VALUES( 1, N'Emergency');
INSERT Wards VALUES( 2, N'Maternity');
INSERT Wards VALUES( 3, N'Pediatrics');
GO
-- Insert patient data
INSERT Patients VALUES ( 1001, N'Victor', 101, 1, '20171217',  '20180326')
INSERT Patients VALUES ( 1002, N'Maria', 102, 1, '20171027',  '20180527')
INSERT Patients VALUES ( 1003, N'Nick', 107, 1, '20170507',  '20170611')
INSERT Patients VALUES ( 1004, N'Nina', 203, 2, '20170308',  '20171214')
INSERT Patients VALUES ( 1005, N'Larissa', 205, 2, '20170127',  '20170512')
INSERT Patients VALUES ( 1006, N'Marc', 301, 3, '20170131',  NULL)
INSERT Patients VALUES ( 1007, N'Sofia', 308, 3, '20170615',  '20170904')
GO
-- Inset nurses' duties
INSERT StaffDuties VALUES ( 101, 1, '20170101', '20171231')
INSERT StaffDuties VALUES ( 101, 2, '20180101', '20181231')
INSERT StaffDuties VALUES ( 102, 1, '20170101', '20170630')
INSERT StaffDuties VALUES ( 102, 2, '20170701', '20171231')
INSERT StaffDuties VALUES ( 102, 3, '20180101', '20181231')
-- Insert doctors' duties
INSERT StaffDuties VALUES ( 200, 1, '20170101', '20171231')
INSERT StaffDuties VALUES ( 200, 3, '20180101', '20181231')
INSERT StaffDuties VALUES ( 201, 1, '20170101', '20181231')
GO
-- Query patients
SELECT * FROM patients;


-- Query assignments
SELECT d.StaffID, StaffName, USER_NAME(DatabasePrincipalID) as DatabaseUser, WardID,
StartTime, EndTime
FROM StaffDuties d
INNER JOIN Staff s ON (s.StaffID = d.StaffID)
ORDER BY StaffID;
GO
-- Implement row level security
CREATE SCHEMA RLS;
GO


-- RLS predicate allows access to rows based on a user's role and assigned staff duties.
-- Because users have both SELECT and UPDATE permissions, we will use this function as a
-- filter predicate (filter which rows are accessible by SELECT and UPDATE queries) and
-- a block predicate after update (prevent user from updating rows to be outside of
-- visible range).
-- RLS predicate allows data access based on role and staff duties.
CREATE FUNCTION RLS.AccessPredicate(@Ward INT, @StartTime DATETIME, @EndTime DATETIME)
    RETURNS TABLE
    WITH SCHEMABINDING
AS
RETURN SELECT 1 AS Access
FROM dbo.StaffDuties AS d JOIN dbo.Staff AS s ON d.StaffId = s.StaffId
WHERE ( -- Nurses can only see patients who overlap with their wing assignments
    IS_MEMBER('Nurse') = 1
    AND s.DatabasePrincipalId = DATABASE_PRINCIPAL_ID()
    AND @Ward = d.WardID
    AND (d.EndTime >= @StartTime AND d.StartTime <= ISNULL(@EndTime, GETDATE()))
)
OR ( -- Doctors can see all patients
    IS_MEMBER('Doctor') = 1
);
GO



-- RLS filter predicate filters which data is seen by SELECT and UPDATE queries
-- RLS block predicate after update prevents updating data outside of visible range
CREATE SECURITY POLICY RLS.PatientsSecurityPolicy
ADD FILTER PREDICATE RLS.AccessPredicate(WardID, StartTime, EndTime) ON dbo.Patients,
ADD BLOCK PREDICATE RLS.AccessPredicate(WardID, StartTime, EndTime) ON dbo.Patients
AFTER UPDATE;
GO
-- Test RLS
-- Impersonate a nurse
EXECUTE ('SELECT * FROM patients;') AS USER = 'NurseIsabelle';
-- Only 3 patient records seen
GO
-- Impersonate a doctor
EXECUTE ('SELECT * FROM patients;') AS USER = 'DoctorChristopher';
-- All 7 patient records returned
GO
-- Attempt by nurse to move patient to another ward
EXECUTE ('UPDATE patients SET WardID = 1 WHERE patientId = 1006;') AS USER = 'NurseIsabelle'
-- Filtered, consequently 0 rows affected
EXECUTE ('UPDATE patients SET WardID = 3 WHERE patientId = 1001;') AS USER = 'NurseIsabelle'
-- Blocked from changing wing, with following error:
/*
Msg 33504, Level 16, State 1, Line 156
The attempted operation failed because the target object 'Hospital.dbo.Patients' has
a block predicate that conflicts with this operation. If the operation is performed
on a view, the block predicate might be enforced on the underlying table. Modify the
operation to target only the rows that are allowed by the block predicate.
The statement has been terminated.
*/