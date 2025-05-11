import React, { useState, useEffect, useCallback } from 'react';
import {
    View,
    Text,
    FlatList,
    StyleSheet,
    ActivityIndicator,
    TouchableOpacity,
    Alert,
    Button // Import Button for Retry
} from 'react-native';
import { useFocusEffect } from '@react-navigation/native';
import { getProviderBookingsApi, updateBookingStatusApi } from '../services/bookingService';
// import { format } from 'date-fns';

// Simple Booking Item Component for Provider view
const ProviderBookingItem = ({ item, onPress, onUpdateStatus }) => {
    const formattedDate = item.serviceDateTime 
        ? new Date(item.serviceDateTime).toLocaleString()
        : 'Date not set';

    const handleStatusUpdate = (newStatus) => {
        Alert.alert(
            'Confirm Status Change',
            `Are you sure you want to change status to "${newStatus.replace('_', ' ')}"?`,
            [
                { text: 'Cancel', style: 'cancel' },
                { text: 'Confirm', onPress: () => onUpdateStatus(item._id, newStatus) }
            ]
        );
    };

    return (
        <TouchableOpacity style={styles.itemContainer} onPress={() => onPress(item._id)}>
            <View style={styles.itemHeader}>
                {/* Display User Name */}
                <Text style={styles.itemClientName}>Client: {item.user?.fullName || 'N/A'}</Text>
                <Text style={[styles.itemStatus, styles[`status${item.status.charAt(0).toUpperCase() + item.status.slice(1)}`]]}>
                    {item.status.replace('_', ' ')}
                </Text>
            </View>
            <Text style={styles.itemDate}>Date: {formattedDate}</Text>
            {item.userNotes ? <Text style={styles.itemNotes}>Notes: {item.userNotes}</Text> : null}
            
            {/* Action Buttons for Provider */}
            <View style={styles.actionContainer}>
                {item.status === 'pending' && (
                    <>
                        <Button title="Accept" onPress={() => handleStatusUpdate('accepted')} color="#28a745" />
                        <View style={{ width: 10 }} /> {/* Spacer */}
                        <Button title="Decline" onPress={() => handleStatusUpdate('declined_by_provider')} color="#dc3545" />
                    </>
                )}
                {item.status === 'accepted' && (
                     <Button title="Mark In Progress" onPress={() => handleStatusUpdate('in_progress')} color="#17a2b8" />
                )}
                {item.status === 'in_progress' && (
                     <Button title="Mark Completed" onPress={() => handleStatusUpdate('completed')} color="#007bff" />
                )}
            </View>
        </TouchableOpacity>
    );
};

const ProviderBookingsScreen = ({ navigation }) => {
    const [bookings, setBookings] = useState([]);
    const [isLoading, setIsLoading] = useState(false);
    const [error, setError] = useState(null);
    const [page, setPage] = useState(1);
    const [totalPages, setTotalPages] = useState(1);
    const [isRefreshing, setIsRefreshing] = useState(false);

    const fetchBookings = async (pageNum = 1, refreshing = false) => {
        if (refreshing) {
            setIsRefreshing(true);
        } else if (pageNum === 1) { // Only show full screen loader on initial load
             setIsLoading(true);
        }
        // Don't set loading true for subsequent pages to avoid full screen loader
        
        setError(null);
        try {
            // Use getProviderBookingsApi
            const data = await getProviderBookingsApi({ page: pageNum, limit: 10 });
            setBookings(pageNum === 1 ? data.bookings : [...bookings, ...data.bookings]);
            setPage(data.currentPage);
            setTotalPages(data.totalPages);
        } catch (err) {
            setError(err.message || 'Could not fetch bookings');
            if (pageNum === 1) { // Only show alert on initial load error
                 Alert.alert('Error', err.message || 'Could not fetch bookings');
            }
        } finally {
             if (refreshing) {
                setIsRefreshing(false);
            } else if (pageNum === 1) {
                 setIsLoading(false);
            }
        }
    };

    // Function to handle status update from item component
    const handleUpdateBookingStatus = async (bookingId, newStatus) => {
        try {
            const updatedBooking = await updateBookingStatusApi(bookingId, newStatus);
            // Update the booking list state locally
            setBookings(currentBookings => 
                currentBookings.map(b => b._id === bookingId ? updatedBooking : b)
            );
            Alert.alert('Success', `Booking status updated to ${newStatus.replace('_', ' ')}`);
        } catch (err) {   
             Alert.alert('Error', err.message || 'Failed to update booking status');
        }
    };

    useFocusEffect(
        useCallback(() => {
            fetchBookings(1);
            return () => {}; 
        }, [])
    );

    const handleRefresh = () => {
        fetchBookings(1, true);
    };

    const handleLoadMore = () => {
        if (page < totalPages && !isLoading && !isRefreshing) {
            // No loading indicator needed here as footer handles it
            fetchBookings(page + 1);
        }
    };

    const handleItemPress = (bookingId) => {
        console.log("Navigate to details for booking:", bookingId);
        // navigation.navigate('ProviderBookingDetails', { bookingId: bookingId }); // Needs specific details screen
    };

    const renderFooter = () => {
        // Show loader only when loading more pages (not initial load or refresh)
        if (isLoading && page > 1 && !isRefreshing) {
             return <ActivityIndicator style={{ marginVertical: 20 }} size="large" color="#007AFF" />;
        }
        return null; 
    };

    // Initial loading state
    if (isLoading && page === 1) { 
        return (
            <View style={styles.centeredContainer}>
                <ActivityIndicator size="large" color="#0000ff" />
            </View>
        );
    }

    // Error state only when no bookings are displayed
    if (error && bookings.length === 0) { 
        return (
            <View style={styles.centeredContainer}>
                <Text style={styles.errorText}>Error: {error}</Text>
                <Button title="Retry" onPress={() => fetchBookings(1)} />
            </View>
        );
    }

    return (
        <FlatList
            data={bookings}
            renderItem={({ item }) => 
                <ProviderBookingItem 
                    item={item} 
                    onPress={handleItemPress} 
                    onUpdateStatus={handleUpdateBookingStatus} 
                />
            }
            keyExtractor={(item) => item._id.toString()}
            contentContainerStyle={styles.listContainer}
            ListEmptyComponent={() => (
                !isLoading && !isRefreshing && <View style={styles.centeredContainer}><Text>No bookings found.</Text></View>
            )}
            onRefresh={handleRefresh}
            refreshing={isRefreshing}
            onEndReached={handleLoadMore}
            onEndReachedThreshold={0.5}
            ListFooterComponent={renderFooter}
        />
    );
};

// Styles (similar to UserBookingsScreen, adjusted slightly)
const styles = StyleSheet.create({
    listContainer: { paddingVertical: 10, paddingHorizontal: 15, flexGrow: 1 }, // flexGrow added
    centeredContainer: { flex: 1, justifyContent: 'center', alignItems: 'center', padding: 20 },
    errorText: { color: 'red', marginBottom: 10 },
    itemContainer: { backgroundColor: '#fff', padding: 15, marginBottom: 10, borderRadius: 8, borderWidth: 1, borderColor: '#eee', elevation: 2 },
    itemHeader: { flexDirection: 'row', justifyContent: 'space-between', marginBottom: 5 },
    itemClientName: { fontSize: 16, fontWeight: 'bold', color: '#333' }, // Changed from ProviderName
    itemStatus: { fontSize: 12, fontWeight: 'bold', paddingVertical: 3, paddingHorizontal: 8, borderRadius: 10, overflow: 'hidden', textTransform: 'capitalize' },
    itemDate: { fontSize: 13, color: '#777', marginBottom: 8 },
    itemNotes: { fontSize: 14, color: '#555', marginBottom: 10, fontStyle: 'italic' },
    actionContainer: { flexDirection: 'row', justifyContent: 'flex-end', marginTop: 10 },
    // Status Colors 
    statusPending: { backgroundColor: '#ffc107', color: '#333' },
    statusAccepted: { backgroundColor: '#28a745', color: '#fff' },
    statusDeclined_by_provider: { backgroundColor: '#dc3545', color: '#fff' },
    statusCancelled_by_user: { backgroundColor: '#6c757d', color: '#fff' },
    statusIn_progress: { backgroundColor: '#17a2b8', color: '#fff' },
    statusCompleted: { backgroundColor: '#007bff', color: '#fff' },
});

export default ProviderBookingsScreen; 