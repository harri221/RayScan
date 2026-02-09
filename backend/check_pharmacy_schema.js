const { Pool } = require('pg');
require('dotenv').config();

const db = new Pool({
  host: process.env.DB_HOST,
  user: process.env.DB_USER,
  password: process.env.DB_PASSWORD,
  database: process.env.DB_NAME,
  port: process.env.DB_PORT || 5432,
});

async function checkPharmacySchema() {
  try {
    console.log('🔍 Checking pharmacy table schema...');

    // Check pharmacies table columns
    const pharmaciesColumns = await db.query(`
      SELECT column_name, data_type, is_nullable
      FROM information_schema.columns
      WHERE table_name = 'pharmacies'
      ORDER BY ordinal_position
    `);

    console.log('🏪 Pharmacies table columns:');
    pharmaciesColumns.rows.forEach(row => {
      console.log(`  - ${row.column_name}: ${row.data_type} (nullable: ${row.is_nullable})`);
    });

    // Check pharmacy_products table columns
    const productsColumns = await db.query(`
      SELECT column_name, data_type, is_nullable
      FROM information_schema.columns
      WHERE table_name = 'pharmacy_products'
      ORDER BY ordinal_position
    `);

    console.log('\n💊 Pharmacy products table columns:');
    productsColumns.rows.forEach(row => {
      console.log(`  - ${row.column_name}: ${row.data_type} (nullable: ${row.is_nullable})`);
    });

    // Check existing data
    const pharmacyCount = await db.query('SELECT COUNT(*) FROM pharmacies');
    const productCount = await db.query('SELECT COUNT(*) FROM pharmacy_products');

    console.log(`\n📊 Data count:`);
    console.log(`  - Pharmacies: ${pharmacyCount.rows[0].count}`);
    console.log(`  - Products: ${productCount.rows[0].count}`);

    if (pharmacyCount.rows[0].count > 0) {
      const samplePharmacies = await db.query('SELECT * FROM pharmacies LIMIT 3');
      console.log('\n🏪 Sample pharmacies:');
      samplePharmacies.rows.forEach(pharmacy => {
        console.log(`  - ID: ${pharmacy.id}, Name: ${pharmacy.name || pharmacy.pharmacy_name || 'Unknown'}`);
      });
    }

  } catch (error) {
    console.error('❌ Error checking schema:', error);
  } finally {
    await db.end();
  }
}

checkPharmacySchema();