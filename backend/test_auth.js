const axios = require('axios');

const BASE_URL = 'http://localhost:3002/api';

// Test user data
const testUser = {
  name: 'Test User',
  email: 'test@rayscan.com',
  password: 'testpassword123'
};

async function testSignup() {
  try {
    console.log('🧪 Testing signup endpoint...');
    const response = await axios.post(`${BASE_URL}/auth/signup`, testUser);
    console.log('✅ Signup successful:', {
      message: response.data.message,
      user: response.data.user.name,
      email: response.data.user.email,
      token: response.data.token ? 'Present' : 'Missing'
    });
    return response.data.token;
  } catch (error) {
    console.error('❌ Signup failed:', error.response?.data || error.message);
    return null;
  }
}

async function testLogin() {
  try {
    console.log('\n🧪 Testing login endpoint...');
    const response = await axios.post(`${BASE_URL}/auth/login`, {
      email: testUser.email,
      password: testUser.password
    });
    console.log('✅ Login successful:', {
      message: response.data.message,
      user: response.data.user.name,
      email: response.data.user.email,
      token: response.data.token ? 'Present' : 'Missing'
    });
    return response.data.token;
  } catch (error) {
    console.error('❌ Login failed:', error.response?.data || error.message);
    return null;
  }
}

async function testProfile(token) {
  try {
    console.log('\n🧪 Testing profile endpoint...');
    const response = await axios.get(`${BASE_URL}/user/profile`, {
      headers: {
        'Authorization': `Bearer ${token}`
      }
    });
    console.log('✅ Profile fetch successful:', {
      user: response.data.user.name,
      email: response.data.user.email,
      id: response.data.user.id
    });
    return true;
  } catch (error) {
    console.error('❌ Profile fetch failed:', error.response?.data || error.message);
    return false;
  }
}

async function testHealthCheck() {
  try {
    console.log('🧪 Testing health check endpoint...');
    const response = await axios.get(`${BASE_URL}/health`);
    console.log('✅ Health check successful:', response.data.message);
    return true;
  } catch (error) {
    console.error('❌ Health check failed:', error.response?.data || error.message);
    return false;
  }
}

async function runTests() {
  console.log('🚀 Starting authentication flow tests...\n');

  // Test health check first
  const healthOk = await testHealthCheck();
  if (!healthOk) {
    console.log('\n❌ Server is not healthy, stopping tests');
    return;
  }

  // Test signup
  let token = await testSignup();

  // Test login (should work whether signup succeeded or user already exists)
  if (!token) {
    token = await testLogin();
  }

  // Test profile if we have a token
  if (token) {
    await testProfile(token);
  }

  console.log('\n✅ Authentication flow tests completed!');
}

// Wait a moment for server to start, then run tests
setTimeout(runTests, 2000);