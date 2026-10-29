-- =============================================================================
-- HOSTEL MANAGEMENT SYSTEM (HMS) - ADVANCED DBMS CONCEPTS
-- AI203 - SVNIT Surat
-- 1. View: vw_room_vacancy
-- 2. Trigger: trg_after_allocation_insert & trg_after_allocation_vacate
-- 3. Stored Procedure: sp_allocate_room
-- 4. Transaction with ACID (COMMIT / ROLLBACK): sp_safe_room_allocation
-- 5. Index with EXPLAIN performance demonstration
-- =============================================================================

USE hostel_db;

-- =============================================================================
-- 1. VIEW: vw_room_vacancy
-- Purpose: Shows room capacity, occupied beds, vacant beds, and occupancy rate
-- =============================================================================
DROP VIEW IF EXISTS vw_room_vacancy;

CREATE VIEW vw_room_vacancy AS
SELECT 
    h.hostel_id,
    h.name AS hostel_name,
    h.type AS hostel_type,
    r.room_id,
    r.room_number,
    r.capacity,
    r.current_occupancy,
    (r.capacity - r.current_occupancy) AS vacant_beds,
    r.fee_per_sem,
    r.status AS room_status
FROM rooms r
JOIN hostels h ON r.hostel_id = h.hostel_id;

-- =============================================================================
-- 2. TRIGGER: trg_after_allocation_insert
-- Purpose: Automatically updates room occupancy and flags 'FULL' when occupied
-- =============================================================================
-- Keep the room count valid for empty hostels on both new and existing schemas.
ALTER TABLE hostels MODIFY total_rooms INT NOT NULL DEFAULT 0 CHECK (total_rooms >= 0);

DROP TRIGGER IF EXISTS trg_after_allocation_insert;
DROP TRIGGER IF EXISTS trg_after_allocation_update;
DROP TRIGGER IF EXISTS trg_after_allocation_delete;
DROP TRIGGER IF EXISTS trg_after_room_insert;
DROP TRIGGER IF EXISTS trg_after_room_update;
DROP TRIGGER IF EXISTS trg_after_room_delete;

DELIMITER $$

CREATE TRIGGER trg_after_allocation_insert
AFTER INSERT ON allocations
FOR EACH ROW
BEGIN
    IF NEW.status = 'ACTIVE' THEN
        UPDATE rooms
        SET status = CASE
                WHEN status = 'MAINTENANCE' THEN 'MAINTENANCE'
                WHEN current_occupancy + 1 >= capacity THEN 'FULL'
                ELSE 'AVAILABLE'
            END,
            current_occupancy = current_occupancy + 1
        WHERE room_id = NEW.room_id;
    END IF;
END$$

-- Trigger to handle when an allocation is vacated (checkout)
CREATE TRIGGER trg_after_allocation_update
AFTER UPDATE ON allocations
FOR EACH ROW
BEGIN
    IF OLD.status = 'ACTIVE' AND (NEW.status <> 'ACTIVE' OR NEW.room_id <> OLD.room_id) THEN
        UPDATE rooms
        SET status = CASE
                WHEN status = 'MAINTENANCE' THEN 'MAINTENANCE'
                WHEN current_occupancy - 1 >= capacity THEN 'FULL'
                ELSE 'AVAILABLE'
            END,
            current_occupancy = GREATEST(0, current_occupancy - 1)
        WHERE room_id = OLD.room_id;
    END IF;

    IF NEW.status = 'ACTIVE' AND (OLD.status <> 'ACTIVE' OR NEW.room_id <> OLD.room_id) THEN
        UPDATE rooms
        SET status = CASE
                WHEN status = 'MAINTENANCE' THEN 'MAINTENANCE'
                WHEN current_occupancy + 1 >= capacity THEN 'FULL'
                ELSE 'AVAILABLE'
            END,
            current_occupancy = current_occupancy + 1
        WHERE room_id = NEW.room_id;
    END IF;
END$$

CREATE TRIGGER trg_after_allocation_delete
AFTER DELETE ON allocations
FOR EACH ROW
BEGIN
    IF OLD.status = 'ACTIVE' THEN
        UPDATE rooms
        SET status = CASE
                WHEN status = 'MAINTENANCE' THEN 'MAINTENANCE'
                WHEN current_occupancy - 1 >= capacity THEN 'FULL'
                ELSE 'AVAILABLE'
            END,
            current_occupancy = GREATEST(0, current_occupancy - 1)
        WHERE room_id = OLD.room_id;
    END IF;
END$$

-- Keep the hostel room-count summary synchronized with room CRUD operations.
CREATE TRIGGER trg_after_room_insert
AFTER INSERT ON rooms
FOR EACH ROW
BEGIN
    UPDATE hostels SET total_rooms = total_rooms + 1 WHERE hostel_id = NEW.hostel_id;
END$$

CREATE TRIGGER trg_after_room_update
AFTER UPDATE ON rooms
FOR EACH ROW
BEGIN
    IF NEW.hostel_id <> OLD.hostel_id THEN
        UPDATE hostels SET total_rooms = GREATEST(total_rooms - 1, 0) WHERE hostel_id = OLD.hostel_id;
        UPDATE hostels SET total_rooms = total_rooms + 1 WHERE hostel_id = NEW.hostel_id;
    END IF;
END$$

CREATE TRIGGER trg_after_room_delete
AFTER DELETE ON rooms
FOR EACH ROW
BEGIN
    UPDATE hostels SET total_rooms = GREATEST(total_rooms - 1, 0) WHERE hostel_id = OLD.hostel_id;
END$$

-- =============================================================================
-- 3. STORED PROCEDURE: sp_allocate_room
-- Purpose: Simple procedure to allocate a student to a room
-- =============================================================================
DROP PROCEDURE IF EXISTS sp_allocate_room;

CREATE PROCEDURE sp_allocate_room(
    IN  p_student_id INT,
    IN  p_room_id    INT,
    OUT p_message    VARCHAR(100)
)
BEGIN
    DECLARE v_student_count INT DEFAULT 0;
    DECLARE v_student_id INT DEFAULT NULL;
    DECLARE v_active_count INT DEFAULT 0;
    DECLARE v_room_count INT DEFAULT 0;
    DECLARE v_room_occ INT DEFAULT 0;
    DECLARE v_room_cap INT DEFAULT 0;
    DECLARE v_room_status VARCHAR(20);

    SELECT COUNT(*) INTO v_student_count
    FROM students
    WHERE student_id = p_student_id;

    IF v_student_count = 0 THEN
        SET p_message = 'ERROR: Student does not exist.';
    ELSE
        -- Lock the student row so concurrent requests cannot double-allocate them.
        SELECT student_id INTO v_student_id
        FROM students
        WHERE student_id = p_student_id
        FOR UPDATE;

    SELECT COUNT(*) INTO v_active_count
    FROM allocations
    WHERE student_id = p_student_id AND status = 'ACTIVE';

    IF v_active_count > 0 THEN
        SET p_message = 'ERROR: Student already has an active room allocation!';
    ELSE
        SELECT COUNT(*) INTO v_room_count
        FROM rooms
        WHERE room_id = p_room_id;

        IF v_room_count = 0 THEN
            SET p_message = 'ERROR: Room does not exist.';
        ELSE
            -- Lock the room row so concurrent requests cannot exceed its capacity.
            SELECT current_occupancy, capacity, status
            INTO v_room_occ, v_room_cap, v_room_status
            FROM rooms
            WHERE room_id = p_room_id
            FOR UPDATE;

        IF v_room_status = 'MAINTENANCE' THEN
            SET p_message = 'ERROR: Room is under maintenance.';
        ELSEIF v_room_occ >= v_room_cap THEN
            SET p_message = 'ERROR: Selected room is already full!';
        ELSE
            INSERT INTO allocations (student_id, room_id, allocation_date, status)
            VALUES (p_student_id, p_room_id, CURDATE(), 'ACTIVE');
            SET p_message = 'SUCCESS: Room allocated successfully!';
        END IF;
        END IF;
    END IF;
    END IF;
END$$

-- =============================================================================
-- 4. TRANSACTION WITH COMMIT / ROLLBACK: sp_safe_room_allocation
-- Purpose: Demonstrates ACID properties by explicitly checking constraints
--          and rolling back if anything fails.
-- =============================================================================
DROP PROCEDURE IF EXISTS sp_safe_room_allocation;

CREATE PROCEDURE sp_safe_room_allocation(
    IN  p_student_id INT,
    IN  p_room_id    INT,
    OUT p_status     VARCHAR(50)
)
proc: BEGIN
    DECLARE v_message VARCHAR(100);

    -- Rollback on any SQL exception
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SET p_status = 'FAILED: SQL Exception, transaction rolled back.';
    END;

    -- START TRANSACTION
    START TRANSACTION;

    -- The procedure uses row locks while this transaction owns COMMIT/ROLLBACK.
    CALL sp_allocate_room(p_student_id, p_room_id, v_message);
    IF LEFT(v_message, 7) <> 'SUCCESS' THEN
        ROLLBACK;
        SET p_status = v_message;
        LEAVE proc;
    END IF;

    -- COMMIT TRANSACTION
    COMMIT;
    SET p_status = 'SUCCESS: Room allocated with ACID commit.';
END$$

DELIMITER ;

-- Reconcile the stored summary for databases that predate the room-count triggers.
UPDATE hostels h
SET total_rooms = (SELECT COUNT(*) FROM rooms r WHERE r.hostel_id = h.hostel_id);

-- =============================================================================
-- 5. INDEX & EXPLAIN DEMONSTRATION
-- Purpose: Support the active-allocation lookup used by reports and student views
-- =============================================================================

-- Run this EXPLAIN before creating the index to record the baseline plan.
EXPLAIN SELECT allocation_id, room_id
FROM allocations
WHERE student_id = 1 AND status = 'ACTIVE';

-- Create this index once; it narrows both the student and allocation status.
SET @allocation_index_exists = (
    SELECT COUNT(*) FROM information_schema.statistics
    WHERE table_schema = DATABASE()
      AND table_name = 'allocations'
      AND index_name = 'idx_allocation_student_status'
);
SET @create_allocation_index = IF(
    @allocation_index_exists = 0,
    'CREATE INDEX idx_allocation_student_status ON allocations(student_id, status)',
    'SELECT 1'
);
PREPARE allocation_index_statement FROM @create_allocation_index;
EXECUTE allocation_index_statement;
DEALLOCATE PREPARE allocation_index_statement;

-- Run this EXPLAIN again and compare the selected key and estimated rows.
EXPLAIN SELECT allocation_id, room_id
FROM allocations
WHERE student_id = 1 AND status = 'ACTIVE';
