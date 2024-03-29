create proc usd_get_program_path
@UserId INT
as
begin
select p.Id,p.P_title title, p.path path,p.Descr from Program_Master p 
inner join Tbl_Rights tr on p.Id=tr.Programe_id 
where tr.UserId = @UserId AND ( p.Status =1 AND tr.Status =1 )
order by p.Display_Sequence
end


exec usd_get_program_path 2



--Login--

create proc USP_LoginUser
@email varchar(50),
@pass varchar(100)
as
begin
	if(EXISTS(SELECT 1 from User_Master(NOLOCK) where Email=@email and Status=1))
	begin
	if exists (select 1 from User_Master where Email = @email AND Password = dbo.HashPassword(@pass))
	begin
		select 1 as result
	end
	else
	begin
		select 2 as result
	end
	end
	else
	begin
	select 3 as result
	end
end

exec USP_LoginUser 'rahul213@gmail.com', 'h@123'


create proc usp_get_user_by_email
@email varchar(100)
as
begin

select Id,Nm,Email,Mobile,Manager_Id 
		from User_Master(nolock) 
				where Email=@email
end

exec usp_get_user_by_email 'rahul213@gmail.com'

select * from sys.tables where name like '%claim%'

--Claim_Master
--Employee_Claim_Action
--Employee_Claim_Master_Mapping
--Employee_Claim_Role_Master
--Employee_Claim_Transaction

insert into Employee_Claim_Role_Master (Role,Action,Status) values
('Employee','Initiated',1),
('Manager','pending at manager',1),
('HR','pending at HR',1),
('Account','Pending at Account',1)

------------

insert into Employee_Claim_Master_Mapping(CurrentAction ,NextAction ,Status) values
('Initiated','Pending at Manager',1),
('Pending at Manager','Pending at HR',1),
('Pending at Manager','Rejected by Manager',0),
('Pending at HR','Pending at Account',1),
('Pending at HR','Rejected by HR',0),
('Pending at Account','Completed',1)

--rasise claim request
---getpendingclaims
---getclaims info
---usp claim action update
---get claim status for employee
---get employee transaction info





-----procedure USP_Raise_Claim_Request data required
-----claim master => Claim_Title,
				--Claim_Reason,
				--Amount,
				--ClaimDt,
				--Evidence,
				--Claim_Description,
				--CurrentStatus,
				--Status,
				--UserId,
--  +
--ExpenseDt

	select * from claim_master
	alter table claim_master add UserId int
	alter table claim_master add ExpenseDt DATEtime 

	-----SET @ClaimID=SCOPE_IDENTITY();
	-----SET @ClaimID= IDENT_CURRENT('CLAIM MASTER')
	---------SET @ClaimID= @@IDENTITY()


CREATE proc USP_Raise_Claim_Request
@Claim_Title varchar(100),
@Claim_Reason varchar(50),
@Amount DECIMAL,
@ExpenseDt varchar(100),
@Evidence varchar(500)=null,
@Claim_Description varchar(500),
@UserId int
as 
begin

	Declare @current_status varchar(100)
	Declare @ClaimID INT
	select @current_status=NextAction 
			from Employee_Claim_Master_Mapping(nolock) 
				where CurrentAction='Initiated'
	begin transaction trn_claim
	begin try

	if(EXISTS(SELECT 1 FROM Claim_Master(NOLOCK) where UserId=@UserId AND CurrentStatus LIKE '%Pending%'))
	BEGIN
	Raiserror('Claim already in pending',1,1)
	return
	END

	insert into Claim_Master 
				(Claim_Title,
				Claim_Reason,
				Amount,
				ClaimDt,
				Evidence,
				Claim_Description,
				CurrentStatus,
				Status,
				UserId,
				ExpenseDt)
			VALUES
				(
				@Claim_Title,
				@Claim_Reason,
				@Amount,
				GETDATE(),
				@Evidence,
				@Claim_Description,
				@current_status,
				1,
				@UserId,
				@ExpenseDt		
				)
	SET @ClaimID=SCOPE_IDENTITY();
	
	----------insert record in action table----------------
	insert into Employee_Claim_Action(
					ClaimId,
					Action,
					ActionBy,
					ActionDt,
					Remarks,
					Status
					)
					VALUES
					(
					@ClaimID,
					'Initiated',
					@UserId,
					GETDATE(),
					@Claim_Description,
					1
					)
	Commit transaction trn_claim
	-------------------
	end try
	begin catch
	rollback transaction trn_claim
	end catch
	end


declare @dt DATETIME=GETDATE()
EXEC USP_Raise_Claim_Request 'Petrol Expense for OCT month','Travel',5000,@dt,'evid.jpg','required claim amount',2

commit

select * from claim_master(nolock)
select * from Employee_Claim_Action(nolock)


SELECT * FROM SYS.tables

SELECT * FROM User_Master
User_Master
SELECT * FROM Program_Master
SELECT * FROM Role_master
SELECT * FROM Role_Employee_Mapping
SELECT * FROM Tbl_Rights
SELECT * FROM  Claim_Master
SELECT * FROM Employee_Claim_Role_Master
SELECT * FROM Employee_Claim_Master_Mapping
SELECT * FROM Employee_Claim_Transaction
SELECT * FROM Employee_Claim_Action

insert into Tbl_Rights(Programe_id,UserId,RoleId,Status) values
(2,3,null,1),
(3,3,null,1);

CREATE PROC USP_GET_Pending_Request
@role varchar(20),
@userid int
as
begin

	select cm.Id,
			cm.Amount,
			cm.Claim_Title,
			cm.Claim_Reason,
			cm.Claim_Description,
			cm.ClaimDt,
			cm.Evidence,
			cm.ExpenseDt,
			cm.CurrentStatus,
			um.Nm
	from Claim_Master(nolock) cm
	JOIN
	User_Master(nolock)um on um.Id=cm.UserId
	WHERE cm.CurrentStatus=(
	select rm.Action from 
	Employee_Claim_Role_Master(nolock)rm where rm.Role=@role
	) AND( um.Manager_Id= CASE WHEN @role = 'Manager' THEN 
			@userid ELSE um.Manager_Id
			END)

end
declare @dt DATETIME=GETDATE()
EXEC USP_Raise_Claim_Request 'Petrol Expense for OCT month','Travel',5000,@dt,'evid.jpg','required claim amount',3

exec USP_GET_Pending_Request 'Manager',1

update Claim_Master set CurrentStatus = 'Pending at HR' where id = 2


exec USP_GET_Pending_Request 'HR',1
----------------



create proc usp_update_claim
@role varchar(20),
@action tinyint,
@remark varchar(200),
@claimid int,
@userid int
as
begin

declare @current_status varchar(100)
declare @next_action varchar(100)

select @current_status=CurrentStatus 
		from Claim_Master(nolock)cm where cm.Id=@claimid

select @next_action=NextAction 
		from Employee_Claim_Master_Mapping(nolock)mp
			where mp.CurrentAction=@current_status and mp.Status=@action

begin tran trn_update_claim
	begin try
	update Claim_Master set CurrentStatus=@next_action where Id=@claimid

	insert into Employee_Claim_Action(
						ClaimId,
						Action,
						ActionBy,
						ActionDt,
						Remarks,
						Status
						)
				values
						(@claimid,
						@next_action,
						@userid,
						getdate(),
						@remark,
						1 
						)

	commit tran trn_update_claim
	end try
	begin catch
	rollback tran trn_update_claim
	end catch



end



exec usp_update_claim 'Manager',1,'approval for amount',1,1
exec usp_update_claim 'HR',0,'rejected due incomplete evidence',2,4
exec USP_GET_Pending_Request 'HR',1
-------------


INSERT INTO Role_master VALUES
('Employee',1),
('Manager',1),
('HR',1),
('Accounts',1);
------------------------------
create function HashPassword(@pass varchar(100))
returns nvarchar(500)
as
begin
declare @afterhash varbinary(500) = HASHBYTES('SHA2_256', @pass)
return convert(nvarchar(1000) , @afterhash , 2)
end

select dbo.HashPassword('amit@gmail.com')

Insert into User_Master(
Nm,
Email,
Mobile,
Password,
Manager_Id,
Status
) values
('Akash Kumar','akash123@gmail.com','93483943',dbo.HashPassword('aks@123'),null,1),
('Rahul Kumar','rahul213@gmail.com','73483943',dbo.HashPassword('rh@123'),null,1),
('Mayank Kumar','mayank0023@gmail.com','88483943',dbo.HashPassword('mank@123'),null,1),
('Sumit Kumar','smt03@gmail.com','78483943',dbo.HashPassword('smt@123'),null,1),
('Pawan Kumar','pawan123@gmail.com','87483943',dbo.HashPassword('pawan@123'),null,1);

update User_Master set Manager_Id=1 where Id=2
update User_Master set Manager_Id=1 where Id=3
update User_Master set Manager_Id=3 where Id=4
update User_Master set Manager_Id=3 where Id=5

insert into Role_Employee_Mapping values
(1,2,1),
(1,3,1),
(2,1,1),
(3,4,1),
(4,5,1);

insert into Program_Master(P_title,Path,Descr,Display_Sequence,Status)
values
('Add Claim','Claim/AddClaim','Add new claim',0,1),
('Employee Claims','Claim/ShowClaim','show claim request',1,1),
('Dashboard','Home/Dashboard','dashboard',2,1),
('Show Claim Status','Claim/ClaimStatus','show claim',3,1);

insert into Tbl_Rights(Programe_id,UserId,RoleId,Status) values
(1,1,null,1),
(2,1,null,1),
(3,1,null,1),
(4,1,null,1),
(1,2,null,1),
(4,2,null,1),
(1,3,null,1),
(4,3,null,1),
(1,4,null,1),
(2,4,null,1),
(3,4,null,1),
(4,4,null,1),
(1,5,null,1),
(2,5,null,1),
(3,5,null,1),
(4,5,null,1);





-- create proc  Usp_get_program_master 
-- @id int
-- as
-- begin
-- select p.P_title , p.Descr  from Program_Master p join Tbl_Rights t on p.Id = t.Programe_id 
-- where t.UserId = @id
-- end

-- Usp_get_program_master 2

-- Insert into User_Master(
-- Nm,
-- Email,
-- Mobile,
-- Password,
-- Manager_Id,
-- Status

-- create proc usp_Login 
-- @usr varchar(100) , @pass varchar(500) 
-- as
-- begin
-- declare @sta varchar(100)  ;
-- declare @passw varchar(500);
-- select @sta = Status 
-- from 
-- User_Master  where Nm = @usr 

-- if @sta = 1
-- begin 
-- select @passw = dbo.HashPassword(@pass) 
-- if @passw =  Password from User_Master where Nm = @usr
-- begin 
-- print 'welcome'
-- end
-- end

-- else 
-- print 'unauthorized'
-- end





--INSERT INTO Role_master VALUES
--('Employee',1),
--('Manager',1),
--('HR',1),
--('Accounts',1);
--------------------------------
--Insert into User_Master(
--Nm,
--Email,
--Mobile,
--Password,
--Manager_Id,
--Status
--) values
--('Akash Kumar','akash123@gmail.com','93483943',dbo.HashPassword('aks@123'),null,1),
--('Rahul Kumar','rahul213@gmail.com','73483943',dbo.HashPassword('rh@123'),null,1),
--('Mayank Kumar','mayank0023@gmail.com','88483943',dbo.HashPassword('mank@123'),null,1),
--('Sumit Kumar','smt03@gmail.com','78483943',dbo.HashPassword('smt@123'),null,1),
--('Pawan Kumar','pawan123@gmail.com','87483943',dbo.HashPassword('pawan@123'),null,1);

--update User_Master set Manager_Id=1 where Id=2
--update User_Master set Manager_Id=1 where Id=3
--update User_Master set Manager_Id=3 where Id=4
--update User_Master set Manager_Id=3 where Id=5

--insert into Role_Employee_Mapping values
--(1,2,1),
--(1,3,1),
--(2,1,1),
--(3,4,1),
--(4,5,1);

--insert into Program_Master(P_title,Path,Descr,Display_Sequence,Status)
--values
--('Add Claim','Claim/AddClaim','Add new claim',0,1),
--('Employee Claims','Claim/ShowClaim','show claim request',1,1),
--('Dashboard','Home/Dashboard','dashboard',2,1),
--('Show Claim Status','Claim/ClaimStatus','show claim',3,1);

--insert into Tbl_Rights(Programe_id,UserId,RoleId,Status) values
--(1,1,null,1),
--(2,1,null,1),
--(3,1,null,1),
--(4,1,null,1),
--(1,2,null,1),
--(4,2,null,1),
--(1,3,null,1),
--(4,3,null,1),
--(1,4,null,1),
--(2,4,null,1),
--(3,4,null,1),
--(4,4,null,1),
--(1,5,null,1),
--(2,5,null,1),
--(3,5,null,1),
--(4,5,null,1);

--insert into Tbl_Rights(Programe_id,UserId,RoleId,Status) values
--(2,3,null,1),
--(3,3,null,1);


CREATE TABLE User_Master
(Id int primary key identity,
Nm varchar(100),
Email varchar(100),
Mobile varchar(100),
Password varchar(500),
Manager_Id int,
Status tinyint
)
------------------------------------

CREATE TABLE Program_Master
(Id int primary key identity,
P_title varchar(100),
Path varchar(500),
Descr varchar(500),
Display_Sequence INT,
Status tinyint
)
-----------------------------
create table Role_master
(Id int primary key identity,
Role varchar(100),
Status tinyint
)
-----------------------------
create table Role_Employee_Mapping
(Id int primary key identity,
RoleId INT,
EmpId int,
Status tinyint
)
------------------------------
create table Role_Employee_Mapping
(Id int primary key identity,
RoleId INT,
EmpId int,
Status tinyint
)
--------------------------------------
create table Tbl_Rights
(Id int primary key identity,
Programe_id INT,
UserId int,
RoleId INT,
Status tinyint
)
---------------------------------------
--drop table Claim_Master
create table Claim_Master
(
Id int primary key identity,
Claim_Title varchar(100),
Claim_Reason varchar(100),
Amount Decimal,
ClaimDt Datetime,
Evidence varchar(500),
Claim_Description varchar(500),
CurrentStatus Varchar(50),
Status tinyint
)
----------------------------------------
create table Employee_Claim_Role_Master
(
Id int primary key identity,
Role varchar(100),
Action varchar(100),
Status tinyint
)
---------------------------------------
create table Employee_Claim_Master_Mapping
(
Id int primary key identity,
CurrentAction varchar(100),
NextAction varchar(100),
Status tinyint
)
----------------------------------------
create table Employee_Claim_Transaction
(
Id int primary key identity,
Transaction_No varchar(100),
Employee_Id INT,
Amount Decimal,
TransactionDt Datetime,
ClaimId int,
Status tinyint
)
--------------------------------
create table Employee_Claim_Action
(
Id int primary key identity,
ClaimId int,
Action varchar(100),
ActionBy INT,
ActionDt Datetime,
Remarks Varchar(100),
Status tinyint
)
----------------------------------------








