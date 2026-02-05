/* Data cleaning (Patient Table)
Remove patient rows where first name is missing
Standarize first name and last name to proper case and createa new 'Full name' column
Gender values should be either Male of Female
Split 'CityStateCountry' into CIty, State and Country columns */

CREATE TABLE dim_patient_clean (
	PatientID VARCHAR(20) PRIMARY KEY,
	Fullname VARCHAR(120),
	Gender VARCHAR(10),
	Date_of_birth DATE,
	City VARCHAR(50),
	State VARCHAR (50),
	Country VARCHAR (50)
)

INSERT INTO dim_patient_clean (
	PatientID, Fullname, Gender, Date_of_birth, City, State, Country
)
SELECT 
	p.patientid,
	UPPER(LEFT(BTRIM(p.firstname),1)) || LOWER(SUBSTRING(BTRIM(p.firstname) from 2 for LENGTH(BTRIM(p.firstname))))  
	|| ' ' ||
	UPPER(LEFT(BTRIM(p.lastname),1)) || LOWER(SUBSTRING(BTRIM(p.lastname) from 2 for LENGTH(BTRIM(p.lastname)))) 
	AS Fullname,
	CASE 
		WHEN p.gender = 'M' THEN 'Male'
		WHEN p.gender = 'F' THEN 'Female'
		ELSE p.gender 
	END AS gender,
	p.dob,
	SPLIT_PART(p.citystatecountry, ',', 1) AS City,
	SPLIT_PART(p.citystatecountry, ',', 2) AS State,
	SPLIT_PART(p.citystatecountry, ',', 3) AS Country
FROM dim_patient p
WHERE p.firstname IS NOT NULL

/*Data Cleaning(Department Table)
Remove departments where 'Department Category' is missing
Drop 'HOD' and 'Department Name' Columns
Use 'Specialization' as 'Department Name' Column */

CREATE TABLE dim_department_clean (
	DepartmentID VARCHAR(20) PRIMARY KEY,
	Department_name VARCHAR(100),
	Department_category VARCHAR(100)
)
INSERT INTO dim_department_clean (
	DepartmentID, Department_name, Department_category
)
SELECT 
	d.departmentid,
	d.specialization,
	d.departmentcategory
FROM dim_department d
WHERE d.departmentcategory IS NOT NULL

/* Data Celaning(Patient Vistis Table)
Merge all yearly visit tables (2020-2025) into one consolidated PatientVisits Table*/

CREATE TABLE PatientVisits (
  VisitID varchar(20) PRIMARY KEY,
  PatientID varchar(20),
  DoctorID varchar(20),
  DepartmentID varchar(20),
  DiagnosisID varchar(20),
  TreatmentID varchar(20),
  PaymentMethodID varchar(20),
  VisitDate date,
  VisitTime time,
  DischargeDate date,
  BillAmount decimal(18,2),
  InsuranceAmount decimal(18,2),
  SatisfactionScore integer,
  WaitTimeMinutes integer,
FOREIGN KEY (PatientID) REFERENCES Dim_Patient_Clean(PatientID),
FOREIGN KEY (DoctorID) REFERENCES Dim_Doctor(DoctorID),
FOREIGN KEY (DepartmentID) REFERENCES Dim_Department_Clean(DepartmentID),
FOREIGN KEY (DiagnosisID) REFERENCES Dim_Diagnosis(DiagnosisID),
FOREIGN KEY (TreatmentID) REFERENCES Dim_Treatment(TreatmentID),
FOREIGN KEY (PaymentMethodID) REFERENCES Dim_PaymentMethod(PaymentMethodID)
);


INSERT INTO PatientVisits (
	VisitID, PatientID, DoctorID, DepartmentID, DiagnosisID, TreatmentID,
	PaymentMethodID, VisitDate, VisitTime, DischargeDate, BillAmount,
	InsuranceAmount, SatisfactionScore, WaitTimeMinutes 
)
SELECT
	VisitID, PatientID, DoctorID, DepartmentID, DiagnosisID, TreatmentID,
	PaymentMethodID, VisitDate, VisitTime, DischargeDate, BillAmount,
	InsuranceAmount, SatisfactionScore, WaitTimeMinutes 
FROM patientvisits_2020_2021

UNION ALL

SELECT
	VisitID, PatientID, DoctorID, DepartmentID, DiagnosisID, TreatmentID,
	PaymentMethodID, VisitDate, VisitTime, DischargeDate, BillAmount,
	InsuranceAmount, SatisfactionScore, WaitTimeMinutes 
FROM patientvisits_2022_2023

UNION ALL

SELECT
	VisitID, PatientID, DoctorID, DepartmentID, DiagnosisID, TreatmentID,
	PaymentMethodID, VisitDate, VisitTime, DischargeDate, BillAmount,
	InsuranceAmount, SatisfactionScore, WaitTimeMinutes 
FROM patientvisits_2024

UNION ALL

SELECT
	VisitID, PatientID, DoctorID, DepartmentID, DiagnosisID, TreatmentID,
	PaymentMethodID, VisitDate, VisitTime, DischargeDate, BillAmount,
	InsuranceAmount, SatisfactionScore, WaitTimeMinutes 
FROM patientvisits_2025;

