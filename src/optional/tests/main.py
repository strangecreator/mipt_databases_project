import os
import math
from pathlib import Path
from decimal import Decimal

# testing libraries
import pytest

# database connection libraries
import psycopg2
from psycopg2.extras import RealDictCursor


CONNECTION_PARAMS = {
    "host": "localhost",
    "port": "5432",
    "database": "postgres",
    "user": "postgres",
    "password": os.environ["DATABASE_PASSWORD"]
}


# helper database functions
def execute_query(query: str):
    with psycopg2.connect(**CONNECTION_PARAMS) as conn:
        with conn.cursor() as cur:
            cur.execute(query)
            result = cur.fetchall()
            return result


def execute_query_json(query: str) -> list[dict]:
    with psycopg2.connect(**CONNECTION_PARAMS) as conn:
        with conn.cursor(cursor_factory=RealDictCursor) as cur:
            cur.execute(query)
            result = cur.fetchall()
            return [{column: value for column, value in row.items()} for row in result]


def get_columns(table_name: str) -> tuple[str]:
    query = f"""
        SELECT column_name
        FROM information_schema.columns
        WHERE table_catalog = 'postgres' AND table_schema = 'project' AND table_name = '{table_name}'
    """
    columns = execute_query(query)
    return tuple([column[0] for column in columns])


def get_table(table_name: str) -> list[tuple]:
    query = f"SELECT * FROM project.{table_name}"
    return execute_query(query)


def get_table_json(table_name: str) -> list[dict]:
    query = f"SELECT * FROM project.{table_name}"
    return execute_query_json(query)


def json_row_to_tuple(row: dict) -> tuple:
    row = sorted([(key, value) for key, value in row.items()])
    return tuple([value for key, value in row])


def compare_results(actual: list[dict], expected: list[dict], sorted_priority=lambda x: 0) -> bool:
    # check if actual rows is correctly sorted
    for i in range(0, len(actual) - 1):
        if not sorted_priority(actual[i]) <= sorted_priority(actual[i]):
            return False
    # compare them in general
    actual = [json_row_to_tuple(row) for row in actual]
    expected = [json_row_to_tuple(row) for row in expected]
    actual.sort()
    expected.sort()
    return actual == expected


def truncate_columns(obj: dict, columns: tuple[str]) -> dict:
    return {column: obj[column] for column in columns}


# helper filesystem functions
def get_sql_query(index: int) -> str:  # index in {1, ..., 10}
    path = Path(__file__).parent.parent.parent / "main" / "sql" / "7.sql"
    with open(str(path), 'r') as file:
        content = file.read()
        return content.split(f"-- {index}\n")[1].split(f"\n-- {index + 1}\n")[0]


# tests
def test_1_query():
    actual_result = execute_query_json(get_sql_query(1))
    # making expected result
    records = get_table_json("record")
    patients_ids = []
    for record in records:
        if record["temperature"] >= 99.5:
            patients_ids.append(record["patient_id"])
    patients = get_table_json("patient")
    expected_result = []
    for patient in patients:
        if patient["patient_id"] in patients_ids:
            expected_result.append({
                "patient_id": patient["patient_id"],
                "name": patient["name"],
                "phone_number": patient["phone_number"]
            })
    assert compare_results(actual_result, expected_result), "Results do not match!"


def test_2_query():
    actual_result = execute_query_json(get_sql_query(2))
    # making expected result
    facility_popularity = {}
    doctors = get_table_json("doctor")
    for doctor in doctors:
        if doctor["primary_facility_id"] is not None:
            facility_popularity[doctor["primary_facility_id"]] = facility_popularity.get(doctor["primary_facility_id"], 0) + 1
    expected_result = [
        truncate_columns(facility, ("facility_id", "name")) | {"workers_number": facility_popularity.get(facility["facility_id"], 0)}
        for facility in get_table_json("medical_facility")
    ]
    expected_result.sort(key=lambda x: (-x["workers_number"], x["facility_id"], x["name"]))
    assert compare_results(
        actual_result,
        expected_result,
        lambda x: -x["workers_number"]
    ), "Results do not match!"


def test_3_query():
    actual_result = execute_query_json(get_sql_query(3))
    # making expected result
    appointments = list(filter(lambda x: x["is_active"] and "2024-04-08" <= x["appointment_dttm"].strftime("%Y-%m-%d") < "2024-04-15", get_table_json("appointment")))
    expected_result = [
        truncate_columns(appointment, ("patient_id", "doctor_id", "facility_id", "appointment_dttm", "reason"))
        for appointment in appointments
    ]
    assert compare_results(actual_result, expected_result), "Results do not match!"


def test_4_query():
    actual_result = execute_query_json(get_sql_query(4))
    # making expected result
    columbus_facilities = list(map(lambda x: x["facility_id"], list(filter(lambda x: x["city"] == "Columbus", get_table_json("medical_facility")))))
    doctors = list(filter(lambda x: x["primary_facility_id"] in columbus_facilities, get_table_json("doctor")))
    expected_result = [
        truncate_columns(doctor, ("doctor_id", "name", "phone_number"))
        for doctor in doctors
    ]
    assert compare_results(actual_result, expected_result), "Results do not match!"


def test_5_query():
    actual_result = execute_query_json(get_sql_query(5))
    # making expected result
    COLUMNS = ("systolic_pressure", "diastolic_pressure", "temperature", "heart_rate")
    patients = [truncate_columns(row, ("patient_id", "name")) for row in get_table_json("patient")]
    records = get_table_json("record")
    expected_result = []
    for patient in patients:
        current_result = {**patient} | {f"max_{column}": None for column in COLUMNS}
        certain_records = list(filter(lambda x: x["patient_id"] == patient["patient_id"], records))
        for column in COLUMNS:
            not_null_records_current = list(map(lambda x: x[column], filter(lambda x: x[column] is not None, certain_records)))
            if len(not_null_records_current) > 0:
                current_result[f"max_{column}"] = max(not_null_records_current)
        if len(certain_records) > 0:
            expected_result.append(current_result)
    assert compare_results(actual_result, expected_result), "Results do not match!"


def test_6_query():
    actual_result = execute_query_json(get_sql_query(6))
    # making expected result
    facilities = [truncate_columns(row, ("facility_id", "name", "city", "phone_number")) for row in get_table_json("medical_facility")]
    expected_result = list(filter(lambda x: x["phone_number"] is not None, facilities))
    assert compare_results(actual_result, expected_result), "Results do not match!"


def test_7_query():
    actual_result = execute_query_json(get_sql_query(7))
    # making expected result
    patients = [truncate_columns(row, ("patient_id", "name", "phone_number", "email")) for row in get_table_json("patient")]
    doctors_ids = list(map(lambda x: x["doctor_id"], (filter(lambda x: x["specialty"] == "Anesthesiology", get_table_json("doctor")))))
    appointments = list(filter(lambda x: x["doctor_id"] in doctors_ids, get_table_json("appointment")))
    expected_result = []
    for patient in patients:
        current_appointments = list(filter(lambda x: x["patient_id"] == patient["patient_id"], appointments))
        for appointment in current_appointments:
            expected_result.append(patient | {"reason": appointment["reason"]})
    assert compare_results(actual_result, expected_result), "Results do not match!"


def test_8_query():
    actual_result = execute_query_json(get_sql_query(8))
    # making expected result
    NAMES = ("high", "average", "low")
    records = get_table_json("record")
    years = {}
    for record in records:
        year = record["assessment_dttm"].year
        years[year] = years.get(year, 0) + 1
    years_sorted = sorted([(year, value) for year, value in years.items()], key=lambda x: (-x[0], x[1]))
    expected_result = []
    group_size = math.ceil(len(years_sorted) / 3)
    for i, (year, number) in enumerate(years_sorted):
        name = NAMES[i // group_size]
        expected_result.append({
            "year": year,
            "assessment_number": name
        })
    assert compare_results(actual_result, expected_result), "Results do not match!"


def test_9_query():
    actual_result = execute_query_json(get_sql_query(9))
    # making expected result
    records = get_table_json("record")
    months = {}
    for record in records:
        month = record["assessment_dttm"].strftime("%B")
        months[month] = months.get(month, 0) + 1
    expected_result = list(filter(lambda x: x["number_of_assessments"] >= 10, [{
        "month": month,
        "number_of_assessments": number_of_assessments
    } for month, number_of_assessments in months.items()]))
    assert compare_results(actual_result, expected_result), "Results do not match!"


def test_10_query():
    actual_result = execute_query_json(get_sql_query(10))
    # making expected result
    COLUMNS = ("systolic_pressure", "diastolic_pressure", "temperature", "heart_rate")
    records = get_table_json("record")
    patients = get_table_json("patient")
    gender_grouped = {
        "male": list(map(lambda x: x["patient_id"], filter(lambda x: x["gender"] == "male", patients))),
        "female": list(map(lambda x: x["patient_id"], filter(lambda x: x["gender"] == "female", patients)))
    }
    expected_result = []
    for gender, patients_ids in gender_grouped.items():
        current_result = {}
        for column in COLUMNS:
            current_records = list(filter(lambda x: x["patient_id"] in patients_ids and x[column] is not None, records))
            current_result[f"avg_{column}"] = round(sum(map(lambda x: Decimal(x[column]), current_records)) / len(current_records), 2)
        expected_result.append({"gender": gender} | current_result)
    import pprint
    pprint.pprint(actual_result)
    pprint.pprint(expected_result)
    assert compare_results(actual_result, expected_result), "Results do not match!"