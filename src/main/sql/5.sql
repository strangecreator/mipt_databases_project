CREATE SCHEMA project;


CREATE TABLE IF NOT EXISTS project.patient(
    patient_id      INTEGER         NOT NULL,
    name            VARCHAR(50)     NOT NULL,
    birth_dt        DATE            NOT NULL,
    gender          VARCHAR(10)     NOT NULL,
    phone_number    VARCHAR(15),
    email           VARCHAR(30),

    CONSTRAINT patient_pk PRIMARY KEY (patient_id)
);

CREATE TABLE IF NOT EXISTS project.medical_facility(
    facility_id     INTEGER         NOT NULL,
    name            VARCHAR(50)     NOT NULL,
    type            VARCHAR(20)     NOT NULL,
    address         VARCHAR(30)     NOT NULL,
    city            VARCHAR(20)     NOT NULL,
    state           VARCHAR(20)     NOT NULL,
    zipcode         INTEGER,
    phone_number    VARCHAR(15),

    CONSTRAINT facility_pk PRIMARY KEY (facility_id)
);

CREATE TABLE IF NOT EXISTS project.doctor(
    doctor_id               INTEGER         NOT NULL,
    name                    VARCHAR(50)     NOT NULL,
    specialty               VARCHAR(25)     NOT NULL,
    phone_number            VARCHAR(15),
    email                   VARCHAR(30),
    primary_facility_id     INTEGER,

    CONSTRAINT doctor_pk PRIMARY KEY (doctor_id),

    CONSTRAINT doctor_medical_facility FOREIGN KEY (primary_facility_id)
        REFERENCES project.medical_facility(facility_id) ON DELETE SET NULL
);

CREATE TABLE IF NOT EXISTS project.appointment(
    appointment_id      INTEGER         NOT NULL,
    patient_id          INTEGER         NOT NULL,
    doctor_id           INTEGER         NOT NULL,
    facility_id         INTEGER,
    appointment_dttm    TIMESTAMP       NOT NULL,
    reason              VARCHAR(30),
    notes               VARCHAR(50),
    is_active           BOOLEAN         NOT NULL,

    CONSTRAINT appointment_pk PRIMARY KEY (appointment_id),

    CONSTRAINT appointment_patient FOREIGN KEY (patient_id)
        REFERENCES project.patient(patient_id) ON DELETE CASCADE,
    CONSTRAINT appointment_doctor FOREIGN KEY (doctor_id)
        REFERENCES project.doctor(doctor_id) ON DELETE CASCADE,
    CONSTRAINT appointment_medical_facility FOREIGN KEY (facility_id)
        REFERENCES project.medical_facility(facility_id) ON DELETE SET NULL
);

CREATE TABLE IF NOT EXISTS project.prescription(
    prescription_id     INTEGER         NOT NULL,
    patient_id          INTEGER         NOT NULL,
    doctor_id           INTEGER         NOT NULL,
    medication_name     VARCHAR(30)     NOT NULL,
    dosage              VARCHAR(30),
    quantity            INTEGER,
    prescription_dt     DATE            NOT NULL,
    notes               VARCHAR(50),

    CONSTRAINT prescription_pk PRIMARY KEY (prescription_id),

    CONSTRAINT prescription_patient FOREIGN KEY (patient_id)
        REFERENCES project.patient(patient_id) ON DELETE CASCADE,
    CONSTRAINT prescription_doctor FOREIGN KEY (doctor_id)
        REFERENCES project.doctor(doctor_id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS project.record(
    record_id               INTEGER         NOT NULL,
    patient_id              INTEGER         NOT NULL,
    assessment_dttm         TIMESTAMP       NOT NULL,
    systolic_pressure       INTEGER,
    diastolic_pressure      INTEGER,
    temperature             REAL,
    heart_rate              REAL,

    CONSTRAINT record_pk PRIMARY KEY (record_id),

    CONSTRAINT record_patient FOREIGN KEY (patient_id)
        REFERENCES project.patient(patient_id) ON DELETE CASCADE
);