const { Pool } = require('pg');
require('dotenv').config();

const db = new Pool({
  host: process.env.DB_HOST,
  user: process.env.DB_USER,
  password: process.env.DB_PASSWORD,
  database: process.env.DB_NAME,
  port: process.env.DB_PORT || 5432,
});

async function createCallLogsTable() {
  const client = await db.connect();

  try {
    await client.query('BEGIN');

    console.log('📊 Creating call_logs table...');

    await client.query(`
      CREATE TABLE IF NOT EXISTS call_logs (
        id SERIAL PRIMARY KEY,
        conversation_id INTEGER REFERENCES conversations(id) ON DELETE CASCADE,
        caller_user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
        receiver_user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
        call_type VARCHAR(10) NOT NULL CHECK (call_type IN ('audio', 'video')),
        status VARCHAR(20) DEFAULT 'initiated' CHECK (status IN ('initiated', 'ringing', 'answered', 'missed', 'rejected', 'ended', 'failed')),
        channel_name VARCHAR(255),
        duration INTEGER DEFAULT 0,
        started_at TIMESTAMP,
        ended_at TIMESTAMP,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      )
    `);

    console.log('✅ call_logs table created successfully');

    // Create indexes for faster queries
    console.log('📊 Creating indexes...');

    await client.query(`
      CREATE INDEX IF NOT EXISTS idx_call_logs_caller
      ON call_logs(caller_user_id)
    `);

    await client.query(`
      CREATE INDEX IF NOT EXISTS idx_call_logs_receiver
      ON call_logs(receiver_user_id)
    `);

    await client.query(`
      CREATE INDEX IF NOT EXISTS idx_call_logs_conversation
      ON call_logs(conversation_id)
    `);

    await client.query(`
      CREATE INDEX IF NOT EXISTS idx_call_logs_status
      ON call_logs(status)
    `);

    console.log('✅ Indexes created successfully');

    await client.query('COMMIT');
    console.log('\n🎉 call_logs table setup completed!');

  } catch (error) {
    await client.query('ROLLBACK');
    console.error('\n❌ Error:', error.message);
    throw error;
  } finally {
    client.release();
    await db.end();
  }
}

createCallLogsTable().catch(err => {
  console.error('Fatal error:', err);
  process.exit(1);
});
