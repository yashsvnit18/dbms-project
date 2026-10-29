const tokenKey = 'hostelDeskToken';
const userKey = 'hostelDeskUser';
let currentUser = null;
let activeSection = '';
let editingId = null;

const sections = {
  admin: [
    ['overview', 'Overview', '⌂'], ['students', 'Students', '♙'], ['hostels', 'Hostels', '▤'],
    ['rooms', 'Rooms', '▦'], ['allocations', 'Allocations', '↔'], ['wardens', 'Wardens', '♧'],
    ['fees', 'Fee payments', '₹'], ['complaints', 'Complaints', '!'], ['visitors', 'Visitor log', '◷'], ['reports', 'Reports', '▥']
  ],
  student: [
    ['my-details', 'My details', '♙'], ['my-fees', 'My fees', '₹'], ['my-complaints', 'My complaints', '!'], ['rooms', 'Room vacancy', '▦']
  ]
};

const moduleInfo = {
  students: { title: 'Students', path: 'students', id: 'student_id', fields: [
    ['roll_number', 'Roll number', 'text'], ['name', 'Full name', 'text'], ['gender', 'Gender', 'select', ['MALE', 'FEMALE']], ['phone', 'Phone', 'tel'], ['email', 'Email', 'email'], ['department', 'Department', 'text'], ['year_of_study', 'Year', 'number']
  ] },
  hostels: { title: 'Hostels', path: 'hostels', id: 'hostel_id', fields: [
    ['name', 'Hostel name', 'text'], ['type', 'Hostel type', 'select', ['BOYS', 'GIRLS']]
  ] },
  rooms: { title: 'Rooms', path: 'rooms', id: 'room_id', fields: [
    ['hostel_id', 'Hostel', 'relation', 'hostels', 'hostel_id', 'name'], ['room_number', 'Room number', 'text'], ['capacity', 'Bed capacity', 'number'], ['fee_per_sem', 'Semester fee', 'number'], ['status', 'Status', 'select', ['AVAILABLE', 'FULL', 'MAINTENANCE']]
  ] },
  wardens: { title: 'Wardens', path: 'wardens', id: 'warden_id', fields: [
    ['hostel_id', 'Hostel', 'relation', 'hostels', 'hostel_id', 'name'], ['name', 'Name', 'text'], ['phone', 'Phone', 'tel'], ['email', 'Email', 'email']
  ] },
  fees: { title: 'Fee payments', path: 'fees', id: 'payment_id', fields: [
    ['student_id', 'Student', 'relation', 'students', 'student_id', 'name'], ['amount_paid', 'Amount', 'number'], ['payment_date', 'Payment date', 'date'], ['payment_mode', 'Mode', 'select', ['ONLINE', 'UPI', 'CASH', 'CHALLAN']], ['receipt_no', 'Receipt number', 'text']
  ] },
  complaints: { title: 'Complaints', path: 'complaints', id: 'complaint_id', fields: [
    ['student_id', 'Student', 'relation', 'students', 'student_id', 'name'], ['room_id', 'Room', 'relation', 'rooms', 'room_id', 'room_number'], ['title', 'Title', 'text'], ['description', 'Description', 'textarea'], ['category', 'Category', 'select', ['ELECTRICAL', 'PLUMBING', 'CARPENTRY', 'CLEANLINESS', 'WIFI']], ['status', 'Status', 'select', ['PENDING', 'RESOLVED']]
  ] },
  visitors: { title: 'Visitor log', path: 'visitors', id: 'visitor_id', fields: [
    ['student_id', 'Student', 'relation', 'students', 'student_id', 'name'], ['visitor_name', 'Visitor name', 'text'], ['relation', 'Relation', 'text'], ['phone', 'Phone', 'tel'], ['visit_date', 'Visit date', 'date'], ['in_time', 'In time', 'time'], ['out_time', 'Out time', 'time']
  ] },
  allocations: { title: 'Allocations', path: 'allocations', id: 'allocation_id', fields: [
    ['student_id', 'Student', 'relation', 'students', 'student_id', 'name'], ['room_id', 'Available room', 'relation', 'rooms', 'room_id', 'room_number'], ['status', 'Status', 'select', ['ACTIVE', 'VACATED']]
  ] }
};

const loginView = document.querySelector('#login-view');
const appView = document.querySelector('#app-view');
const content = document.querySelector('#content');
const notice = document.querySelector('#notice');

function escapeHtml(value) {
  return String(value ?? '').replace(/[&<>"']/g, (char) => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' })[char]);
}

async function api(path, options = {}) {
  const response = await fetch(`/api/${path}`, {
    ...options,
    headers: { 'Content-Type': 'application/json', ...(localStorage.getItem(tokenKey) ? { Authorization: `Bearer ${localStorage.getItem(tokenKey)}` } : {}), ...options.headers }
  });
  const result = await response.json().catch(() => ({}));
  if (!response.ok) throw new Error(result.error || 'The request could not be completed.');
  return result;
}

function showNotice(message, isError = false) {
  notice.textContent = message;
  notice.className = `notice show${isError ? ' error' : ''}`;
  window.setTimeout(() => { notice.className = 'notice'; }, 3200);
}

function setSignedIn(user) {
  currentUser = user;
  loginView.hidden = true;
  appView.hidden = false;
  document.querySelector('#user-name').textContent = user.name || user.username;
  document.querySelector('#user-role').textContent = user.role;
  document.querySelector('#avatar').textContent = (user.name || user.username).slice(0, 1).toUpperCase();
  document.querySelector('#today-label').textContent = new Intl.DateTimeFormat('en-IN', { dateStyle: 'medium' }).format(new Date());
  renderNavigation();
  navigate(user.role === 'ADMIN' ? 'overview' : 'my-details');
}

document.querySelector('#login-form').addEventListener('submit', async (event) => {
  event.preventDefault();
  const form = new FormData(event.currentTarget);
  const message = document.querySelector('#login-message');
  message.textContent = '';
  try {
    const result = await api('login', { method: 'POST', body: JSON.stringify({ username: form.get('username'), password: form.get('password') }) });
    localStorage.setItem(tokenKey, result.token);
    localStorage.setItem(userKey, JSON.stringify(result.user));
    setSignedIn(result.user);
  } catch (error) {
    message.textContent = error.message;
  }
});

function renderNavigation() {
  const list = currentUser.role === 'ADMIN' ? sections.admin : sections.student;
  document.querySelector('#navigation').innerHTML = list.map(([id, label, icon]) =>
    `<button class="nav-link" type="button" data-section="${id}"><span class="nav-icon">${icon}</span>${label}</button>`
  ).join('');
  document.querySelectorAll('.nav-link').forEach((button) => button.addEventListener('click', () => navigate(button.dataset.section)));
}

const sectionTitles = Object.fromEntries([...sections.admin, ...sections.student].map(([id, label]) => [id, label]));

async function navigate(section) {
  activeSection = section;
  editingId = null;
  document.querySelectorAll('.nav-link').forEach((button) => button.classList.toggle('active', button.dataset.section === section));
  document.querySelector('#section-title').textContent = sectionTitles[section] || 'Hostel Desk';
  try {
    if (section === 'overview') await renderOverview();
    else if (section === 'reports') await renderReports();
    else if (section === 'my-details') await renderMyDetails();
    else if (section === 'my-fees') await renderStudentTable('fees', 'My fee payments');
    else if (section === 'my-complaints') await renderStudentComplaints();
    else if (section === 'rooms' && currentUser.role === 'STUDENT') await renderRoomVacancy();
    else await renderModule(section);
  } catch (error) {
    content.innerHTML = `<div class="empty-state">${escapeHtml(error.message)}</div>`;
  }
}

function buildSummary(items) {
  return `<div class="summary-grid">${items.map(([label, value]) => `<div class="summary-item"><span>${escapeHtml(label)}</span><strong>${escapeHtml(value)}</strong></div>`).join('')}</div>`;
}

async function renderOverview() {
  const [students, hostels, occupancy, complaints] = await Promise.all([
    api('students'), api('hostels'), api('reports/occupancy'), api('reports/complaints')
  ]);
  const totalBeds = occupancy.reduce((sum, row) => sum + Number(row.beds), 0);
  const occupied = occupancy.reduce((sum, row) => sum + Number(row.occupied), 0);
  const pending = complaints.find((row) => row.status === 'PENDING')?.complaint_count || 0;
  content.innerHTML = `${buildSummary([['Registered students', students.length], ['Hostel buildings', hostels.length], ['Beds occupied', `${occupied} / ${totalBeds}`]])}
    <div class="section-heading"><div><h2>Hostel occupancy</h2><p>Current room use across campus.</p></div><button class="button secondary" data-open="reports">View reports →</button></div>
    ${renderSimpleTable(occupancy, ['hostel_name', 'rooms', 'beds', 'occupied', 'vacant'], ['Hostel', 'Rooms', 'Beds', 'Occupied', 'Vacant'])}
    <p class="muted" style="font-size:11px">${pending} complaint${Number(pending) === 1 ? '' : 's'} awaiting resolution.</p>`;
  content.querySelector('[data-open="reports"]').addEventListener('click', () => navigate('reports'));
}

function renderSimpleTable(rows, keys, labels) {
  if (!rows.length) return '<div class="empty-state">No records to show.</div>';
  return `<div class="table-wrap"><table><thead><tr>${labels.map((label) => `<th>${escapeHtml(label)}</th>`).join('')}</tr></thead><tbody>${rows.map((row) => `<tr>${keys.map((key) => `<td>${escapeHtml(row[key])}</td>`).join('')}</tr>`).join('')}</tbody></table></div>`;
}

async function renderReports() {
  const [occupancy, defaulters, complaints] = await Promise.all([
    api('reports/occupancy'), api('reports/defaulters'), api('reports/complaints')
  ]);
  content.innerHTML = `<div class="report-block"><h2>Occupancy per hostel</h2>${renderSimpleTable(occupancy, ['hostel_name', 'rooms', 'beds', 'occupied', 'vacant'], ['Hostel', 'Rooms', 'Beds', 'Occupied', 'Vacant'])}</div>
    <div class="report-block"><h2>Fee defaulters</h2>${renderSimpleTable(defaulters, ['roll_number', 'name', 'hostel_name', 'room_number', 'fee_due', 'fee_paid', 'balance'], ['Roll number', 'Student', 'Hostel', 'Room', 'Due', 'Paid', 'Balance'])}</div>
    <div class="report-block"><h2>Complaints by status</h2>${renderSimpleTable(complaints, ['status', 'complaint_count'], ['Status', 'Count'])}</div>`;
}

async function renderMyDetails() {
  const student = await api('me');
  if (!student) throw new Error('No student profile is linked to this account.');
  content.innerHTML = `<div class="student-welcome"><h2>Welcome, ${escapeHtml(student.name)}</h2><p>${escapeHtml(student.roll_number)} · ${escapeHtml(student.department)}</p></div>
    ${renderSimpleTable([student], ['roll_number', 'name', 'gender', 'phone', 'email', 'department', 'year_of_study'], ['Roll number', 'Name', 'Gender', 'Phone', 'Email', 'Department', 'Year'])}`;
}

async function renderStudentTable(resource, title) {
  const rows = await api(resource);
  content.innerHTML = `<div class="section-heading"><div><h2>${escapeHtml(title)}</h2><p>Records linked to your account.</p></div></div>${rows.length ? renderSimpleTable(rows, Object.keys(rows[0]).filter((key) => !['student_id', 'room_id', 'created_at', 'user_id'].includes(key)).slice(0, 7), Object.keys(rows[0]).filter((key) => !['student_id', 'room_id', 'created_at', 'user_id'].includes(key)).slice(0, 7).map((key) => key.replaceAll('_', ' '))) : '<div class="empty-state">No records found.</div>'}`;
}

async function renderStudentComplaints() {
  const rows = await api('complaints');
  content.innerHTML = `<div class="form-panel"><h2>Submit a complaint</h2><form id="student-complaint" class="record-form">
      <label>Room<select name="room_id" required></select></label>
      <label>Title<input name="title" required maxlength="150"></label>
      <label>Category<select name="category" required>${['ELECTRICAL', 'PLUMBING', 'CARPENTRY', 'CLEANLINESS', 'WIFI'].map((value) => `<option>${value}</option>`).join('')}</select></label>
      <label>Description<textarea name="description" required></textarea></label>
      <div class="form-actions"><button class="button primary">Submit complaint</button></div>
    </form></div><div class="section-heading"><div><h2>My complaints</h2><p>Updates to your submitted issues.</p></div></div>
    ${rows.length ? renderSimpleTable(rows, ['title', 'category', 'status', 'room_number', 'created_at'], ['Title', 'Category', 'Status', 'Room', 'Created']) : '<div class="empty-state">No complaints yet.</div>'}`;
  const roomList = await api('my/rooms');
  const roomSelect = content.querySelector('[name="room_id"]');
  roomSelect.innerHTML = roomList.map((room) => `<option value="${room.room_id}">${escapeHtml(room.hostel_name)} · ${escapeHtml(room.room_number)}</option>`).join('');
  content.querySelector('#student-complaint').addEventListener('submit', async (event) => {
    event.preventDefault();
    const body = Object.fromEntries(new FormData(event.currentTarget));
    try { await api('complaints', { method: 'POST', body: JSON.stringify(body) }); showNotice('Complaint submitted.'); await navigate('my-complaints'); }
    catch (error) { showNotice(error.message, true); }
  });
}

async function renderRoomVacancy() {
  const [rooms, hostels] = await Promise.all([api('rooms'), api('hostels')]);
  const roomCards = rooms.map((room) => `<article class="room-card"><strong>${escapeHtml(room.hostel_name)} · Room ${escapeHtml(room.room_number)}</strong><p>${room.current_occupancy} of ${room.capacity} beds occupied<br>${escapeHtml(room.status)} · ₹${escapeHtml(room.fee_per_sem)} / semester</p></article>`).join('');
  content.innerHTML = `<div class="section-heading"><div><h2>Room vacancy</h2><p>${hostels.length} hostels · availability is subject to admin allocation.</p></div></div><div class="room-cards">${roomCards || '<div class="empty-state">No rooms found.</div>'}</div>`;
}

async function getOptions(source) {
  const rows = await api(source);
  return rows;
}

function formatInputValue(value, type) {
  if (value == null) return '';
  if (type === 'date') return String(value).slice(0, 10);
  if (type === 'time') return String(value).slice(0, 8);
  return String(value);
}

async function renderModule(name) {
  const info = moduleInfo[name];
  if (!info) throw new Error('This section is not available.');
  const rows = await api(info.path);
  const visibleFields = info.fields.filter(([key]) => !(name === 'complaints' && currentUser.role === 'STUDENT' && key === 'student_id'));
  const formFields = name === 'allocations' && editingId
    ? visibleFields.filter(([key]) => key === 'status')
    : visibleFields;
  const headers = [info.id, ...visibleFields.map(([key]) => key)];
  const labels = ['ID', ...visibleFields.map(([, label]) => label)];
  const canEdit = currentUser.role === 'ADMIN';
  const columns = headers.map((key) => key === info.id ? key : key);
  content.innerHTML = `${canEdit ? `<div class="form-panel"><h2 id="form-title">Add ${escapeHtml(info.title.slice(0, -1) || info.title)}</h2><form id="record-form" class="record-form">${formFields.map(([key, label]) => `<label>${escapeHtml(label)}<span class="field-slot" data-field="${key}"></span></label>`).join('')}<div class="form-actions"><button class="button primary" type="submit">Save record</button><button id="cancel-edit" class="button secondary" type="button" hidden>Cancel edit</button></div></form></div>` : ''}
    <div class="section-heading"><div><h2>${escapeHtml(info.title)}</h2><p>${rows.length} record${rows.length === 1 ? '' : 's'}</p></div></div>
    ${rows.length ? `<div class="table-wrap"><table><thead><tr>${labels.map((label) => `<th>${escapeHtml(label)}</th>`).join('')}${canEdit ? '<th>Actions</th>' : ''}</tr></thead><tbody>${rows.map((row) => `<tr>${columns.map((key) => `<td>${formatCell(key, row[key])}</td>`).join('')}${canEdit ? `<td><div class="table-actions"><button class="table-action" data-edit="${row[info.id]}" type="button">Edit</button><button class="table-action delete" data-delete="${row[info.id]}" type="button">Delete</button></div></td>` : ''}</tr>`).join('')}</tbody></table></div>` : '<div class="empty-state">No records found.</div>'}`;

  if (canEdit) {
    await fillFormFields(name, formFields);
    const form = content.querySelector('#record-form');
    form.addEventListener('submit', async (event) => {
      event.preventDefault();
      if (!form.reportValidity()) return;
      const body = Object.fromEntries(new FormData(form));
      try {
        await api(editingId ? `${info.path}/${editingId}` : info.path, { method: editingId ? 'PUT' : 'POST', body: JSON.stringify(body) });
        showNotice(editingId ? 'Record updated.' : 'Record added.');
        await navigate(name);
      } catch (error) { showNotice(error.message, true); }
    });
    content.querySelector('#cancel-edit').addEventListener('click', () => navigate(name));
    content.querySelectorAll('[data-edit]').forEach((button) => button.addEventListener('click', async () => {
      if (name === 'allocations') {
        editingId = button.dataset.edit;
        await renderModule(name);
      }
      startEdit(name, button.dataset.edit, rows);
    }));
    content.querySelectorAll('[data-delete]').forEach((button) => button.addEventListener('click', () => deleteRecord(name, button.dataset.delete)));
  }
}

function formatCell(key, value) {
  if (value == null || value === '') return '<span class="muted">—</span>';
  if (key === 'status') return `<span class="status-pill ${String(value).toLowerCase()}">${escapeHtml(value)}</span>`;
  if (value instanceof Date) value = value.toLocaleString();
  return escapeHtml(value);
}

async function fillFormFields(name, fields) {
  for (const [key, label, type, choices, valueKey, labelKey] of fields) {
    const slot = content.querySelector(`[data-field="${key}"]`);
    if (type === 'relation') {
      const rows = await getOptions(choices);
      slot.innerHTML = `<select name="${key}" required><option value="">Choose ${escapeHtml(label.toLowerCase())}</option>${rows.map((row) => `<option value="${escapeHtml(row[valueKey])}">${escapeHtml(row[labelKey])}</option>`).join('')}</select>`;
    } else if (type === 'select') {
      slot.innerHTML = `<select name="${key}" required>${choices.map((choice) => `<option value="${choice}">${choice.replaceAll('_', ' ')}</option>`).join('')}</select>`;
    } else {
      const defaultValue = type === 'date' ? new Date().toISOString().slice(0, 10) : type === 'time' ? new Date().toTimeString().slice(0, 5) : '';
      slot.innerHTML = type === 'textarea' ? `<textarea name="${key}" required></textarea>` : `<input name="${key}" type="${type}" ${type === 'number' ? 'min="0" step="any"' : ''} value="${defaultValue}" required>`;
    }
  }
  if (name === 'allocations' && !editingId) {
    const roomSelect = content.querySelector('[name="room_id"]');
    const roomRows = await getOptions('rooms');
    roomSelect.innerHTML = `<option value="">Choose available room</option>${roomRows.filter((room) => room.status === 'AVAILABLE' && Number(room.current_occupancy) < Number(room.capacity)).map((room) => `<option value="${room.room_id}">${escapeHtml(room.hostel_name)} · ${escapeHtml(room.room_number)} (${room.current_occupancy}/${room.capacity})</option>`).join('')}`;
  }
}

function startEdit(name, id, rows) {
  const info = moduleInfo[name];
  const row = rows.find((item) => String(item[info.id]) === String(id));
  if (!row) return;
  editingId = id;
  document.querySelector('#form-title').textContent = `Edit ${info.title}`;
  document.querySelector('#cancel-edit').hidden = false;
  for (const [key, , type] of info.fields) {
    const input = content.querySelector(`[name="${key}"]`);
    if (input) input.value = formatInputValue(row[key], type);
  }
  content.querySelector('#record-form').scrollIntoView({ behavior: 'smooth', block: 'center' });
}

async function deleteRecord(name, id) {
  if (!window.confirm('Delete this record? This may also remove related records.')) return;
  try { await api(`${moduleInfo[name].path}/${id}`, { method: 'DELETE' }); showNotice('Record deleted.'); await navigate(name); }
  catch (error) { showNotice(error.message, true); }
}

document.querySelector('#logout-button').addEventListener('click', async () => {
  try { await api('logout', { method: 'POST' }); } catch { /* The local session can still be cleared. */ }
  localStorage.removeItem(tokenKey);
  localStorage.removeItem(userKey);
  currentUser = null;
  appView.hidden = true;
  loginView.hidden = false;
  document.querySelector('#login-form').reset();
});

const savedUser = localStorage.getItem(userKey);
if (savedUser && localStorage.getItem(tokenKey)) {
  api('me').then(() => setSignedIn(JSON.parse(savedUser))).catch(() => {
    localStorage.removeItem(tokenKey);
    localStorage.removeItem(userKey);
  });
}