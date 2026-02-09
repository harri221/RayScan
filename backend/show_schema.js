const { Pool } = require('pg');
require('dotenv').config();

async function showCompleteSchema() {
  const pool = new Pool({
    host: process.env.DB_HOST,
    user: process.env.DB_USER,
    password: process.env.DB_PASSWORD,
    database: process.env.DB_NAME,
    port: process.env.DB_PORT || 5432,
  });

  try {
    console.log('🔍 COMPLETE DATABASE SCHEMA ANALYSIS\n');

    // Get all tables
    const tables = await pool.query(`
      SELECT table_name
      FROM information_schema.tables
      WHERE table_schema = 'public'
      ORDER BY table_name
    `);

    console.log(`📋 Found ${tables.rows.length} tables:\n`);

    for (const table of tables.rows) {
      const tableName = table.table_name;
      console.log(`\n📄 TABLE: ${tableName.toUpperCase()}`);
      console.log('=' .repeat(50));

      // Get columns for this table
      const columns = await pool.query(`
        SELECT
          column_name,
          data_type,
          character_maximum_length,
          is_nullable,
          column_default
        FROM information_schema.columns
        WHERE table_name = $1
        ORDER BY ordinal_position
      `, [tableName]);

      columns.rows.forEach(col => {
        const length = col.character_maximum_length ? `(${col.character_maximum_length})` : '';
        const nullable = col.is_nullable === 'YES' ? 'NULL' : 'NOT NULL';
        const defaultVal = col.column_default ? ` DEFAULT ${col.column_default}` : '';
        console.log(`  ${col.column_name.padEnd(20)} ${(col.data_type + length).padEnd(25)} ${nullable}${defaultVal}`);
      });

      // Get constraints for this table
      const constraints = await pool.query(`
        SELECT
          tc.constraint_name,
          tc.constraint_type,
          kcu.column_name,
          ccu.table_name AS foreign_table_name,
          ccu.column_name AS foreign_column_name
        FROM information_schema.table_constraints tc
        LEFT JOIN information_schema.key_column_usage kcu
          ON tc.constraint_name = kcu.constraint_name
        LEFT JOIN information_schema.constraint_column_usage ccu
          ON tc.constraint_name = ccu.constraint_name
        WHERE tc.table_name = $1
        ORDER BY tc.constraint_type, tc.constraint_name
      `, [tableName]);

      if (constraints.rows.length > 0) {
        console.log('\n  CONSTRAINTS:');
        constraints.rows.forEach(constraint => {
          const foreign = constraint.foreign_table_name
            ? ` → ${constraint.foreign_table_name}.${constraint.foreign_column_name}`
            : '';
          console.log(`    ${constraint.constraint_type}: ${constraint.constraint_name} (${constraint.column_name})${foreign}`);
        });
      }

      // Get sample data (first 3 rows)
      try {
        const sampleData = await pool.query(`SELECT * FROM ${tableName} LIMIT 3`);
        if (sampleData.rows.length > 0) {
          console.log('\n  SAMPLE DATA:');
          sampleData.rows.forEach((row, index) => {
            console.log(`    Row ${index + 1}:`, JSON.stringify(row, null, 2).substring(0, 200) + '...');
          });
        }
      } catch (error) {
        console.log('\n  SAMPLE DATA: (Error reading data)');
      }
    }

    console.log('\n\n🎯 KEY TABLES FOR AUTHENTICATION:');
    console.log('=' .repeat(50));

    // Focus on users table
    if (tables.rows.some(t => t.table_name === 'users')) {
      const userColumns = await pool.query(`
        SELECT column_name, data_type, is_nullable, column_default
        FROM information_schema.columns
        WHERE table_name = 'users'
        ORDER BY ordinal_position
      `);

      console.log('\n👤 USERS TABLE - Column Mapping for Auth:');
      userColumns.rows.forEach(col => {
        const suggestion = col.column_name === 'full_name' ? ' → use for "name"' :
                          col.column_name === 'password_hash' ? ' → use for "password"' :
                          col.column_name === 'email' ? ' → matches "email"' : '';
        console.log(`  ${col.column_name.padEnd(20)} ${col.data_type.padEnd(20)} ${suggestion}`);
      });
    }

    // Check doctors table
    if (tables.rows.some(t => t.table_name === 'doctors')) {
      const doctorColumns = await pool.query(`
        SELECT column_name, data_type
        FROM information_schema.columns
        WHERE table_name = 'doctors'
        ORDER BY ordinal_position
      `);

      console.log('\n👨‍⚕️ DOCTORS TABLE - Columns:');
      doctorColumns.rows.forEach(col => {
        console.log(`  ${col.column_name.padEnd(20)} ${col.data_type}`);
      });
    }

  } catch (error) {
    console.error('❌ Error analyzing schema:', error.message);
  } finally {
    await pool.end();
  }
}

showCompleteSchema();