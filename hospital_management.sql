DROP DATABASE IF EXISTS hospital_database;
CREATE DATABASE hospital_database;
USE hospital_database;

/* ---------- DIMENSION TABLES ---------- */

CREATE TABLE patient_locations (
    location_id INT PRIMARY KEY AUTO_INCREMENT,
    city VARCHAR(50),
    state VARCHAR(50),
    country VARCHAR(50)
);

CREATE TABLE patients (
    patient_id INT PRIMARY KEY AUTO_INCREMENT,
    patient_name VARCHAR(100),
    email VARCHAR(100),
    location_id INT,
    FOREIGN KEY (location_id) REFERENCES patient_locations(location_id)
);

CREATE TABLE departments (
    department_id INT PRIMARY KEY AUTO_INCREMENT,
    department_name VARCHAR(100)
);

CREATE TABLE treatments (
    treatment_id INT PRIMARY KEY AUTO_INCREMENT,
    treatment_name VARCHAR(100),
    department_id INT,
    treatment_cost DECIMAL(10,2),
    FOREIGN KEY (department_id) REFERENCES departments(department_id)
);

/* ---------- FACT TABLE ---------- */

CREATE TABLE visits (
    visit_id VARCHAR(50) PRIMARY KEY,
    patient_id INT,
    treatment_id INT,
    quantity INT,
    visit_date DATE,
    FOREIGN KEY (patient_id) REFERENCES patients(patient_id),
    FOREIGN KEY (treatment_id) REFERENCES treatments(treatment_id)
);

/* ---------- STAGING TABLE (RAW DATA) ---------- */

CREATE TABLE staging_visits (
    visit_id VARCHAR(50),
    patient_name VARCHAR(100),
    email VARCHAR(100),
    city VARCHAR(50),
    state VARCHAR(50),
    country VARCHAR(50),
    treatment_name VARCHAR(100),
    department_name VARCHAR(100),
    treatment_cost DECIMAL(10,2),
    quantity INT,
    visit_date DATE
);

/* ---------- DIRTY DATA INSERT ---------- */

INSERT INTO staging_visits VALUES
('V001', 'John Doe', 'john@email.com', 'NYC', 'NY', 'USA', 'ECG', 'Cardiology', NULL, 1, '2025-01-01'),
('V002', 'Jane Smith', 'jane@email.com', 'LA', 'CA', 'USA', 'MRI', 'Neurology', 2500.00, 1, '2025-01-02'),
('V001', 'John Doe', 'john@email.com', 'NYC', 'NY', 'USA', 'ECG', 'Cardiology', 800.00, 1, '2025-01-01');

/* ---------- ETL PROCESS ---------- */

/* Load Patient Locations */
INSERT INTO patient_locations (city, state, country)
SELECT DISTINCT city, state, country
FROM staging_visits;

/* Load Patients */
INSERT INTO patients (patient_name, email, location_id)
SELECT DISTINCT s.patient_name, s.email, l.location_id
FROM staging_visits s
JOIN patient_locations l
ON s.city = l.city AND s.state = l.state AND s.country = l.country;

/* Load Departments */
INSERT INTO departments (department_name)
SELECT DISTINCT department_name
FROM staging_visits;

/* Load Treatments (Handle Missing Cost) */
INSERT INTO treatments (treatment_name, department_id, treatment_cost)
SELECT DISTINCT
    s.treatment_name,
    d.department_id,
    COALESCE(NULLIF(s.treatment_cost, 0), 500.00)
FROM staging_visits s
JOIN departments d
ON s.department_name = d.department_name;

