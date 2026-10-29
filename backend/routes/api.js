const express = require('express');
const router = express.Router();
const { pool } = require('../db');
const { createSession, requireLogin, requireAdmin, removeSession } = require('../auth');

function asyncRoute(handler) {
  return (req, res, next) => Promise.resolve(handler(req, res, next)).catch(next);
}

router.post('/login', asyncRoute(async (req, res) => {
  const { username, password } = req.body;
  if (!username || !password) return res.status(400).json({ error: 'Enter a username and password.' });

  const [rows] = await pool.execute(
    `SELECT u.user_id, u.username, u.password, u.role, s.student_id, s.name
     FROM users u LEFT JOIN students s ON s.user_id = u.user_id
     WHERE u.username = ?`, [username]
  );
  const user = rows[0];
  if (!user || user.password !== password) return res.status(401).json({ error: 'Username or password is incorrect.' });

  const safeUser = { userId: user.user_id, username: user.username, role: user.role, studentId: user.student_id, name: user.name };
  res.json({ token: createSession(safeUser), user: safeUser });
}));

router.post('/logout', requireLogin, (req, res) => {
  removeSession(req.sessionToken);
  res.json({ message: 'Logged out.' });
});

router.get('/me', requireLogin, asyncRoute(async (req, res) => {
  if (req.user.role === 'ADMIN') return res.json(req.user);
  const [rows] = await pool.execute('SELECT * FROM students WHERE student_id = ?', [req.user.studentId]);
  res.json(rows[0] || null);
}));

router.get('/my/rooms', requireLogin, asyncRoute(async (req, res) => {
  if (req.user.role !== 'STUDENT') return res.status(403).json({ error: 'Students only.' });
  const [rows] = await pool.execute(
    `SELECT r.room_id, r.room_number, h.name AS hostel_name
     FROM allocations a JOIN rooms r ON r.room_id = a.room_id
     JOIN hostels h ON h.hostel_id = r.hostel_id
     WHERE a.student_id = ? AND a.status = 'ACTIVE'`, [req.user.studentId]
  );
  res.json(rows);
}));

router.get('/students', requireLogin, requireAdmin, asyncRoute(async (req, res) => {
  const [rows] = await pool.query('SELECT student_id, roll_number, name, gender, phone, email, department, year_of_study FROM students ORDER BY name');
  res.json(rows);
}));

router.post('/students', requireLogin, requireAdmin, asyncRoute(async (req, res) => {
  const { roll_number, name, gender, phone, email, department, year_of_study } = req.body;
  const connection = await pool.getConnection();
  try {
    await connection.beginTransaction();
    const username = String(roll_number || '').toLowerCase();
    const [userResult] = await connection.execute(
      'INSERT INTO users (username, password, role) VALUES (?, ?, ?)', [username, 'student123', 'STUDENT']
    );
    const [studentResult] = await connection.execute(
      `INSERT INTO students (user_id, roll_number, name, gender, phone, email, department, year_of_study)
       VALUES (?, ?, ?, ?, ?, ?, ?, ?)`,
      [userResult.insertId, roll_number, name, gender, phone, email, department, year_of_study || 2]
    );
    await connection.commit();
    res.status(201).json({ student_id: studentResult.insertId, username, initial_password: 'student123' });
  } catch (error) {
    await connection.rollback();
    throw error;
  } finally {
    connection.release();
  }
}));

router.put('/students/:id', requireLogin, requireAdmin, asyncRoute(async (req, res) => {
  const fields = ['roll_number', 'name', 'gender', 'phone', 'email', 'department', 'year_of_study'];
  const values = fields.map((field) => req.body[field]);
  const connection = await pool.getConnection();
  try {
    await connection.beginTransaction();
    const [students] = await connection.execute(
      'SELECT user_id FROM students WHERE student_id = ? FOR UPDATE', [req.params.id]
    );
    if (!students.length) {
      await connection.rollback();
      return res.status(404).json({ error: 'Student not found.' });
    }
    await connection.execute(
      `UPDATE students SET ${fields.map((field) => `${field} = ?`).join(', ')} WHERE student_id = ?`,
      [...values, req.params.id]
    );
    await connection.execute(
      'UPDATE users SET username = ? WHERE user_id = ?',
      [String(req.body.roll_number || '').toLowerCase(), students[0].user_id]
    );
    await connection.commit();
    res.json({ message: 'Student updated.' });
  } catch (error) {
    await connection.rollback();
    throw error;
  } finally {
    connection.release();
  }
}));

router.delete('/students/:id', requireLogin, requireAdmin, asyncRoute(async (req, res) => {
  const connection = await pool.getConnection();
  try {
    await connection.beginTransaction();
    const [activeAllocations] = await connection.execute(
      'SELECT room_id FROM allocations WHERE student_id = ? AND status = ?',
      [req.params.id, 'ACTIVE']
    );
    const [deleteResult] = await connection.execute(
      'DELETE u FROM users u JOIN students s ON s.user_id = u.user_id WHERE s.student_id = ?',
      [req.params.id]
    );
    if (!deleteResult.affectedRows) {
      await connection.rollback();
      return res.status(404).json({ error: 'Student not found.' });
    }
    for (const roomId of new Set(activeAllocations.map((allocation) => allocation.room_id))) {
      await connection.execute(
        `UPDATE rooms
         SET current_occupancy = (
               SELECT COUNT(*) FROM allocations WHERE room_id = ? AND status = 'ACTIVE'
             ),
             status = CASE
               WHEN status = 'MAINTENANCE' THEN 'MAINTENANCE'
               WHEN (SELECT COUNT(*) FROM allocations WHERE room_id = ? AND status = 'ACTIVE') >= capacity THEN 'FULL'
               ELSE 'AVAILABLE'
             END
         WHERE room_id = ?`,
        [roomId, roomId, roomId]
      );
    }
    await connection.commit();
    res.json({ message: 'Student deleted.' });
  } catch (error) {
    await connection.rollback();
    throw error;
  } finally {
    connection.release();
  }
}));

const resources = {
  hostels: {
    select: `SELECT h.hostel_id, h.name, h.type, COUNT(r.room_id) AS total_rooms
      FROM hostels h LEFT JOIN rooms r ON r.hostel_id = h.hostel_id
      GROUP BY h.hostel_id, h.name, h.type ORDER BY h.name`,
    table: 'hostels', key: 'hostel_id', fields: ['name', 'type']
  },
  rooms: {
    select: `SELECT room_id, hostel_id, room_number, capacity, current_occupancy,
      fee_per_sem, room_status AS status, hostel_name
      FROM vw_room_vacancy ORDER BY hostel_name, room_number`,
    table: 'rooms', key: 'room_id', fields: ['hostel_id', 'room_number', 'capacity', 'fee_per_sem', 'status']
  },
  wardens: { select: 'SELECT * FROM wardens ORDER BY name', table: 'wardens', key: 'warden_id', fields: ['hostel_id', 'name', 'phone', 'email'] },
  fees: {
    select: 'SELECT fp.*, s.name AS student_name, s.roll_number FROM fee_payments fp JOIN students s ON s.student_id = fp.student_id ORDER BY fp.payment_date DESC',
    table: 'fee_payments', key: 'payment_id', fields: ['student_id', 'amount_paid', 'payment_date', 'payment_mode', 'receipt_no']
  },
  complaints: {
    select: 'SELECT c.*, s.name AS student_name, s.roll_number, r.room_number FROM complaints c JOIN students s ON s.student_id = c.student_id JOIN rooms r ON r.room_id = c.room_id ORDER BY c.created_at DESC',
    table: 'complaints', key: 'complaint_id', fields: ['student_id', 'room_id', 'title', 'description', 'category', 'status']
  },
  visitors: {
    select: 'SELECT v.*, s.name AS student_name, s.roll_number FROM visitor_logs v JOIN students s ON s.student_id = v.student_id ORDER BY v.visit_date DESC, v.in_time DESC',
    table: 'visitor_logs', key: 'visitor_id', fields: ['student_id', 'visitor_name', 'relation', 'phone', 'visit_date', 'in_time', 'out_time']
  }
};

for (const [name, resource] of Object.entries(resources)) {
  router.get(`/${name}`, requireLogin, asyncRoute(async (req, res) => {
    if ((name === 'complaints' || name === 'fees') && req.user.role === 'STUDENT') {
      const filter = name === 'fees' ? 'fp.student_id' : 'c.student_id';
      const sort = name === 'fees' ? 'ORDER BY fp.payment_date DESC' : 'ORDER BY c.created_at DESC';
      const filteredSelect = resource.select.replace(sort, `WHERE ${filter} = ? ${sort}`);
      const [rows] = await pool.execute(filteredSelect, [req.user.studentId]);
      return res.json(rows);
    }
    if (req.user.role !== 'ADMIN' && name !== 'hostels' && name !== 'rooms') {
      return res.status(403).json({ error: 'You do not have permission to view these records.' });
    }
    const [rows] = await pool.query(resource.select);
    res.json(rows);
  }));

  router.post(`/${name}`, requireLogin, asyncRoute(async (req, res) => {
    const studentCanCreate = name === 'complaints' && req.user.role === 'STUDENT';
    if (!studentCanCreate && req.user.role !== 'ADMIN') return res.status(403).json({ error: 'Administrators only.' });
    const values = resource.fields.map((field) => req.body[field]);
    if (studentCanCreate) values[0] = req.user.studentId;
    if (name === 'rooms') values[4] = req.body.status === 'MAINTENANCE' ? 'MAINTENANCE' : 'AVAILABLE';
    if (studentCanCreate) {
      const [allocations] = await pool.execute(
        'SELECT allocation_id FROM allocations WHERE student_id = ? AND room_id = ? AND status = ?',
        [req.user.studentId, req.body.room_id, 'ACTIVE']
      );
      if (!allocations.length) throw Object.assign(new Error('Complaints can only be filed for your active room.'), { status: 403 });
      values[5] = 'PENDING';
    }
    const [result] = await pool.execute(
      `INSERT INTO ${resource.table} (${resource.fields.join(', ')}) VALUES (${resource.fields.map(() => '?').join(', ')})`, values
    );
    res.status(201).json({ id: result.insertId, message: 'Record added.' });
  }));

  router.put(`/${name}/:id`, requireLogin, requireAdmin, asyncRoute(async (req, res) => {
    const values = resource.fields.map((field) => req.body[field]);
    if (name === 'rooms') {
      const [roomRows] = await pool.execute('SELECT current_occupancy FROM rooms WHERE room_id = ?', [req.params.id]);
      if (!roomRows.length) return res.status(404).json({ error: 'Room not found.' });
      values[4] = req.body.status === 'MAINTENANCE'
        ? 'MAINTENANCE'
        : Number(roomRows[0].current_occupancy) >= Number(req.body.capacity) ? 'FULL' : 'AVAILABLE';
    }
    const [result] = await pool.execute(
      `UPDATE ${resource.table} SET ${resource.fields.map((field) => `${field} = ?`).join(', ')} WHERE ${resource.key} = ?`,
      [...values, req.params.id]
    );
    if (!result.affectedRows) return res.status(404).json({ error: 'Record not found.' });
    res.json({ message: 'Record updated.' });
  }));

  router.delete(`/${name}/:id`, requireLogin, requireAdmin, asyncRoute(async (req, res) => {
    const [result] = await pool.execute(`DELETE FROM ${resource.table} WHERE ${resource.key} = ?`, [req.params.id]);
    if (!result.affectedRows) return res.status(404).json({ error: 'Record not found.' });
    res.json({ message: 'Record deleted.' });
  }));
}

router.get('/allocations', requireLogin, requireAdmin, asyncRoute(async (req, res) => {
  const [rows] = await pool.query(
    `SELECT a.*, s.name AS student_name, s.roll_number, r.room_number, h.name AS hostel_name
     FROM allocations a JOIN students s ON s.student_id = a.student_id
     JOIN rooms r ON r.room_id = a.room_id JOIN hostels h ON h.hostel_id = r.hostel_id
     ORDER BY a.allocation_date DESC`
  );
  res.json(rows);
}));

router.post('/allocations', requireLogin, requireAdmin, asyncRoute(async (req, res) => {
  const connection = await pool.getConnection();
  try {
    await connection.beginTransaction();
    await connection.query('CALL sp_allocate_room(?, ?, @allocation_message)', [req.body.student_id, req.body.room_id]);
    const [[{ message }]] = await connection.query('SELECT @allocation_message AS message');
    if (!message || !message.startsWith('SUCCESS:')) {
      throw Object.assign(new Error(message || 'The room allocation could not be completed.'), {
        status: message && /(already has an active|already full|maintenance)/i.test(message) ? 409 : 400
      });
    }
    await connection.commit();
    res.status(201).json({ message: 'Room allocated.' });
  } catch (error) {
    await connection.rollback();
    throw error;
  } finally {
    connection.release();
  }
}));

router.put('/allocations/:id', requireLogin, requireAdmin, asyncRoute(async (req, res) => {
  if (!['ACTIVE', 'VACATED'].includes(req.body.status)) return res.status(400).json({ error: 'Choose ACTIVE or VACATED.' });
  const [rows] = await pool.execute('SELECT status FROM allocations WHERE allocation_id = ?', [req.params.id]);
  if (!rows.length) return res.status(404).json({ error: 'Allocation not found.' });
  if (rows[0].status === 'VACATED' && req.body.status === 'ACTIVE') {
    return res.status(409).json({ error: 'Create a new allocation to assign this student again.' });
  }
  const [result] = await pool.execute('UPDATE allocations SET status = ? WHERE allocation_id = ?', [req.body.status, req.params.id]);
  if (!result.affectedRows) return res.status(404).json({ error: 'Allocation not found.' });
  res.json({ message: 'Allocation updated.' });
}));

router.delete('/allocations/:id', requireLogin, requireAdmin, asyncRoute(async (req, res) => {
  const connection = await pool.getConnection();
  try {
    await connection.beginTransaction();
    await connection.execute('UPDATE allocations SET status = ? WHERE allocation_id = ? AND status = ?', ['VACATED', req.params.id, 'ACTIVE']);
    const [result] = await connection.execute('DELETE FROM allocations WHERE allocation_id = ?', [req.params.id]);
    await connection.commit();
    if (!result.affectedRows) return res.status(404).json({ error: 'Allocation not found.' });
    res.json({ message: 'Allocation deleted.' });
  } catch (error) {
    await connection.rollback();
    throw error;
  } finally {
    connection.release();
  }
}));

router.get('/reports/occupancy', requireLogin, requireAdmin, asyncRoute(async (req, res) => {
  const [rows] = await pool.query(
    `SELECT h.hostel_id, h.name AS hostel_name, COUNT(v.room_id) AS rooms,
      COALESCE(SUM(v.capacity), 0) AS beds,
      COALESCE(SUM(v.current_occupancy), 0) AS occupied,
      COALESCE(SUM(v.vacant_beds), 0) AS vacant
     FROM hostels h LEFT JOIN vw_room_vacancy v ON v.hostel_id = h.hostel_id
     GROUP BY h.hostel_id, h.name ORDER BY h.name`
  );
  res.json(rows);
}));

router.get('/reports/defaulters', requireLogin, requireAdmin, asyncRoute(async (req, res) => {
  const [rows] = await pool.query(
    `SELECT s.student_id, s.roll_number, s.name, h.name AS hostel_name, r.room_number,
      r.fee_per_sem AS fee_due, COALESCE(SUM(fp.amount_paid), 0) AS fee_paid,
      r.fee_per_sem - COALESCE(SUM(fp.amount_paid), 0) AS balance
     FROM students s JOIN allocations a ON a.student_id = s.student_id AND a.status = 'ACTIVE'
     JOIN rooms r ON r.room_id = a.room_id JOIN hostels h ON h.hostel_id = r.hostel_id
     LEFT JOIN fee_payments fp ON fp.student_id = s.student_id
     GROUP BY s.student_id, s.roll_number, s.name, h.name, r.room_number, r.fee_per_sem
     HAVING balance > 0 ORDER BY balance DESC`
  );
  res.json(rows);
}));

router.get('/reports/complaints', requireLogin, requireAdmin, asyncRoute(async (req, res) => {
  const [rows] = await pool.query('SELECT status, COUNT(*) AS complaint_count FROM complaints GROUP BY status ORDER BY status');
  res.json(rows);
}));

module.exports = router;