const axios = require('axios');

// Use your existing backend API instead of direct database access
const BACKEND_API_URL = process.env.BACKEND_API_URL || 'https://skillsocket-backend.onrender.com';

// Function to find users with complementary skills using your existing API
const findComplementaryUsers = async (skillsRequired = [], skillsOffered = []) => {
  try {
    console.log('🔍 Searching for users via backend API...');
    console.log('- Want to learn:', skillsRequired);
    console.log('- Can teach:', skillsOffered);
    
    // Use the first skill from each array for the API call
    const requiredSkill = skillsRequired && skillsRequired.length > 0 ? skillsRequired[0] : '';
    const offeredSkill = skillsOffered && skillsOffered.length > 0 ? skillsOffered[0] : '';
    
    if (!requiredSkill && !offeredSkill) {
      console.log('⚠️ No skills provided');
      return [];
    }
    
    // Call your existing skill matching API
    const apiUrl = `${BACKEND_API_URL}/api/users/match`;
    const params = {};
    
    if (requiredSkill) params.required = requiredSkill;
    if (offeredSkill) params.offered = offeredSkill;
    
    console.log('🌐 Calling API:', apiUrl, 'with params:', params);
    
    const response = await axios.get(apiUrl, {
      params: params,
      timeout: 8000 // 8 second timeout
    });
    
    if (response.data && Array.isArray(response.data)) {
      console.log(`✅ API returned ${response.data.length} users`);
      return response.data;
    } else {
      console.log('⚠️ API returned unexpected format:', response.data);
      return [];
    }
    
  } catch (error) {
    console.error('❌ API call failed:', error.message);
    
    // If API fails, return empty array with helpful message
    if (error.code === 'ECONNREFUSED' || error.code === 'ETIMEDOUT') {
      throw new Error('Backend API is not accessible. Please check if the backend server is running.');
    } else if (error.response) {
      throw new Error(`Backend API error: ${error.response.status} - ${error.response.statusText}`);
    } else {
      throw new Error(`Network error: ${error.message}`);
    }
  }
};

// Simple function to test API connectivity
const testConnection = async () => {
  try {
    console.log('🧪 Testing backend API connectivity...');
    
    const response = await axios.get(`${BACKEND_API_URL}/api/health`, {
      timeout: 5000
    });
    
    if (response.status === 200) {
      console.log('✅ Backend API is accessible');
      console.log('📊 API Health:', response.data);
      return { success: true, apiStatus: response.data };
    } else {
      throw new Error(`API returned status ${response.status}`);
    }
  } catch (error) {
    console.error('❌ API test failed:', error.message);
    return { success: false, error: error.message };
  }
};

module.exports = {
  findComplementaryUsers,
  testConnection
};