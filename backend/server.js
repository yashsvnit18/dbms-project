require('dotenv').config();

const express = require('express');
const cors = require('cors');
const path = require('path');
const { testConnection } = require('./db');
const apiRoutes = require('./routes/api');

const app = express();
const port = Number(process.env.PORT || 3000);

app.use(cors());
app.use(express.json());
app.use(express.static(path.join(__dirname, '..', 'frontend')));
app.use('/api', apiRoutes);

app.get('/api/health', (req, res) => {
  res.json({ status: 'ok', database: 'MySQL' });
});

app.use((err, req, res, next) => {
  console.error(err);
  const databaseErrors = {
    ER_DUP_ENTRY: [409, 'That value already exists. Choose a unique value.'],
    ER_NO_REFERENCED_ROW_2: [400, 'Choose an existing related record.'],
    ER_ROW_IS_REFERENCED_2: [409, 'This record is still used by related records.'],
    ER_CHECK_CONSTRAINT_VIOLATED: [400, 'One or more values are outside the allowed range.'],
    ER_BAD_NULL_ERROR: [400, 'Complete all required fields.'],
    ER_DATA_TOO_LONG: [400, 'One or more values exceed the allowed length.'],
    ER_TRUNCATED_WRONG_VALUE: [400, 'One or more values have an invalid format.']
  };
  const databaseError = databaseErrors[err.code];
  const status = err.status || (databaseError && databaseError[0]) || 500;
  const message = err.status ? err.message : databaseError ? databaseError[1] : 'The request could not be completed.';
  res.status(status).json({ error: message });
});

app.listen(port, async () => {
  console.log(`Hostel Management System: http://localhost:${port}`);
  await testConnection();
});