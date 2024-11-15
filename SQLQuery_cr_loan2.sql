select * from [SQL_CREDIT_CARDS].[dbo].['cr_loan2']

select count(*) from [SQL_CREDIT_CARDS].[dbo].['cr_loan2']

/* EXPLORATORY DATA ANALYSIS
============================*/


/*PART I : HANDLE ANOMALIES IN DATA | DATA CLEANING
===================================================*/

-----------------------------------------------------------------------------------------------------------------------------------

--IDENTIFY ANOMALIES
select max(person_age) MAX1, MIN(person_age) MIN1, AVG(person_age) AVG1 from [SQL_CREDIT_CARDS].[dbo].['cr_loan2']
--144	20	27.7345999201989

select max(person_income) MAX1, MIN(person_income) MIN1, AVG(person_income) AVG1 from [SQL_CREDIT_CARDS].[dbo].['cr_loan2']
--6000000	4000	66074.8484699672

select max(person_emp_length) MAX1, MIN(person_emp_length) MIN1, AVG(person_emp_length) AVG1 from [SQL_CREDIT_CARDS].[dbo].['cr_loan2']
--123	0	4.78968629678722

-----------------------------------------------------------------------------------------------------------------------------------

--DATA CLEANING

ALTER DATABASE [SQL_CREDIT_CARDS] 
SET COMPATIBILITY_LEVEL = 90; --for syntax issues


GO --to use in a separate batch

DROP VIEW IF EXISTS Cleaned_Credit_View; -- This will remove the existing view if it exists after making changes

GO
CREATE VIEW Cleaned_Credit_View AS
SELECT *
from [SQL_CREDIT_CARDS].[dbo].['cr_loan2']
WHERE person_age < 100 and
person_emp_length <60
GO

select count(*) from Cleaned_Credit_View --to check the cleaned data by row count change


/*To permanently delete:
DELETE FROM [SQL_CREDIT_CARDS].[dbo].['cr_loan2'] WHERE person_age > 100;
*/

-----------------------------------------------------------------------------------------------------------------------------------


/*PART II : DATA ANALYSIS - BASIC
===================================================*/

SELECT * FROM Cleaned_Credit_View

/*
Q. Average Loan Amount by Purpose
*/
select loan_intent, avg(loan_amnt) as avg_loan_amnt
from Cleaned_Credit_View
group by loan_intent

/*
Q. Total Number of Loans by Status (non-default vs. default)
loan_status shows whether the loan is currently in default with 1 being default and 0 being non-default.
*/
select loan_status, count(*) as loan_status_cnt
from Cleaned_Credit_View
group by loan_status

/*
Q. Average Interest Rate by Loan Grade
*/
select loan_grade, avg(loan_int_rate) avg_lg
from Cleaned_Credit_View
group by loan_grade order by loan_grade

/*
Q. Average Income by Home Ownership Status
*/
select person_home_ownership, avg(person_income) as avg_inc
from Cleaned_Credit_View
group by person_home_ownership

/*
Q. Top 5 Most Common Loan Purposes *
*/
select top 5 loan_intent, count(*) cnt
from Cleaned_Credit_View
group by loan_intent
order by cnt desc

/*
Q. Count of (non-default vs. default) Loans by Loan Grade *
*/
select loan_grade, loan_status, count(*) cnt
from Cleaned_Credit_View
group by loan_grade, loan_status
order by loan_grade, loan_status

/*
Q. Average Employment Length for Approved Loans
*/
select avg(person_emp_length)
from Cleaned_Credit_View
where loan_status = 0

/*
Q. Default Rate by Credit History Length *
*/

with dflt_tbl as(
select cb_person_cred_hist_length,
sum(case when cb_person_default_on_file = 'Y' then 1 else 0 end) as dflt, count(*) as dfltcnt
from Cleaned_Credit_View
group by cb_person_cred_hist_length
order by cb_person_cred_hist_length
)
select cb_person_cred_hist_length, dflt/dfltcnt
from dflt_tbl

--The ORDER BY clause is invalid in views, inline functions, derived tables, subqueries, and common table expressions, unless TOP, OFFSET or FOR XML is also specified.
--correction:

ALTER DATABASE [SQL_CREDIT_CARDS] 
SET COMPATIBILITY_LEVEL = 90; --for syntax issues

with dflt_tbl2 as(
select cb_person_cred_hist_length,
sum(case when cb_person_default_on_file = 'Y' then 1 else 0 end) as dflt, count(*) as dfltcnt
from Cleaned_Credit_View
group by cb_person_cred_hist_length

)
select cb_person_cred_hist_length, cast((dflt*100.0)/(dfltcnt*1.0)  as decimal(5,2))perc_dflt
from dflt_tbl2
order by cb_person_cred_hist_length

/*
Q. Average Loan Percent Income by Loan Grade
*/
select loan_grade, avg(loan_percent_income) avg_lp
from Cleaned_Credit_View
group by loan_grade

/*
Q. Income Distribution of Loan Applicants
*/
select person_income, count(*) as distribution
from Cleaned_Credit_View
group by person_income order by person_income desc

/*
Q. Count of Defaulted Loans by Employment Length
*/
select person_emp_length, count(*) as cnt
from Cleaned_Credit_View
where cb_person_default_on_file = 'Y'
group by person_emp_length
order by person_emp_length

/*
Q. Top 5 Loan Purposes for High Loan Amounts *
*/
select top 5 loan_intent, loan_amnt
from Cleaned_Credit_View
order by loan_amnt desc

/*
Q. Default Rate by Home Ownership Status *
*/
with cte as(
select person_home_ownership, sum(case when cb_person_default_on_file = 'Y' then 1 else 0 end) as sum_dflt, COUNT (*) as cnt
from Cleaned_Credit_View
group by person_home_ownership
) select person_home_ownership, sum_dflt, cnt, sum_dflt*100.0/cnt as rate
from cte

/*
Q. Loan Amount Distribution by Age Group
*/

select 
case
when person_age <25 then 'under 25' 
when person_age>=25 and person_age<=35 then '25-35'
when person_age>35 and person_age<=50 then '35-50'
else '50+'
end
as age_group,
avg(loan_amnt) as avg_loan_amt
from Cleaned_Credit_View
group by 
case
when person_age <25 then 'under 25' 
when person_age>=25 and person_age<=35 then '25-35'
when person_age>35 and person_age<=50 then '35-50'
else '50+'
end


/*
Q. Average Loan Amount and Interest Rate by Loan Status
*/
select loan_status, avg(loan_amnt) avg_loan, avg(loan_int_rate) avg_loan_intr
from Cleaned_Credit_View
group by loan_status


/*
Q. Applicants with High Loan Amount Relative to Income
*/

select *
from Cleaned_Credit_View
where loan_amnt*1.0/person_income>0.6

/*
Q. Average Loan Interest Rate by Age Group
*/
select age_group, avg(loan_int_rate) avg_loan_intr
from (
select loan_int_rate,
case
when person_age<25 then 'under25'
when person_age>=25 and person_age<=35 then '25 - 35'
when person_age>35 and person_age<=50 then '35 - 50'
else '50+'
end 
as age_group
from Cleaned_Credit_View
) t
group by age_group

/*
Q. Relationship Between Employment Length and Loan Approval
*/
select person_emp_length, avg(loan_status) loan_status
from Cleaned_Credit_View
group by person_emp_length
order by person_emp_length

/*
Q. Credit History Length and Default Rate
*/
select cb_person_default_on_file, avg(cb_person_cred_hist_length) as avg_cred_hist_lngth
from Cleaned_Credit_View
group by cb_person_default_on_file

--or
select cb_person_cred_hist_length, sum_dflt*100.0/cnt_dflt as dflt_rate
from(
select cb_person_cred_hist_length, sum(case when cb_person_default_on_file = 'Y' then 1 else 0 end) sum_dflt, count(case when cb_person_default_on_file = 'Y' then 1 else 0 end) cnt_dflt
from Cleaned_Credit_View
group by cb_person_cred_hist_length
) t
order by cb_person_cred_hist_length

/*
Q. Count of High-Interest Loans by Loan Grade
*/

select AVG(loan_int_rate) from Cleaned_Credit_View

select loan_grade, count(*) cnt
from Cleaned_Credit_View
where loan_int_rate > (select AVG(loan_int_rate) from Cleaned_Credit_View)
group by loan_grade
order by loan_grade

/*
Q. 3rd largest loan amount
*/
select distinct loan_amnt
from(
select loan_amnt, 
dense_rank() over(order by loan_amnt desc) as rnk
from Cleaned_Credit_View
) t
where rnk =3

--or

select distinct loan_amnt
from Cleaned_Credit_View
order by loan_amnt desc
offset 2 rows 
fetch next 1 rows only

-----------------------------------------------------------------------------------------------------------------------------------

/*PART III : Additional Queries
===================================================*/

Select * 
from Cleaned_Credit_View


--Query Focus Area: Identifying High-Risk Loans Based on Combined Factors
SELECT
    person_income, 
    loan_grade, 
    loan_intent, 
    loan_amnt, 
    loan_status
FROM 
    Cleaned_Credit_View
WHERE 
    loan_grade IN ('D', 'E', 'F')
    AND loan_amnt > 20000
    AND person_income < 40000
    AND loan_status = 1


--Query Focus Area: Income vs. Loan Interest Rates
SELECT top 10
    person_income, 
    AVG(loan_int_rate) AS avg_int_rate
FROM 
    Cleaned_Credit_View
GROUP BY 
    person_income
ORDER BY 
    avg_int_rate DESC

