-- ============================================================
-- IBM HR Analytics: Employee Attrition Analysis
-- Purpose: Explore data quality, overall attrition, and factors
-- associated with employees leaving the organization.
-- Attrition and OverTime are BIT: 1 = Yes/True, 0 = No/False.
-- ============================================================
USE [IBM HR Analytics];
GO

-- 1. DATA QUALITY: Check whether EmployeeNumber appears more than once.
SELECT EmployeeNumber, count(employeenumber) as Duplicate_Counts
FROM Employee
group by EmployeeNumber
having count(*) > 1;

-- 2. DATA QUALITY: Count missing values in key analysis columns.
SELECT
    SUM(CASE WHEN EmployeeNumber IS NULL THEN 1 ELSE 0 END) AS MissingEmployeeNumber,
    SUM(CASE WHEN Age IS NULL THEN 1 ELSE 0 END) AS MissingAge,
    SUM(CASE WHEN Department IS NULL THEN 1 ELSE 0 END) AS MissingDepartment,
    SUM(CASE WHEN JobRole IS NULL THEN 1 ELSE 0 END) AS MissingJobRole,
    SUM(CASE WHEN MonthlyIncome IS NULL THEN 1 ELSE 0 END) AS MissingMonthlyIncome,
    SUM(CASE WHEN Attrition IS NULL THEN 1 ELSE 0 END) AS MissingAttrition,
    SUM(CASE WHEN OverTime IS NULL THEN 1 ELSE 0 END) AS MissingOverTime
FROM Employee;

-- 3. DATA INSPECTION: Display employee records for manual inspection. Avoid exposing row-level data publicly.
select * from Employee;

-- 4. OVERALL ATTRITION: Calculate total employees, employees who left, and the overall attrition rate.
With Employee_stats as(
    Select
    count(employeenumber) as Total_Employees,
    sum(
        case
            when attrition = 1 then 1 
            else 0 
        end
        ) as Employees_left
    From employee
)
Select 
    Total_Employees,
    Employees_left,
    Employees_left * 100.0/ Total_Employees as Attrition_Rate
From Employee_stats;

-- 5. ATTRITION BY DEPARTMENT: Compare employee counts and attrition rates across departments.
With Employee_stats as (
    Select
    Department,
    Count(EmployeeNumber) as Total_Employees,
    Sum(
        Case
            When Attrition = 1 Then 1 
            Else 0
        End) as Employees_left
    From Employee
    Group by Department
    )
Select 
    Department,
    Total_Employees,
    Employees_left,
    CAST(
        Employees_left * 100.0 / Total_Employees
        AS DECIMAL(5,2)
    ) AS Attrition_Rate
From Employee_stats;

-- 6. ATTRITION BY OVERTIME: Compare attrition for employees with and without overtime.
With Employee_stats as (
    Select
        OverTime,
        count(EmployeeNumber) as Total_Employees,
        Sum(
            Case
                When Attrition = 1 Then 1
                Else 0
            End) as Employees_left
    From Employee
    Group By OverTime
    )
Select
    OverTime,
    Total_Employees,
    Employees_left,
    Cast(
        Employees_left * 100.0/Total_Employees
        AS Decimal(10,2)
        ) as Attrition_Rate
From Employee_stats;

-- 7. ATTRITION BY JOB ROLE: Rank job roles by attrition rate.
With Employee_stats as (
    Select
        JobRole,
        count(EmployeeNumber) as Total_Employees,
        Sum(
            Case
                When Attrition = 1 Then 1
                Else 0
            End) as Employees_left
    From Employee
    Group By JobRole
    )
Select
    JobRole,
    Total_Employees,
    Employees_left,
    Cast(
        Employees_left * 100.0/Total_Employees
        AS Decimal(10,2)
        ) as Attrition_Rate
From Employee_stats
Order by Attrition_Rate desc;

-- 8. ATTRITION BY TENURE: Compare attrition rates across years-at-company groups.
With Employee_stats as(
    Select
        Case
            When YearsAtCompany <=2 Then 'Early Career'
            When YearsAtCompany <=5 Then 'Mid'
            When YearsAtCompany <=10 Then 'Experienced'
            Else 'Long Tenure'
        End as TenureGroup,
        count(EmployeeNumber) as Total_Employees,
        Sum(
            Case
                When Attrition = 1 Then 1
                Else 0
            End) as Employees_left
    From Employee
    Group by
        Case
            When YearsAtCompany <=2 Then 'Early Career'
            When YearsAtCompany <=5 Then 'Mid'
            When YearsAtCompany <=10 Then 'Experienced'
            Else 'Long Tenure'
        End
)
Select
    TenureGroup,
    Total_Employees,
    Employees_left,
    Cast(
        Employees_left * 100.0/Total_Employees
        AS Decimal(10,2)
        ) as Attrition_Rate
From Employee_stats
Order by Attrition_Rate desc;

-- 9. ATTRITION BY SALARY GROUP: Compare attrition across monthly-income bands.
With Employee_stats as(
    Select
        CASE
            WHEN MonthlyIncome < 3000 THEN 'Low Income'
            WHEN MonthlyIncome <= 5000 THEN 'Lower-Middle Income'
            WHEN MonthlyIncome <= 10000 THEN 'Upper-Middle Income'
            ELSE 'High Income'
        END AS SalaryGroup,
        count(EmployeeNumber) as Total_Employees,
        Sum(
            Case
                When Attrition = 1 Then 1
                Else 0
            End) as Employees_left
    From Employee
    Group by
        CASE
            WHEN MonthlyIncome < 3000 THEN 'Low Income'
            WHEN MonthlyIncome <= 5000 THEN 'Lower-Middle Income'
            WHEN MonthlyIncome <= 10000 THEN 'Upper-Middle Income'
            ELSE 'High Income'
        END
)
Select
    SalaryGroup,
    Total_Employees,
    Employees_left,
    Cast(
        Employees_left * 100.0/Total_Employees
        AS Decimal(10,2)
        ) as Attrition_Rate
From Employee_stats
Order by Attrition_Rate desc;

-- 10. JOB ROLE AND OVERTIME: Compare attrition for each job-role/overtime combination.
Select
    JobRole,
    OverTime,
    Count(EmployeeNumber) as Total_Employees,
    Sum(
        Case
            When Attrition = 1 Then 1
            Else 0
        End) as Employees_Left,
    Cast(
        Sum(
        Case
            When Attrition = 1 Then 1
            Else 0
        End) * 100.0
        / Count(EmployeeNumber)
        as Decimal(10,2)
        ) as Attrition_Rate
From Employee
Group by JobRole,OverTime
Order by Attrition_Rate Desc;

-- 11. JOB ROLE VS OVERALL: Compare each job role attrition rate with the company-wide rate.
With Overall as(
    Select
        Cast(
            Sum(
                Case
                    When Attrition = 1 Then 1 Else 0
                End) * 100.0
                /
                Count(EmployeeNumber) 
            as Decimal(10,2)
            )as OverallRate
    From Employee),

    JobLevelStats as (
    Select
        JobRole,
        count(EmployeeNumber) as Total_Employees,
        Sum(
            Case
                When Attrition = 1 Then 1
                Else 0
            End) as Employees_left,
        Cast(
            Sum(
                Case
                    When Attrition = 1 Then 1 Else 0
                End) * 100.0
                /
                Count(EmployeeNumber) 
            as Decimal(10,2)
            )as AttritionRate
    From Employee
    Group By JobRole)

Select
    JobRole,
    AttritionRate,
    OverallRate,
    AttritionRate - OverallRate as 'Difference'
From JobLevelStats
Cross Join Overall;

With Overall as(
    Select
        Cast(
            Sum(
                Case
                    When Attrition = 1 Then 1 Else 0
                End) * 100.0
                /
                Count(EmployeeNumber) 
            as Decimal(10,2)
            )as OverallRate
    From Employee),
    
-- 12. JOB ROLE AND SALARY GROUP: Find job-role/salary groups with above-overall attrition; small groups are excluded below.
    SalaryStats AS (
    SELECT
        JobRole,
        CASE
            WHEN MonthlyIncome < 3000 THEN 'Low Income'
            WHEN MonthlyIncome <= 5000 THEN 'Lower-Middle Income'
            WHEN MonthlyIncome <= 10000 THEN 'Upper-Middle Income'
            ELSE 'High Income'
        END AS SalaryGroup,
        count(EmployeeNumber) as Total_Employees,
        Sum(
            Case
                When Attrition = 1 Then 1
                Else 0
            End) as Employees_left,
        Cast(
            Sum(
                Case
                    When Attrition = 1 Then 1 Else 0
                End) * 100.0
                /
                Count(EmployeeNumber) 
            as Decimal(10,2)
            )as AttritionRate
    FROM Employee
    GROUP BY
        JobRole,
        CASE
            WHEN MonthlyIncome < 3000 THEN 'Low Income'
            WHEN MonthlyIncome <= 5000 THEN 'Lower-Middle Income'
            WHEN MonthlyIncome <= 10000 THEN 'Upper-Middle Income'
            ELSE 'High Income'
        END
)
SELECT
    JobRole,
    SalaryGroup,
    Total_Employees,
    Employees_left,
    AttritionRate,
    AttritionRate - OverallRate AS Difference_From_Overall
FROM SalaryStats
Cross Join Overall
WHERE AttritionRate > OverallRate
    AND Total_Employees >= 20;

-- 13. EARLY-TENURE ATTRITION BY JOB ROLE: Focus on employees with two or fewer years at the company.
Select
    JobRole,
    count(EmployeeNumber) as Total_Employees,
        Sum(
            Case
                When Attrition = 1 Then 1
                Else 0
            End) as Employees_left,
        Cast(
            Sum(
                Case
                    When Attrition = 1 Then 1 Else 0
                End) * 100.0
                /
                Count(EmployeeNumber) 
            as Decimal(10,2)
            )as AttritionRate
 FROM Employee
 Where YearsAtCompany <=2
 Group by JobRole
 Order by AttritionRate desc;

-- 14. ATTRITION BY JOB SATISFACTION: Compare attrition across satisfaction groups.
 WITH SatisfactionStats AS (
    SELECT
        CASE
            WHEN JobSatisfaction <= 2 THEN 'Low Satisfaction'
            WHEN JobSatisfaction = 3 THEN 'Medium Satisfaction'
            ELSE 'High Satisfaction'
        END AS SatisfactionGroup,
        
        COUNT(EmployeeNumber) AS Total_Employees,
        
        SUM(
            CASE
                WHEN Attrition = 1 THEN 1
                ELSE 0
            END
        ) AS Employees_Left
        
    FROM Employee
    
    GROUP BY
        CASE
            WHEN JobSatisfaction <= 2 THEN 'Low Satisfaction'
            WHEN JobSatisfaction = 3 THEN 'Medium Satisfaction'
            ELSE 'High Satisfaction'
        END
)
SELECT
    SatisfactionGroup,
    Total_Employees,
    Employees_Left,
    CAST(
        Employees_Left * 100.0 / Total_Employees
        AS DECIMAL(10,2)
    ) AS Attrition_Rate
FROM SatisfactionStats;

-- 15. SALARY RELATIVE TO ROLE AVERAGE: Compare attrition below versus at/above the average salary for each job role.
With EmployeeSalary as(
    Select
        EmployeeNumber,
        JobRole,
        MonthlyIncome,
        Attrition,
        AVG(MonthlyIncome) Over(Partition by JobRole) as RoleAvgSalary
     From Employee
     ),
    
   SalaryBucket as(
    Select
        EmployeeNumber,
        JobRole,
        MonthlyIncome,
        Attrition,
        RoleAvgSalary,
        Case
            When MonthlyIncome < RoleAvgSalary THEN 'Below Average'
            Else 'At/Above Average'
        End as SalaryClassification
    From EmployeeSalary
    )

Select
    SalaryClassification,
    Count(EmployeeNumber) as TotalEmployees,
    SUM(Case When Attrition = 1 Then 1 Else 0 END) as EmployeesLeft,
    Cast(SUM(Case When Attrition = 1 Then 1 Else 0 END) *100.0 / Count(EmployeeNumber) as Decimal(10,2)) as AttritionRate
From SalaryBucket
Group by SalaryClassification;

-- 16. COMBINED RISK SEGMENT: Compare attrition for employees with short tenure, overtime, and low satisfaction against others.
Select
    Case 
        When YearsAtCompany <= 2 
            AND OverTime = 1
            AND JobSatisfaction <=2
            Then 'High Risk'
            Else 'Others'
        End as Segment,
    Count(EmployeeNumber) as TotalEmployees,
    SUM(Case When Attrition = 1 Then 1 Else 0 End) as EmployeesLeft,
    Cast(SUM(Case When Attrition = 1 Then 1 Else 0 End) * 100.0 / Count(EmployeeNumber) as Decimal(10,2)) as AttritionRate
From Employee
Group by    
  Case 
        When YearsAtCompany <= 2 
            AND OverTime = 1 
            AND JobSatisfaction <=2
            Then 'High Risk'
            Else 'Others'
        End;  
 
-- 17. CURRENT EMPLOYEE SEGMENT MIX: Among employees who stayed, calculate the share in the defined risk segment versus others.
With CurrentEmployees as(
    Select * From Employee
    Where Attrition = 0
    )
Select
    Case 
        When YearsAtCompany <= 2 
            AND OverTime = 1
            AND JobSatisfaction <=2
            Then 'High Risk'
            Else 'Others'
        End as Segment,
    Count(EmployeeNumber) as TotalEmployees,
    Cast(Count(*) * 100.0 / Sum(count(*)) over() as Decimal(10,2)) as Percentage
From CurrentEmployees
Group by
    Case 
        When YearsAtCompany <= 2 
            AND OverTime = 1
            AND JobSatisfaction <=2
            Then 'High Risk'
            Else 'Others'
        End;

