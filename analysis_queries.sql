--Q1. For each doctor, count how many distinct patients they have treated.

SELECT 
	doc.firstname || ' ' || doc.lastname AS doctor_name,
	COUNT(DISTINCT v.patientiD) AS distinct_patients
FROM patientvisits v
JOIN dim_doctor doc
	ON v.doctorid = doc.doctorid
GROUP BY doc.doctorid, doc.firstname, doc.lastname
ORDER BY distinct_patients DESC

--Q2. Show the revenue split by each payment method, along with total visits.

SELECT 
	pm.paymentmethod AS payment_method,
	COUNT(*) AS total_visits,
	SUM(v.billamount) AS total_revenue
FROM patientvisits v
JOIN dim_paymentmethod pm
	ON v.paymentmethodid= pm.paymentmethodid
GROUP BY pm.paymentmethod

/*Q3. Categorize patients into age groups and calculate the average bill amount for each age band.
(Assume age at time of visit based on VisitDate.) */

WITH patients_age AS ( 
	SELECT 
		v.billamount, 
		CASE 
			WHEN EXTRACT(YEAR from AGE(v.visitdate, p.dob)) < 18 THEN '0-17' 
			WHEN EXTRACT(YEAR from AGE(v.visitdate, p.dob)) BETWEEN 18 AND 35 THEN '18-35' 
			WHEN EXTRACT(YEAR from AGE(v.visitdate, p.dob)) BETWEEN 36 AND 55 THEN '36-55' 
			ELSE '56+' 
		END AS age_group 
	FROM patientvisits v 
	JOIN dim_patient_clean p 
	ON v.patientid = p.patientid 
) 
SELECT 
	age_group, 
	CAST(AVG(billamount) AS NUMERIC(18,2)) AS avg_bill_amount, 
	COUNT(*) AS total_visits 
FROM patients_age 
GROUP BY age_group 
ORDER BY 
	CASE age_group
		WHEN '0-17' THEN 1 
		WHEN '18-35' THEN 2 
		WHEN '36-55' THEN 3 
		ELSE 4 
	END;
	
--Q4. Find total revenue and number of visits for each department.

SELECT
	d.department_name,
	COUNT(v.visitid) AS total_visits,
	SUM(v.billamount) AS total_revenue
FROM patientvisits v
JOIN dim_department_clean d
	ON v.departmentid = d.departmentid
GROUP BY d.department_name
ORDER BY total_revenue DESC


--Q5. Rank departments based on their total revenue within each department category.

WITH revenue_by_category AS (
	SELECT 
		d.department_category,
		d.department_name,
		SUM(v.billamount) AS total_revenue
	FROM patientvisits v
	JOIN dim_department_clean d
		ON v.departmentid = d.departmentid
	GROUP BY d.department_category, d.department_name
)
SELECT
	department_category,
	department_name,
	total_revenue,
	RANK()OVER(PARTITION BY department_category
	ORDER BY total_revenue DESC
	) AS rnk	
FROM revenue_by_category


--Q6. For each department, find the average satisfaction score and average wait time.

SELECT 
	d.department_name,
	-- kept as decimal for analytical accuracy; can be rounded in reporting layer
	ROUND(AVG(v.satisfactionscore),2) AS avg_satisfaction_score,
	ROUND(AVG(v.waittimeminutes),2) AS avg_waiting_time_minutes
FROM patientvisits v
JOIN dim_department_clean d
	ON v.departmentid = d.departmentid
GROUP BY d.department_name
ORDER BY avg_satisfaction_score DESC

--Q7. Compare the total number of hospital visits on weekdays vs weekends.

SELECT
	CASE
		WHEN EXTRACT(DOW FROM visitdate) IN (0,6) THEN 'Weekend'
		ELSE 'Weekday'
	END AS day_type,
	COUNT(*) AS total_visits
FROM patientvisits
GROUP BY day_type;

--Q8. For each month calculate total visits and a running cumulative total of visits.

WITH monthly_visits AS (
	SELECT
		COUNT(*) AS total_visits,
		CAST(DATE_TRUNC('month', visitdate) AS DATE) AS month_start
	FROM patientvisits
	GROUP BY DATE_TRUNC('month', visitdate)
) 
SELECT
	month_start,
	total_visits,
	SUM(total_visits) OVER(ORDER BY month_start
	ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cumulative_total
FROM monthly_visits
ORDER BY month_start

--Q9. Find the doctors with the highest average satisfaction score(minimum 100 visits)

SELECT 
	d.firstname  || ' ' || d.lastname AS doctor_name,
	ROUND(AVG(v.satisfactionscore),2) AS avg_satisfaction_score, 
	COUNT(v.visitid) AS total_visits
FROM dim_doctor d
JOIN patientvisits v
	ON d.doctorid = v.doctorid
GROUP BY d.doctorid, d.firstname, d.lastname
HAVING COUNT(v.visitid) >= 100
ORDER BY avg_satisfaction_score DESC

--Q10. Identify the most commonly prescribed treatment for each diagnosis.

WITH treatment_counts AS (
	SELECT 
		d.diagnosisname, 
		t.treatmentname, 
		COUNT(t.treatmentname) AS treatment_count
	FROM dim_treatment t
	JOIN patientvisits v
		ON t.treatmentid = v.treatmentid
	JOIN dim_diagnosis d
		ON d.diagnosisid = v.diagnosisid
	GROUP BY d.diagnosisid, d.diagnosisname, t.treatmentname
), ranked AS (
SELECT *,
	RANK() OVER (
	PARTITION BY diagnosisname 
	ORDER BY treatment_count DESC
	) AS rnk
FROM treatment_counts
)
SELECT *
FROM ranked
WHERE rnk = 1;