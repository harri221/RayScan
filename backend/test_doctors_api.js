const axios = require('axios');

async function testDoctorsAPI() {
  const baseURL = 'http://localhost:3002/api';

  try {
    console.log('🔄 Testing RayScan Doctor API...\n');

    // First, create a test user account
    console.log('1. Creating test user...');
    try {
      const signupResponse = await axios.post(`${baseURL}/auth/signup`, {
        name: 'Test User',
        email: 'testuser@rayscan.com',
        password: 'testpass123'
      });
      console.log('✅ User created successfully');
      console.log('Token:', signupResponse.data.token.substring(0, 20) + '...');

      const token = signupResponse.data.token;

      // Test getting all doctors
      console.log('\n2. Testing doctors list...');
      const doctorsResponse = await axios.get(`${baseURL}/doctors`, {
        headers: {
          'Authorization': `Bearer ${token}`,
          'Content-Type': 'application/json'
        }
      });

      console.log('✅ Doctors API working!');
      console.log(`Found ${doctorsResponse.data.doctors.length} doctors:`);

      doctorsResponse.data.doctors.forEach((doctor, index) => {
        console.log(`  ${index + 1}. ${doctor.name} - ${doctor.specialty} (Rating: ${doctor.rating})`);
      });

      // Test specialties
      console.log('\n3. Testing specialties...');
      const specialtiesResponse = await axios.get(`${baseURL}/doctors/specialties/list`, {
        headers: {
          'Authorization': `Bearer ${token}`,
          'Content-Type': 'application/json'
        }
      });

      console.log('✅ Specialties API working!');
      console.log('Available specialties:', specialtiesResponse.data.specialties);

      console.log('\n🎉 All tests passed! The doctor list should now work in the Flutter app.');

    } catch (signupError) {
      if (signupError.response?.status === 400 && signupError.response?.data?.error?.includes('already exists')) {
        console.log('ℹ️ User already exists, trying to login...');

        const loginResponse = await axios.post(`${baseURL}/auth/login`, {
          email: 'testuser@rayscan.com',
          password: 'testpass123'
        });
        console.log('✅ Login successful');

        const token = loginResponse.data.token;

        // Test getting all doctors
        console.log('\n2. Testing doctors list...');
        const doctorsResponse = await axios.get(`${baseURL}/doctors`, {
          headers: {
            'Authorization': `Bearer ${token}`,
            'Content-Type': 'application/json'
          }
        });

        console.log('✅ Doctors API working!');
        console.log(`Found ${doctorsResponse.data.doctors.length} doctors:`);

        doctorsResponse.data.doctors.forEach((doctor, index) => {
          console.log(`  ${index + 1}. ${doctor.name} - ${doctor.specialty} (Rating: ${doctor.rating})`);
        });

        console.log('\n🎉 All tests passed! The doctor list should now work in the Flutter app.');
      } else {
        throw signupError;
      }
    }

  } catch (error) {
    console.error('❌ Test failed:', error.response?.data || error.message);
  }
}

testDoctorsAPI();