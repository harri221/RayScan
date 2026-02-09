const { Pool } = require('pg');
const fs = require('fs');
require('dotenv').config();

async function setupDatabase() {
  let defaultPool;
  let dbPool;

  try {
    console.log('🔄 Setting up PostgreSQL database...');

    // First connect to default postgres database to create our database
    defaultPool = new Pool({
      host: process.env.DB_HOST,
      user: process.env.DB_USER,
      password: process.env.DB_PASSWORD,
      database: 'postgres', // Connect to default database first
      port: process.env.DB_PORT || 5432,
    });

    console.log('✅ Connected to PostgreSQL');

    // Create database if it doesn't exist
    try {
      await defaultPool.query(`CREATE DATABASE ${process.env.DB_NAME}`);
      console.log(`✅ Database '${process.env.DB_NAME}' created successfully`);
    } catch (error) {
      if (error.code === '42P04') {
        console.log(`ℹ️  Database '${process.env.DB_NAME}' already exists`);
      } else {
        throw error;
      }
    }

    // Close default connection
    await defaultPool.end();

    // Now connect to our new database
    dbPool = new Pool({
      host: process.env.DB_HOST,
      user: process.env.DB_USER,
      password: process.env.DB_PASSWORD,
      database: process.env.DB_NAME,
      port: process.env.DB_PORT || 5432,
    });

    console.log(`✅ Connected to database '${process.env.DB_NAME}'`);

    // Read and execute schema
    const schema = fs.readFileSync('./database/schema.sql', 'utf8');

    // Split by semicolon and execute each statement
    const statements = schema.split(';').filter(stmt => stmt.trim().length > 0);

    console.log(`🔄 Executing ${statements.length} database statements...`);

    for (const statement of statements) {
      const trimmedStatement = statement.trim();
      if (trimmedStatement) {
        try {
          await dbPool.query(trimmedStatement);
        } catch (error) {
          // Ignore "already exists" errors
          if (!error.message.includes('already exists') && !error.message.includes('relation') && error.code !== '42P07') {
            console.error('Error executing statement:', trimmedStatement.substring(0, 100) + '...');
            throw error;
          }
        }
      }
    }

    console.log('✅ Database schema setup completed');

    // Verify tables exist
    const tablesResult = await dbPool.query(`
      SELECT table_name
      FROM information_schema.tables
      WHERE table_schema = 'public'
      ORDER BY table_name
    `);

    console.log('📋 Created tables:', tablesResult.rows.map(row => row.table_name).join(', '));

    await dbPool.end();
    console.log('🎉 Database setup completed successfully!');

  } catch (error) {
    console.error('❌ Database setup failed:', error);
    if (defaultPool) await defaultPool.end();
    if (dbPool) await dbPool.end();
    process.exit(1);
  }
}

setupDatabase();