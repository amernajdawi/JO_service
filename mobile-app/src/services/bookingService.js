import apiClient from './api';

// Fetch bookings for the logged-in user
// GET /api/bookings/user
export const getUserBookingsApi = async (params = {}) => {
    // params can include { status: 'pending', page: 1, limit: 10 }
    try {
        const response = await apiClient.get('/bookings/user', { params });
        return response.data; // { bookings, currentPage, totalPages, totalBookings }
    } catch (error) {
        const errorMessage = error.response?.data?.message || error.message || 'Failed to fetch bookings';
        throw { message: errorMessage };
    }
};

// Fetch bookings for the logged-in provider
// GET /api/bookings/provider
export const getProviderBookingsApi = async (params = {}) => {
    try {
        const response = await apiClient.get('/bookings/provider', { params });
        return response.data;
    } catch (error) {
        const errorMessage = error.response?.data?.message || error.message || 'Failed to fetch provider bookings';
        throw { message: errorMessage };
    }
};

// Fetch a single booking by ID
// GET /api/bookings/:id
export const getBookingByIdApi = async (bookingId) => {
    try {
        const response = await apiClient.get(`/bookings/${bookingId}`);
        return response.data;
    } catch (error) {
        const errorMessage = error.response?.data?.message || error.message || 'Failed to fetch booking details';
        throw { message: errorMessage };
    }
};

// User creates a booking request
// POST /api/bookings
export const createBookingApi = async (bookingData) => {
    // bookingData: { providerId, serviceDateTime, serviceLocationDetails?, userNotes? }
    try {
        const response = await apiClient.post('/bookings', bookingData);
        return response.data; // The newly created booking object
    } catch (error) {
        const errorMessage = error.response?.data?.message || error.message || 'Failed to create booking';
        const errors = error.response?.data?.errors; // For validation errors
        throw { message: errorMessage, errors };
    }
};

// Update booking status
// PATCH /api/bookings/:id/status
export const updateBookingStatusApi = async (bookingId, status) => {
    try {
        const response = await apiClient.patch(`/bookings/${bookingId}/status`, { status });
        return response.data; // The updated booking object
    } catch (error) {
        const errorMessage = error.response?.data?.message || error.message || 'Failed to update booking status';
        throw { message: errorMessage };
    }
};
 