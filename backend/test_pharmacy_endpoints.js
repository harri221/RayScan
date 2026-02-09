const axios = require('axios');

const BASE_URL = 'http://localhost:3002/api';

async function testPharmacyEndpoints() {
  try {
    console.log('🔄 Testing pharmacy API endpoints...');

    // First, create a test user and get a token
    const signupData = {
      name: 'Test User',
      email: 'test@example.com',
      password: 'password123'
    };

    let token;
    try {
      const signupResponse = await axios.post(`${BASE_URL}/auth/signup`, signupData);
      token = signupResponse.data.token;
      console.log('✅ Test user created and logged in');
    } catch (error) {
      if (error.response?.status === 400 && error.response.data.error.includes('already exists')) {
        // User exists, try to login
        const loginResponse = await axios.post(`${BASE_URL}/auth/login`, {
          email: signupData.email,
          password: signupData.password
        });
        token = loginResponse.data.token;
        console.log('✅ Test user logged in');
      } else {
        throw error;
      }
    }

    const headers = {
      'Authorization': `Bearer ${token}`,
      'Content-Type': 'application/json'
    };

    // Test 1: Get all pharmacies
    console.log('\n🔧 Testing GET /pharmacy...');
    const pharmaciesResponse = await axios.get(`${BASE_URL}/pharmacy`, { headers });
    console.log(`✅ Found ${pharmaciesResponse.data.pharmacies.length} pharmacies`);
    pharmaciesResponse.data.pharmacies.forEach(pharmacy => {
      console.log(`   - ${pharmacy.name} at ${pharmacy.address}`);
    });

    if (pharmaciesResponse.data.pharmacies.length > 0) {
      const firstPharmacy = pharmaciesResponse.data.pharmacies[0];

      // Test 2: Get pharmacy by ID
      console.log(`\n🔧 Testing GET /pharmacy/${firstPharmacy.id}...`);
      const pharmacyDetailResponse = await axios.get(`${BASE_URL}/pharmacy/${firstPharmacy.id}`, { headers });
      const pharmacy = pharmacyDetailResponse.data.pharmacy;
      console.log(`✅ Pharmacy details: ${pharmacy.name}`);
      console.log(`   - Products: ${pharmacy.products.length}`);

      // Test 3: Get product categories
      console.log('\n🔧 Testing GET /pharmacy/categories/list...');
      const categoriesResponse = await axios.get(`${BASE_URL}/pharmacy/categories/list`, { headers });
      console.log(`✅ Found ${categoriesResponse.data.categories.length} categories:`);
      console.log(`   - ${categoriesResponse.data.categories.join(', ')}`);

      // Test 4: Search pharmacies
      console.log('\n🔧 Testing GET /pharmacy/search/health...');
      const searchResponse = await axios.get(`${BASE_URL}/pharmacy/search/health`, { headers });
      console.log(`✅ Search results: ${searchResponse.data.pharmacies.length} pharmacies found`);

      // Test 5: Search products
      console.log('\n🔧 Testing GET /pharmacy/products/search/paracetamol...');
      const productSearchResponse = await axios.get(`${BASE_URL}/pharmacy/products/search/paracetamol`, { headers });
      console.log(`✅ Product search results: ${productSearchResponse.data.products.length} products found`);

      // Test 6: Get pharmacy products
      console.log(`\n🔧 Testing GET /pharmacy/${firstPharmacy.id}/products...`);
      const productsResponse = await axios.get(`${BASE_URL}/pharmacy/${firstPharmacy.id}/products`, { headers });
      console.log(`✅ Pharmacy products: ${productsResponse.data.products.length} products`);
    }

    console.log('\n🎉 All pharmacy API endpoints tested successfully!');

  } catch (error) {
    console.error('❌ Error testing pharmacy endpoints:', error.response?.data || error.message);
  }
}

testPharmacyEndpoints();