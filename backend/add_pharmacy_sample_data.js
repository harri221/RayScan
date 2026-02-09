const { Pool } = require('pg');
require('dotenv').config();

const db = new Pool({
  host: process.env.DB_HOST,
  user: process.env.DB_USER,
  password: process.env.DB_PASSWORD,
  database: process.env.DB_NAME,
  port: process.env.DB_PORT || 5432,
});

async function addPharmacySampleData() {
  try {
    console.log('🔄 Adding pharmacy sample data...');

    // First check if we have any users to associate pharmacies with
    const users = await db.query('SELECT id FROM users LIMIT 3');

    if (users.rows.length === 0) {
      console.log('❌ No users found. Please create some users first.');
      return;
    }

    // Check if pharmacies already exist
    const existingPharmacies = await db.query('SELECT COUNT(*) FROM pharmacies');

    if (existingPharmacies.rows[0].count > 0) {
      console.log('✅ Pharmacies already exist in database');
      console.log(`Found ${existingPharmacies.rows[0].count} pharmacies`);
    } else {
      // Insert sample pharmacies
      await db.query(`
        INSERT INTO pharmacies (user_id, pharmacy_name, license_number, owner_name, pharmacy_address, pharmacy_phone, operating_hours, delivery_available, latitude, longitude) VALUES
        ($1, 'Healthy Life Pharmacy', 'PH001', 'Dr. Ahmed Khan', 'Main Street, Lahore', '+92-42-111-2222', '8:00 AM - 10:00 PM', true, 31.5497, 74.3436),
        ($2, 'City Medico', 'PH002', 'Dr. Sarah Ali', 'Mall Road, Lahore', '+92-42-333-4444', '9:00 AM - 11:00 PM', true, 31.5204, 74.3587),
        ($3, 'Good Health Drugs', 'PH003', 'Dr. Hassan Shah', 'Iqbal Town, Lahore', '+92-42-555-6666', '7:00 AM - 9:00 PM', false, 31.5925, 74.3095)
      `, [users.rows[0].id, users.rows[1]?.id || users.rows[0].id, users.rows[2]?.id || users.rows[0].id]);

      console.log('✅ Sample pharmacies inserted');
    }

    // Now add products
    const existingProducts = await db.query('SELECT COUNT(*) FROM pharmacy_products');

    if (existingProducts.rows[0].count > 0) {
      console.log('✅ Pharmacy products already exist in database');
      console.log(`Found ${existingProducts.rows[0].count} products`);
      return;
    }

    console.log('🔄 Adding pharmacy product data...');

    // Get pharmacy IDs
    const pharmacies = await db.query('SELECT id FROM pharmacies ORDER BY id');

    const products = [
      // COVID-19 category
      { name: 'Paracetamol 500mg', category: 'covid19', price: 25.50 },
      { name: 'Vitamin C 1000mg', category: 'covid19', price: 85.00 },
      { name: 'Zinc Supplements', category: 'covid19', price: 120.00 },
      { name: 'Throat Lozenges', category: 'covid19', price: 45.00 },

      // Blood pressure category
      { name: 'Amlodipine 5mg', category: 'blood_pressure', price: 150.00 },
      { name: 'Lisinopril 10mg', category: 'blood_pressure', price: 180.00 },
      { name: 'Metoprolol 25mg', category: 'blood_pressure', price: 220.00 },
      { name: 'Hydrochlorothiazide', category: 'blood_pressure', price: 95.00 },

      // Pain killers category
      { name: 'Ibuprofen 400mg', category: 'pain_killers', price: 35.00 },
      { name: 'Aspirin 300mg', category: 'pain_killers', price: 28.00 },
      { name: 'Diclofenac Gel', category: 'pain_killers', price: 75.00 },
      { name: 'Tramadol 50mg', category: 'pain_killers', price: 125.00 },

      // Stomach category
      { name: 'Omeprazole 20mg', category: 'stomach', price: 110.00 },
      { name: 'Antacid Tablets', category: 'stomach', price: 42.00 },
      { name: 'Loperamide 2mg', category: 'stomach', price: 65.00 },
      { name: 'Domperidone 10mg', category: 'stomach', price: 88.00 },

      // Epilepsy category
      { name: 'Carbamazepine 200mg', category: 'epiapcy', price: 185.00 },
      { name: 'Phenytoin 100mg', category: 'epiapcy', price: 145.00 },
      { name: 'Valproic Acid 500mg', category: 'epiapcy', price: 275.00 },

      // Pancreatic category
      { name: 'Pancreatin Enzymes', category: 'pancreatics', price: 320.00 },
      { name: 'Insulin Glargine', category: 'pancreatics', price: 850.00 },
      { name: 'Metformin 500mg', category: 'pancreatics', price: 95.00 },

      // Neuro pills category
      { name: 'Sertraline 50mg', category: 'nuero_pill', price: 195.00 },
      { name: 'Escitalopram 10mg', category: 'nuero_pill', price: 165.00 },
      { name: 'Lorazepam 1mg', category: 'nuero_pill', price: 135.00 },

      // Immune system category
      { name: 'Multivitamin Complex', category: 'immune_system', price: 145.00 },
      { name: 'Vitamin D3 2000IU', category: 'immune_system', price: 125.00 },
      { name: 'Echinacea Extract', category: 'immune_system', price: 185.00 },
      { name: 'Probiotics', category: 'immune_system', price: 225.00 },

      // Other category
      { name: 'Cetrizine 10mg', category: 'other', price: 55.00 },
      { name: 'Eye Drops', category: 'other', price: 85.00 },
      { name: 'Cough Syrup', category: 'other', price: 95.00 },
      { name: 'Hand Sanitizer', category: 'other', price: 45.00 }
    ];

    // Add products to each pharmacy with some variation
    for (const pharmacy of pharmacies.rows) {
      console.log(`Adding products for pharmacy ID: ${pharmacy.id}`);

      // Each pharmacy will have 15-25 random products from the list
      const shuffledProducts = products.sort(() => 0.5 - Math.random());
      const pharmacyProducts = shuffledProducts.slice(0, Math.floor(Math.random() * 11) + 15);

      for (const product of pharmacyProducts) {
        // Add some price variation (±20%)
        const priceVariation = 1 + (Math.random() - 0.5) * 0.4;
        const finalPrice = (product.price * priceVariation).toFixed(2);

        // Random stock availability (90% chance of being in stock)
        const inStock = Math.random() > 0.1;

        await db.query(
          'INSERT INTO pharmacy_products (pharmacy_id, name, category, price, in_stock) VALUES ($1, $2, $3, $4, $5)',
          [pharmacy.id, product.name, product.category, finalPrice, inStock]
        );
      }
    }

    // Display summary
    const totalPharmacies = await db.query('SELECT COUNT(*) FROM pharmacies');
    const totalProducts = await db.query('SELECT COUNT(*) FROM pharmacy_products');
    const inStockProducts = await db.query('SELECT COUNT(*) FROM pharmacy_products WHERE in_stock = true');
    const categories = await db.query('SELECT DISTINCT category FROM pharmacy_products ORDER BY category');

    console.log('\n✅ Pharmacy data added successfully!');
    console.log(`🏪 Total pharmacies: ${totalPharmacies.rows[0].count}`);
    console.log(`📦 Total products: ${totalProducts.rows[0].count}`);
    console.log(`✅ In stock: ${inStockProducts.rows[0].count}`);
    console.log(`🏷️  Categories: ${categories.rows.map(r => r.category).join(', ')}`);

  } catch (error) {
    console.error('❌ Error adding pharmacy data:', error);
  } finally {
    await db.end();
  }
}

addPharmacySampleData();