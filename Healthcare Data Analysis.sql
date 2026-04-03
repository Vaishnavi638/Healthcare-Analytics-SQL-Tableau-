create database healthcare_db;
use healthcare_db;

create table healthcare (
id int auto_increment primary key,
Name varchar(100),
Age int,
Gender varchar(100),
Blood_Type varchar(5),
Medical_Condition varchar(100),
Date_of_Admission date,
Doctor varchar(100),
Hospital varchar(150),
Insurance_Provider varchar(100),
Billing_Amount decimal(10,2),
Room_Number int,
Admission_Type varchar(50),
Discharge_Date date,
Medication varchar(100),
Test_Results varchar(50)  
);

truncate table healthcare;

set global local_infile = 1;

show variables like 'secure_file_priv';

LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/healthcare_dataset.csv'
INTO TABLE healthcare
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(Name,	Age, Gender, Blood_Type, Medical_Condition,	Date_of_Admission,	Doctor,	Hospital, Insurance_Provider, Billing_Amount,
	Room_Number, Admission_Type, Discharge_Date, Medication, Test_Results );
    

-- Check total rows
SELECT COUNT(*) AS total_rows FROM healthcare;

-- Check for NULL values in key columns
SELECT 
    SUM(CASE WHEN name IS NULL THEN 1 ELSE 0 END) AS null_names,
    SUM(CASE WHEN billing_amount IS NULL THEN 1 ELSE 0 END) AS null_billing,
    SUM(CASE WHEN date_of_admission IS NULL THEN 1 ELSE 0 END) AS null_dates
FROM healthcare;
    
-- Check distinct values in categorical columns

SELECT DISTINCT admission_type FROM healthcare;

SELECT DISTINCT test_results FROM healthcare;

SELECT DISTINCT medical_condition FROM healthcare;    
 
 
-- Check date range of the dataset
SELECT 
    MIN(date_of_admission) AS earliest,
    MAX(date_of_admission) AS latest
FROM healthcare;


-- Average age
SELECT AVG(Age) AS avg_age FROM healthcare;
-- average age is 51


-- Average billing amount
SELECT AVG(Billing_Amount) FROM healthcare;
-- 25539.316075


-- Gender Distribution
SELECT Gender, COUNT(*) AS total
FROM healthcare
GROUP BY Gender;
-- Male	->27774,  Female ->27726


-- most common medical condition
SELECT Medical_Condition, COUNT(*) AS cases
FROM healthcare
GROUP BY Medical_Condition
ORDER BY cases DESC;


         --   Patient & Admission Analysis  --

-- 1. Average hospital stay by medical condition
SELECT 
    medical_condition,
    COUNT(*) AS total_patients,
    ROUND(AVG(DATEDIFF(discharge_date, date_of_admission)), 1) AS avg_stay_days
FROM healthcare
GROUP BY medical_condition
ORDER BY avg_stay_days DESC;
-- average stay is 15 days for all medical conditions


-- 2. Admission type breakdown
SELECT 
    admission_type,
    COUNT(*) AS total,
    ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM healthcare), 1) AS percentage
FROM healthcare
GROUP BY admission_type
ORDER BY total DESC;
-- Elective -> 33.6,  Urgent -> 33.5, Emergency-> 32.9 


-- 3. Age group segmentation
SELECT 
    CASE 
        WHEN age < 20 THEN 'Under 20'
        WHEN age BETWEEN 20 AND 39 THEN '20-39'
        WHEN age BETWEEN 40 AND 59 THEN '40-59'
        WHEN age BETWEEN 60 AND 79 THEN '60-79'
        ELSE '80+'
    END AS age_group,
    COUNT(*) AS patient_count,
    ROUND(AVG(billing_amount), 2) AS avg_billing
FROM healthcare
GROUP BY age_group
ORDER BY patient_count DESC;
-- most patients are 40-59 age group and highest average bill is 60-79 age group
    
    
       --  Billing & Insurance Analysis  --

-- 1. Revenue by insurance provider
SELECT 
    insurance_provider,
    COUNT(*) AS total_claims,
    ROUND(SUM(billing_amount), 2) AS total_revenue,
    ROUND(AVG(billing_amount), 2) AS avg_claim_amount
FROM healthcare
GROUP BY insurance_provider
ORDER BY total_revenue DESC;
-- Cigna insurers bring the most revenue


-- 2. Average billing by medical condition AND admission type
SELECT 
    medical_condition,
    admission_type,
    ROUND(AVG(billing_amount), 2) AS avg_billing,
    COUNT(*) AS cases
FROM healthcare
GROUP BY medical_condition, admission_type
ORDER BY avg_billing DESC;
-- highest average cost is for Diabetes patients with Elective admission type


-- 3. Top 10 highest billing hospitals
SELECT 
    hospital,
    COUNT(*) AS patients_served,
    ROUND(SUM(billing_amount), 2) AS total_revenue
FROM healthcare
GROUP BY hospital
ORDER BY total_revenue DESC
LIMIT 10;
-- highest revenue is Johnson PLC hospital




-- 1. Window function: Rank doctors by billing within each condition
SELECT 
    doctor,
    medical_condition,
    ROUND(SUM(billing_amount), 2) AS total_billed,
    RANK() OVER (
        PARTITION BY medical_condition 
        ORDER BY SUM(billing_amount) DESC
    ) AS doctor_rank
FROM healthcare
GROUP BY doctor, medical_condition;


-- 2. CTE: Readmission risk (patients admitted more than once)
WITH patient_visits AS (
    SELECT 
        name,
        age,
        medical_condition,
        COUNT(*) AS total_visits,
        MIN(date_of_admission) AS first_admission,
        MAX(date_of_admission) AS last_admission
    FROM healthcare
    GROUP BY name, age, medical_condition
)
SELECT *,
    DATEDIFF(last_admission, first_admission) AS days_between_visits
FROM patient_visits
WHERE total_visits > 1
ORDER BY total_visits DESC;


-- 3. Monthly admission trend with running total
SELECT 
    DATE_FORMAT(date_of_admission, '%Y-%m') AS month,
    COUNT(*) AS monthly_admissions,
    SUM(COUNT(*)) OVER (ORDER BY DATE_FORMAT(date_of_admission, '%Y-%m')) AS running_total
FROM healthcare
GROUP BY month
ORDER BY month;


-- 4. Test result analysis by condition (% breakdown)
SELECT 
    medical_condition,
    test_results,
    COUNT(*) AS count,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (PARTITION BY medical_condition), 1) AS pct
FROM healthcare
GROUP BY medical_condition, test_results
ORDER BY medical_condition, count DESC;






