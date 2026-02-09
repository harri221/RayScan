const { Pool } = require('pg');
require('dotenv').config();

const db = new Pool({
  host: process.env.DB_HOST,
  user: process.env.DB_USER,
  password: process.env.DB_PASSWORD,
  database: process.env.DB_NAME,
  port: process.env.DB_PORT || 5432,
});

async function createPharmacyTables() {
  try {
    console.log('🔄 Creating pharmacy tables...');

    // Create pharmacies table
    await db.query(`
      CREATE TABLE IF NOT EXISTS pharmacies (
        id SERIAL PRIMARY KEY,
        name VARCHAR(100) NOT NULL,
        address TEXT NOT NULL,
        phone VARCHAR(20),
        latitude DECIMAL(10, 8),
        longitude DECIMAL(11, 8),
        is_open BOOLEAN DEFAULT TRUE,
        opening_hours JSONB,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      )
    `);
    console.log('✅ Pharmacies table created');

    // Create pharmacy_products table
    await db.query(`
      CREATE TABLE IF NOT EXISTS pharmacy_products (
        id SERIAL PRIMARY KEY,
        pharmacy_id INTEGER NOT NULL REFERENCES pharmacies(id) ON DELETE CASCADE,
        name VARCHAR(100) NOT NULL,
        category VARCHAR(50) NOT NULL CHECK (category IN ('covid19', 'blood_pressure', 'pain_killers', 'stomach', 'epiapcy', 'pancreatics', 'nuero_pill', 'immune_system', 'other')),
        price DECIMAL(10,2),
        in_stock BOOLEAN DEFAULT TRUE,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      )
    `);
    console.log('✅ Pharmacy products table created');

    // Insert sample pharmacies
    const existingPharmacies = await db.query('SELECT COUNT(*) FROM pharmacies');

    if (existingPharmacies.rows[0].count == 0) {
      await db.query(`
        INSERT INTO pharmacies (name, address, phone, latitude, longitude, is_open) VALUES
        ('Healthy Life Pharmacy', 'Main Street, Lahore', '+92-xxx-xxx-xxxx', 31.5497, 74.3436, TRUE),
        ('City Medico', 'Mall Road, Lahore', '+92-xxx-xxx-xxxx', 31.5204, 74.3587, TRUE),
        ('Good Health Drugs', 'Iqbal Town, Lahore', '+92-xxx-xxx-xxxx', 31.5925, 74.3095, TRUE)
      `);
      console.log('✅ Sample pharmacies inserted');
    } else {
      console.log('ℹ️  Pharmacies already exist');
    }

    console.log('🎉 Pharmacy tables setup completed!');

  } catch (error) {
    console.error('❌ Error creating pharmacy tables:', error);
  } finally {
    await db.end();
  }
}

createPharmacyTables();