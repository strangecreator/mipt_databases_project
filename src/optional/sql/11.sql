-- 1
CREATE TABLE project.prescription_log (
    log_id                      SERIAL                  NOT NULL,
    operation_type              VARCHAR(8)              NOT NULL,
    operation_timestamp         TIMESTAMP               NOT NULL,
    executed_by                 VARCHAR(50)             NOT NULL,
    previous_prescription_id    INTEGER,

    prescription_id             INTEGER                 NOT NULL,
    patient_id                  INTEGER                 NOT NULL,
    doctor_id                   INTEGER                 NOT NULL,
    medication_name             VARCHAR(30)             NOT NULL,
    dosage                      VARCHAR(30),
    quantity                    INTEGER,
    prescription_dt             DATE                    NOT NULL,
    notes                       VARCHAR(50),

    CONSTRAINT log_pk PRIMARY KEY (log_id)
);


CREATE OR REPLACE FUNCTION project.log_prescription_changes()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        INSERT INTO project.prescription_log (
            operation_type, operation_timestamp, executed_by, previous_prescription_id,
            prescription_id, patient_id, doctor_id, medication_name, dosage, quantity, prescription_dt, notes
        )
        VALUES (
            'INSERT', NOW(), current_user, NULL,
            NEW.prescription_id, NEW.patient_id, NEW.doctor_id, NEW.medication_name, NEW.dosage, NEW.quantity, NEW.prescription_dt, NEW.notes
        );
        RETURN NEW;
    ELSIF TG_OP = 'UPDATE' THEN
        INSERT INTO project.prescription_log (
            operation_type, operation_timestamp, executed_by, previous_prescription_id,
            prescription_id, patient_id, doctor_id, medication_name, dosage, quantity, prescription_dt, notes
        )
        VALUES (
            'UPDATE', NOW(), current_user,  OLD.prescription_id,
            NEW.prescription_id, NEW.patient_id, NEW.doctor_id, NEW.medication_name, NEW.dosage, NEW.quantity, NEW.prescription_dt, NEW.notes
        );
        RETURN NEW;
    ELSIF TG_OP = 'DELETE' THEN
        INSERT INTO project.prescription_log (
            operation_type, operation_timestamp, executed_by, previous_prescription_id,
            prescription_id, patient_id, doctor_id, medication_name, dosage, quantity, prescription_dt, notes
        )
        VALUES (
            'DELETE', NOW(), current_user,  NULL,
            OLD.prescription_id, OLD.patient_id, OLD.doctor_id, OLD.medication_name, OLD.dosage, OLD.quantity, OLD.prescription_dt, OLD.notes
        );
        RETURN OLD;
    END IF;
END;
$$ LANGUAGE plpgsql;


CREATE TRIGGER prescription_changes_trigger
AFTER INSERT OR UPDATE OR DELETE ON project.prescription
FOR EACH ROW EXECUTE FUNCTION project.log_prescription_changes();


-- 2
CREATE OR REPLACE VIEW project.medical_facility_json AS (
    SELECT
        row_to_json(m)
    FROM (SELECT * FROM project.medical_facility) m
);


CREATE OR REPLACE FUNCTION project.medical_facility_json_instead_of_insert_trigger_function() RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO project.medical_facility (facility_id, name, type, address, city, state, zipcode, phone_number)
    VALUES (
        CAST(NEW.row_to_json::json#>>'{facility_id}' as INTEGER),
        NEW.row_to_json::json#>>'{name}',
        NEW.row_to_json::json#>>'{type}',
        NEW.row_to_json::json#>>'{address}',
        NEW.row_to_json::json#>>'{city}',
        NEW.row_to_json::json#>>'{state}',
        CAST(NEW.row_to_json::json#>>'{zipcode}' as INTEGER),
        NEW.row_to_json::json#>>'{phone_number}'
    );
    return NULL; -- Suppress the default INSERT action
END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE TRIGGER medical_facility_json_instead_of_insert_trigger
INSTEAD OF INSERT ON project.medical_facility_json
FOR EACH ROW
EXECUTE FUNCTION project.medical_facility_json_instead_of_insert_trigger_function();


-- 3
CREATE OR REPLACE FUNCTION project.validate_email(email_text TEXT) RETURNS BOOLEAN AS $$
BEGIN
    -- Regular expression to validate email format
    RETURN email_text ~* '^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$';
END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION project.validate_email_trigger() RETURNS TRIGGER AS $$
BEGIN
    IF NEW.email is not NULL AND NOT project.validate_email(NEW.email) THEN
        RAISE EXCEPTION 'Invalid email format: %', NEW.email;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;


CREATE TRIGGER patient_check_email_trigger
BEFORE INSERT OR UPDATE ON project.patient
FOR EACH ROW
EXECUTE FUNCTION project.validate_email_trigger();


CREATE TRIGGER doctor_check_email_trigger
BEFORE INSERT OR UPDATE ON project.doctor
FOR EACH ROW
EXECUTE FUNCTION project.validate_email_trigger();