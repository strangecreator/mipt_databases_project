### 5-7:
[Ссылка на выполненные задания 5-7](../main/README.md)


## 8. Представления

1) Так как врачи всегда должны уметь быстро мониторить состояния всех пациентов, сделаем представление, которое показывает последние данные каждого пациента:

    ```sql
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
    ```

    Вывод:

    | record\_id | patient\_id | assessment\_dttm | systolic\_pressure | diastolic\_pressure | temperature | heart\_rate |
    | :--- | :--- | :--- | :--- | :--- | :--- | :--- |
    | 36 | 1 | 2024-04-24 19:15:59.000000 | 129 | 83 | 99.1 | 71.3 |
    | 32 | 2 | 2024-02-02 15:45:00.000000 | 130 | 87 | 98.4 | 72.3 |
    | 33 | 3 | 2023-12-17 16:30:00.000000 | 124 | 80 | 98.3 | 68.9 |
    | 37 | 4 | 2023-04-25 08:33:05.000000 | 124 | 80 | 99.3 | 68.6 |
    | 40 | 5 | 2024-04-25 09:13:28.000000 | 125 | 86 | 98.4 | 77.2 |


2) Также, так как некоторые пациенты уже давно выздоровели, для уменьшения нагрузки на врача, мониторящего показатели, сделаем представление с последними измерениями каждого пациента, при условии, что измерение было проведено в предыдущие $24$ часа:

    ```sql
    CREATE OR REPLACE view project.last_record_current as (
        SELECT
            *
        FROM project.last_record
        WHERE assessment_dttm >= (NOW() - INTERVAL '1 DAY')
    );
    ```

    Вывод:

    | record\_id | patient\_id | assessment\_dttm | systolic\_pressure | diastolic\_pressure | temperature | heart\_rate |
    | :--- | :--- | :--- | :--- | :--- | :--- | :--- |
    | 36 | 1 | 2024-04-24 19:15:59.000000 | 129 | 83 | 99.1 | 71.3 |
    | 40 | 5 | 2024-04-25 09:13:28.000000 | 125 | 86 | 98.4 | 77.2 |


3) Некоторые пациенты могут быть в очень плохом состоянии, следовательно, врачи должны уделять им больше внимания. Для этого создадим представление на основе предыдущего, показывающее только пациентов с показателями, требующими действий врачей:

    ```sql
    CREATE OR REPLACE view project.last_record_current_urgent as (
        SELECT
            *
        FROM project.last_record_current
        WHERE 1=1 AND
            systolic_pressure >= 130 OR
            systolic_pressure < 90 OR
            diastolic_pressure >= 80 OR
            diastolic_pressure < 60 OR
            temperature >= 104 OR       /* 38 C */
            heart_rate >= 100 OR        /* tachycardia */
            heart_rate < 60             /* bradycardia */
    );
    ```

    Вывод:

    | record\_id | patient\_id | assessment\_dttm | systolic\_pressure | diastolic\_pressure | temperature | heart\_rate |
    | :--- | :--- | :--- | :--- | :--- | :--- | :--- |
    | 36 | 1 | 2024-04-24 19:15:59.000000 | 129 | 83 | 99.1 | 71.3 |
    | 40 | 5 | 2024-04-25 09:13:28.000000 | 125 | 86 | 98.4 | 77.2 |

## 9. Индексы
На основе созданных в предыдущем пункте представлений, создадим соответствующие индексы для ускорения выполнения запросов:
1) `patient_id`, `assessment_dttm` (для $1$-го представления):
    ```sql
    CREATE INDEX record_patient_id_dttm_index
    ON project.record (patient_id, assessment_dttm);
    ```

2) `systolic_pressure`, `diastolic_pressure`, `temperature`, `heart_rate` (для $3$-го представления):
    ```sql
    CREATE INDEX record_indicators_index
    ON project.record (systolic_pressure, diastolic_pressure, temperature, heart_rate);
    ```

3) `patient_id`, `appointment_dttm` (так как очевидно, что пользователи (пациенты) захотят смотреть список их встреч, отсортированный по времени):
    ```sql
    CREATE INDEX appointment_patient_id_dttm_index
    ON project.appointment (patient_id, appointment_dttm, is_active);
    ```

4) `doctor_id`, `appointment_dttm` (то же самое, но только для врачей):
    ```sql
    CREATE INDEX appointment_doctor_id_dttm_index
    ON project.appointment (doctor_id, appointment_dttm, is_active);
    ```

## 10. Хранимые процедуры и функции
1) Сделаем функцию получения будущих встреч с врачом у конкретного пользователя (при отсутствии такого пациента в базе выводим ошибку):
    ```sql
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
    ```

    Используем:

    1) 
        ```sql
        SELECT * FROM project.get_upcoming_appointments(45);
        ```

        Вывод:

        <div style="color: white; background: #5e3838; margin-top: 10px; padding: 5px; font-size: 12px; width: fit-content; margin-bottom: 20px;">[02000] ERROR: There is no patient with patient_id: "45"!<br>
        Where: PL/pgSQL function project.get_upcoming_appointments(integer) line 5 at RAISE</div>

    2) 
        ```sql
        SELECT * FROM project.get_upcoming_appointments(12);
        ```

        Вывод:

        | appointment\_id | patient\_id | doctor\_id | facility\_id | appointment\_dttm | reason | notes | is\_active |
        | :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- |
        | 21 | 12 | 4 | 2 | 2025-04-01 09:00:00.000000 | Annual check-up | null | true |

2) Создадим функцию для получения последних показателей конкретного пациента (при отсутствии также выводим ошибку):
    ```sql
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
    ```

    Используем:

    1) 
        ```sql
        SELECT * FROM project.get_upcoming_appointments(45);
        ```

        Вывод:

        <div style="color: white; background: #5e3838; margin-top: 10px; padding: 5px; font-size: 12px; width: fit-content; margin-bottom: 20px;">[02000] ERROR: There is no patient with patient_id: "45"!<br>
        Where: PL/pgSQL function project.get_last_record(integer) line 5 at RAISE</div>

    2) 
        ```sql
        SELECT * FROM project.get_last_record(5);
        ```

        Вывод:

        | record\_id | patient\_id | assessment\_dttm | systolic\_pressure | diastolic\_pressure | temperature | heart\_rate |
        | :--- | :--- | :--- | :--- | :--- | :--- | :--- |
        | 40 | 5 | 2024-04-25 09:13:28.000000 | 125 | 86 | 98.4 | 77.2 |

3) Иногда нужно узнать контакты врачей определённых специальностей, поэтому напишем функцию, которая по больнице (клинике) и специальности выдаёт данные врачей, работающих в данной больнице по данной специальности (также с обработкой отсутствия):
    ```sql
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
    ```

    Используем:

    1)
        ```sql
        SELECT * FROM project.get_number_of_doctors_by_facility_and_specialty(16, 'Neurology');
        ```

        Вывод:

        <div style="color: white; background: #5e3838; margin-top: 10px; padding: 5px; font-size: 12px; width: fit-content; margin-bottom: 20px;">[02000] ERROR: There is no medical facility with facility_id: "16"!<br> Where: PL/pgSQL function project.get_number_of_doctors_by_facility_and_specialty(integer,character varying) line 6 at RAISE</div>
    2)
        ```sql
        SELECT * FROM project.get_number_of_doctors_by_facility_and_specialty(15, 'Neurology');
        ```

        Вывод:

        | doctor\_id | name | specialty | phone\_number | email | primary\_facility\_id |
        | :--- | :--- | :--- | :--- | :--- | :--- |
        | 3 | Michael Brown | Neurology | +15551010004 | michael.brown@email.com | 15 |

## 11. Триггеры
1) Так как предписания врачей это всегда очень щепетильная тема, ведь от них напрямую зависит здоровье пациента, создадим триггер, который будет записывать все изменения таблицы `prescription` в отдельную таблицу логов `prescription_log`. Информация, которая должна быть отражена в таблице логов:
    * Какая операция была совершена
    * Время операции
    * Пользователь, который совершил операцию
    * Значения новых полей

    Для этого, вначале создадим таблицу `prescription_log`:
    ```sql
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
    ```

    Далее пишем функцию триггера:
    ```sql
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
    ```

    И привязываем сам триггер:
    ```sql
    CREATE TRIGGER prescription_changes_trigger
    AFTER INSERT OR UPDATE OR DELETE ON project.prescription
    FOR EACH ROW EXECUTE FUNCTION project.log_prescription_changes();
    ```

    Результаты:
    1) Попробуем добавить строки в таблицу:
        ```sql
        INSERT INTO project.prescription (prescription_id, patient_id, doctor_id, medication_name, dosage, quantity, prescription_dt, notes)
        VALUES
            (16, 4, 1, 'Metformin', '500mg', 60, '2024-04-10', 'Take twice daily'),
            (17, 5, 5, 'Atorvastatin', '20mg', 30, '2024-04-15', 'Take once at night'),
            (18, 6, 6, 'Levothyroxine', '100mcg', 30, '2024-04-20', NULL),
            (19, 1, 4, 'Sertraline', '50mg', 30, '2024-04-25', 'Do not use with alcohol'),
            (20, 2, 2, 'Ciprofloxacin', '250mg', 20, '2024-04-05', 'Drink plenty of fluids'),
            (21, 3, 3, 'Albuterol', '90mcg', 1, '2024-04-18', 'Use as needed for asthma attacks'),
            (22, 7, 7, 'Simvastatin', '40mg', 30, '2024-04-28', 'Avoid grapefruit juice');
        ```

        Посмотрим на `prescription_log` таблицу:
        | log\_id | operation\_type | operation\_timestamp | executed\_by | previous\_prescription\_id | prescription\_id | patient\_id | doctor\_id | medication\_name | dosage | quantity | prescription\_dt | notes |
        | :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- |
        | 1 | INSERT | 2024-04-28 07:26:37.744387 | postgres | null | 16 | 4 | 1 | Metformin | 500mg | 60 | 2024-04-10 | Take twice daily |
        | 2 | INSERT | 2024-04-28 07:26:37.744387 | postgres | null | 17 | 5 | 5 | Atorvastatin | 20mg | 30 | 2024-04-15 | Take once at night |
        | 3 | INSERT | 2024-04-28 07:26:37.744387 | postgres | null | 18 | 6 | 6 | Levothyroxine | 100mcg | 30 | 2024-04-20 | null |
        | 4 | INSERT | 2024-04-28 07:26:37.744387 | postgres | null | 19 | 1 | 4 | Sertraline | 50mg | 30 | 2024-04-25 | Do not use with alcohol |
        | 5 | INSERT | 2024-04-28 07:26:37.744387 | postgres | null | 20 | 2 | 2 | Ciprofloxacin | 250mg | 20 | 2024-04-05 | Drink plenty of fluids |
        | 6 | INSERT | 2024-04-28 07:26:37.744387 | postgres | null | 21 | 3 | 3 | Albuterol | 90mcg | 1 | 2024-04-18 | Use as needed for asthma attacks |
        | 7 | INSERT | 2024-04-28 07:26:37.744387 | postgres | null | 22 | 7 | 7 | Simvastatin | 40mg | 30 | 2024-04-28 | Avoid grapefruit juice |

    2) Попробуем удалить какие-нибудь строки:
        ```sql
        DELETE FROM project.prescription WHERE prescription_id IN (16, 20);
        ```

        Заметим, в логи добавились $2$ строки:
        | log\_id | operation\_type | operation\_timestamp | executed\_by | previous\_prescription\_id | prescription\_id | patient\_id | doctor\_id | medication\_name | dosage | quantity | prescription\_dt | notes |
        | :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- |
        | 8 | DELETE | 2024-04-28 07:36:58.430530 | postgres | null | 16 | 4 | 1 | Metformin | 500mg | 60 | 2024-04-10 | Take twice daily |
        | 9 | DELETE | 2024-04-28 07:36:58.430530 | postgres | null | 20 | 2 | 2 | Ciprofloxacin | 250mg | 20 | 2024-04-05 | Drink plenty of fluids |

    3) Попробуем отредактировать какую-нибудь строку:
        ```sql
        UPDATE project.prescription
        SET medication_name = 'Albuterol'
        WHERE prescription_id = 17;
        ```

        Получим изменения в логах:
        | log\_id | operation\_type | operation\_timestamp | executed\_by | previous\_prescription\_id | prescription\_id | patient\_id | doctor\_id | medication\_name | dosage | quantity | prescription\_dt | notes |
        | :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- |
        | 10 | UPDATE | 2024-04-28 07:43:32.296780 | postgres | 17 | 17 | 5 | 5 | Albuterol | 20mg | 30 | 2024-04-15 | Take once at night |

2) Напишем триггер, который будет срабатывать при добавлении элементов в *json*-представление таблицы `medical_facility`:
    Для начала создадим само *json*-представление:
    ```sql
    CREATE OR REPLACE VIEW project.medical_facility_json AS (
        SELECT
            row_to_json(m)
        FROM (SELECT * FROM project.medical_facility) m
    );
    ```

    Результат:
    | row\_to\_json |
    | :--- |
    | {"facility\_id":1,"name":"Sunshine Health Clinic","type":"Clinic","address":"1234 Maple St","city":"Springfield","state":"MA","zipcode":1103,"phone\_number":null} |
    | {"facility\_id":2,"name":"Riverside Hospital","type":"Hospital","address":"5678 River Rd","city":"Columbus","state":"GA","zipcode":31901,"phone\_number":"+15552345678"} |
    | {"facility\_id":3,"name":"Metro Dental Care","type":"Dental","address":"9012 Oak Blvd","city":"Cincinnati","state":"KY","zipcode":41073,"phone\_number":"+15553456789"} |
    | {"facility\_id":4,"name":"Vision Plus Eye Center","type":"Eye Care","address":"3456 Pine St","city":"Dayton","state":"NV","zipcode":89403,"phone\_number":"+15554567890"} |
    | {"facility\_id":5,"name":"Central Pediatrics","type":"Pediatrics","address":"7890 Elm St","city":"Akron","state":"CO","zipcode":80720,"phone\_number":"+15555678901"} |
    | {"facility\_id":6,"name":"Advanced Dermatology","type":"Dermatology","address":"6543 Birch Rd","city":"Toledo","state":"WA","zipcode":null,"phone\_number":"+15556789012"} |
    | {"facility\_id":7,"name":"Summit Rehabilitation","type":"Family Medicine","address":"3218 Cedar Ave","city":"Cleveland","state":"TX","zipcode":77327,"phone\_number":"+15557890123"} |
    | {"facility\_id":8,"name":"Harmony Mental Health","type":"Mental Health","address":"2134 Willow Way","city":"Youngstown","state":"FL","zipcode":32466,"phone\_number":"+15558901234"} |
    | {"facility\_id":9,"name":"Green Valley Orthopedics","type":"Orthopedics","address":"4321 Mountain Rd","city":"Flagstaff","state":"AZ","zipcode":86001,"phone\_number":null} |
    | {"facility\_id":10,"name":"Oceanview Cardiology","type":"Cardiology","address":"8765 Sea Breeze Ave","city":"Savannah","state":"GA","zipcode":31401,"phone\_number":"+15550123456"} |
    | {"facility\_id":11,"name":"Bright Smile Dental Clinic","type":"Dental","address":"9632 Sunshine Rd","city":"El Paso","state":"TX","zipcode":79925,"phone\_number":"+15551239876"} |
    | {"facility\_id":12,"name":"Pinecrest Psychiatric","type":"Psychiatric","address":"1482 Pine St","city":"Rapid City","state":"SD","zipcode":57701,"phone\_number":"+15552348910"} |
    | {"facility\_id":13,"name":"Maple Family Health","type":"Family Medicine","address":"7426 Maple Ave","city":"Norman","state":"OK","zipcode":null,"phone\_number":"+15553456781"} |
    | {"facility\_id":14,"name":"River Rock Medical","type":"General Practice","address":"2587 River Rd","city":"Missoula","state":"MT","zipcode":59801,"phone\_number":"+15554567891"} |
    | {"facility\_id":15,"name":"Desert Bloom Neurology","type":"Neurology","address":"6391 Cactus Blvd","city":"Tucson","state":"AZ","zipcode":85710,"phone\_number":"+15555678902"} |

    Далее, напишем сам триггер:
    ```sql
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
    ```

    Привяжем триггер:
    ```sql
    CREATE OR REPLACE TRIGGER medical_facility_json_instead_of_insert_trigger
    INSTEAD OF INSERT ON project.medical_facility_json
    FOR EACH ROW
    EXECUTE FUNCTION project.medical_facility_json_instead_of_insert_trigger_function();
    ```

    Результаты:
    1) Попробуем добавить новую запись в формате *json* в наше представление:
        ```sql
        INSERT INTO project.medical_facility_json VALUES (
        '{
            "facility_id": 16,
            "name":"Douglas Health Care Clinic",
            "type":"Clinic",
            "address":"34 Oak street",
            "city":"Douglas",
            "state":"CA",
            "zipcode":2842,
            "phone_number":null
        }');
        ```

        Заметим, в таблице `medical_facility` появилась новая запись:
        | facility\_id | name | type | address | city | state | zipcode | phone\_number |
        | :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- |
        | 16 | Douglas Health Care Clinic | Clinic | 34 Oak street | Douglas | CA | 2842 | null |

3) Напишем триггер, проверяющий корректность набранного поля `email` (для таблиц `patient` и `doctor`):
    ```sql
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
    ```

    Привязываем триггеры:
    ```sql
    CREATE TRIGGER patient_check_email_trigger
    BEFORE INSERT OR UPDATE ON project.patient
    FOR EACH ROW
    EXECUTE FUNCTION project.validate_email_trigger();


    CREATE TRIGGER doctor_check_email_trigger
    BEFORE INSERT OR UPDATE ON project.doctor
    FOR EACH ROW
    EXECUTE FUNCTION project.validate_email_trigger();
    ```

    Результат:
    1) Попробуем набрать что-то некорректное:
        ```sql
        INSERT INTO project.patient (patient_id, name, birth_dt, gender, phone_number, email)
        VALUES
            (16, 'Rebecca L. Ferguson', to_date('October 19, 1983', 'Month DD, YYYY'), 'female', '+12812891453', 'rebecca.ferguson.com');
        ```

        Вывод:

        <div style="color: white; background: #5e3838; margin-top: 10px; padding: 5px; font-size: 12px; width: fit-content; margin-bottom: 20px;">[P0001] ERROR: Invalid email format: rebecca.ferguson.com<br>
        Where: PL/pgSQL function project.validate_email_trigger() line 4 at RAISE</div>

    2) А теперь, что-то корректное:
        ```sql
        INSERT INTO project.patient (patient_id, name, birth_dt, gender, phone_number, email)
        VALUES
            (16, 'Rebecca L. Ferguson', to_date('October 19, 1983', 'Month DD, YYYY'), 'female', '+12812891453', 'rebecca.ferguson@gmail.com');
        ```

        Заметим, что в таблице `patient` появилась новая строчка:
        | patient\_id | name | birth\_dt | gender | phone\_number | email |
        | :--- | :--- | :--- | :--- | :--- | :--- |
        | 16 | Rebecca L. Ferguson | 1983-10-19 | female | +12812891453 | rebecca.ferguson@gmail.com |

## 12. Тесты
[Ссылка на файл с тестами `tests/main.py`](tests/main.py)

Запуск:
```sh
pytest <path-to-main.py>
```