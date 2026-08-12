-- ========================================================
-- PlaqueCheck Supabase Production PostgreSQL Canonical Schema
-- Execute this SQL script in your Supabase SQL Editor to set up
-- all authoritative production tables, indexes, and constraints.
-- ========================================================

-- 1. Patient Users Table
CREATE TABLE IF NOT EXISTS patient_users (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    email VARCHAR(255) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    status VARCHAR(50) NOT NULL DEFAULT 'active',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 2. Doctor Users Table
CREATE TABLE IF NOT EXISTS doctor_users (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    email VARCHAR(255) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    status VARCHAR(50) NOT NULL DEFAULT 'pending_approval',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 3. Administrator Users Table
CREATE TABLE IF NOT EXISTS admin_users (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    email VARCHAR(255) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    status VARCHAR(50) NOT NULL DEFAULT 'active',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 4. Session Tokens Table
CREATE TABLE IF NOT EXISTS sessions (
    token_hash VARCHAR(255) PRIMARY KEY,
    user_id INTEGER NOT NULL,
    role VARCHAR(50) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 5. Patients Profile Details Table
CREATE TABLE IF NOT EXISTS patients (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL UNIQUE REFERENCES patient_users(id) ON DELETE CASCADE,
    age INTEGER DEFAULT 30,
    gender VARCHAR(50) DEFAULT 'Not Specified',
    phone VARCHAR(50) DEFAULT 'N/A',
    medical_history TEXT,
    profile_picture TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 6. Doctors Professional Credentials Table
CREATE TABLE IF NOT EXISTS doctors (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL UNIQUE REFERENCES doctor_users(id) ON DELETE CASCADE,
    mobile VARCHAR(50),
    qualification VARCHAR(255),
    specialization VARCHAR(255),
    registration_number VARCHAR(100),
    clinic_name VARCHAR(255),
    hospital_name VARCHAR(255),
    approval_status VARCHAR(50) NOT NULL DEFAULT 'pending_approval',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 7. Plaque Analysis Reports Table
CREATE TABLE IF NOT EXISTS reports (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL REFERENCES patient_users(id) ON DELETE CASCADE,
    image_path TEXT NOT NULL,
    processed_image TEXT NOT NULL,
    plaque_percent INTEGER NOT NULL,
    severity VARCHAR(50) NOT NULL DEFAULT 'Low',
    confidence REAL NOT NULL DEFAULT 0.85,
    recommendation TEXT NOT NULL,
    timestamp TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    doctor_id INTEGER,
    review_status VARCHAR(50) DEFAULT 'pending_review',
    doctor_notes TEXT,
    treatment_recommendations TEXT,
    follow_up_date VARCHAR(50),
    reviewed_at TIMESTAMP WITH TIME ZONE
);

-- 8. Notifications Table
CREATE TABLE IF NOT EXISTS notifications (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL,
    title VARCHAR(255) NOT NULL,
    message TEXT NOT NULL,
    type VARCHAR(50) NOT NULL DEFAULT 'info',
    is_read BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 9. Security Audit Logs Table
CREATE TABLE IF NOT EXISTS audit_logs (
    id SERIAL PRIMARY KEY,
    user_id INTEGER,
    action VARCHAR(100) NOT NULL,
    details TEXT,
    ip_address VARCHAR(50),
    timestamp TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Performance Indexes
CREATE INDEX IF NOT EXISTS idx_reports_user_id ON reports(user_id);
CREATE INDEX IF NOT EXISTS idx_reports_doctor_id ON reports(doctor_id);
CREATE INDEX IF NOT EXISTS idx_notifications_user_id ON notifications(user_id);
CREATE UNIQUE INDEX IF NOT EXISTS idx_patients_user_id ON patients(user_id);
CREATE UNIQUE INDEX IF NOT EXISTS idx_doctors_user_id ON doctors(user_id);
