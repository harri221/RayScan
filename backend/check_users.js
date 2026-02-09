const mysql = require('mysql2/promise');
require('dotenv').config();

async function checkUsers() {
  try {
    const db = await mysql.createConnection({
      host: process.env.DB_HOST,
      user: process.env.DB_USER,
      password: process.env.DB_PASSWORD,
      database: process.env.DB_NAME,
      port: process.env.DB_PORT || 3306
    });

    const [users] = await db.execute('SELECT id, name, email, created_at FROM users ORDER BY id DESC LIMIT 5');
    console.log('📊 Latest users in database:');
    users.forEach(user => {
      console.log(`- ID: ${user.id}, Name: ${user.name}, Email: ${user.email}, Created: ${user.created_at}`);
    });

    await db.end();
  } catch (error) {
    console.error('❌ Database check error:', error);
  }
}

checkUsers();