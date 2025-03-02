CREATE DATABASE HealthcareAnalytics
USE HealthcareAnalytics

SELECT * FROM Transaction_coo
SELECT * FROM Review_transaction_coo
SELECT * FROM Patient_history_samp
SELECT * FROM Review_patient_history_samp
SELECT * FROM Medicare_Provider_Charge_Inpatient
SELECT * FROM Medicare_Provider_Charge_Outpatient
SELECT * FROM Medicare_Charge_Inpatient_Summary
SELECT * FROM Medicare_Charge_Outpatient_Summary

-- Number of Rows in each table
SELECT COUNT(*) AS Row_Count FROM Transaction_coo
SELECT COUNT(*) AS Row_Count FROM Rreview_transaction_coo
SELECT COUNT(*) AS Row_Count FROM Patient_history_samp
SELECT COUNT(*) AS Row_Count FROM Review_patient_history_samp
SELECT COUNT(*) AS Row_Count FROM Medicare_Provider_Charge_Inpatient
SELECT COUNT(*) AS Row_Count FROM Medicare_Provider_Charge_Outpatient
SELECT COUNT(*) AS Row_Count FROM Medicare_Charge_Inpatient_Summary
SELECT COUNT(*) AS Row_Count FROM Medicare_Charge_Outpatient_Summary


--IMPATIENT ANALYSIS

-- Understand provider distribution across states and cities for Inpatients
SELECT COUNT(DISTINCT  DRG_Definition) AS DRG_Definition,
       COUNT(DISTINCT Provider_Id) AS Unique_Providers, 
       COUNT(DISTINCT Provider_State) AS Unique_States, 
       COUNT(DISTINCT Provider_City) AS Unique_Cities
FROM Medicare_Provider_Charge_Inpatient


--Hospitals handling the highest number of patients
SELECT TOP 10 Provider_Name, Provider_State, SUM(Total_Discharges) AS Total_Discharges
FROM Medicare_Provider_Charge_Inpatient
GROUP BY Provider_Name, Provider_State
ORDER BY Total_Discharges DESC


-- Analyze cost distribution for Inpatients
SELECT 
    MIN(Average_Total_Payments) AS Min_Payment, 
    MAX(Average_Total_Payments) AS Max_Payment, 
    AVG(Average_Total_Payments) AS Avg_Payment
FROM Medicare_Provider_Charge_Inpatient


-- Identify the most expensive inpatient procedures
SELECT TOP 10 DRG_Definition, 
       AVG(Average_Covered_Charges) AS Avg_Covered_Charge, 
       AVG(Average_Total_Payments) AS Avg_Total_Payment
FROM Medicare_Provider_Charge_Inpatient
GROUP BY DRG_Definition
ORDER BY Avg_Covered_Charge DESC


-- Most Common DRGs
SELECT DRG_Definition, COUNT(*) AS Frequency
FROM Medicare_Provider_Charge_Inpatient
GROUP BY DRG_Definition
ORDER BY Frequency DESC

-- Top 10 Providers with Highest Charges
SELECT TOP 10 Provider_Name, Provider_City, Provider_State, 
       AVG(Average_Covered_Charges) AS Avg_Covered_Charge
FROM Medicare_Provider_Charge_Inpatient
GROUP BY Provider_Name, Provider_City, Provider_State
ORDER BY Avg_Covered_Charge DESC

--Top 10 Regions with Highest Charges
SELECT TOP 10 Hospital_Referral_Region_HRR_Description, 
       AVG(Average_Covered_Charges) AS Avg_Covered_Charge
FROM Medicare_Provider_Charge_Inpatient
GROUP BY Hospital_Referral_Region_HRR_Description
ORDER BY Avg_Covered_Charge DESC

-- Identify cost variations across states
SELECT Provider_State, AVG(Average_Covered_Charges) AS Avg_Covered_Charge
FROM Medicare_Provider_Charge_Inpatient
GROUP BY Provider_State
ORDER BY Avg_Covered_Charge DESC

--Cities where Medicare reimbursement is highes
SELECT Provider_City, Provider_State, AVG(Average_Medicare_Payments) AS Avg_Medicare_Payment
FROM Medicare_Provider_Charge_Inpatient
GROUP BY Provider_City, Provider_State
ORDER BY Avg_Medicare_Payment DESC


--Providers with the largest charge vs. Medicare reimbursement gaps
SELECT Provider_Name, Provider_State,
       AVG(Average_Covered_Charges) AS Avg_Charge,
       AVG(Average_Medicare_Payments) AS Avg_Medicare_Payment,
       (AVG(Average_Covered_Charges) - AVG(Average_Medicare_Payments)) AS Charge_Payment_Diff
FROM Medicare_Provider_Charge_Inpatient
GROUP BY Provider_Name, Provider_State
ORDER BY Charge_Payment_Diff DESC

--Flag providers billing more than twice the average charge for the same procedure
SELECT DRG_Definition, Provider_Name, Provider_State, 
       AVG(Average_Covered_Charges) AS Avg_Covered_Charge
FROM Medicare_Provider_Charge_Inpatient
GROUP BY DRG_Definition, Provider_Name, Provider_State
HAVING AVG(Average_Covered_Charges) > 
       (SELECT AVG(Average_Covered_Charges) * 2 FROM Medicare_Provider_Charge_Inpatient)
ORDER BY Avg_Covered_Charge DESC

--Detect hospitals charging significantly above the 95th percentile
SELECT Provider_Name, Provider_State, DRG_Definition, 
       Average_Covered_Charges, 
       PERCENTILE_CONT(0.95) WITHIN GROUP (ORDER BY Average_Covered_Charges) OVER () AS P95_Charge
FROM Medicare_Provider_Charge_Inpatient
WHERE Average_Covered_Charges > 
      (SELECT PERCENTILE_CONT(0.95) WITHIN GROUP (ORDER BY Average_Covered_Charges) FROM Medicare_Provider_Charge_Inpatient)

--Identify providers with high patient volume but low average payments
SELECT Provider_Name, Provider_State, 
       SUM(Total_Discharges) AS Total_Discharges,
       AVG(Average_Medicare_Payments) AS Avg_Medicare_Payment
FROM Medicare_Provider_Charge_Inpatient
GROUP BY Provider_Name, Provider_State
HAVING SUM(Total_Discharges) > 1000 AND AVG(Average_Medicare_Payments) < 5000
ORDER BY Total_Discharges DESC


--OUTPATIENT ANALYSIS

--Total records, distinct providers, APC codes, and states
SELECT 
    COUNT(*) AS total_records,
    COUNT(DISTINCT provider_id) AS unique_providers,
    COUNT(DISTINCT APC) AS unique_APCs,
    COUNT(DISTINCT provider_state) AS unique_states
FROM Medicare_Provider_Charge_Outpatient


--Analyze cost distribution for Outpatients
SELECT 
    MIN(Average_Estimated_Submitted_Charges) AS min_charge,
    MAX(Average_Estimated_Submitted_Charges) AS max_charge,
    AVG(Average_Estimated_Submitted_Charges) AS avg_charge,
    MIN(Average_Total_Payments) AS min_payment,
    MAX(Average_Total_Payments) AS max_payment,
    AVG(Average_Total_Payments) AS avg_payment
FROM Medicare_Provider_Charge_Outpatient


--Top 10 Most Expensive Procedures (APCs)
SELECT TOP 10 
    APC, 
    AVG(Average_Estimated_Submitted_Charges) AS avg_charge
FROM Medicare_Provider_Charge_Outpatient
GROUP BY APC
ORDER BY avg_charge DESC


--Top 5 States with Highest Submitted Charges
SELECT TOP 5 
    provider_state, 
    AVG(Average_Estimated_Submitted_Charges) AS avg_charge
FROM Medicare_Provider_Charge_Outpatient
GROUP BY provider_state
ORDER BY avg_charge DESC

--Cost & Payment Gaps by Hospital Referral Region (HRR)
SELECT 
    [Hospital_Referral_Region_HRR_Description], 
    AVG(Average_Estimated_Submitted_Charges) AS avg_charge, 
    AVG(Average_Total_Payments) AS avg_payment,
    AVG(Average_Estimated_Submitted_Charges) - AVG(Average_Total_Payments) AS avg_gap
FROM Medicare_Provider_Charge_Outpatient
GROUP BY [Hospital_Referral_Region_HRR_Description]
ORDER BY avg_gap DESC

--Providers with Highest Payment-Submission Discrepancy
SELECT TOP 10 
    provider_id, 
    provider_name, 
    provider_state, 
    AVG(Average_Estimated_Submitted_Charges) AS avg_charge, 
    AVG(Average_Total_Payments) AS avg_payment,
    AVG(Average_Estimated_Submitted_Charges) - AVG(Average_Total_Payments) AS charge_payment_gap
FROM Medicare_Provider_Charge_Outpatient
GROUP BY provider_id, provider_name, provider_state
ORDER BY charge_payment_gap DESC


--Outlier Hospitals (Above 95th Percentile in Charges)
WITH ChargePercentiles AS (
    SELECT 
        APC,
        PERCENTILE_CONT(0.95) WITHIN GROUP (ORDER BY avg_estimated_submitted_charges) 
        OVER (PARTITION BY APC) AS percentile_95
    FROM Medicare_Provider_Charge_Outpatient
)
SELECT 
    c.provider_id, 
    c.provider_name, 
    c.provider_state, 
    c.APC, 
    c.Average_Estimated_Submitted_Charges, 
    p.percentile_95
FROM Medicare_Provider_Charge_Outpatient c
JOIN ChargePercentiles p 
    ON c.APC = p.APC
WHERE c.Average_Estimated_Submitted_Charges > p.percentile_95
ORDER BY c.APC, c.Average_Estimated_Submitted_Charges DESC


--Compare Inpatient & Outpatient Payments by Provider
SELECT 
    A.Provider_Name, 
    A.Provider_State, 
    AVG(A.Average_Total_Payments) AS Avg_Inpatient_Payment,
    AVG(B.Average_Total_Payments) AS Avg_Outpatient_Payment
FROM Medicare_Provider_Charge_Inpatient A
JOIN Medicare_Provider_Charge_Outpatient B
    ON A.Provider_Name = B.Provider_Name AND A.Provider_State = B.Provider_State
GROUP BY A.Provider_Name, A.Provider_State
ORDER BY Avg_Inpatient_Payment DESC


--TRANSACTIONS AND PATIENT HISTORY ANALYSIS

-- Count of unique procedures
SELECT COUNT(DISTINCT global_proc_id) AS Unique_Procedures FROM Transaction_coo

--Patients occuring more than once 
SELECT id, COUNT(*) AS Transaction_coo
FROM Transaction_coo
GROUP BY id
HAVING COUNT(*) > 1


--Total Count by Procedure
SELECT global_proc_id, SUM(count) AS total_count
FROM Transaction_coo
GROUP BY global_proc_id
ORDER BY total_count DESC

-- Percentage Contribution of Each Procedure
WITH Total AS (
    SELECT SUM(count) AS total_count FROM Transaction_coo
)
SELECT global_proc_id, 
       SUM(count) AS procedure_count,
       (SUM(count) * 100.0) / (SELECT total_count FROM Total) AS percentage_contribution
FROM Transaction_coo
GROUP BY global_proc_id
ORDER BY percentage_contribution DESC;


--Unique patients
SELECT COUNT(DISTINCT id) AS Unique_Patients FROM Patient_history_samp


--Gender distribution
SELECT gender, COUNT(*) AS Count, 
       ROUND((COUNT(*) * 100.0 / (SELECT COUNT(*) FROM Patient_history_samp)), 2) AS Percentage
FROM Patient_history_samp
GROUP BY gender


--Age distribution
SELECT age, COUNT(*) AS Count, 
       ROUND((COUNT(*) * 100.0 / (SELECT COUNT(*) FROM Patient_history_samp)), 2) AS Percentage
FROM Patient_history_samp
GROUP BY age


--Income distribution
SELECT income, COUNT(*) AS Count, 
       ROUND((COUNT(*) * 100.0 / (SELECT COUNT(*) FROM Patient_history_samp)), 2) AS Percentage
FROM Patient_history_samp
GROUP BY income




--Missing Data Check (Patients with Missing Age or Income)
SELECT 
    SUM(CASE WHEN age IS NULL THEN 1 ELSE 0 END) AS missing_age_count,
    SUM(CASE WHEN income IS NULL THEN 1 ELSE 0 END) AS missing_income_count
FROM patient_history_samp


--patient revisting hospital more than once 
SELECT id, COUNT(*) AS occurrence_count
FROM Review_Transaction_coo
GROUP BY id,global_proc_id
HAVING COUNT(*) > 1;


---Most Frequent Procedures Leading to Revisits
SELECT global_proc_id, SUM(count) AS total_revisits
FROM Review_Transaction_coo
GROUP BY global_proc_id
ORDER BY total_revisits DESC


--Gender Distribution of Revisiting Patients
SELECT gender, COUNT(*) AS total_count,
       (COUNT(*) * 100.0) / (SELECT COUNT(*) FROM Review_patient_history_samp) AS percentage
FROM Review_patient_history_samp
GROUP BY gender

--Income Distribution Among Revisiting Patients
SELECT income, COUNT(*) AS total_count,
       (COUNT(*) * 100.0) / (SELECT COUNT(*) FROM Review_patient_history_samp WHERE income IS NOT NULL) AS percentage
FROM Review_patient_history_samp
WHERE income IS NOT NULL
GROUP BY income
ORDER BY percentage DESC


--Age Group Distribution of Revisiting Patients
SELECT age, COUNT(*) AS total_count,
       (COUNT(*) * 100.0) / (SELECT COUNT(*) FROM Review_patient_history_samp WHERE income IS NOT NULL) AS percentage
FROM Review_patient_history_samp
WHERE income IS NOT NULL
GROUP BY income
ORDER BY percentage DESC


--Number of Transactions per Patient
SELECT p.id, p.age, p.gender, p.income, 
       COUNT(t.id) AS Total_Transactions
FROM Patient_history_samp p
LEFT JOIN Transaction_coo t ON p.id = t.id
GROUP BY p.id, p.age, p.gender, p.income
ORDER BY Total_Transactions DESC


--Most Frequent Procedure by Gender
SELECT p.gender, t.global_proc_id , COUNT(*) AS Procedure_Count
FROM Patient_history_samp p
JOIN Transaction_coo t ON p.id = t.id
GROUP BY p.gender,t.global_proc_id 
ORDER BY Procedure_Count DESC


--Most Frequent Procedure by Age
SELECT p.age,t.global_proc_id  ,COUNT(*) AS Procedure_Count
FROM Patient_history_samp p
JOIN Transaction_coo t ON p.id = t.id
GROUP BY p.age,t.global_proc_id 
ORDER BY Procedure_Count DESC


--Most Frequent Procedure by Income
SELECT p.income,t.global_proc_id , COUNT(*) AS Procedure_Count
FROM Patient_history_samp p
JOIN Transaction_coo t ON p.id = t.id
GROUP BY p.income,t.global_proc_id 
ORDER BY Procedure_Count DESC

--Procedures with the Highest Revisit Rate
SELECT TOP 5 t.global_proc_id, 
       SUM(r.count) AS total_revisits, 
       SUM(t.count) AS total_procedures, 
       (SUM(r.count) * 100.0 / NULLIF(SUM(t.count), 0)) AS revisit_rate
FROM Transaction_coo t
LEFT JOIN Review_Transaction_coo r ON t.global_proc_id = r.global_proc_id
GROUP BY t.global_proc_id
ORDER BY revisit_rate DESC
