-- 1
SELECT DISTINCT
    patient.patient_id,
    name,
    phone_number
FROM project.patient
JOIN project.record ON patient.patient_id = record.patient_id
WHERE record.temperature >= 99.5;  -- 37.5 by Celsius

-- 2
SELECT
    facility_id,
    name,
    (SELECT COUNT(*) FROM (SELECT doctor_id FROM project.doctor WHERE primary_facility_id = facility_id) as doctors) as workers_number
FROM project.medical_facility
ORDER BY 3 DESC;

-- 3
SELECT
    patient_id,
    doctor_id,
    facility_id,
    appointment_dttm,
    reason
FROM project.appointment
WHERE
    is_active AND
    '2024-04-08' <= appointment_dttm::date AND appointment_dttm::date < '2024-04-15';

-- 4
SELECT
    doctor_id,
    doctor.name,
    doctor.phone_number
FROM project.doctor
JOIN project.medical_facility ON doctor.primary_facility_id = medical_facility.facility_id
WHERE city = 'Columbus';

-- 5
SELECT
    record.patient_id,
    (SELECT name FROM project.patient WHERE patient.patient_id = record.patient_id) as name,
    max(systolic_pressure) as max_systolic_pressure,
    max(diastolic_pressure) as max_diastolic_pressure,
    max(temperature) as max_temperature,
    max(heart_rate) as max_heart_rate
FROM project.record
GROUP BY record.patient_id
ORDER BY record.patient_id;

-- 6
SELECT
    facility_id,
    name,
    city,
    phone_number
FROM project.medical_facility
WHERE phone_number IS NOT NULL;

-- 7
SELECT DISTINCT
    patient.patient_id,
    patient.name,
    patient.phone_number,
    patient.email,
    appointment.reason as reason
FROM project.patient
JOIN project.appointment ON patient.patient_id = appointment.patient_id
JOIN project.doctor ON appointment.doctor_id = doctor.doctor_id
WHERE doctor.specialty = 'Anesthesiology';

-- 8
SELECT
    year,
    assessment_number
FROM
(
    WITH years as
    (
        SELECT DISTINCT EXTRACT(YEAR FROM record.assessment_dttm) as year
        FROM project.record
    ),
    years_with_assessment_number as (
        SELECT
            year,
            (SELECT COUNT(*) FROM (SELECT FROM project.record WHERE EXTRACT(YEAR FROM record.assessment_dttm) = year) as _) as assessment_number
        FROM years
    )
    SELECT
        year,
        (NTILE(3) OVER(ORDER BY assessment_number DESC)) as ntile_group,
        CASE
            WHEN NTILE(3) OVER(ORDER BY assessment_number DESC) = 1 THEN 'high'
            WHEN NTILE(3) OVER(ORDER BY assessment_number DESC) = 2 THEN 'average'
            WHEN NTILE(3) OVER(ORDER BY assessment_number DESC) = 3 THEN 'low'
        END as assessment_number
    FROM years_with_assessment_number
    ORDER BY ntile_group, year
) as _;

-- 9
SELECT
    month_str as month,
    number_of_assessments
FROM
(
    SELECT
        EXTRACT(MONTH FROM record.assessment_dttm) as month,
        TRIM(TO_CHAR(TO_DATE(EXTRACT(MONTH FROM record.assessment_dttm)::text, 'MM'), 'Month')) as month_str,
        COUNT(*) as number_of_assessments
    FROM project.record
    GROUP BY EXTRACT(MONTH FROM record.assessment_dttm)
    HAVING COUNT(*) >= 10
    ORDER BY month
) as _;

-- 10
SELECT
    gender,
    ROUND(avg(systolic_pressure)::numeric, 2) as avg_systolic_pressure,
    ROUND(avg(diastolic_pressure)::numeric, 2) as avg_diastolic_pressure,
    ROUND(avg(temperature)::numeric, 2) as avg_temperature,
    ROUND(avg(heart_rate)::numeric, 2) as avg_heart_rate
FROM project.record
JOIN project.patient ON record.patient_id = patient.patient_id
GROUP BY patient.gender;