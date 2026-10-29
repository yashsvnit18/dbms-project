-- =============================================================================
-- HOSTEL MANAGEMENT SYSTEM (HMS) - SCHEMA DEFINITION (DDL)
-- AI203 - Database Management Systems Course Project
-- SVNIT Surat, B.Tech II (Dept. of Artificial Intelligence)
-- 9 Normalized Tables in 3NF with Constraints (PK, FK, UNIQUE, CHECK, DEFAULT)
-- =============================================================================

CREATE DATABASE IF NOT EXISTS hostel_db;
USE hostel_db;

-- -----------------------------------------------------------------------------
-- 1. USERS: Authentication table for Admin and Student logins
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS users (
    user_id INT AUTO_INCREMENT PRIMARY KEY,
    username VARCHAR(50) NOT NULL UNIQUE,
    password VARCHAR(100) NOT NULL, -- Stored securely (plain demo password or hash)
    role ENUM('ADMIN', 'STUDENT') NOT NULL DEFAULT 'STUDENT',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

-- -----------------------------------------------------------------------------
-- 2. HOSTELS: College residential buildings (e.g. Gajjar Bhavan, Mother Teresa)
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS hostels (
    hostel_id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL UNIQUE,
    type ENUM('BOYS', 'GIRLS') NOT NULL,
    total_rooms INT NOT NULL DEFAULT 0 CHECK (total_rooms >= 0)
) ENGINE=InnoDB;

-- -----------------------------------------------------------------------------
-- 3. ROOMS: Individual rooms within each hostel
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS rooms (
    room_id INT AUTO_INCREMENT PRIMARY KEY,
    hostel_id INT NOT NULL,
    room_number VARCHAR(10) NOT NULL,
    capacity INT NOT NULL DEFAULT 2 CHECK (capacity >= 1 AND capacity <= 4),
    current_occupancy INT NOT NULL DEFAULT 0 CHECK (current_occupancy >= 0 AND current_occupancy <= capacity),
    fee_per_sem DECIMAL(10,2) NOT NULL DEFAULT 25000.00 CHECK (fee_per_sem > 0),
    status ENUM('AVAILABLE', 'FULL', 'MAINTENANCE') NOT NULL DEFAULT 'AVAILABLE',
    CONSTRAINT fk_rooms_hostel FOREIGN KEY (hostel_id) REFERENCES hostels(hostel_id) ON DELETE CASCADE ON UPDATE CASCADE,
    UNIQUE KEY uq_hostel_room (hostel_id, room_number)
) ENGINE=InnoDB;

-- -----------------------------------------------------------------------------
-- 4. WARDENS: Faculty in-charge of hostels
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS wardens (
    warden_id INT AUTO_INCREMENT PRIMARY KEY,
    hostel_id INT NOT NULL,
    name VARCHAR(100) NOT NULL,
    phone VARCHAR(15) NOT NULL,
    email VARCHAR(100) NOT NULL UNIQUE,
    CONSTRAINT fk_wardens_hostel FOREIGN KEY (hostel_id) REFERENCES hostels(hostel_id) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;

-- -----------------------------------------------------------------------------
-- 5. STUDENTS: Resident student records linked to a user login
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS students (
    student_id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL UNIQUE,
    roll_number VARCHAR(20) NOT NULL UNIQUE,
    name VARCHAR(100) NOT NULL,
    gender ENUM('MALE', 'FEMALE') NOT NULL,
    phone VARCHAR(15) NOT NULL,
    email VARCHAR(100) NOT NULL UNIQUE,
    department VARCHAR(50) NOT NULL,
    year_of_study INT NOT NULL DEFAULT 2 CHECK (year_of_study >= 1 AND year_of_study <= 4),
    CONSTRAINT fk_students_user FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;

-- -----------------------------------------------------------------------------
-- 6. ALLOCATIONS: Room assignments for students
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS allocations (
    allocation_id INT AUTO_INCREMENT PRIMARY KEY,
    student_id INT NOT NULL,
    room_id INT NOT NULL,
    allocation_date DATE NOT NULL,
    status ENUM('ACTIVE', 'VACATED') NOT NULL DEFAULT 'ACTIVE',
    CONSTRAINT fk_allocations_student FOREIGN KEY (student_id) REFERENCES students(student_id) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_allocations_room FOREIGN KEY (room_id) REFERENCES rooms(room_id) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;

-- -----------------------------------------------------------------------------
-- 7. FEE_PAYMENTS: Fee payment transactions made by students
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS fee_payments (
    payment_id INT AUTO_INCREMENT PRIMARY KEY,
    student_id INT NOT NULL,
    amount_paid DECIMAL(10,2) NOT NULL CHECK (amount_paid > 0),
    payment_date DATE NOT NULL,
    payment_mode ENUM('ONLINE', 'UPI', 'CASH', 'CHALLAN') NOT NULL DEFAULT 'ONLINE',
    receipt_no VARCHAR(50) NOT NULL UNIQUE,
    CONSTRAINT fk_fee_payments_student FOREIGN KEY (student_id) REFERENCES students(student_id) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;

-- -----------------------------------------------------------------------------
-- 8. COMPLAINTS: Maintenance grievances raised by students for their rooms
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS complaints (
    complaint_id INT AUTO_INCREMENT PRIMARY KEY,
    student_id INT NOT NULL,
    room_id INT NOT NULL,
    title VARCHAR(150) NOT NULL,
    description TEXT NOT NULL,
    category ENUM('ELECTRICAL', 'PLUMBING', 'CARPENTRY', 'CLEANLINESS', 'WIFI') NOT NULL,
    status ENUM('PENDING', 'RESOLVED') NOT NULL DEFAULT 'PENDING',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_complaints_student FOREIGN KEY (student_id) REFERENCES students(student_id) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_complaints_room FOREIGN KEY (room_id) REFERENCES rooms(room_id) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;

-- -----------------------------------------------------------------------------
-- 9. VISITOR_LOGS: Security gate register for student visitors
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS visitor_logs (
    visitor_id INT AUTO_INCREMENT PRIMARY KEY,
    student_id INT NOT NULL,
    visitor_name VARCHAR(100) NOT NULL,
    relation VARCHAR(50) NOT NULL,
    phone VARCHAR(15) NOT NULL,
    visit_date DATE NOT NULL,
    in_time TIME NOT NULL,
    out_time TIME NULL,
    CONSTRAINT fk_visitor_logs_student FOREIGN KEY (student_id) REFERENCES students(student_id) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;
