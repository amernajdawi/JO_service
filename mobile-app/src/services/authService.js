import apiClient from './api';

export const registerUserApi = async (userData) => {
  try {
    // Backend endpoint: /api/auth/user/register
    const response = await apiClient.post('/auth/user/register', userData);
    return response.data; // Contains { message, user, token }
  } catch (error) {
    // Axios wraps errors, the actual server response is in error.response
    const errorMessage = error.response?.data?.message || error.message || 'Registration failed';
    const errors = error.response?.data?.errors; // For validation errors array
    throw { message: errorMessage, errors };
  }
};

export const loginUserApi = async (email, password) => {
  try {
    // Backend endpoint: /api/auth/user/login
    const response = await apiClient.post('/auth/user/login', { email, password });
    return response.data; // Contains { message, user, token }
  } catch (error) {
    const errorMessage = error.response?.data?.message || error.message || 'Login failed';
    throw { message: errorMessage };
  }
};

// --- Provider Auth API Calls ---

export const registerProviderApi = async (providerData) => {
  try {
    // Backend endpoint: /api/auth/provider/register
    const response = await apiClient.post('/auth/provider/register', providerData);
    return response.data; // Contains { message, provider, token }
  } catch (error) {
    const errorMessage = error.response?.data?.message || error.message || 'Provider registration failed';
    const errors = error.response?.data?.errors;
    throw { message: errorMessage, errors };
  }
};

export const loginProviderApi = async (email, password) => {
  try {
    // Backend endpoint: /api/auth/provider/login
    const response = await apiClient.post('/auth/provider/login', { email, password });
    return response.data; // Contains { message, provider, token }
  } catch (error) {
    const errorMessage = error.response?.data?.message || error.message || 'Login failed';
    throw { message: errorMessage };
  }
};

// TODO: Add registerProviderApi and loginProviderApi when backend is ready for Mongoose Providers 