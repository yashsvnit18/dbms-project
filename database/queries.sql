-- =============================================================================
-- HOSTEL MANAGEMENT SYSTEM (HMS) - SQL QUERIES REPOSITORY
-- AI203 - SVNIT Surat
-- Clean, well-commented queries covering JOINs, Aggregates, and Subqueries
-- =============================================================================

USE hostel_db;

-- =============================================================================
-- 1. MULTI-TABLE JOINS (INNER JOIN & LEFT JOIN)
-- =============================================================================

-- Query 1.1: Active Student Room Allotment Roster (4-Table INNER JOIN)
-- Retrieves complete resident details: student, roll number, hostel name, room number, and warden in-charge.
SELECT 
    s.roll_number,
    s.name AS student_name,
    s.department,
    h.name AS hostel_name,
    r.room_number,
    w.name AS warden_name,
    a.allocation_date
FROM students s
INNER JOIN allocations a ON s.student_id = a.student_id AND a.status = 'ACTIVE'
INNER JOIN rooms r ON a.room_id = r.room_id
INNER JOIN hostels h ON r.hostel_id = h.hostel_id
INNER JOIN wardens w ON h.hostel_id = w.hostel_id
ORDER BY h.name, r.room_number;

-- Query 1.2: All Rooms with Current Occupants (LEFT JOIN to include vacant rooms)
-- Displays all hostel rooms regardless of whether they currently have residents or are completely empty.
SELECT 
    h.name AS hostel_name,
    r.room_number,
    r.capacity,
    r.current_occupancy,
    r.status AS room_status,
    s.roll_number,
    s.name AS occupant_name
FROM rooms r
INNER JOIN hostels h ON r.hostel_id = h.hostel_id
LEFT JOIN allocations a ON r.room_id = a.room_id AND a.status = 'ACTIVE'
LEFT JOIN students s ON a.student_id = s.student_id
ORDER BY h.name, r.room_number;

-- Query 1.3: Active Maintenance Complaints with Room & Student Info (INNER JOIN)
-- Shows all pending complaints along with student name, room number, and category.
SELECT 
    c.complaint_id,
    c.title,
    c.category,
    c.status,
    s.name AS student_name,
    s.roll_number,
    r.room_number,
    h.name AS hostel_name
FROM complaints c
INNER JOIN students s ON c.student_id = s.student_id
INNER JOIN rooms r ON c.room_id = r.room_id
INNER JOIN hostels h ON r.hostel_id = h.hostel_id
WHERE c.status = 'PENDING'
ORDER BY c.created_at DESC;


-- =============================================================================
-- 2. AGGREGATE FUNCTIONS WITH GROUP BY & HAVING
-- =============================================================================

-- Query 2.1: Hostel Bed Capacity and Occupancy Summary (SUM, COUNT, GROUP BY)
-- Aggregates total rooms, total bed capacity, occupied beds, and vacant beds per hostel building.
SELECT 
    h.name AS hostel_name,
    h.type AS hostel_type,
    COUNT(r.room_id) AS total_rooms,
    SUM(r.capacity) AS total_bed_capacity,
    SUM(r.current_occupancy) AS total_occupied_beds,
    SUM(r.capacity - r.current_occupancy) AS total_vacant_beds,
    ROUND((SUM(r.current_occupancy) * 100.0) / SUM(r.capacity), 1) AS occupancy_percentage
FROM hostels h
INNER JOIN rooms r ON h.hostel_id = r.hostel_id
GROUP BY h.hostel_id, h.name, h.type;

-- Query 2.1a: Active students currently allocated in each hostel.
SELECT h.name AS hostel_name, COUNT(DISTINCT a.student_id) AS students
FROM hostels h
LEFT JOIN rooms r ON r.hostel_id = h.hostel_id
LEFT JOIN allocations a ON a.room_id = r.room_id AND a.status = 'ACTIVE'
GROUP BY h.hostel_id, h.name
HAVING COUNT(DISTINCT a.student_id) > 0
ORDER BY h.name;

-- Query 2.2: Fee Defaulters with Outstanding Dues (SUM, GROUP BY, HAVING)
-- Identifies allocated students whose total payments are strictly less than their semester room fee.
SELECT 
    s.student_id,
    s.roll_number,
    s.name AS student_name,
    h.name AS hostel_name,
    r.room_number,
    r.fee_per_sem AS total_fee_due,
    COALESCE(SUM(fp.amount_paid), 0.00) AS total_fee_paid,
    (r.fee_per_sem - COALESCE(SUM(fp.amount_paid), 0.00)) AS outstanding_balance
FROM students s
INNER JOIN allocations a ON s.student_id = a.student_id AND a.status = 'ACTIVE'
INNER JOIN rooms r ON a.room_id = r.room_id
INNER JOIN hostels h ON r.hostel_id = h.hostel_id
LEFT JOIN fee_payments fp ON s.student_id = fp.student_id
GROUP BY s.student_id, s.roll_number, s.name, h.name, r.room_number, r.fee_per_sem
HAVING outstanding_balance > 0
ORDER BY outstanding_balance DESC;

-- Query 2.3: Total Fees Collected by Payment Mode (SUM, COUNT, GROUP BY)
-- Calculates transaction count and total revenue generated for each payment channel.
SELECT 
    payment_mode,
    COUNT(payment_id) AS total_transactions,
    SUM(amount_paid) AS total_amount_collected
FROM fee_payments
GROUP BY payment_mode
ORDER BY total_amount_collected DESC;

-- Query 2.4: Hostels with More Than 3 Occupied Beds (HAVING filter on aggregate)
-- Filters hostels that have reached significant occupancy levels.
SELECT 
    h.name AS hostel_name,
    SUM(r.current_occupancy) AS total_occupied
FROM hostels h
INNER JOIN rooms r ON h.hostel_id = r.hostel_id
GROUP BY h.hostel_id, h.name
HAVING total_occupied >= 3;


-- =============================================================================
-- 3. SUBQUERIES (CORRELATED & NESTED)
-- =============================================================================

-- Query 3.1: Subquery with NOT IN (Students without Any Room Allocation)
-- Finds registered students who are currently unassigned and waiting for a room.
SELECT 
    student_id,
    roll_number,
    name,
    gender,
    department
FROM students
WHERE student_id NOT IN (
    SELECT student_id 
    FROM allocations 
    WHERE status = 'ACTIVE'
);

-- Query 3.2: Subquery with NOT EXISTS (Rooms that have never had a single complaint)
-- Finds well-maintained rooms that have zero logged complaints in history.
SELECT 
    r.room_id,
    h.name AS hostel_name,
    r.room_number
FROM rooms r
INNER JOIN hostels h ON r.hostel_id = h.hostel_id
WHERE NOT EXISTS (
    SELECT 1 
    FROM complaints c 
    WHERE c.room_id = r.room_id
);

-- Query 3.3: Scalar Subquery (Payments higher than average payment amount)
-- Retrieves fee payments that exceed the overall institutional average transaction value.
SELECT 
    fp.receipt_no,
    s.name AS student_name,
    fp.amount_paid,
    fp.payment_date
FROM fee_payments fp
INNER JOIN students s ON fp.student_id = s.student_id
WHERE fp.amount_paid > (SELECT AVG(amount_paid) FROM fee_payments);
