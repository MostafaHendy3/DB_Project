go

Create or alter Procedure SP_GetInstructorCourses @ins_id int
as
  
      SELECT 
        c.C_Name,
        COUNT(DISTINCT t.S_Id) AS students_count
    FROM Teaching t
    JOIN Course c ON t.C_Id = c.C_Id
    WHERE t.Ins_Id = @ins_id
    GROUP BY c.C_Name;


go

go 
create or alter procedure SP_GetCourseTopics  @CourseId INT
as
SELECT T.Topic_Name,T.Topic_Des
    FROM Course_Topic CT
    JOIN Topic T ON CT.Topic_Id = T.Topic_Id
    WHERE CT.C_Id = @CourseId;

	go

	go
create or alter procedure SP_CreateInstructor 
	@ins_id int,
    @ins_fname nvarchar(50) = null,
    @ins_lname nvarchar(50) = null,
    @ins_email nvarchar(100) = null,
    @password nvarchar(100) = null,
    @salary decimal(10,2) = null,
    @ins_gender nvarchar(10) = null
	as 
	begin
	if exists (select 1 from instructor where ins_id = @ins_id)
    begin
        throw 50001, 'instructor already exists', 1;
        return;
    end
    begin try
        insert into instructor
        (ins_id, ins_fname, ins_lname, ins_email, password, salary, ins_gender)
        values
        (@ins_id, @ins_fname, @ins_lname, @ins_email, @password, @salary, @ins_gender);
    end try
    begin catch
        throw;
    end catch
	end
	go


	go

	create or alter procedure SP_UpdateInstructor 
	@InsId int,
	@InsFName nvarchar(50) = null,
	@InsLName nvarchar(50) = Null,
	@InsEmail nvarchar(100) = Null,
	@InsPassword nvarchar(100) = Null,
	@InsSalary decimal(10,2) = Null,
	@InsGender nvarchar(10) = Null
	as
begin
	IF NOT EXISTS (SELECT 1 FROM Instructor WHERE [Ins_Id] = @InsId)
		RETURN;

	update Instructor
	set
		[Ins_FName] = COALESCE(@InsFName, [Ins_FName]),
		[Ins_Lname] = COALESCE(@InsLName, [Ins_Lname]),
		[Ins_Email] = COALESCE(@InsEmail, [Ins_Email]),
		[Password] = COALESCE(@InsPassword, [Password]),
		[Salary] = COALESCE(@InsSalary, [Salary]),
		[Ins_Gender] = COALESCE(@InsGender, [Ins_Gender])

	where [Ins_Id] = @InsId
end;
go


go 
create or alter procedure SP_DeleteInstructor @Ins_Id INT
as 
DELETE FROM Instructor
    WHERE Ins_Id = @Ins_Id;

	go

	go
	create or alter procedure SP_AddInstructorPhone   @ins_id int,
    @phone nvarchar(20)
	as 
	 if not exists (select 1 from instructor where ins_id = @ins_id)
        throw 50007, 'instructor not found', 1;

    if exists (
        select 1 from instructor_phones
        where ins_id = @ins_id and phone = @phone
    )
        throw 50008, 'duplicate phone', 1;

    insert into instructor_phones (ins_id, phone)
    values (@ins_id, @phone);
	go

	go
	create or alter procedure SP_DeleteInstructorPhone @Ins_Id INT,
    @Phone NVARCHAR(20)
	as
	 IF NOT EXISTS (SELECT 1 FROM Instructor WHERE Ins_Id = @Ins_Id)
		   throw 50007, 'instructor not found', 1;

    DELETE FROM Instructor_Phones
    WHERE Ins_Id = @Ins_Id
      AND Phone = @Phone;
	  go



	go
create or alter procedure SP_CreateCourse
    @c_id int,
    @c_name nvarchar(100),
    @c_des nvarchar(200) = null,
    @c_duration int,
    @track_id int
as
begin
    if exists (select 1 from course where c_id = @c_id)
        throw 51001, 'course already exists', 1;

    if not exists (select 1 from track where track_id = @track_id)
        throw 51002, 'track not found', 1;

    insert into course (c_id, c_name, c_des, c_duration, track_id)
    values (@c_id, @c_name, @c_des, @c_duration, @track_id);
end
go

create or alter procedure SP_UpdateCourse
    @c_id int,
    @c_name nvarchar(100) = null,
    @c_des nvarchar(200) = null,
    @c_duration int = null,
    @track_id int = null
as
begin
    if not exists (select 1 from course where c_id = @c_id)
        throw 51003, 'course not found', 1;

    if @track_id is not null
       and not exists (select 1 from track where track_id = @track_id)
        throw 51004, 'track not found', 1;

    update course
    set
        c_name = coalesce(@c_name, c_name),
        c_des = coalesce(@c_des, c_des),
        c_duration = coalesce(@c_duration, c_duration),
        track_id = coalesce(@track_id, track_id)
    where c_id = @c_id;
end
go

go
create or alter procedure SP_DeleteCourse
    @c_id int
as
begin
    if not exists (select 1 from course where c_id = @c_id)
        throw 51005, 'course not found', 1;

    delete from course
    where c_id = @c_id;
end
go

create or alter procedure SP_AssignTopicToCourse
    @c_id int,
    @topic_id int
as
begin
    if not exists (select 1 from course where c_id = @c_id)
        throw 52001, 'course not found', 1;

    if not exists (select 1 from topic where topic_id = @topic_id)
        throw 52002, 'topic not found', 1;

    if exists (
        select 1 from course_topic
        where c_id = @c_id and topic_id = @topic_id
    )
        throw 52003, 'topic already assigned to course', 1;

    insert into course_topic (c_id, topic_id)
    values (@c_id, @topic_id);
end
go

go
create or alter procedure SP_RemoveTopicFromCourse
    @c_id int,
    @topic_id int
as
begin
    if not exists (
        select 1 from course_topic
        where c_id = @c_id and topic_id = @topic_id
    )
        throw 52004, 'topic not assigned to course', 1;

    delete from course_topic
    where c_id = @c_id and topic_id = @topic_id;
end
go

go
create or alter procedure SP_AssignTeaching
    @s_id int,
    @ins_id int,
    @c_id int
as
begin
    if not exists (select 1 from student where s_id = @s_id)
        throw 53001, 'student not found', 1;

    if not exists (select 1 from instructor where ins_id = @ins_id)
        throw 53002, 'instructor not found', 1;

    if not exists (select 1 from course where c_id = @c_id)
        throw 53003, 'course not found', 1;

    if exists (
        select 1 from teaching
        where s_id = @s_id
          and ins_id = @ins_id
          and c_id = @c_id
    )
        throw 53004, 'teaching assignment already exists', 1;

    insert into teaching (s_id, ins_id, c_id)
    values (@s_id, @ins_id, @c_id);
end
go

go
create or alter procedure SP_RemoveTeaching
    @s_id int,
    @ins_id int,
    @c_id int
as
begin
    if not exists (
        select 1 from teaching
        where s_id = @s_id
          and ins_id = @ins_id
          and c_id = @c_id
    )
        throw 53005, 'teaching assignment not found', 1;

    delete from teaching
    where s_id = @s_id
      and ins_id = @ins_id
      and c_id = @c_id;
end
go