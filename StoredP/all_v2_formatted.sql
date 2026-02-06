-- ============================================
-- STORED PROCEDURES - Organized by Entity
-- ============================================

-- ================================================
-- DEPARTMENT PROCEDURES
-- ================================================

CREATE PROCEDURE SP_CreateDepartment
    @DepartmentId INT,
    @DepartmentName NVARCHAR(100)
AS
BEGIN
    INSERT INTO Department(D_Id, D_Name)
    VALUES (@DepartmentId, @DepartmentName)
END
GO

CREATE PROCEDURE SP_UpdateDepartment
    @DepartmentId INT,
    @DepartmentName NVARCHAR(100)
AS
BEGIN
    UPDATE Department
    SET D_Name = @DepartmentName
    WHERE D_Id = @DepartmentId
END
GO

CREATE PROCEDURE SP_DeleteDepartment
    @DepartmentId INT
AS
BEGIN
    DELETE FROM Department
    WHERE D_Id = @DepartmentId
END
GO

-- ================================================
-- TRACK PROCEDURES
-- ================================================

CREATE PROCEDURE SP_CreateTrack
    @TrackId INT,
    @TrackName NVARCHAR(100),
    @TrackDescription NVARCHAR(200),
    @DepartmentId INT
AS
BEGIN
    INSERT INTO Track(Track_Id, Track_Name, Track_Des, Dep_Id)
    VALUES (@TrackId, @TrackName, @TrackDescription, @DepartmentId)
END
GO

CREATE PROCEDURE SP_UpdateTrack
    @TrackId INT,
    @TrackName NVARCHAR(100),
    @TrackDescription NVARCHAR(200),
    @DepartmentId INT
AS
BEGIN
    UPDATE Track
    SET Track_Name = @TrackName,
        Track_Des = @TrackDescription,
        Dep_Id = @DepartmentId
    WHERE Track_Id = @TrackId
END
GO

CREATE PROCEDURE SP_DeleteTrack
    @TrackId INT
AS
BEGIN
    DELETE FROM Track
    WHERE Track_Id = @TrackId
END
GO

CREATE PROCEDURE SP_GetTrackCourses
    @TrackId INT
AS
BEGIN
    SELECT C_Id, C_Name, C_Des, C_Duration, Track_Id
    FROM Course
    WHERE Track_Id = @TrackId
END
GO

CREATE PROCEDURE SP_AddTrackJobProfile
    @TrackId INT,
    @JobProfile NVARCHAR(100)
AS
BEGIN
    INSERT INTO Track_JobProfile(Track_Id, T_JobProfiles)
    VALUES (@TrackId, @JobProfile)
END
GO

CREATE PROCEDURE SP_RemoveTrackJobProfile
    @TrackId INT,
    @JobProfile NVARCHAR(100)
AS
BEGIN
    DELETE FROM Track_JobProfile
    WHERE Track_Id = @TrackId
      AND T_JobProfiles = @JobProfile
END
GO

-- ================================================
-- TOPIC PROCEDURES
-- ================================================

CREATE PROCEDURE SP_CreateTopic
    @TopicId INT,
    @TopicName NVARCHAR(50),
    @TopicDescription NVARCHAR(200)
AS
BEGIN
    INSERT INTO Topic(Topic_Id, Topic_Name, Topic_Des)
    VALUES (@TopicId, @TopicName, @TopicDescription)
END
GO

CREATE PROCEDURE SP_UpdateTopic
    @TopicId INT,
    @TopicName NVARCHAR(50),
    @TopicDescription NVARCHAR(200)
AS
BEGIN
    UPDATE Topic
    SET Topic_Name = @TopicName,
        Topic_Des = @TopicDescription
    WHERE Topic_Id = @TopicId
END
GO

CREATE PROCEDURE SP_DeleteTopic
    @TopicId INT
AS
BEGIN
    DELETE FROM Topic
    WHERE Topic_Id = @TopicId
END
GO

-- ================================================
-- COURSE PROCEDURES
-- ================================================

CREATE PROCEDURE SP_CreateCourse
    @c_id INT,
    @c_name NVARCHAR(100),
    @c_des NVARCHAR(200) = NULL,
    @c_duration INT,
    @track_id INT
AS
BEGIN
    IF EXISTS (SELECT 1 FROM course WHERE c_id = @c_id)
        THROW 51001, 'course already exists', 1;

    IF NOT EXISTS (SELECT 1 FROM track WHERE track_id = @track_id)
        THROW 51002, 'track not found', 1;

    INSERT INTO course (c_id, c_name, c_des, c_duration, track_id)
    VALUES (@c_id, @c_name, @c_des, @c_duration, @track_id);
END
GO

CREATE PROCEDURE SP_UpdateCourse
    @c_id INT,
    @c_name NVARCHAR(100) = NULL,
    @c_des NVARCHAR(200) = NULL,
    @c_duration INT = NULL,
    @track_id INT = NULL
AS
BEGIN
    IF NOT EXISTS (SELECT 1 FROM course WHERE c_id = @c_id)
        THROW 51003, 'course not found', 1;

    IF @track_id IS NOT NULL 
       AND NOT EXISTS (SELECT 1 FROM track WHERE track_id = @track_id)
        THROW 51004, 'track not found', 1;

    UPDATE course
    SET
        c_name = COALESCE(@c_name, c_name),
        c_des = COALESCE(@c_des, c_des),
        c_duration = COALESCE(@c_duration, c_duration),
        track_id = COALESCE(@track_id, track_id)
    WHERE c_id = @c_id;
END
GO

CREATE PROCEDURE SP_DeleteCourse
    @c_id INT
AS
BEGIN
    IF NOT EXISTS (SELECT 1 FROM course WHERE c_id = @c_id)
        THROW 51005, 'course not found', 1;

    DELETE FROM course
    WHERE c_id = @c_id;
END
GO

CREATE PROCEDURE SP_AssignTopicToCourse
    @c_id INT,
    @topic_id INT
AS
BEGIN
    IF NOT EXISTS (SELECT 1 FROM course WHERE c_id = @c_id)
        THROW 52001, 'course not found', 1;

    IF NOT EXISTS (SELECT 1 FROM topic WHERE topic_id = @topic_id)
        THROW 52002, 'topic not found', 1;

    IF EXISTS (
        SELECT 1 FROM course_topic
        WHERE c_id = @c_id AND topic_id = @topic_id
    )
        THROW 52003, 'topic already assigned to course', 1;

    INSERT INTO course_topic (c_id, topic_id)
    VALUES (@c_id, @topic_id);
END
GO

CREATE PROCEDURE SP_RemoveTopicFromCourse
    @c_id INT,
    @topic_id INT
AS
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM course_topic
        WHERE c_id = @c_id AND topic_id = @topic_id
    )
        THROW 52004, 'topic not assigned to course', 1;

    DELETE FROM course_topic
    WHERE c_id = @c_id AND topic_id = @topic_id;
END
GO

CREATE PROCEDURE SP_GetCourseTopics
    @CourseId INT
AS
BEGIN
    SELECT T.Topic_Name, T.Topic_Des
    FROM Course_Topic CT
    JOIN Topic T ON CT.Topic_Id = T.Topic_Id
    WHERE CT.C_Id = @CourseId;
END
GO

-- ================================================
-- INSTRUCTOR PROCEDURES
-- ================================================

CREATE PROCEDURE SP_CreateInstructor
    @ins_id INT,
    @ins_fname NVARCHAR(50) = NULL,
    @ins_lname NVARCHAR(50) = NULL,
    @ins_email NVARCHAR(100) = NULL,
    @password NVARCHAR(100) = NULL,
    @salary DECIMAL(10,2) = NULL,
    @ins_gender NVARCHAR(10) = NULL
AS
BEGIN
    IF EXISTS (SELECT 1 FROM instructor WHERE ins_id = @ins_id)
    BEGIN
        THROW 50001, 'instructor already exists', 1;
        RETURN;
    END

    BEGIN TRY
        INSERT INTO instructor
        (ins_id, ins_fname, ins_lname, ins_email, password, salary, ins_gender)
        VALUES
        (@ins_id, @ins_fname, @ins_lname, @ins_email, @password, @salary, @ins_gender);
    END TRY
    BEGIN CATCH
        THROW;
    END CATCH
END
GO

CREATE PROCEDURE SP_UpdateInstructor
    @InsId INT,
    @InsFName NVARCHAR(50) = NULL,
    @InsLName NVARCHAR(50) = NULL,
    @InsEmail NVARCHAR(100) = NULL,
    @InsPassword NVARCHAR(100) = NULL,
    @InsSalary DECIMAL(10,2) = NULL,
    @InsGender NVARCHAR(10) = NULL
AS
BEGIN
    IF NOT EXISTS (SELECT 1 FROM Instructor WHERE [Ins_Id] = @InsId)
        RETURN;

    UPDATE Instructor
    SET
        [Ins_FName] = COALESCE(@InsFName, [Ins_FName]),
        [Ins_Lname] = COALESCE(@InsLName, [Ins_Lname]),
        [Ins_Email] = COALESCE(@InsEmail, [Ins_Email]),
        [Password] = COALESCE(@InsPassword, [Password]),
        [Salary] = COALESCE(@InsSalary, [Salary]),
        [Ins_Gender] = COALESCE(@InsGender, [Ins_Gender])
    WHERE [Ins_Id] = @InsId
END
GO

CREATE PROCEDURE SP_DeleteInstructor
    @Ins_Id INT
AS
BEGIN
    DELETE FROM Instructor
    WHERE Ins_Id = @Ins_Id;
END
GO

CREATE PROCEDURE SP_AddInstructorPhone
    @ins_id INT,
    @phone NVARCHAR(20)
AS
BEGIN
    IF NOT EXISTS (SELECT 1 FROM instructor WHERE ins_id = @ins_id)
        THROW 50007, 'instructor not found', 1;

    IF EXISTS (
        SELECT 1 FROM instructor_phones
        WHERE ins_id = @ins_id AND phone = @phone
    )
        THROW 50008, 'duplicate phone', 1;

    INSERT INTO instructor_phones (ins_id, phone)
    VALUES (@ins_id, @phone);
END
GO

CREATE PROCEDURE SP_DeleteInstructorPhone
    @Ins_Id INT,
    @Phone NVARCHAR(20)
AS
BEGIN
    IF NOT EXISTS (SELECT 1 FROM Instructor WHERE Ins_Id = @Ins_Id)
        THROW 50007, 'instructor not found', 1;

    DELETE FROM Instructor_Phones
    WHERE Ins_Id = @Ins_Id
      AND Phone = @Phone;
END
GO

CREATE PROCEDURE SP_GetInstructorCourses
    @ins_id INT
AS
BEGIN
    SELECT 
        c.C_Name,
        COUNT(DISTINCT t.S_Id) AS students_count
    FROM Teaching t
    JOIN Course c ON t.C_Id = c.C_Id
    WHERE t.Ins_Id = @ins_id
    GROUP BY c.C_Name;
END
GO

-- ================================================
-- STUDENT PROCEDURES
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
        
        IF @S_Age < 16 OR @S_Age > 100
        BEGIN
            RAISERROR('Invalid age: must be between 16 and 100', 16, 1)
            RETURN
        END
        
        IF @S_GPA IS NOT NULL AND (@S_GPA < 0.0 OR @S_GPA > 4.0)
        BEGIN
            RAISERROR('Invalid GPA: must be between 0.0 and 4.0', 16, 1)
            RETURN
        END
        
        IF EXISTS (SELECT 1 FROM Student WHERE S_Email = @S_Email)
        BEGIN
            RAISERROR('Email %s already exists', 16, 1, @S_Email)
            RETURN
        END
        
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
        IF NOT EXISTS (SELECT 1 FROM Student WHERE S_Id = @S_Id)
        BEGIN
            RAISERROR('Student ID %d does not exist', 16, 1, @S_Id)
            RETURN
        END
        
        IF @S_Age IS NOT NULL AND (@S_Age < 16 OR @S_Age > 100)
        BEGIN
            RAISERROR('Invalid age: must be between 16 and 100', 16, 1)
            RETURN
        END
        
        IF @S_GPA IS NOT NULL AND (@S_GPA < 0.0 OR @S_GPA > 4.0)
        BEGIN
            RAISERROR('Invalid GPA: must be between 0.0 and 4.0', 16, 1)
            RETURN
        END
        
        IF @S_Email IS NOT NULL AND EXISTS (
            SELECT 1 FROM Student WHERE S_Email = @S_Email AND S_Id <> @S_Id
        )
        BEGIN
            RAISERROR('Email %s already exists', 16, 1, @S_Email)
            RETURN
        END
        
        IF @Track_Id IS NOT NULL AND NOT EXISTS (SELECT 1 FROM Track WHERE Track_Id = @Track_Id)
        BEGIN
            RAISERROR('Track ID %d does not exist', 16, 1, @Track_Id)
            RETURN
        END
        
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

CREATE PROCEDURE SP_DeleteStudent
    @S_Id INT,
    @Force BIT = 0
AS
BEGIN
    SET NOCOUNT ON;
    
    BEGIN TRY
        BEGIN TRANSACTION
        
        IF NOT EXISTS (SELECT 1 FROM Student WHERE S_Id = @S_Id)
        BEGIN
            RAISERROR('Student ID %d does not exist', 16, 1, @S_Id)
            RETURN
        END
        
        DECLARE @HasExams INT = (SELECT COUNT(*) FROM Student_Exam WHERE S_Id = @S_Id)
        DECLARE @HasAnswers INT = (SELECT COUNT(*) FROM Student_Answer WHERE S_Id = @S_Id)
        DECLARE @HasEnrollments INT = (SELECT COUNT(*) FROM Student_Course WHERE S_Id = @S_Id)
        
        IF (@HasExams > 0 OR @HasAnswers > 0 OR @HasEnrollments > 0) AND @Force = 0
        BEGIN
            RAISERROR('Cannot delete student: has related records (exams: %d, answers: %d, enrollments: %d). Use @Force = 1 to cascade delete.',
                       16, 1, @HasExams, @HasAnswers, @HasEnrollments)
            RETURN
        END
        
        IF @Force = 1
        BEGIN
            DELETE FROM Student_Answer WHERE S_Id = @S_Id
            DELETE FROM Student_Exam WHERE S_Id = @S_Id
            DELETE FROM Student_Course WHERE S_Id = @S_Id
            DELETE FROM Teaching WHERE S_Id = @S_Id
            DELETE FROM Student_Phones WHERE S_Id = @S_Id
        END
        
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

CREATE PROCEDURE SP_AddStudentPhone
    @S_Id INT,
    @S_Phone NVARCHAR(20)
AS
BEGIN
    SET NOCOUNT ON;
    
    BEGIN TRY
        IF NOT EXISTS (SELECT 1 FROM Student WHERE S_Id = @S_Id)
        BEGIN
            RAISERROR('Student ID %d does not exist', 16, 1, @S_Id)
            RETURN
        END
        
        IF EXISTS (SELECT 1 FROM Student_Phones WHERE S_Id = @S_Id AND S_Phone = @S_Phone)
        BEGIN
            RAISERROR('Phone number %s already exists for this student', 16, 1, @S_Phone)
            RETURN
        END
        
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

CREATE PROCEDURE SP_DeleteStudentPhone
    @S_Id INT,
    @S_Phone NVARCHAR(20)
AS
BEGIN
    SET NOCOUNT ON;
    
    BEGIN TRY
        IF NOT EXISTS (SELECT 1 FROM Student_Phones WHERE S_Id = @S_Id AND S_Phone = @S_Phone)
        BEGIN
            RAISERROR('Phone number %s not found for student %d', 16, 1, @S_Phone, @S_Id)
            RETURN
        END
        
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

CREATE PROCEDURE SP_GetStudentGrades
    @S_Id INT
AS
BEGIN
    SET NOCOUNT ON;
    
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
-- STUDENT ENROLLMENT PROCEDURES
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
        
        IF NOT EXISTS (SELECT 1 FROM Student WHERE S_Id = @S_Id)
        BEGIN
            RAISERROR('Student ID %d does not exist', 16, 1, @S_Id)
            RETURN
        END
        
        IF NOT EXISTS (SELECT 1 FROM Course WHERE C_Id = @Course_Id)
        BEGIN
            RAISERROR('Course ID %d does not exist', 16, 1, @Course_Id)
            RETURN
        END
        
        IF EXISTS (SELECT 1 FROM Student_Course WHERE S_Id = @S_Id AND Course_Id = @Course_Id)
        BEGIN
            RAISERROR('Student %d is already enrolled in course %d', 16, 1, @S_Id, @Course_Id)
            RETURN
        END
        
        IF @Enrollment_Date IS NULL
            SET @Enrollment_Date = GETDATE()
        
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

CREATE PROCEDURE SP_EnrollStudentInTrackCourses
    @S_Id INT,
    @Track_Id INT
AS
BEGIN
    SET NOCOUNT ON;
    
    BEGIN TRY
        IF NOT EXISTS (SELECT 1 FROM Student WHERE S_Id = @S_Id)
        BEGIN
            RAISERROR('Student ID %d does not exist', 16, 1, @S_Id)
            RETURN
        END
        
        IF NOT EXISTS (SELECT 1 FROM Track WHERE Track_Id = @Track_Id)
        BEGIN
            RAISERROR('Track ID %d does not exist', 16, 1, @Track_Id)
            RETURN
        END
        
        DECLARE @CourseId INT
        DECLARE @EnrollmentCount INT = 0
        
        DECLARE course_cursor CURSOR FOR
        SELECT C_Id
        FROM Course
        WHERE Track_Id = @Track_Id
        
        OPEN course_cursor
        FETCH NEXT FROM course_cursor INTO @CourseId
        
        WHILE @@FETCH_STATUS = 0
        BEGIN
            IF NOT EXISTS (SELECT 1 FROM Student_Course WHERE S_Id = @S_Id AND Course_Id = @CourseId)
            BEGIN
                EXEC SP_EnrollStudentInCourse @S_Id = @S_Id, @Course_Id = @CourseId
                SET @EnrollmentCount = @EnrollmentCount + 1
            END
            
            FETCH NEXT FROM course_cursor INTO @CourseId
        END
        
        CLOSE course_cursor
        DEALLOCATE course_cursor
        
        PRINT 'Student ' + CAST(@S_Id AS VARCHAR) + ' enrolled in ' + CAST(@EnrollmentCount AS VARCHAR) + ' new courses for track ' + CAST(@Track_Id AS VARCHAR)
        
    END TRY
    BEGIN CATCH
        IF CURSOR_STATUS('local', 'course_cursor') >= 0
        BEGIN
            CLOSE course_cursor
            DEALLOCATE course_cursor
        END
        
        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE()
        DECLARE @ErrorSeverity INT = ERROR_SEVERITY()
        DECLARE @ErrorState INT = ERROR_STATE()
        
        RAISERROR(@ErrorMessage, @ErrorSeverity, @ErrorState)
    END CATCH
END
GO

CREATE PROCEDURE SP_UnenrollStudentFromCourse
    @S_Id INT,
    @Course_Id INT
AS
BEGIN
    SET NOCOUNT ON;
    
    BEGIN TRY
        BEGIN TRANSACTION
        
        IF NOT EXISTS (SELECT 1 FROM Student_Course WHERE S_Id = @S_Id AND Course_Id = @Course_Id)
        BEGIN
            RAISERROR('Student %d is not enrolled in course %d', 16, 1, @S_Id, @Course_Id)
            RETURN
        END
        
        IF EXISTS (
            SELECT 1 FROM Student_Exam se
            INNER JOIN Exam e ON se.E_Id = e.E_Id
            WHERE se.S_Id = @S_Id AND e.C_Id = @Course_Id
        )
        BEGIN
            RAISERROR('Cannot unenroll: student has taken exams for this course', 16, 1)
            RETURN
        END
        
        DELETE FROM Student_Course 
        WHERE S_Id = @S_Id AND Course_Id = @Course_Id
        
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

CREATE PROCEDURE SP_GetStudentEnrollments
    @S_Id INT
AS
BEGIN
    SET NOCOUNT ON;
    
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
-- TEACHING PROCEDURES
-- ================================================

CREATE PROCEDURE SP_AssignTeaching
    @s_id INT,
    @ins_id INT,
    @c_id INT
AS
BEGIN
    IF NOT EXISTS (SELECT 1 FROM student WHERE s_id = @s_id)
        THROW 53001, 'student not found', 1;

    IF NOT EXISTS (SELECT 1 FROM instructor WHERE ins_id = @ins_id)
        THROW 53002, 'instructor not found', 1;

    IF NOT EXISTS (SELECT 1 FROM course WHERE c_id = @c_id)
        THROW 53003, 'course not found', 1;

    IF EXISTS (
        SELECT 1 FROM teaching
        WHERE s_id = @s_id
          AND ins_id = @ins_id
          AND c_id = @c_id
    )
        THROW 53004, 'teaching assignment already exists', 1;

    INSERT INTO teaching (s_id, ins_id, c_id)
    VALUES (@s_id, @ins_id, @c_id);
END
GO

CREATE PROCEDURE SP_RemoveTeaching
    @s_id INT,
    @ins_id INT,
    @c_id INT
AS
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM teaching
        WHERE s_id = @s_id
          AND ins_id = @ins_id
          AND c_id = @c_id
    )
        THROW 53005, 'teaching assignment not found', 1;

    DELETE FROM teaching
    WHERE s_id = @s_id
      AND ins_id = @ins_id
      AND c_id = @c_id;
END
GO

-- ================================================
-- QUESTION PROCEDURES
-- ================================================

CREATE PROCEDURE SP_CreateQuestion
    @Qid INT,
    @Q_Content NVARCHAR(400),
    @Q_Type NVARCHAR(50),
    @Q_Points FLOAT,
    @Q_hardness NVARCHAR(50)
AS
BEGIN
    INSERT INTO Question
    VALUES (@Qid, @Q_Content, @Q_Type, @Q_Points, @Q_hardness)
END
GO

CREATE PROCEDURE SP_UpdateQuestion
    @Qid INT,
    @Q_Content NVARCHAR(400),
    @Q_Type NVARCHAR(50),
    @Q_Points FLOAT,
    @Q_hardness NVARCHAR(50)
AS
BEGIN
    UPDATE Question
    SET Q_Content = @Q_Content,
        Q_hardness = @Q_hardness,
        Q_Points = @Q_Points,
        Q_Type = @Q_Type
    WHERE Q_Id = @Qid
END
GO

CREATE PROCEDURE SP_DeleteQuestion
    @Qid INT
AS
BEGIN
    UPDATE dbo.Student_Answer
    SET Choice_Id = NULL
    WHERE Question_Id = @Qid;

    DELETE FROM dbo.Student_Answer
    WHERE Question_Id = @Qid;

    DELETE FROM dbo.Choice
    WHERE Q_Id = @Qid;

    IF OBJECT_ID('dbo.Exam_Question', 'U') IS NOT NULL
    BEGIN
        DELETE FROM dbo.Exam_Question WHERE Question_Id = @Qid;
    END

    DELETE FROM dbo.Question
    WHERE Q_Id = @Qid;
END
GO

-- ================================================
-- CHOICE PROCEDURES
-- ================================================

CREATE PROCEDURE SP_CreateChoice
    @c_id INT,
    @Qid INT,
    @isC BIT,
    @C_c NVARCHAR(100)
AS
BEGIN
    INSERT INTO Choice
    VALUES (@c_id, @Qid, @isC, @C_c)
END
GO

CREATE PROCEDURE SP_UpdateChoice
    @c_id INT,
    @Qid INT,
    @isC BIT,
    @C_c NVARCHAR(100)
AS
BEGIN
    UPDATE Choice
    SET Q_id = @Qid,
        Is_Correct = @isC,
        Choice_Content = @C_c
    WHERE Choice_Id = @c_id
END
GO

CREATE PROCEDURE SP_DeleteChoice
    @Cid INT
AS
BEGIN
    DELETE FROM Choice
    WHERE Choice_Id = @Cid
END
GO

-- ================================================
-- EXAM PROCEDURES
-- ================================================

CREATE PROCEDURE SP_CreateExam
    @ExamId INT,
    @ExamTitle NVARCHAR(50),
    @TotalMarks FLOAT,
    @Duration FLOAT,
    @ExamDate DATE,
    @CourseId INT
AS
BEGIN
    INSERT INTO Exam (E_Id, E_Title, E_Total_Marks, E_Duaration, E_Date, C_Id)
    VALUES (@ExamId, @ExamTitle, @TotalMarks, @Duration, @ExamDate, @CourseId)
END
GO

CREATE PROCEDURE SP_UpdateExam
    @ExamId INT,
    @ExamTitle NVARCHAR(50),
    @TotalMarks FLOAT,
    @Duration FLOAT,
    @ExamDate DATE
AS
BEGIN
    UPDATE Exam
    SET E_Title = @ExamTitle,
        E_Total_Marks = @TotalMarks,
        E_Duaration = @Duration,
        E_Date = @ExamDate
    WHERE E_Id = @ExamId
END
GO

CREATE PROCEDURE SP_DeleteExam
    @ExamId INT
AS
BEGIN
    DELETE FROM Exam
    WHERE E_Id = @ExamId
END
GO

CREATE PROCEDURE SP_GenerateExam
    @C_Id INT,
    @NumTrueFalse INT,
    @NumMCQ INT,
    @E_Id INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    
    INSERT INTO Exam (E_Title, E_Total_Marks, E_Duaration, E_Date, C_Id)
    VALUES ('Auto Generated Exam', 0, 60, GETDATE(), @C_Id);
    
    SET @E_Id = SCOPE_IDENTITY();
    
    INSERT INTO Exam_Questions (E_Id, Q_Id)
    SELECT TOP (@NumTrueFalse) @E_Id, Q_Id
    FROM Question
    WHERE Q_Type = 'TF'
      AND C_Id = @C_Id
    ORDER BY NEWID();
    
    INSERT INTO Exam_Questions (E_Id, Q_Id)
    SELECT TOP (@NumMCQ) @E_Id, Q_Id
    FROM Question
    WHERE Q_Type = 'MCQ'
      AND C_Id = @C_Id
    ORDER BY NEWID();
    
    UPDATE Exam
    SET E_Total_Marks = (
        SELECT SUM(Q.Q_Points)
        FROM Exam_Questions EQ
        JOIN Question Q ON EQ.Q_Id = Q.Q_Id
        WHERE EQ.E_Id = @E_Id
    )
    WHERE E_Id = @E_Id;
    
    PRINT 'Exam generated for Course ' + CAST(@C_Id AS VARCHAR) + ' with Exam ID: ' + CAST(@E_Id AS VARCHAR);
END
GO

CREATE PROCEDURE SP_GetExamQuestions
    @ExamId INT
AS
BEGIN
    SELECT
        eq.E_Id,
        q.Q_Id,
        q.Q_Content,
        q.Q_Type,
        q.Q_Points,
        q.Q_Hardness,
        c.Choice_Id,
        c.Choice_Content,
        c.Is_Correct
    FROM Exam_Questions eq
    INNER JOIN Question q ON eq.Q_Id = q.Q_Id
    INNER JOIN Choice c ON q.Q_Id = c.Q_Id
    WHERE eq.E_Id = @ExamId
    ORDER BY q.Q_Id, c.Choice_Id
END
GO

CREATE PROCEDURE SP_GetExamQuestionsWithChoices
    @E_Id INT
AS
BEGIN
    SELECT 
        e.E_Id AS ExamId,
        eq.Q_Id AS QuestionId,
        q.Q_Content AS Content,
        q.Q_Type AS Type,
        q.Q_Points AS Points,
        c.Choice_Id AS ChoiceId,
        c.Choice_Content AS ChoiceContent,
        c.Is_Correct AS IsCorrect
    FROM Exam e
    INNER JOIN Exam_Questions eq ON e.E_Id = eq.E_Id
    INNER JOIN Question q ON eq.Q_Id = q.Q_Id
    LEFT JOIN Choice c ON q.Q_Id = c.Q_Id
    WHERE e.E_Id = @E_Id
    ORDER BY eq.Q_Id, c.Choice_Id
END
GO

CREATE PROCEDURE SP_GetAvailableExamsForStudent
    @S_Id INT
AS
BEGIN
    SET NOCOUNT ON;
    
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

-- ================================================
-- STUDENT EXAM ANSWER PROCEDURES
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
        
        IF NOT EXISTS (SELECT 1 FROM Exam WHERE E_Id = @E_Id)
        BEGIN
            RAISERROR('Exam ID %d does not exist', 16, 1, @E_Id)
            RETURN
        END
        
        IF NOT EXISTS (SELECT 1 FROM Student WHERE S_Id = @S_Id)
        BEGIN
            RAISERROR('Student ID %d does not exist', 16, 1, @S_Id)
            RETURN
        END
        
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
        
        DECLARE @NextAId INT = ISNULL((SELECT MAX(A_Id) FROM Student_Answer), 0) + 1
        
        INSERT INTO Student_Answer (A_Id, Question_Id, Exam_Id, Choice_Id, S_Id)
        SELECT
            @NextAId + ROW_NUMBER() OVER (ORDER BY Q_Id) - 1,
            Q_Id,
            @E_Id,
            Choice_Id,
            @S_Id
        FROM @Answers
        
        IF EXISTS (SELECT 1 FROM Student_Exam WHERE S_Id = @S_Id AND E_Id = @E_Id)
        BEGIN
            UPDATE Student_Exam
            SET Date_Taken = GETDATE()
            WHERE S_Id = @S_Id AND E_Id = @E_Id
        END
        ELSE
        BEGIN
            INSERT INTO Student_Exam (S_Id, E_Id, Grade, Date_Taken)
            VALUES (@S_Id, @E_Id, NULL, GETDATE())
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

CREATE PROCEDURE SP_GetStudentExamAnswers
    @StudentId INT,
    @ExamId INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        q.Q_Id,
        q.Q_Content,
        q.Q_Points,
        sc.Choice_Content AS Student_Answer,
        ISNULL(cc.Choice_Content, 'N/A') AS Correct_Answer,
        CASE
            WHEN sc.Is_Correct = 1 THEN 'Correct'
            ELSE 'Wrong'
        END AS Answer_Status
    FROM Student_Answer sa
    INNER JOIN Question q ON sa.Question_Id = q.Q_Id
    INNER JOIN Choice sc ON sa.Choice_Id = sc.Choice_Id AND sa.Question_Id = sc.Q_Id
    LEFT JOIN Choice cc ON q.Q_Id = cc.Q_Id AND cc.Is_Correct = 1
    WHERE sa.S_Id = @StudentId
      AND sa.Exam_Id = @ExamId
    ORDER BY q.Q_Id;
END
GO

CREATE PROCEDURE SP_CorrectExam
    @E_Id INT,
    @S_Id INT,
    @ScorePercentage DECIMAL(5,2) OUTPUT
AS
BEGIN
    DECLARE @TotalPoints FLOAT = 0;
    DECLARE @EarnedPoints FLOAT = 0;

    SELECT
        q.Q_Id,
        q.Q_Content,
        sa.Choice_Id AS Student_Choice_Id,
        sc.Choice_Content AS Student_Answer,
        cc.Choice_Id AS Correct_Choice_Id,
        cc.Choice_Content AS Correct_Answer,
        CASE
            WHEN sc.Choice_Id = cc.Choice_Id THEN q.Q_Points
            ELSE 0
        END AS Earned_Points,
        q.Q_Points
    FROM Exam_Questions eq
    JOIN Question q ON eq.Q_Id = q.Q_Id
    LEFT JOIN Student_Answer sa
        ON sa.Question_Id = q.Q_Id
        AND sa.Exam_Id = @E_Id
        AND sa.S_Id = @S_Id
    LEFT JOIN Choice sc
        ON sc.Choice_Id = sa.Choice_Id
        AND sc.Q_Id = q.Q_Id
    JOIN Choice cc
        ON cc.Q_Id = q.Q_Id
        AND cc.Is_Correct = 1
    WHERE eq.E_Id = @E_Id;

    SELECT @TotalPoints = SUM(q.Q_Points)
    FROM Exam_Questions eq
    JOIN Question q ON eq.Q_Id = q.Q_Id
    WHERE eq.E_Id = @E_Id;

    SELECT @EarnedPoints = SUM(
        CASE
            WHEN sc.Choice_Id = cc.Choice_Id THEN q.Q_Points
            ELSE 0
        END
    )
    FROM Exam_Questions eq
    JOIN Question q ON eq.Q_Id = q.Q_Id
    LEFT JOIN Student_Answer sa
        ON sa.Question_Id = q.Q_Id
        AND sa.Exam_Id = @E_Id
        AND sa.S_Id = @S_Id
    LEFT JOIN Choice sc
        ON sc.Choice_Id = sa.Choice_Id
        AND sc.Q_Id = q.Q_Id
    JOIN Choice cc
        ON cc.Q_Id = q.Q_Id
        AND cc.Is_Correct = 1
    WHERE eq.E_Id = @E_Id;

    SET @ScorePercentage =
        CASE
            WHEN @TotalPoints = 0 THEN 0
            ELSE (@EarnedPoints / @TotalPoints) * 100
        END;

    IF EXISTS (
        SELECT 1 FROM Student_Exam
        WHERE S_Id = @S_Id AND E_Id = @E_Id
    )
    BEGIN
        UPDATE Student_Exam
        SET Grade = @ScorePercentage,
            Date_Taken = GETDATE()
        WHERE S_Id = @S_Id AND E_Id = @E_Id;
    END
    ELSE
    BEGIN
        INSERT INTO Student_Exam (S_Id, E_Id, Grade, Date_Taken)
        VALUES (@S_Id, @E_Id, @ScorePercentage, GETDATE());
    END
END
GO

-- ================================================
-- API HELPER PROCEDURES
-- ================================================

-- Get next available student ID
CREATE PROCEDURE SP_GetNextStudentId
AS
BEGIN
    SELECT ISNULL(MAX(S_Id), 0) + 1 AS NextId FROM Student
END
GO

-- Get count of student enrollments
CREATE PROCEDURE SP_GetStudentEnrollmentCount
    @StudentId INT
AS
BEGIN
    SELECT COUNT(*) AS EnrollmentCount 
    FROM Student_Course 
    WHERE S_Id = @StudentId
END
GO

-- Student login authentication
CREATE PROCEDURE SP_LoginStudent
    @Email NVARCHAR(100),
    @Password NVARCHAR(100)
AS
BEGIN
    SELECT S_Id, S_FName, S_LName, S_Email 
    FROM Student 
    WHERE S_Email = @Email AND Password = @Password
END
GO

-- Get all tracks ordered by name
CREATE PROCEDURE SP_GetAllTracks
AS
BEGIN
    SELECT Track_Id, Track_Name 
    FROM Track 
    ORDER BY Track_Name
END
GO

-- Get course ID by name
CREATE PROCEDURE SP_GetCourseIdByName
    @CourseName NVARCHAR(100)
AS
BEGIN
    SELECT C_Id 
    FROM Course 
    WHERE C_Name = @CourseName
END
GO

-- Verify student course enrollment
CREATE PROCEDURE SP_VerifyStudentCourseEnrollment
    @StudentId INT,
    @CourseId INT
AS
BEGIN
    SELECT COUNT(*) AS IsEnrolled
    FROM Student_Course 
    WHERE S_Id = @StudentId AND Course_Id = @CourseId
END
GO

-- Get True/False choices for an exam
CREATE PROCEDURE SP_GetTrueFalseChoices
    @ExamId INT
AS
BEGIN
    SELECT 
        eq.Q_Id, 
        c.Choice_Id, 
        c.Choice_Content 
    FROM Exam_Questions eq
    INNER JOIN Question q ON eq.Q_Id = q.Q_Id
    INNER JOIN Choice c ON q.Q_Id = c.Q_Id
    WHERE eq.E_Id = @ExamId 
      AND q.Q_Type IN ('TF', 'TrueFalse')
END
GO

-- Get student's answer choices for an exam
CREATE PROCEDURE SP_GetStudentAnswerChoices
    @StudentId INT,
    @ExamId INT
AS
BEGIN
    SELECT Question_Id, Choice_Id 
    FROM Student_Answer 
    WHERE S_Id = @StudentId AND Exam_Id = @ExamId
END
GO

-- Get student's enrolled courses
CREATE PROCEDURE SP_GetStudentEnrolledCourses
    @StudentId INT
AS
BEGIN
    SELECT 
        c.C_Id,
        c.C_Name AS CourseName,
        c.C_Des AS CourseDescription,
        sc.Enrollment_Date
    FROM Student_Course sc
    INNER JOIN Course c ON sc.Course_Id = c.C_Id
    WHERE sc.S_Id = @StudentId
    ORDER BY sc.Enrollment_Date DESC
END
GO

-- Insert new student record
CREATE PROCEDURE SP_InsertStudent
    @SId INT,
    @FName NVARCHAR(50),
    @LName NVARCHAR(50),
    @Email NVARCHAR(100),
    @Password NVARCHAR(100),
    @Age INT,
    @GPA FLOAT,
    @TrackId INT,
    @DepId INT
AS
BEGIN
    INSERT INTO Student 
    (S_Id, S_FName, S_LName, S_Email, Password, S_Age, S_GPA, Track_id, Dep_id) 
    VALUES 
    (@SId, @FName, @LName, @Email, @Password, @Age, @GPA, @TrackId, @DepId)
END
GO
