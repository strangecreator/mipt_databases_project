-- 1
CREATE OR REPLACE view project.last_record as (
    SELECT
        record_id,
        patient_id,
        assessment_dttm,
        systolic_pressure,
        diastolic_pressure,
        temperature,
        heart_rate
    FROM (
        SELECT
            *,
            RANK() OVER (PARTITION BY patient_id ORDER BY assessment_dttm DESC) as rank
        FROM project.record
    ) as _ WHERE rank = 1
);

-- 2
CREATE OR REPLACE view project.last_record_current as (
    SELECT
        *
    FROM project.last_record
    WHERE assessment_dttm >= (NOW() - INTERVAL '1 DAY')
);

-- 3
CREATE OR REPLACE view project.last_record_current_urgent as (
    SELECT
        *
    FROM project.last_record_current
    WHERE 1=1 AND
        systolic_pressure >= 130 OR
        systolic_pressure < 90 OR
        diastolic_pressure >= 80 OR
        diastolic_pressure < 60 OR
        temperature >= 104 OR /* 38 C */
        heart_rate >= 100 OR /* tachycardia */
        heart_rate < 60 /* bradycardia */
);