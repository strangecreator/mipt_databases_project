-- 1
CREATE INDEX record_patient_id_dttm_index
ON project.record (patient_id, assessment_dttm);

-- 2
CREATE INDEX record_indicators_index
ON project.record (systolic_pressure, diastolic_pressure, temperature, heart_rate);

-- 3
CREATE INDEX appointment_patient_id_dttm_index
ON project.appointment (patient_id, appointment_dttm);

-- 4
CREATE INDEX appointment_doctor_id_dttm_index
ON project.appointment (doctor_id, appointment_dttm);