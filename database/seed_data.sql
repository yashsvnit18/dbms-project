-- =============================================================================
-- HOSTEL MANAGEMENT SYSTEM (HMS) - REALISTIC SEED DATA
-- AI203 - SVNIT Surat
-- 3 Hostels, 3 Wardens, 24 Rooms, 18 Students, Allocations, Fees, Complaints, Visitors
-- =============================================================================

USE hostel_db;

-- Seed only an empty database. Existing project records are never deleted or overwritten.
DROP PROCEDURE IF EXISTS seed_hostel_demo_data;
DELIMITER $$
CREATE PROCEDURE seed_hostel_demo_data()
BEGIN
  IF EXISTS (SELECT 1 FROM users)
    OR EXISTS (SELECT 1 FROM hostels)
    OR EXISTS (SELECT 1 FROM rooms)
    OR EXISTS (SELECT 1 FROM students)
    OR EXISTS (SELECT 1 FROM wardens)
    OR EXISTS (SELECT 1 FROM allocations)
    OR EXISTS (SELECT 1 FROM fee_payments)
    OR EXISTS (SELECT 1 FROM complaints)
    OR EXISTS (SELECT 1 FROM visitor_logs) THEN
    SELECT 'Seed skipped: existing project data was preserved.' AS seed_status;
  ELSE3
  

-- -----------------------------------------------------------------------------
-- 1. USERS (Admin + 18 Students)
-- -----------------------------------------------------------------------------
INSERT INTO users (user_id, username, password, role) VALUES
(1, 'admin', 'admin123', 'ADMIN'),
(2, 'u24ai001', 'student123', 'STUDENT'),
(3, 'u24ai002', 'student123', 'STUDENT'),
(4, 'u24ai003', 'student123', 'STUDENT'),
(5, 'u24ai004', 'student123', 'STUDENT'),
(6, 'u24ai005', 'student123', 'STUDENT'),
(7, 'u24ai006', 'student123', 'STUDENT'),
(8, 'u24ai007', 'student123', 'STUDENT'),
(9, 'u24ai008', 'student123', 'STUDENT'),
(10, 'u24ai009', 'student123', 'STUDENT'),
(11, 'u24ai010', 'student123', 'STUDENT'),
(12, 'u24ai011', 'student123', 'STUDENT'),
(13, 'u24ai012', 'student123', 'STUDENT'),
(14, 'u24ai013', 'student123', 'STUDENT'),
(15, 'u24ai014', 'student123', 'STUDENT'),
(16, 'u24ai015', 'student123', 'STUDENT'),
(17, 'u24ai016', 'student123', 'STUDENT'),
(18, 'u24ai017', 'student123', 'STUDENT'),
(19, 'u24ai018', 'student123', 'STUDENT');

-- -----------------------------------------------------------------------------
-- 2. HOSTELS (SVNIT Bhavans)
-- -----------------------------------------------------------------------------
INSERT INTO hostels (hostel_id, name, type) VALUES
(1, 'Gajjar Bhavan', 'BOYS'),
(2, 'Bhabha Bhavan', 'BOYS'),
(3, 'Mother Teresa Bhavan', 'GIRLS');

-- -----------------------------------------------------------------------------
-- 3. WARDENS
-- -----------------------------------------------------------------------------
INSERT INTO wardens (warden_id, hostel_id, name, phone, email) VALUES
(1, 1, 'Dr. Anil Patel', '9825100001', 'warden.gajjar@svnit.ac.in'),
(2, 2, 'Dr. Rajesh Sharma', '9825100002', 'warden.bhabha@svnit.ac.in'),
(3, 3, 'Dr. Sneha Mehta', '9825100003', 'warden.mtb@svnit.ac.in');

-- -----------------------------------------------------------------------------
-- 4. ROOMS (8 rooms per hostel = 24 rooms total, capacity 2 beds each)
-- -----------------------------------------------------------------------------
INSERT INTO rooms (room_id, hostel_id, room_number, capacity, current_occupancy, fee_per_sem, status) VALUES
-- Gajjar Bhavan (Hostel 1, Boys)
(1, 1, '101', 2, 0, 25000.00, 'AVAILABLE'),
(2, 1, '102', 2, 0, 25000.00, 'AVAILABLE'),
(3, 1, '103', 2, 0, 25000.00, 'AVAILABLE'),
(4, 1, '104', 2, 0, 25000.00, 'AVAILABLE'),
(5, 1, '201', 2, 0, 25000.00, 'AVAILABLE'),
(6, 1, '202', 2, 0, 25000.00, 'AVAILABLE'),
(7, 1, '203', 2, 0, 25000.00, 'AVAILABLE'),
(8, 1, '204', 2, 0, 25000.00, 'AVAILABLE'),

-- Bhabha Bhavan (Hostel 2, Boys)
(9,  2, '101', 2, 0, 24000.00, 'AVAILABLE'),
(10, 2, '102', 2, 0, 24000.00, 'AVAILABLE'),
(11, 2, '103', 2, 0, 24000.00, 'AVAILABLE'),
(12, 2, '104', 2, 0, 24000.00, 'AVAILABLE'),
(13, 2, '201', 2, 0, 24000.00, 'AVAILABLE'),
(14, 2, '202', 2, 0, 24000.00, 'AVAILABLE'),
(15, 2, '203', 2, 0, 24000.00, 'AVAILABLE'),
(16, 2, '204', 2, 0, 24000.00, 'AVAILABLE'),

-- Mother Teresa Bhavan (Hostel 3, Girls)
(17, 3, '101', 2, 0, 26000.00, 'AVAILABLE'),
(18, 3, '102', 2, 0, 26000.00, 'AVAILABLE'),
(19, 3, '103', 2, 0, 26000.00, 'AVAILABLE'),
(20, 3, '104', 2, 0, 26000.00, 'AVAILABLE'),
(21, 3, '201', 2, 0, 26000.00, 'AVAILABLE'),
(22, 3, '202', 2, 0, 26000.00, 'AVAILABLE'),
(23, 3, '203', 2, 0, 26000.00, 'AVAILABLE'),
(24, 3, '204', 2, 0, 26000.00, 'AVAILABLE');

-- -----------------------------------------------------------------------------
-- 5. STUDENTS (18 Students: 12 Male, 6 Female)
-- -----------------------------------------------------------------------------
INSERT INTO students (student_id, user_id, roll_number, name, gender, phone, email, department, year_of_study) VALUES
(1,  2,  'U24AI001', 'Aarav Patel',     'MALE',   '9876543201', 'u24ai001@svnit.ac.in', 'Artificial Intelligence', 2),
(2,  3,  'U24AI002', 'Aryan Sharma',    'MALE',   '9876543202', 'u24ai002@svnit.ac.in', 'Artificial Intelligence', 2),
(3,  4,  'U24AI003', 'Rohan Verma',     'MALE',   '9876543203', 'u24ai003@svnit.ac.in', 'Computer Science', 2),
(4,  5,  'U24AI004', 'Vivaan Desai',    'MALE',   '9876543204', 'u24ai004@svnit.ac.in', 'Computer Science', 2),
(5,  6,  'U24AI005', 'Kabir Mehta',     'MALE',   '9876543205', 'u24ai005@svnit.ac.in', 'Electronics & Comm', 2),
(6,  7,  'U24AI006', 'Dev Gupta',       'MALE',   '9876543206', 'u24ai006@svnit.ac.in', 'Mechanical Engg', 2),
(7,  8,  'U24AI007', 'Yash Singh',      'MALE',   '9876543207', 'u24ai007@svnit.ac.in', 'Mechanical Engg', 2),
(8,  9,  'U24AI008', 'Dhruv Joshi',     'MALE',   '9876543208', 'u24ai008@svnit.ac.in', 'Civil Engg', 2),
(9,  10, 'U24AI009', 'Tanmay Shah',     'MALE',   '9876543209', 'u24ai009@svnit.ac.in', 'Chemical Engg', 2),
(10, 11, 'U24AI010', 'Pranav Chauhan',  'MALE',   '9876543210', 'u24ai010@svnit.ac.in', 'Electrical Engg', 2),
(11, 12, 'U24AI011', 'Ayush Rathore',   'MALE',   '9876543211', 'u24ai011@svnit.ac.in', 'Electrical Engg', 2),
(12, 13, 'U24AI012', 'Gaurav Yadav',    'MALE',   '9876543212', 'u24ai012@svnit.ac.in', 'Computer Science', 2),
(13, 14, 'U24AI013', 'Priya Trivedi',   'FEMALE', '9876543213', 'u24ai013@svnit.ac.in', 'Artificial Intelligence', 2),
(14, 15, 'U24AI014', 'Ananya Bhatt',    'FEMALE', '9876543214', 'u24ai014@svnit.ac.in', 'Artificial Intelligence', 2),
(15, 16, 'U24AI015', 'Isha Nair',       'FEMALE', '9876543215', 'u24ai015@svnit.ac.in', 'Computer Science', 2),
(16, 17, 'U24AI016', 'Diya Iyer',       'FEMALE', '9876543216', 'u24ai016@svnit.ac.in', 'Computer Science', 2),
(17, 18, 'U24AI017', 'Sneha Reddy',     'FEMALE', '9876543217', 'u24ai017@svnit.ac.in', 'Electronics & Comm', 2),
(18, 19, 'U24AI018', 'Riya Mishra',     'FEMALE', '9876543218', 'u24ai018@svnit.ac.in', 'Electrical Engg', 2);

-- -----------------------------------------------------------------------------
-- 6. ALLOCATIONS (14 active room allocations; triggers will adjust room occupancy)
-- -----------------------------------------------------------------------------
-- Room 1 (Gajjar 101): Aarav, Aryan -> Room becomes FULL (2/2)
INSERT INTO allocations (allocation_id, student_id, room_id, allocation_date, status) VALUES
(1, 1, 1, '2026-07-20', 'ACTIVE'),
(2, 2, 1, '2026-07-20', 'ACTIVE'),

-- Room 2 (Gajjar 102): Rohan -> Occupancy 1/2
(3, 3, 2, '2026-07-21', 'ACTIVE'),

-- Room 3 (Gajjar 103): Vivaan, Kabir -> Room becomes FULL (2/2)
(4, 4, 3, '2026-07-21', 'ACTIVE'),
(5, 5, 3, '2026-07-21', 'ACTIVE'),

-- Room 9 (Bhabha 101): Dev, Yash -> Room becomes FULL (2/2)
(6, 6, 9, '2026-07-22', 'ACTIVE'),
(7, 7, 9, '2026-07-22', 'ACTIVE'),

-- Room 10 (Bhabha 102): Dhruv -> Occupancy 1/2
(8, 8, 10, '2026-07-22', 'ACTIVE'),

-- Room 11 (Bhabha 103): Tanmay -> Occupancy 1/2
(9, 9, 11, '2026-07-23', 'ACTIVE'),

-- Room 17 (Mother Teresa 101): Priya, Ananya -> Room becomes FULL (2/2)
(10, 13, 17, '2026-07-20', 'ACTIVE'),
(11, 14, 17, '2026-07-20', 'ACTIVE'),

-- Room 18 (Mother Teresa 102): Isha, Diya -> Room becomes FULL (2/2)
(12, 15, 18, '2026-07-21', 'ACTIVE'),
(13, 16, 18, '2026-07-21', 'ACTIVE'),

-- Room 19 (Mother Teresa 103): Sneha -> Occupancy 1/2
(14, 17, 19, '2026-07-21', 'ACTIVE');
-- Note: Students 10, 11, 12, 18 are not yet allocated (for testing allocations)

-- Keep the room summary columns consistent with the active allocation rows above.
UPDATE rooms r
SET current_occupancy = (
		SELECT COUNT(*) FROM allocations a
		WHERE a.room_id = r.room_id AND a.status = 'ACTIVE'
	),
	status = CASE
		WHEN r.status = 'MAINTENANCE' THEN 'MAINTENANCE'
		WHEN (SELECT COUNT(*) FROM allocations a WHERE a.room_id = r.room_id AND a.status = 'ACTIVE') >= r.capacity THEN 'FULL'
		ELSE 'AVAILABLE'
	END;

-- -----------------------------------------------------------------------------
-- 7. FEE_PAYMENTS (Some full payments, some partial, some 0 for defaulter query)
-- -----------------------------------------------------------------------------
INSERT INTO fee_payments (payment_id, student_id, amount_paid, payment_date, payment_mode, receipt_no) VALUES
(1, 1, 25000.00, '2026-07-25', 'ONLINE',  'REC-2026-001'),
(2, 2, 25000.00, '2026-07-25', 'UPI',     'REC-2026-002'),
(3, 3, 15000.00, '2026-07-26', 'CHALLAN', 'REC-2026-003'), -- Partial payment (defaulter)
(4, 4, 25000.00, '2026-07-26', 'ONLINE',  'REC-2026-004'),
(5, 5, 10000.00, '2026-07-27', 'UPI',     'REC-2026-005'), -- Partial payment (defaulter)
(6, 6, 24000.00, '2026-07-27', 'ONLINE',  'REC-2026-006'),
(7, 7, 24000.00, '2026-07-28', 'CASH',    'REC-2026-007'),
(8, 13, 26000.00, '2026-07-25', 'ONLINE', 'REC-2026-008'),
(9, 14, 26000.00, '2026-07-25', 'UPI',    'REC-2026-009'),
(10, 15, 12000.00, '2026-07-26', 'CHALLAN','REC-2026-010'); -- Partial payment (defaulter)

-- -----------------------------------------------------------------------------
-- 8. COMPLAINTS
-- -----------------------------------------------------------------------------
INSERT INTO complaints (complaint_id, student_id, room_id, title, description, category, status, created_at) VALUES
(1, 1, 1, 'Ceiling fan makes humming sound', 'Fan regulator is loose and fan makes loud humming at night.', 'ELECTRICAL', 'RESOLVED', '2026-08-01 10:00:00'),
(2, 2, 1, 'LAN Ethernet port loose', 'Wall socket ethernet port is loose, intermittent internet connection.', 'WIFI', 'PENDING', '2026-08-03 14:30:00'),
(3, 3, 2, 'Bathroom tap leaking', 'Wash basin tap drips continuously, wasting clean water.', 'PLUMBING', 'RESOLVED', '2026-08-05 09:15:00'),
(4, 4, 3, 'Wardrobe latch misaligned', 'Wooden cupboard door does not snap shut securely.', 'CARPENTRY', 'PENDING', '2026-08-07 16:45:00'),
(5, 6, 9, 'Window mesh torn', 'Mosquito net mesh on balcony window has a tear.', 'CARPENTRY', 'PENDING', '2026-08-10 11:20:00'),
(6, 13, 17, 'Balcony light flickering', 'Balcony LED bulb flickering periodically.', 'ELECTRICAL', 'RESOLVED', '2026-08-12 18:00:00');

-- -----------------------------------------------------------------------------
-- 9. VISITOR_LOGS
-- -----------------------------------------------------------------------------
INSERT INTO visitor_logs (visitor_id, student_id, visitor_name, relation, phone, visit_date, in_time, out_time) VALUES
(1, 1, 'Suresh Patel', 'Father', '9898012345', '2026-08-02', '10:00:00', '12:30:00'),
(2, 3, 'Mahesh Verma', 'Father', '9898012346', '2026-08-04', '14:00:00', '16:00:00'),
(3, 4, 'Sunita Desai', 'Mother', '9898012347', '2026-08-08', '11:30:00', '13:45:00'),
(4, 6, 'Ramesh Gupta', 'Uncle',  '9898012348', '2026-08-11', '15:00:00', NULL), -- Currently inside
(5, 13, 'Bhavna Trivedi', 'Mother', '9898012349', '2026-08-14', '10:30:00', '12:15:00');
  END IF;
END$$
DELIMITER ;

CALL seed_hostel_demo_data();
DROP PROCEDURE seed_hostel_demo_data;
