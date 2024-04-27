-- ---------------------------------------------------------------------------------------
-- PROJECT-277 -- CROWDFUNDING KICKSTARTER
-- ---------------------------------------------------------------------------------------

# LOADING DATA 

LOAD DATA INFILE 'crowdfunding_Category.csv'
INTO TABLE crowdfunding_category
CHARACTER SET utf8
FIELDS TERMINATED BY ',' 
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES; 

LOAD DATA INFILE 'crowdfunding_Creator.csv'
INTO TABLE crowdfunding_creator
CHARACTER SET utf8
FIELDS TERMINATED BY ',' 
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES; 

LOAD DATA INFILE 'crowdfunding_Location.csv'
INTO TABLE crowdfunding_location
CHARACTER SET utf8
FIELDS TERMINATED BY ',' 
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES; 

SELECT * FROM internship_project.projects;
select * from crowdfunding_category;
select * from crowdfunding_creator;
select * from crowdfunding_location;

-- -----------------------------------------------------------------------------------------------------------------------------------------
# DATA CLEANING 

-- Convert the Date fields to Natural Time 

SET SQL_SAFE_UPDATES=0;   

SELECT convert(from_unixtime(created_at), date) AS created_date
from projects;

update projects
set created_at = convert(from_unixtime(created_at), date) ;

alter table projects
add created_date date,
add deadline_date date,
add updated_date date,
add state_changed_date date,
add successful_date date,
add launched_date date ;

select * from projects ;

UPDATE projects
SET created_date =  convert(from_unixtime(created_at), date);

UPDATE projects
SET deadline_date =  convert(from_unixtime(deadline), date);
SET updated_date =  convert(from_unixtime(updated_at), date);
SET state_changed_date =  convert(from_unixtime(state_changed_at), date);
SET successful_date =  convert(from_unixtime(successful_at), date);
-- SET successful_at = null WHERE successful_at = "";
SET launched_date =  convert(from_unixtime(launched_at), date); 

-- ------------------------------------------------------------------------------------------------------------------------------------------
-- Convert the Goal amount into USD using the Static USD Rate.
Alter table projects
add Goal_usd int after goal ;

update projects
set goal_usd = goal * static_usd_rate ;

select * from projects;

-- -----------------------------------------------------------------------------------------------------------------------------------------

-- Total Number of Projects based on outcome 
select state, count(projectid) as total_project
from projects
group by 1
order by 2 desc;

-- -----------------------------------------------------------------------------------------------------------------------------------------

-- Total Number of Projects based on Locations
select * from crowdfunding_location;

select cl.country, count(p.projectid) as Total_project
from crowdfunding_location as cl
join projects as P
on cl.location_id = p.location_id
group by 1
order by 2 desc ;

-- -----------------------------------------------------------------------------------------------------------------------------------------

-- Total Number of Projects based on  Category
select * from crowdfunding_category;

select c.name, count(p.projectid) total_project
from crowdfunding_category as c
left join projects as P
on c.category_id = p.category_id
group by 1
order by 2 desc ;

-- ----------------------------------------------------------------------------------------------------------------------------------------
 
-- Total Number of Projects created by Year , Quarter , Month
select * from projects;

select year(created_date) as year, quarter(created_date) as quarter, monthname(created_date) as Month, count(ProjectID) as project_count
from projects
group by 1,2,3
order by 1;

-- --------------------------------------------------------------------------------------------------------------------------------------

-- No. of Backers based on successfull Projects
select * from projects;
select concat(format(sum(backers_count)/1000000,0), ' M') as NO_of_backers
from projects
where state = 'successful';

-- ---------------------------------------------------------------------------------------------------------------------------------------

-- Amount Raised based on Successful projects
select concat(format(sum(usd_pledged)/1000000000,2), ' Bn') as Amount_raised
from projects
where state = 'successful';

-- ---------------------------------------------------------------------------------------------------------------------------------------

-- Avg NUmber of Days for successful projects
select * from projects;

alter table projects
add no_successful_days int default null ;

update projects
set no_successful_days = case
          when successful_date is null then 0
          else datediff(successful_date, created_date)
	end ;
    
    
select format(avg(no_successful_days),0) as avg_no_days
from projects
where state = 'successful';

-- --------------------------------------------------------------------------------------------------------------------------------------

-- Top 5 Successful Projects Based on Number of Backers
select name, concat(round(sum(backers_count)/1000), ' K') as backers_count
from projects
where state = 'successful'
group by 1
order by sum(backers_count) desc
limit 5 ;

-- -----------------------------------------------------------------------------------------------------------------------------------------

-- Top 5 Successful Projects Based on Amount Raised
select name, concat(format(sum(usd_pledged)/1000000, 2), ' M') as Amount_raised
from projects
where state = 'successful'
group by 1
order by sum(usd_pledged) desc
limit 5 ;

-- --------------------------------------------------------------------------------------------------------------------------------------

-- Percentage of Successful Projects overall
select concat(format((select count(projectid) from projects where state = 'successful')/
					  count(projectid) * 100, 2), ' %') as Prnct_successful_projects
from projects ;

-- ---------------------------------------------------------------------------------------------------------------------------------------

-- Percentage of Successful Projects  by Category
select name, concat(format(project_count/sum(project_count) over() * 100, 2), ' %') as Prnct_successful_projects
from (select c.name, count(p.projectid) as project_count
from crowdfunding_category as c
join projects as p
on c.category_id = p.category_id
where p.state = 'successful'
group by 1
order by 2 desc) as x ;


-- -----------------------------------------------------------------------------------------------------------------------------------------
-- Percentage of Successful Projects by Year , Month etc..
select year, month, concat(round(project_count/sum(project_count) over(partition by year) * 100,2), ' %') as Prnct_successful_projects
from ( select year(successful_date) year, monthname(successful_date) month, count(projectid) as project_count
from projects
where state = 'successful'
group by 1,2
order by 1,2) as x;

-- -----------------------------------------------------------------------------------------------------------------------------------------

-- Percentage of Successful projects by Goal Range
select * from projects;

alter table projects
add goal_range text;

update projects
set goal_range = case
          when goal_usd < 20000 then 'less then 20000'
          when goal_usd >= 20000 and goal_usd < 40000 then '20000 to 40000'
		  when goal_usd >= 40000 and goal_usd < 60000 then '40000 to 60000'
		  when goal_usd >= 60000 and goal_usd < 80000 then '60000 to 80000'
		  when goal_usd >= 80000 and goal_usd < 100000 then '80000 to 100000'
          else 'Above 100000'
		end;
        
alter table projects
add Sorting_goal_range  int default null;

update projects
set Sorting_goal_range = case
          when goal_usd < 20000 then 1
          when goal_usd >= 20000 and goal_usd < 40000 then 2
		  when goal_usd >= 40000 and goal_usd < 60000 then 3
		  when goal_usd >= 60000 and goal_usd < 80000 then 4
		  when goal_usd >= 80000 and goal_usd < 100000 then 5
          else 6
		end;
SET SQL_SAFE_UPDATES=0;   


select goal_range, concat(round(project_count/sum(project_count) over() * 100, 2), ' %') as prcnt_successful_project
from (select goal_range, Sorting_goal_range, count(projectid) as project_count
from projects
where state = 'successful'
group by 1,2
order by 2) as x;

-- ----------------------------------------------------------------------------------------------------------------------------------------
-- 								------END------
-- ------------------------------------------------------------------------------------------------