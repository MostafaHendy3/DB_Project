--=========================================================
--=============================--1.CREATE Question--==================
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

--=========================================================
--=======================(2)SP_UpdateQuestion==============
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
--========================================================
--======================(3)SP_DeleteQuestion===============
CREATE PROCEDURE SP_DeleteQuestion
    @Qid INT
AS
BEGIN
      UPDATE dbo.Student_Answer
    SET Choice_Id = NULL  -- Adjust column name if different (might be Selected_Choice_Id, Answer_Choice_Id, etc.)
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
--=================================================
--====================(4)SP_CreateChoice==========
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
--=====================================================
--====================(5)SP_UpdateChoice===============
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
--=====================================================
--=======================(6)SP_DeleteChoice===============
CREATE PROCEDURE SP_DeleteChoice
    @Cid INT
AS
BEGIN
    DELETE FROM Choice
    WHERE Choice_Id = @Cid
END
--===================================================
--====================================================
-- SP_GetExamQuestions - Display exam questions with choices
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
    INNER JOIN Question q
        ON eq.Q_Id = q.Q_Id
    INNER JOIN Choice c
        ON q.Q_Id = c.Q_Id
    WHERE eq.E_Id = @ExamId
    ORDER BY q.Q_Id, c.Choice_Id
END
--===================================================
-- SP_GetStudentExamAnswers
CREATE PROCEDURE SP_GetStudentExamAnswers
    @StudentId INT,
    @ExamId INT
AS
BEGIN
    SELECT
        q.Q_Id,
        q.Q_Content,
        q.Q_Points,
        sc.Choice_Content AS Student_Answer,
        cc.Choice_Content AS Correct_Answer,
        CASE
            WHEN sc.Is_Correct = 1 THEN 'Correct'
            ELSE 'Wrong'
        END AS Answer_Status
    FROM Student_Answer sa
    INNER JOIN Question q
        ON sa.Question_Id = q.Q_Id
    INNER JOIN Choice sc
        ON sa.Choice_Id = sc.Choice_Id
    INNER JOIN Choice cc
        ON q.Q_Id = cc.Q_Id
       AND cc.Is_Correct = 1
    WHERE sa.S_Id = @StudentId
      AND sa.Exam_Id = @ExamId
    ORDER BY q.Q_Id
END
--==============================================================
-- Generate Exam
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
    WHERE Q_Type = 'TrueFalse'
    ORDER BY NEWID();

    INSERT INTO Exam_Questions (E_Id, Q_Id)
    SELECT TOP (@NumMCQ) @E_Id, Q_Id
    FROM Question
    WHERE Q_Type = 'MCQ'
    ORDER BY NEWID();

    UPDATE Exam
    SET E_Total_Marks =
        (
            SELECT SUM(Q.Q_Points)
            FROM Exam_Questions EQ
            JOIN Question Q ON EQ.Q_Id = Q.Q_Id
            WHERE EQ.E_Id = @E_Id
        )
    WHERE E_Id = @E_Id;
END
--=====================================================
-- SP_CorrectExam
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
