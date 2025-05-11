import axios from 'axios';
import AsyncStorage from '@react-native-async-storage/async-storage';

// Get the backend URL from an environment variable or use a default
// For React Native, environment variables are typically handled differently (e.g., react-native-config)
// For now, we'll hardcode it, but this should be configurable.
const API_BASE_URL = 'http://localhost:3000/api'; // Replace with your actual backend URL if different (e.g., your machine's IP for device testing)

const apiClient = axios.create({
  baseURL: API_BASE_URL,
  headers: {
    'Content-Type': 'application/json',
  },
});

// Optional: Interceptor to add the auth token to requests
apiClient.interceptors.request.use(
  async (config) => {
    const token = await AsyncStorage.getItem('userToken');
    if (token) {
      config.headers.Authorization = `Bearer ${token}`;
    }
    return config;
  },
  (error) => {
    return Promise.reject(error);
  }
);

// Optional: Interceptor to handle responses (e.g., for global error handling or token refresh)
apiClient.interceptors.response.use(
  (response) => {
    return response; // Pass through successful responses
  },
  (error) => {
    // Handle specific error statuses globally if needed
    if (error.response) {
      console.error('API Error:', error.response.status, error.response.data);
      if (error.response.status === 401) {
        // Example: Token expired or invalid - trigger logout
        // This would typically involve calling a logout function from AuthContext
        // For now, just log it. This logic will be refined.
        console.warn('API: Unauthorized access (401). Token might be invalid or expired.');
        // Potentially clear token and navigate to login: await AsyncStorage.removeItem('userToken'); etc.
      }
    }
    return Promise.reject(error);
  }
);

export default apiClient; 