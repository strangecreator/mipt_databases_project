-- 1
CREATE OR REPLACE FUNCTION project.get_upcoming_appointments(INTEGER) RETURNS SETOF project.appointment AS $$
declare patient_id_arg alias for $1;
    begin
        IF (SELECT COUNT(*) FROM project.patient AS p WHERE p.patient_id = patient_id_arg) = 0 THEN
            RAISE EXCEPTION USING ERRCODE = '02000', MESSAGE = 'There is no patient with patient_id: "' || patient_id_arg || '"!';
        ELSE
            return query (
                SELECT * FROM project.appointment AS meeting WHERE 1=1 AND
                    meeting.patient_id = patient_id_arg AND
                    meeting.appointment_dttm >= NOW() AND
                    meeting.is_active = true
            );
        END IF;
    end
$$ LANGUAGE plpgsql;

-- 2
CREATE OR REPLACE FUNCTION project.get_last_record(INTEGER) RETURNS SETOF project.record AS $$
declare patient_id_arg alias for $1;
    begin
        IF (SELECT COUNT(*) FROM project.patient AS p WHERE p.patient_id = patient_id_arg) = 0 THEN
            RAISE EXCEPTION USING ERRCODE = '02000', MESSAGE = 'There is no patient with patient_id: "' || patient_id_arg || '"!';
        ELSE
            return query (
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
                    WHERE patient_id = patient_id_arg
                ) as _ WHERE rank = 1
            );
        END IF;
    end
$$ LANGUAGE plpgsql;

-- 3
CREATE OR REPLACE FUNCTION project.get_number_of_doctors_by_facility_and_specialty(INTEGER, VARCHAR(25)) RETURNS SETOF project.doctor AS $$
declare facility_id_arg alias for $1;
declare specialty_arg alias for $2;
    begin
        IF (SELECT COUNT(*) FROM project.medical_facility AS f WHERE f.facility_id = facility_id_arg) = 0 THEN
            RAISE EXCEPTION USING ERRCODE = '02000', MESSAGE = 'There is no medical facility with facility_id: "' || facility_id_arg || '"!';
        ELSE
            return query (
                SELECT * FROM project.doctor AS d WHERE 1=1 AND
                    d.specialty = specialty_arg AND
                    d.primary_facility_id = facility_id_arg
            );
        END IF;
    end
$$ LANGUAGE plpgsql;