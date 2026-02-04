USE [ITI_E]
GO

-- ================================================
-- REPORT: Get Student Exam Answers
-- ================================================

CREATE PROCEDURE [dbo].[SP_GetStudentExamAnswers]
    @E_Id INT,
    @S_Id INT
AS
BEGIN
    SET NOCOUNT ON
    
    IF NOT EXISTS (SELECT 1 FROM Exam WHERE E_Id = @E_Id)
    BEGIN
        RAISERROR('Exam ID does not exist', 16, 1)
        RETURN
    END
    
    IF NOT EXISTS (SELECT 1 FROM Student WHERE S_Id = @S_Id)
    BEGIN
        RAISERROR('Student ID does not exist', 16, 1)
        RETURN
    END
    
    SELECT 
        e.E_Id,
        e.E_Title,
        e.E_Total_Marks,
        s.S_FName + ' ' + s.S_LName AS StudentName,
        q.Q_Id,
        q.Q_Content AS QuestionText,
        q.Q_Type,
        q.Q_Points,
        c.Choice_Id,
        c.Choice_Content,
        c.Is_Correct,
        CASE WHEN sa.Choice_Id = c.Choice_Id THEN 1 ELSE 0 END AS StudentSelected,
        CASE 
            WHEN sa.Choice_Id = c.Choice_Id AND c.Is_Correct = 1 THEN 'Correct'
            WHEN sa.Choice_Id = c.Choice_Id AND c.Is_Correct = 0 THEN 'Incorrect'
            WHEN sa.Choice_Id IS NULL THEN 'Not Answered'
            ELSE 'Wrong Answer'
        END AS AnswerStatus
    FROM Exam e
    INNER JOIN Exam_Questions eq ON e.E_Id = eq.E_Id
    INNER JOIN Question q ON eq.Q_Id = q.Q_Id
    INNER JOIN Student s ON s.S_Id = @S_Id
    LEFT JOIN Choice c ON q.Q_Id = c.Q_Id
    LEFT JOIN Student_Answer sa ON eq.E_Id = sa.Exam_Id AND eq.Q_Id = sa.Question_Id AND sa.S_Id = @S_Id
    WHERE e.E_Id = @E_Id
    ORDER BY q.Q_Id, c.Choice_Id
END
GO

USE [ITI_E2]
GO

CREATE PROCEDURE [dbo].[SP_GetExamQuestionsWithChoices]
    @E_Id INT
AS
BEGIN
    SELECT 
        e.E_Id,
        e.E_Title,
        e.E_Total_Marks,
        e.E_Duaration AS Duration_Minutes,
        eq.Q_Id,
        q.Q_Content,
        c.Choice_Id,
        c.Choice_Content,
        c.Is_Correct
    FROM Exam e
    INNER JOIN Exam_Questions eq ON e.E_Id = eq.E_Id
    INNER JOIN Question q ON eq.Q_Id = q.Q_Id
    LEFT JOIN Choice c ON q.Q_Id = c.Q_Id
    WHERE e.E_Id = @E_Id
    ORDER BY eq.Q_Id, c.Choice_Id
END
GO

