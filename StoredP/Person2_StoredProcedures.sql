
USE [ITI_E]
GO

-- ================================================
-- DROP EXISTING STORED PROCEDURES
-- ================================================

-- DROP PROCEDURE IF EXISTS SP_SubmitStudentAnswers;
-- DROP PROCEDURE IF EXISTS SP_GetStudentsByDepartment;
-- DROP PROCEDURE IF EXISTS SP_GetStudentGrades;
-- DROP PROCEDURE IF EXISTS SP_CreateStudent;
-- DROP PROCEDURE IF EXISTS SP_UpdateStudent;
-- DROP PROCEDURE IF EXISTS SP_DeleteStudent;
-- DROP PROCEDURE IF EXISTS SP_AddStudentPhone;
-- DROP PROCEDURE IF EXISTS SP_DeleteStudentPhone;
-- DROP PROCEDURE IF EXISTS SP_EnrollStudentInCourse;
-- DROP PROCEDURE IF EXISTS SP_UnenrollStudentFromCourse;
-- DROP PROCEDURE IF EXISTS SP_GetStudentEnrollments;
-- DROP PROCEDURE IF EXISTS SP_GetAvailableExamsForStudent;
GO

-- ================================================
-- MAIN FUNCTION: Submit Student Answers
-- ================================================

CREATE PROCEDURE SP_SubmitStudentAnswers
    @E_Id INT,
    @S_Id INT,
    @Answers AnswerListType READONLY  
AS
BEGIN
    SET NOCOUNT ON;
    
    BEGIN TRY
        BEGIN TRANSACTION
        
        -- Validate exam exists
        IF NOT EXISTS (SELECT 1 FROM Exam WHERE E_Id = @E_Id)
        BEGIN
            RAISERROR('Exam ID %d does not exist', 16, 1, @E_Id)
            RETURN
        END
        
        -- Validate student exists
        IF NOT EXISTS (SELECT 1 FROM Student WHERE S_Id = @S_Id)
        BEGIN
            RAISERROR('Student ID %d does not exist', 16, 1, @S_Id)
            RETURN
        END
        
        -- Check if student is enrolled in the course of this exam
        IF NOT EXISTS (
            SELECT 1 
            FROM Student_Course sc
            INNER JOIN Exam e ON sc.Course_Id = e.C_Id
            WHERE sc.S_Id = @S_Id AND e.E_Id = @E_Id
        )
        BEGIN
            RAISERROR('Student %d is not enrolled in the course for exam %d', 16, 1, @S_Id, @E_Id)
            RETURN
        END
        
        -- Insert student answers
        INSERT INTO Student_Answer (Question_Id, Exam_Id, Choice_Id, S_Id)
        SELECT 
            Q_Id,
            @E_Id,
            Choice_Id,
            @S_Id
        FROM @Answers
        
        -- Create or update Student_Exam record
        IF EXISTS (SELECT 1 FROM Student_Exam WHERE S_Id = @S_Id AND E_Id = @E_Id)
        BEGIN
            UPDATE Student_Exam 
            SET Date_Taken = GETDATE()
            WHERE S_Id = @S_Id AND E_Id = @E_Id
        END
        ELSE
        BEGIN
            INSERT INTO Student_Exam (S_Id, E_Id, Grade, Date_Taken)
            VALUES (@S_Id, @E_Id, NULL, GETDATE())  -- Grade will be set by SP_CorrectExam
        END
        
        COMMIT TRANSACTION
        
        PRINT 'Student answers submitted successfully'
        
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION
        
        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE()
        DECLARE @ErrorSeverity INT = ERROR_SEVERITY()
        DECLARE @ErrorState INT = ERROR_STATE()
        
        RAISERROR(@ErrorMessage, @ErrorSeverity, @ErrorState)
    END CATCH
END
GO

-- Create Table-Valued Parameter Type for Answers
IF NOT EXISTS (SELECT * FROM sys.types WHERE name = 'AnswerListType')
BEGIN
    CREATE TYPE AnswerListType AS TABLE
    (
        Q_Id INT,
        Choice_Id INT NULL  -- NULL for True/False questions
    )
END
GO

-- ================================================
-- REPORT 1: Get Students by Department
-- ================================================

CREATE PROCEDURE SP_GetStudentsByDepartment
    @Dep_Id INT
AS
BEGIN
    SET NOCOUNT ON;
    
    SELECT 
        s.S_Id,
        s.S_FName + ' ' + s.S_LName AS StudentName,
        s.S_FName,
        s.S_LName,
        s.S_Age,
        s.S_Email,
        s.S_GPA,
        t.Track_Name,
        t.Track_Id,
        d.D_Name AS DepartmentName,
        STRING_AGG(sp.S_Phone, ', ') AS PhoneNumbers
    FROM Student s
    INNER JOIN Track t ON s.Track_Id = t.Track_Id
    INNER JOIN Department d ON s.Dep_Id = d.D_Id
    LEFT JOIN Student_Phones sp ON s.S_Id = sp.S_Id
    WHERE s.Dep_Id = @Dep_Id
    GROUP BY 
        s.S_Id, s.S_FName, s.S_LName, s.S_Age, 
        s.S_Email, s.S_GPA, t.Track_Name, t.Track_Id, d.D_Name
    ORDER BY s.S_LName, s.S_FName
END
GO

-- ================================================
-- REPORT 2: Get Student Grades
-- ================================================

CREATE PROCEDURE SP_GetStudentGrades
    @S_Id INT
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Validate student exists
    IF NOT EXISTS (SELECT 1 FROM Student WHERE S_Id = @S_Id)
    BEGIN
        RAISERROR('Student ID %d does not exist', 16, 1, @S_Id)
        RETURN
    END
    
    SELECT 
        s.S_FName + ' ' + s.S_LName AS StudentName,
        c.C_Id,
        c.C_Name AS CourseName,
        AVG(se.Grade) AS AverageGrade,
        COUNT(se.E_Id) AS ExamsTaken,
        CASE 
            WHEN AVG(se.Grade) >= 90 THEN 'A'
            WHEN AVG(se.Grade) >= 80 THEN 'B'
            WHEN AVG(se.Grade) >= 70 THEN 'C'
            WHEN AVG(se.Grade) >= 60 THEN 'D'
            ELSE 'F'
        END AS LetterGrade,
        CASE 
            WHEN AVG(se.Grade) >= 60 THEN 'Pass'
            ELSE 'Fail'
        END AS Status
    FROM Student s
    INNER JOIN Student_Exam se ON s.S_Id = se.S_Id
    INNER JOIN Exam e ON se.E_Id = e.E_Id
    INNER JOIN Course c ON e.C_Id = c.C_Id
    WHERE s.S_Id = @S_Id AND se.Grade IS NOT NULL
    GROUP BY s.S_FName, s.S_LName, c.C_Id, c.C_Name
    ORDER BY c.C_Name
END
GO

-- ================================================
-- CRUD 1: Create Student
-- ================================================

CREATE PROCEDURE SP_CreateStudent
    @S_FName NVARCHAR(50),
    @S_LName NVARCHAR(50),
    @S_Age INT,
    @S_Email NVARCHAR(100),
    @S_GPA DECIMAL(3,2) = NULL,
    @Track_Id INT,
    @Dep_Id INT,
    @NewStudentId INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    
    BEGIN TRY
        BEGIN TRANSACTION
        
        -- Validate age
        IF @S_Age < 16 OR @S_Age > 100
        BEGIN
            RAISERROR('Invalid age: must be between 16 and 100', 16, 1)
            RETURN
        END
        
        -- Validate GPA
        IF @S_GPA IS NOT NULL AND (@S_GPA < 0.0 OR @S_GPA > 4.0)
        BEGIN
            RAISERROR('Invalid GPA: must be between 0.0 and 4.0', 16, 1)
            RETURN
        END
        
        -- Validate email is unique
        IF EXISTS (SELECT 1 FROM Student WHERE S_Email = @S_Email)
        BEGIN
            RAISERROR('Email %s already exists', 16, 1, @S_Email)
            RETURN
        END
        
        -- Validate foreign keys
        IF NOT EXISTS (SELECT 1 FROM Department WHERE D_Id = @Dep_Id)
        BEGIN
            RAISERROR('Department ID %d does not exist', 16, 1, @Dep_Id)
            RETURN
        END
        
        IF NOT EXISTS (SELECT 1 FROM Track WHERE Track_Id = @Track_Id)
        BEGIN
            RAISERROR('Track ID %d does not exist', 16, 1, @Track_Id)
            RETURN
        END
        
        -- Insert student
        INSERT INTO Student (S_FName, S_LName, S_Age, S_Email, S_GPA, Track_Id, Dep_Id)
        VALUES (@S_FName, @S_LName, @S_Age, @S_Email, @S_GPA, @Track_Id, @Dep_Id)
        
        SET @NewStudentId = SCOPE_IDENTITY()
        
        COMMIT TRANSACTION
        
        PRINT 'Student created successfully with ID: ' + CAST(@NewStudentId AS VARCHAR)
        
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION
        
        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE()
        RAISERROR(@ErrorMessage, 16, 1)
    END CATCH
END
GO

-- ================================================
-- CRUD 2: Update Student
-- ================================================

CREATE PROCEDURE SP_UpdateStudent
    @S_Id INT,
    @S_FName NVARCHAR(50) = NULL,
    @S_LName NVARCHAR(50) = NULL,
    @S_Age INT = NULL,
    @S_Email NVARCHAR(100) = NULL,
    @S_GPA DECIMAL(3,2) = NULL,
    @Track_Id INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    
    BEGIN TRY
        -- Validate student exists
        IF NOT EXISTS (SELECT 1 FROM Student WHERE S_Id = @S_Id)
        BEGIN
            RAISERROR('Student ID %d does not exist', 16, 1, @S_Id)
            RETURN
        END
        
        -- Validate age if provided
        IF @S_Age IS NOT NULL AND (@S_Age < 16 OR @S_Age > 100)
        BEGIN
            RAISERROR('Invalid age: must be between 16 and 100', 16, 1)
            RETURN
        END
        
        -- Validate GPA if provided
        IF @S_GPA IS NOT NULL AND (@S_GPA < 0.0 OR @S_GPA > 4.0)
        BEGIN
            RAISERROR('Invalid GPA: must be between 0.0 and 4.0', 16, 1)
            RETURN
        END
        
        -- Validate email uniqueness if provided
        IF @S_Email IS NOT NULL AND EXISTS (
            SELECT 1 FROM Student WHERE S_Email = @S_Email AND S_Id <> @S_Id
        )
        BEGIN
            RAISERROR('Email %s already exists', 16, 1, @S_Email)
            RETURN
        END
        
        -- Validate Track if provided
        IF @Track_Id IS NOT NULL AND NOT EXISTS (SELECT 1 FROM Track WHERE Track_Id = @Track_Id)
        BEGIN
            RAISERROR('Track ID %d does not exist', 16, 1, @Track_Id)
            RETURN
        END
        
        -- Update student (only non-NULL parameters)
        UPDATE Student
        SET 
            S_FName = ISNULL(@S_FName, S_FName),
            S_LName = ISNULL(@S_LName, S_LName),
            S_Age = ISNULL(@S_Age, S_Age),
            S_Email = ISNULL(@S_Email, S_Email),
            S_GPA = ISNULL(@S_GPA, S_GPA),
            Track_Id = ISNULL(@Track_Id, Track_Id)
        WHERE S_Id = @S_Id
        
        PRINT 'Student updated successfully'
        
    END TRY
    BEGIN CATCH
        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE()
        RAISERROR(@ErrorMessage, 16, 1)
    END CATCH
END
GO

-- ================================================
-- CRUD 3: Delete Student
-- ================================================

CREATE PROCEDURE SP_DeleteStudent
    @S_Id INT,
    @Force BIT = 0  -- If 1, cascade delete related records
AS
BEGIN
    SET NOCOUNT ON;
    
    BEGIN TRY
        BEGIN TRANSACTION
        
        -- Validate student exists
        IF NOT EXISTS (SELECT 1 FROM Student WHERE S_Id = @S_Id)
        BEGIN
            RAISERROR('Student ID %d does not exist', 16, 1, @S_Id)
            RETURN
        END
        
        -- Check for dependencies
        DECLARE @HasExams INT = (SELECT COUNT(*) FROM Student_Exam WHERE S_Id = @S_Id)
        DECLARE @HasAnswers INT = (SELECT COUNT(*) FROM Student_Answer WHERE S_Id = @S_Id)
        DECLARE @HasEnrollments INT = (SELECT COUNT(*) FROM Student_Course WHERE S_Id = @S_Id)
        
        IF (@HasExams > 0 OR @HasAnswers > 0 OR @HasEnrollments > 0) AND @Force = 0
        BEGIN
            RAISERROR('Cannot delete student: has related records (exams: %d, answers: %d, enrollments: %d). Use @Force = 1 to cascade delete.', 
                      16, 1, @HasExams, @HasAnswers, @HasEnrollments)
            RETURN
        END
        
        -- Cascade delete if forced
        IF @Force = 1
        BEGIN
            DELETE FROM Student_Answer WHERE S_Id = @S_Id
            DELETE FROM Student_Exam WHERE S_Id = @S_Id
            DELETE FROM Student_Course WHERE S_Id = @S_Id
            DELETE FROM Teaching WHERE S_Id = @S_Id
            DELETE FROM Student_Phones WHERE S_Id = @S_Id
        END
        
        -- Delete student
        DELETE FROM Student WHERE S_Id = @S_Id
        
        COMMIT TRANSACTION
        
        PRINT 'Student deleted successfully'
        
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION
        
        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE()
        RAISERROR(@ErrorMessage, 16, 1)
    END CATCH
END
GO

-- ================================================
-- CRUD 4: Add Student Phone
-- ================================================

CREATE PROCEDURE SP_AddStudentPhone
    @S_Id INT,
    @S_Phone NVARCHAR(20)
AS
BEGIN
    SET NOCOUNT ON;
    
    BEGIN TRY
        -- Validate student exists
        IF NOT EXISTS (SELECT 1 FROM Student WHERE S_Id = @S_Id)
        BEGIN
            RAISERROR('Student ID %d does not exist', 16, 1, @S_Id)
            RETURN
        END
        
        -- Check if phone already exists for this student
        IF EXISTS (SELECT 1 FROM Student_Phones WHERE S_Id = @S_Id AND S_Phone = @S_Phone)
        BEGIN
            RAISERROR('Phone number %s already exists for this student', 16, 1, @S_Phone)
            RETURN
        END
        
        -- Insert phone
        INSERT INTO Student_Phones (S_Id, S_Phone)
        VALUES (@S_Id, @S_Phone)
        
        PRINT 'Phone number added successfully'
        
    END TRY
    BEGIN CATCH
        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE()
        RAISERROR(@ErrorMessage, 16, 1)
    END CATCH
END
GO

-- ================================================
-- CRUD 5: Delete Student Phone
-- ================================================

CREATE PROCEDURE SP_DeleteStudentPhone
    @S_Id INT,
    @S_Phone NVARCHAR(20)
AS
BEGIN
    SET NOCOUNT ON;
    
    BEGIN TRY
        -- Check if phone exists
        IF NOT EXISTS (SELECT 1 FROM Student_Phones WHERE S_Id = @S_Id AND S_Phone = @S_Phone)
        BEGIN
            RAISERROR('Phone number %s not found for student %d', 16, 1, @S_Phone, @S_Id)
            RETURN
        END
        
        -- Delete phone
        DELETE FROM Student_Phones 
        WHERE S_Id = @S_Id AND S_Phone = @S_Phone
        
        PRINT 'Phone number deleted successfully'
        
    END TRY
    BEGIN CATCH
        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE()
        RAISERROR(@ErrorMessage, 16, 1)
    END CATCH
END
GO

-- ================================================
-- CRUD 6: Enroll Student in Course
-- ================================================

CREATE PROCEDURE SP_EnrollStudentInCourse
    @S_Id INT,
    @Course_Id INT,
    @Enrollment_Date DATE = NULL
AS
BEGIN
    SET NOCOUNT ON;
    
    BEGIN TRY
        BEGIN TRANSACTION
        
        -- Validate student exists
        IF NOT EXISTS (SELECT 1 FROM Student WHERE S_Id = @S_Id)
        BEGIN
            RAISERROR('Student ID %d does not exist', 16, 1, @S_Id)
            RETURN
        END
        
        -- Validate course exists
        IF NOT EXISTS (SELECT 1 FROM Course WHERE C_Id = @Course_Id)
        BEGIN
            RAISERROR('Course ID %d does not exist', 16, 1, @Course_Id)
            RETURN
        END
        
        -- Check if already enrolled
        IF EXISTS (SELECT 1 FROM Student_Course WHERE S_Id = @S_Id AND Course_Id = @Course_Id)
        BEGIN
            RAISERROR('Student %d is already enrolled in course %d', 16, 1, @S_Id, @Course_Id)
            RETURN
        END
        
        -- Set enrollment date to today if not provided
        IF @Enrollment_Date IS NULL
            SET @Enrollment_Date = GETDATE()
        
        -- Enroll student
        INSERT INTO Student_Course (S_Id, Course_Id, Enrollment_Date)
        VALUES (@S_Id, @Course_Id, @Enrollment_Date)
        
        COMMIT TRANSACTION
        
        PRINT 'Student enrolled successfully'
        
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION
        
        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE()
        RAISERROR(@ErrorMessage, 16, 1)
    END CATCH
END
GO

-- ================================================
-- CRUD 7: Unenroll Student from Course
-- ================================================

CREATE PROCEDURE SP_UnenrollStudentFromCourse
    @S_Id INT,
    @Course_Id INT
AS
BEGIN
    SET NOCOUNT ON;
    
    BEGIN TRY
        BEGIN TRANSACTION
        
        -- Check if enrollment exists
        IF NOT EXISTS (SELECT 1 FROM Student_Course WHERE S_Id = @S_Id AND Course_Id = @Course_Id)
        BEGIN
            RAISERROR('Student %d is not enrolled in course %d', 16, 1, @S_Id, @Course_Id)
            RETURN
        END
        
        -- Check for exam dependencies
        IF EXISTS (
            SELECT 1 FROM Student_Exam se
            INNER JOIN Exam e ON se.E_Id = e.E_Id
            WHERE se.S_Id = @S_Id AND e.C_Id = @Course_Id
        )
        BEGIN
            RAISERROR('Cannot unenroll: student has taken exams for this course', 16, 1)
            RETURN
        END
        
        -- Delete enrollment
        DELETE FROM Student_Course 
        WHERE S_Id = @S_Id AND Course_Id = @Course_Id
        
        -- Also remove teaching assignments for this student-course
        DELETE FROM Teaching 
        WHERE S_Id = @S_Id AND C_Id = @Course_Id
        
        COMMIT TRANSACTION
        
        PRINT 'Student unenrolled successfully'
        
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION
        
        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE()
        RAISERROR(@ErrorMessage, 16, 1)
    END CATCH
END
GO

-- ================================================
-- CRUD 8: Get Student Enrollments
-- ================================================

CREATE PROCEDURE SP_GetStudentEnrollments
    @S_Id INT
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Validate student exists
    IF NOT EXISTS (SELECT 1 FROM Student WHERE S_Id = @S_Id)
    BEGIN
        RAISERROR('Student ID %d does not exist', 16, 1, @S_Id)
        RETURN
    END
    
    SELECT 
        s.S_FName + ' ' + s.S_LName AS StudentName,
        c.C_Id,
        c.C_Name AS CourseName,
        c.C_Des AS CourseDescription,
        c.C_Duration,
        sc.Enrollment_Date,
        t.Track_Name,
        DATEDIFF(DAY, sc.Enrollment_Date, GETDATE()) AS DaysEnrolled,
        (SELECT COUNT(*) FROM Exam WHERE C_Id = c.C_Id) AS TotalExams,
        (SELECT COUNT(*) FROM Student_Exam se 
         INNER JOIN Exam e ON se.E_Id = e.E_Id 
         WHERE se.S_Id = @S_Id AND e.C_Id = c.C_Id) AS ExamsTaken
    FROM Student s
    INNER JOIN Student_Course sc ON s.S_Id = sc.S_Id
    INNER JOIN Course c ON sc.Course_Id = c.C_Id
    LEFT JOIN Track t ON c.Track_Id = t.Track_Id
    WHERE s.S_Id = @S_Id
    ORDER BY sc.Enrollment_Date DESC
END
GO

-- ================================================
-- ADDITIONAL HELPER: Get Available Exams for Student
-- ================================================

CREATE PROCEDURE SP_GetAvailableExamsForStudent
    @S_Id INT
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Validate student exists
    IF NOT EXISTS (SELECT 1 FROM Student WHERE S_Id = @S_Id)
    BEGIN
        RAISERROR('Student ID %d does not exist', 16, 1, @S_Id)
        RETURN
    END
    
    SELECT 
        e.E_Id,
        e.E_Title,
        e.E_Total_Marks,
        e.E_Duaration AS Duration_Minutes,
        e.E_Date,
        c.C_Name AS CourseName,
        c.C_Id,
        CASE 
            WHEN se.E_Id IS NOT NULL THEN 'Taken'
            ELSE 'Available'
        END AS ExamStatus,
        se.Grade,
        se.Date_Taken,
        (SELECT COUNT(*) FROM Exam_Questions WHERE E_Id = e.E_Id) AS TotalQuestions
    FROM Student_Course sc
    INNER JOIN Course c ON sc.Course_Id = c.C_Id
    INNER JOIN Exam e ON c.C_Id = e.C_Id
    LEFT JOIN Student_Exam se ON e.E_Id = se.E_Id AND se.S_Id = @S_Id
    WHERE sc.S_Id = @S_Id
    ORDER BY e.E_Date DESC, c.C_Name
END
GO

PRINT ''
PRINT '================================================'
PRINT 'Person 2 Stored Procedures Created Successfully!'
PRINT '================================================'
PRINT ''
PRINT 'Summary:'
PRINT '  - 1 Main Function: SP_SubmitStudentAnswers'
PRINT '  - 2 Reports: SP_GetStudentsByDepartment, SP_GetStudentGrades'
PRINT '  - 8 CRUD: Student operations, Phones, Enrollments'
PRINT '  - 1 Helper: SP_GetAvailableExamsForStudent'
PRINT ''
PRINT 'Total: 12 stored procedures'
PRINT '================================================'
