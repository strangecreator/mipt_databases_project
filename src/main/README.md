### 1-4:
[Ссылка на выполненные задания 1-4](../../README.md)

## 5. DDL скрипты
```sql
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
```

## 6. Наполнение данными
```sql
INSERT INTO project.patient (patient_id, name, birth_dt, gender, phone_number, email)
VALUES
    (1, 'Sarah C. Salyers', to_date('November 24, 1956', 'Month DD, YYYY'), 'female', '+12812891222', 'SarahCSalyers@armyspy.com'),
    (2, 'Frank V. Salinas', to_date('September 27, 1942', 'Month DD, YYYY'), 'male', '+12173990093', 'FrankVSalinas@dayrep.com'),
    (3, 'Michael S. Cheatham', to_date('December 6, 1939', 'Month DD, YYYY'), 'male', '+16787813623', NULL),
    (4, 'David J. Walker', to_date('July 11, 2002', 'Month DD, YYYY'), 'male', '+12122418038', 'DavidJWalker@dayrep.com'),
    (5, 'Brittany R. Cooper', to_date('January 8, 1998', 'Month DD, YYYY'), 'female', '+13305288860', 'BrittanyRCooper@armyspy.com'),
    (6, 'Sandra M. Pender', to_date('March 22, 1981', 'Month DD, YYYY'), 'female', '+16019196651', 'SandraMPender@teleworm.us'),
    (7, 'William P. Butler', to_date('June 10, 1989', 'Month DD, YYYY'), 'male', '+16153062955', 'WilliamPButler@jourrapide.com'),
    (8, 'Lucille C. Moro', to_date('April 9, 1982', 'Month DD, YYYY'), 'female', '+19087914331', NULL),
    (9, 'Janice N. Hayward', to_date('November 15, 1993', 'Month DD, YYYY'), 'female', '+16312252613', 'JaniceNHayward@jourrapide.com'),
    (10, 'Tom C. Hollingshead', to_date('December 19, 1998', 'Month DD, YYYY'), 'male', '+13134060743', 'TomCHollingshead@rhyta.com'),
    (11, 'Taylor J. McDuffy', to_date('November 25, 1993', 'Month DD, YYYY'), 'male', '+16517263810', 'TaylorJMcDuffy@armyspy.com'),
    (12, 'George D. Roach', to_date('July 11, 1994', 'Month DD, YYYY'), 'male', '+13237350233', 'GeorgeDRoach@teleworm.us'),
    (13, 'Alison P. Hall', to_date('April 19, 1990', 'Month DD, YYYY'), 'female', NULL, 'AlisonPHall@dayrep.com'),
    (14, 'Brandi D. Lopez', to_date('September 16, 1995', 'Month DD, YYYY'), 'female', '+13133334822', 'BrandiDLopez@jourrapide.com'),
    (15, 'Viola M. Gray', to_date('October 3, 1991', 'Month DD, YYYY'), 'female', '+18083307720', 'ViolaMGray@jourrapide.com');

INSERT INTO project.medical_facility (facility_id, name, type, address, city, state, zipcode, phone_number)
VALUES
    (1, 'Sunshine Health Clinic', 'Clinic', '1234 Maple St', 'Springfield', 'MA', '01103', NULL),
    (2, 'Riverside Hospital', 'Hospital', '5678 River Rd', 'Columbus', 'GA', '31901', '+15552345678'),
    (3, 'Metro Dental Care', 'Dental', '9012 Oak Blvd', 'Cincinnati', 'KY', '41073', '+15553456789'),
    (4, 'Vision Plus Eye Center', 'Eye Care', '3456 Pine St', 'Dayton', 'NV', '89403', '+15554567890'),
    (5, 'Central Pediatrics', 'Pediatrics', '7890 Elm St', 'Akron', 'CO', '80720', '+15555678901'),
    (6, 'Advanced Dermatology', 'Dermatology', '6543 Birch Rd', 'Toledo', 'WA', NULL, '+15556789012'),
    (7, 'Summit Rehabilitation', 'Family Medicine', '3218 Cedar Ave', 'Cleveland', 'TX', '77327', '+15557890123'),
    (8, 'Harmony Mental Health', 'Mental Health', '2134 Willow Way', 'Youngstown', 'FL', '32466', '+15558901234'),
    (9, 'Green Valley Orthopedics', 'Orthopedics', '4321 Mountain Rd', 'Flagstaff', 'AZ', '86001', NULL),
    (10, 'Oceanview Cardiology', 'Cardiology', '8765 Sea Breeze Ave', 'Savannah', 'GA', '31401', '+15550123456'),
    (11, 'Bright Smile Dental Clinic', 'Dental', '9632 Sunshine Rd', 'El Paso', 'TX', '79925', '+15551239876'),
    (12, 'Pinecrest Psychiatric', 'Psychiatric', '1482 Pine St', 'Rapid City', 'SD', '57701', '+15552348910'),
    (13, 'Maple Family Health', 'Family Medicine', '7426 Maple Ave', 'Norman', 'OK', NULL, '+15553456781'),
    (14, 'River Rock Medical', 'General Practice', '2587 River Rd', 'Missoula', 'MT', '59801', '+15554567891'),
    (15, 'Desert Bloom Neurology', 'Neurology', '6391 Cactus Blvd', 'Tucson', 'AZ', '85710', '+15555678902');

INSERT INTO project.doctor (doctor_id, name, specialty, phone_number, email, primary_facility_id)
VALUES
    (1, 'John Smith', 'Cardiology', '+15551010002', 'john.smith@email.com', 2),
    (2, 'Emily Davis', 'Dermatology', NULL, 'emily.davis@email.com', 2),
    (3, 'Michael Brown', 'Neurology', '+15551010004', 'michael.brown@email.com', 15),
    (4, 'Jessica Taylor', 'Pediatrics', '+15551010005', 'jessica.taylor@email.com', 5),
    (5, 'William Johnson', 'Orthopedics', '+15551010006', 'william.johnson@email.com', 9),
    (6, 'Olivia Lee', 'General Surgery', '+15551010007', 'olivia.lee@email.com', 2),
    (7, 'Henry Martinez', 'Psychiatry', NULL, 'henry.martinez@email.com', 12),
    (8, 'Ava Nguyen', 'Ophthalmology', '+15551010009', 'ava.nguyen@email.com', 4),
    (9, 'Sophia Rodriguez', 'Endocrinology', '+15551010010', 'sophia.rodriguez@email.com', 1),
    (10, 'Mason Kim', 'Gastroenterology', '+15551010011', 'mason.kim@email.com', 1),
    (11, 'Isabella Jones', 'Rheumatology', '+15551010012', 'isabella.jones@email.com', 2),
    (12, 'Ethan Garcia', 'Pulmonology', '+15551010013', 'ethan.garcia@email.com', NULL),
    (13, 'Mia White', 'Nephrology', '+15551010014', 'mia.white@email.com', 5),
    (14, 'Alexander Thompson', 'Oncology', '+15551010015', NULL, 1),
    (15, 'Amelia Anderson', 'Anesthesiology', '+15551010016', 'amelia.anderson@email.com', 2);

INSERT INTO project.appointment (appointment_id, patient_id, doctor_id, facility_id, appointment_dttm, reason, notes, is_active)
VALUES
    (1, 12, 4, 2, '2024-04-01 09:00:00', 'Annual check-up', NULL, true),
    (2, 3, 10, 1, '2024-04-02 10:30:00', 'Follow-up consultation', 'Put on shoe covers before going in', true),
    (3, 1, 9, 1, '2024-04-03 11:15:00', 'Vaccination', 'Bring insurance card', false),
    (4, 6, 4, NULL, '2024-04-04 14:00:00', NULL, 'Please arrive 15 minutes early', true),
    (5, 2, 5, 3, '2024-04-04 15:45:00', 'Dental cleaning', 'Bring list of medications', false),
    (6, 11, 13, 5, '2024-04-06 08:30:00', 'Cataract surgery', 'No food or drink after midnight', true),
    (7, 15, 14, 1, '2024-04-07 13:00:00', 'Therapy session', 'Bring completed forms', true),
    (8, 7, 13, 5, '2024-04-08 14:45:00', 'Eye examination', 'Bring glasses or contacts', true),
    (9, 8, 9, 1, '2024-04-09 10:00:00', 'Diabetes management', 'Fast for 8 hours before appointment', true),
    (10, 14, 10, 2, '2024-04-10 11:30:00', 'Colonoscopy', 'Follow prep instructions', true),
    (11, 10, 11, NULL, '2024-04-11 13:15:00', 'Arthritis check-up', 'Bring list of symptoms', true),
    (12, 9, 9, 1, '2024-04-12 15:00:00', 'Lung function test', 'Avoid caffeine before test', false),
    (13, 5, 6, 2, '2024-04-12 09:30:00', 'Kidney biopsy', 'Wear loose clothing', true),
    (14, 8, 2, 2, '2024-04-12 12:45:00', 'Chemotherapy session', 'Arrange for transportation', true),
    (15, 1, 15, 8, '2024-04-15 16:00:00', 'Pain management', 'Bring list of allergies', true),
    (16, 11, 1, 2, '2024-04-15 08:15:00', 'MRI scan', 'No metal objects', true),
    (17, 15, 6, 12, '2024-04-17 11:00:00', 'Psychological evaluation', 'Arrive 30 minutes early', true),
    (18, 4, 6, NULL, '2024-04-18 14:30:00', 'Physical therapy', NULL, true),
    (19, 8, 12, 1, '2024-04-19 10:45:00', 'Allergy testing', 'Avoid antihistamines', true),
    (20, 1, 13, 7, '2024-04-19 13:30:00', 'Sleep study', 'Bring pajamas', true);

INSERT INTO project.prescription (prescription_id, patient_id, doctor_id, medication_name, dosage, quantity, prescription_dt, notes)
VALUES
    (1, 1, 4, 'Aspirin', '100mg', 30, '2024-04-01', 'Take with food'),
    (2, 2, 2, 'Amoxicillin', '500mg', 20, '2024-04-01', NULL),
    (3, 3, 3, 'Lisinopril', '10mg', 30, '2024-04-12', 'Avoid potassium supplements'),
    (4, 4, 4, 'Atorvastatin', '20mg', 30, '2024-04-12', 'Take at bedtime'),
    (5, 5, 8, 'Metformin', '500mg', 60, '2024-04-05', 'Monitor blood sugar levels'),
    (6, 6, 12, 'Levothyroxine', '50mcg', 30, '2024-04-06', 'Take on an empty stomach'),
    (7, 7, 11, 'Sertraline', '50mg', 30, '2024-04-07', 'Report any mood changes'),
    (8, 8, 10, 'Albuterol', '1ml', 1, '2024-04-08', 'Use as needed for asthma symptoms'),
    (9, 9, 15, 'Omeprazole', '20mg', 30, '2024-04-09', 'Take before breakfast'),
    (10, 10, 15, 'Prednisone', '10mg', 20, '2024-04-10', 'Gradually taper off dosage'),
    (11, 11, 13, 'Warfarin', '5mg', 30, '2024-04-01', 'Avoid foods high in vitamin K'),
    (12, 12, 11, 'Citalopram', '20mg', 30, '2024-04-12', NULL),
    (13, 13, 9, 'Gabapentin', '300mg', 60, '2024-04-13', 'May cause dizziness'),
    (14, 14, 1, 'Hydrochlorothiazide', '25mg', 30, '2024-04-14', 'Monitor blood pressure regularly'),
    (15, 15, 2, 'Acetaminophen', '500mg', 30, '2024-04-15', 'Do not exceed recommended dosage');

INSERT INTO project.record (record_id, patient_id, assessment_dttm, systolic_pressure, diastolic_pressure, temperature, heart_rate)
VALUES
    (1, 1, '2024-04-01 08:00:00', 120, 80, 98.6, 70.5),
    (2, 2, '2024-02-02 15:15:00', 130, 85, 99.1, 72.3),
    (3, 3, '2023-12-17 10:30:00', 122, 78, 98.3, 68.9),
    (4, 4, '2022-02-24 20:41:13', 118, 75, 98.9, 74.2),
    (5, 5, '2024-04-05 12:03:00', 126, 82, 98.7, 76.8),
    (6, 1, '2024-04-01 08:15:00', 132, 88, 99.2, 78.4),
    (7, 2, '2024-02-02 15:20:00', 124, 80, 98.4, 80.1),
    (8, 3, '2023-12-17 11:30:00', 128, 84, 99.0, 82.7),
    (9, 4, '2022-02-24 20:47:16', 130, 86, 98.8, 84.3),
    (10, 5, '2024-04-05 13:03:00', 126, 83, 98.5, 86.9),
    (11, 1, '2024-04-01 08:30:00', 134, 90, 99.3, 88.5),
    (12, 2, '2024-02-02 15:25:00', 128, 82, 98.7, 90.2),
    (13, 3, '2023-12-17 12:30:00', 122, 79, 98.2, 92.8),
    (14, 4, '2022-02-24 20:51:10', 120, 76, 98.4, 94.4),
    (15, 5, '2024-04-05 14:03:00', 124, 81, 98.6, 96.0),
    (16, 1, '2024-04-01 08:45:00', 130, 87, 98.9, 71.6),
    (17, 2, '2024-02-02 15:30:00', 126, 83, 99.1, 73.2),
    (18, 3, '2023-12-17 13:30:00', 124, 81, 98.7, 67.8),
    (19, 4, '2022-02-24 20:56:56', 128, 84, 98.5, 72.4),
    (20, 5, '2024-04-05 15:03:00', 122, 78, 98.3, 78.0),
    (21, 1, '2024-04-01 09:00:00', 126, 82, 99.0, 76.6),
    (22, 2, '2024-02-02 15:35:00', 132, 88, 98.8, 70.2),
    (23, 3, '2023-12-17 14:30:00', 128, 85, 98.6, 74.8),
    (24, 4, '2022-02-24 21:04:37', 124, 80, 98.4, 80.4),
    (25, 5, '2024-04-05 16:03:00', 130, 86, 98.2, 86.0),
    (26, 1, '2024-04-01 09:15:02', 126, 83, 99.3, 88.6),
    (27, 2, '2024-02-02 15:40:00', 124, 81, 99.5, 90.2),
    (28, 3, '2023-12-17 15:30:00', 130, 87, 99.2, 92.8),
    (29, 4, '2022-02-24 21:12:21', 132, 88, 99.0, 94.4),
    (30, 5, '2024-04-05 17:03:00', 126, 82, 98.8, 96.0),
    (31, 1, '2024-04-01 09:30:03', 128, 85, 98.6, 70.5),
    (32, 2, '2024-02-02 15:45:00', 130, 87, 98.4, 72.3),
    (33, 3, '2023-12-17 16:30:00', 124, 80, 98.3, 68.9),
    (34, 4, '2022-02-24 21:23:29', 126, 82, 98.9, 74.2);
```

## 7. Написание запросов к схеме

1) Найдём тех людей, у которых температура когда либо была выше $37.5$ градусов по Цельсию.
    ```sql
    SELECT DISTINCT
        patient.patient_id,
        name,
        phone_number
    FROM project.patient
    JOIN project.record ON patient.patient_id = record.patient_id
    WHERE record.temperature >= 99.5;  -- 37.5 by Celsius
    ```
    Вывод:
    | patient\_id | name | phone\_number |
    | :--- | :--- | :--- |
    | 2 | Frank V. Salinas | +12173990093 |

2) Отсортируем мед. учреждения по количеству официальных работников в них:
    ```sql
    SELECT
        facility_id,
        name,
        (SELECT COUNT(*) FROM (SELECT doctor_id FROM project.doctor WHERE primary_facility_id = facility_id) as doctors) as workers_number
    FROM project.medical_facility
    ORDER BY 3 DESC;
    ```
    Вывод:
    | facility\_id | name | workers\_number |
    | :--- | :--- | :--- |
    | 2 | Riverside Hospital | 5 |
    | 1 | Sunshine Health Clinic | 3 |
    | 5 | Central Pediatrics | 2 |
    | 15 | Desert Bloom Neurology | 1 |
    | 4 | Vision Plus Eye Center | 1 |
    | 9 | Green Valley Orthopedics | 1 |
    | 12 | Pinecrest Psychiatric | 1 |
    | 8 | Harmony Mental Health | 0 |
    | 14 | River Rock Medical | 0 |
    | 10 | Oceanview Cardiology | 0 |

3) Посмотрим на не отменённые встречи, которые ожидаются во вторую неделю апреля:
    ```sql
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
    ```
    Вывод:
    | patient\_id | doctor\_id | facility\_id | appointment\_dttm | reason |
    | :--- | :--- | :--- | :--- | :--- |
    | 7 | 13 | 5 | 2024-04-08 14:45:00.000000 | Eye examination |
    | 8 | 9 | 1 | 2024-04-09 10:00:00.000000 | Diabetes management |
    | 14 | 10 | 2 | 2024-04-10 11:30:00.000000 | Colonoscopy |
    | 10 | 11 | null | 2024-04-11 13:15:00.000000 | Arthritis check-up |
    | 5 | 6 | 2 | 2024-04-12 09:30:00.000000 | Kidney biopsy |
    | 8 | 2 | 2 | 2024-04-12 12:45:00.000000 | Chemotherapy session |

4) Выведем тех врачей, которые официально работают в Коламбусе:
    ```sql
    SELECT
        doctor_id,
        doctor.name,
        doctor.phone_number
    FROM project.doctor
    JOIN project.medical_facility ON doctor.primary_facility_id = medical_facility.facility_id
    WHERE city = 'Columbus';
    ```
    Вывод:
    | doctor\_id | name | phone\_number |
    | :--- | :--- | :--- |
    | 1 | John Smith | +15551010002 |
    | 2 | Emily Davis | null |
    | 6 | Olivia Lee | +15551010007 |
    | 11 | Isabella Jones | +15551010012 |
    | 15 | Amelia Anderson | +15551010016 |

5) Сформируем сводную таблицу максимальных показателей у пациентов по которым такие данные есть:
    ```sql
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
    ```
    Вывод:
    | patient\_id | name | max\_systolic\_pressure | max\_diastolic\_pressure | max\_temperature | max\_heart\_rate |
    | :--- | :--- | :--- | :--- | :--- | :--- |
    | 1 | Sarah C. Salyers | 134 | 90 | 99.3 | 88.6 |
    | 2 | Frank V. Salinas | 132 | 88 | 99.5 | 90.2 |
    | 3 | Michael S. Cheatham | 130 | 87 | 99.2 | 92.8 |
    | 4 | David J. Walker | 132 | 88 | 99 | 94.4 |
    | 5 | Brittany R. Cooper | 130 | 86 | 98.8 | 96 |

6) Выберем мед. учреждения, у которых есть контактный телефон:
    ```sql
    SELECT
        facility_id,
        name,
        city,
        phone_number
    FROM project.medical_facility
    WHERE phone_number IS NOT NULL;
    ```
    Вывод:
    | facility\_id | name | city | phone\_number |
    | :--- | :--- | :--- | :--- |
    | 2 | Riverside Hospital | Columbus | +15552345678 |
    | 3 | Metro Dental Care | Cincinnati | +15553456789 |
    | 4 | Vision Plus Eye Center | Dayton | +15554567890 |
    | 5 | Central Pediatrics | Akron | +15555678901 |
    | 6 | Advanced Dermatology | Toledo | +15556789012 |
    | 7 | Summit Rehabilitation | Cleveland | +15557890123 |
    | 8 | Harmony Mental Health | Youngstown | +15558901234 |
    | 10 | Oceanview Cardiology | Savannah | +15550123456 |
    | 11 | Bright Smile Dental Clinic | El Paso | +15551239876 |
    | 12 | Pinecrest Psychiatric | Rapid City | +15552348910 |

7) Выведем тех людей, которые по каким-то причинам (их тоже выводим) записывались на приём к анестезиологу:
    ```sql
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
    ```
    Вывод:
    | patient\_id | name | phone\_number | email | reason |
    | :--- | :--- | :--- | :--- | :--- |
    | 1 | Sarah C. Salyers | +12812891222 | SarahCSalyers@armyspy.com | Pain management |

8) Разделим года, в которые производились измерения состояний пациентов, на $3$ группы по суммарному количеству измерений:
    ```sql
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
    ```
    Вывод:
    | year | assessment\_number |
    | :--- | :--- |
    | 2024 | high |
    | 2023 | average |
    | 2022 | low |

9) Получим месяц, в который было совершено хотя бы $10$ измерений:
    ```sql
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
    ```
    Вывод:
    | month | number\_of\_assessments |
    | :--- | :--- |
    | February  | 14 |
    | April     | 13 |

10) Посмотрим, как отличаются средние показатели у мужчин и у женщин:
    ```sql
    SELECT
        gender,
        ROUND(avg(systolic_pressure)::numeric, 2) as avg_systolic_pressure,
        ROUND(avg(diastolic_pressure)::numeric, 2) as avg_diastolic_pressure,
        ROUND(avg(temperature)::numeric, 2) as avg_temperature,
        ROUND(avg(heart_rate)::numeric, 2) as avg_heart_rate
    FROM project.record
    JOIN project.patient ON record.patient_id = patient.patient_id
    GROUP BY patient.gender;
    ```
    Вывод:
    | gender | avg\_systolic\_pressure | avg\_diastolic\_pressure | avg\_temperature | avg\_heart\_rate |
    | :--- | :--- | :--- | :--- | :--- |
    | male | 126.19 | 82.43 | 98.72 | 79.6 |
    | female | 126.92 | 83.62 | 98.77 | 81.88 |

### 8-12:
[Ссылка на выполненные задания 8-12](../optional/README.md)