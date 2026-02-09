const { Pool } = require('pg');
require('dotenv').config();

const db = new Pool({
  host: process.env.DB_HOST,
  user: process.env.DB_USER,
  password: process.env.DB_PASSWORD,
  database: process.env.DB_NAME,
  port: process.env.DB_PORT || 5432,
});

async function migrate() {
  const client = await db.connect();

  try {
    await client.query('BEGIN');

    console.log('📊 Step 1: Checking current conversations...');
    const countResult = await client.query('SELECT COUNT(*) as count FROM conversations');
    console.log(`   Found ${countResult.rows[0].count} existing conversations`);

    console.log('\n🔧 Step 2: Adding doctor_user_id column...');
    await client.query(`
      ALTER TABLE conversations
      ADD COLUMN IF NOT EXISTS doctor_user_id INTEGER REFERENCES users(id)
    `);
    console.log('   ✅ Column added');

    console.log('\n🔄 Step 3: Migrating existing data...');
    const updateResult = await client.query(`
      UPDATE conversations c
      SET doctor_user_id = d.user_id
      FROM doctors d
      WHERE c.doctor_id = d.id AND c.doctor_user_id IS NULL
    `);
    console.log(`   ✅ Updated ${updateResult.rowCount} rows`);

    console.log('\n✅ Step 4: Verifying migration...');
    const verifyResult = await client.query(`
      SELECT COUNT(*) as count
      FROM conversations
      WHERE doctor_user_id IS NULL
    `);

    if (parseInt(verifyResult.rows[0].count) > 0) {
      throw new Error(`Migration incomplete! ${verifyResult.rows[0].count} rows still have NULL doctor_user_id`);
    }
    console.log('   ✅ All rows migrated successfully');

    console.log('\n📋 Step 5: Sample data check...');
    const sampleResult = await client.query(`
      SELECT c.id, c.user_id, c.doctor_id, c.doctor_user_id, d.user_id as expected_user_id
      FROM conversations c
      LEFT JOIN doctors d ON c.doctor_id = d.id
      LIMIT 5
    `);

    console.log('   Sample records:');
    sampleResult.rows.forEach(row => {
      const match = row.doctor_user_id === row.expected_user_id ? '✅' : '❌';
      console.log(`   ${match} Conv ID: ${row.id}, doctor_id: ${row.doctor_id}, doctor_user_id: ${row.doctor_user_id}, expected: ${row.expected_user_id}`);
    });

    await client.query('COMMIT');
    console.log('\n🎉 Migration completed successfully!');

  } catch (error) {
    await client.query('ROLLBACK');
    console.error('\n❌ Migration failed:', error.message);
    throw error;
  } finally {
    client.release();
    await db.end();
  }
}

migrate().catch(err => {
  console.error('Fatal error:', err);
  process.exit(1);
});
