import React, { useState, useEffect, useCallback } from 'react';
import {
    View,
    Text,
    FlatList,
    StyleSheet,
    ActivityIndicator,
    TouchableOpacity,
    Alert
} from 'react-native';
import { useFocusEffect } from '@react-navigation/native';
import { getUserBookingsApi } from '../services/bookingService';
// Import a date formatting library if needed (e.g., date-fns or moment)
// import { format } from 'date-fns'; 

// Simple Booking Item Component
const BookingItem = ({ item, onPress }) => {
    const formattedDate = item.serviceDateTime 
        ? new Date(item.serviceDateTime).toLocaleString() // Basic formatting
        : 'Date not set';

    return (
        <TouchableOpacity style={styles.itemContainer} onPress={() => onPress(item._id)}>
            <View style={styles.itemHeader}>
                <Text style={styles.itemProviderName}>Provider: {item.provider?.fullName || 'N/A'}</Text>
                <Text style={[styles.itemStatus, styles[`status${item.status.charAt(0).toUpperCase() + item.status.slice(1)}`]]}>
                    {item.status.replace('_', ' ')}
                 </Text>
            </View>
            <Text style={styles.itemServiceType}>Service: {item.provider?.serviceType || 'N/A'}</Text>
            <Text style={styles.itemDate}>Date: {formattedDate}</Text>
        </TouchableOpacity>
    );
};

const UserBookingsScreen = ({ navigation }) => {
    const [bookings, setBookings] = useState([]);
    const [isLoading, setIsLoading] = useState(false);
    const [error, setError] = useState(null);
    const [page, setPage] = useState(1);
    const [totalPages, setTotalPages] = useState(1);
    const [isRefreshing, setIsRefreshing] = useState(false);

    const fetchBookings = async (pageNum = 1, refreshing = false) => {
        if (refreshing) {
            setIsRefreshing(true);
        } else {
            setIsLoading(true);
        }
        setError(null);
        try {
            const data = await getUserBookingsApi({ page: pageNum, limit: 10 });
            setBookings(pageNum === 1 ? data.bookings : [...bookings, ...data.bookings]);
            setPage(data.currentPage);
            setTotalPages(data.totalPages);
        } catch (err) {
            setError(err.message || 'Could not fetch bookings');
            Alert.alert('Error', err.message || 'Could not fetch bookings');
        } finally {
             if (refreshing) {
                setIsRefreshing(false);
            } else {
                setIsLoading(false);
            }
        }
    };

    // useFocusEffect to refetch when screen comes into focus
    useFocusEffect(
        useCallback(() => {
            fetchBookings(1); // Fetch first page when screen focuses
            return () => {}; // Optional cleanup
        }, [])
    );

    const handleRefresh = () => {
        fetchBookings(1, true); // Fetch page 1 and set refreshing state
    };

    const handleLoadMore = () => {
        if (page < totalPages && !isLoading) {
            fetchBookings(page + 1);
        }
    };

    const handleItemPress = (bookingId) => {
        // Navigate to a Booking Details screen (to be created)
        console.log("Navigate to details for booking:", bookingId);
        // navigation.navigate('BookingDetails', { bookingId: bookingId });
    };

    const renderFooter = () => {
        if (!isLoading || isRefreshing) return null; // Don't show loader while refreshing
        return <ActivityIndicator style={{ marginVertical: 20 }} size="large" color="#007AFF" />;
    };

    if (isLoading && page === 1 && !isRefreshing) { // Show initial loading state
        return (
            <View style={styles.centeredContainer}>
                <ActivityIndicator size="large" color="#0000ff" />
            </View>
        );
    }

    if (error && bookings.length === 0) { // Show error only if no data is loaded
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
            renderItem={({ item }) => <BookingItem item={item} onPress={handleItemPress} />}
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

const styles = StyleSheet.create({
    listContainer: {
        paddingVertical: 10,
        paddingHorizontal: 15,
    },
    centeredContainer: {
        flex: 1,
        justifyContent: 'center',
        alignItems: 'center',
        padding: 20,
    },
    errorText: {
        color: 'red',
        marginBottom: 10,
    },
    itemContainer: {
        backgroundColor: '#fff',
        padding: 15,
        marginBottom: 10,
        borderRadius: 8,
        borderWidth: 1,
        borderColor: '#eee',
        shadowColor: '#000',
        shadowOffset: { width: 0, height: 1 },
        shadowOpacity: 0.1,
        shadowRadius: 2,
        elevation: 2,
    },
    itemHeader: {
        flexDirection: 'row',
        justifyContent: 'space-between',
        marginBottom: 5,
    },
    itemProviderName: {
        fontSize: 16,
        fontWeight: 'bold',
        color: '#333',
    },
    itemStatus: {
        fontSize: 12,
        fontWeight: 'bold',
        paddingVertical: 3,
        paddingHorizontal: 8,
        borderRadius: 10,
        overflow: 'hidden', // Ensures border radius works on text bg
        textTransform: 'capitalize',
    },
    itemServiceType: {
        fontSize: 14,
        color: '#555',
        marginBottom: 8,
    },
    itemDate: {
        fontSize: 13,
        color: '#777',
    },
    // Status Colors (add more as needed based on enum)
    statusPending: { backgroundColor: '#ffc107', color: '#333' },
    statusAccepted: { backgroundColor: '#28a745', color: '#fff' },
    statusDeclined_by_provider: { backgroundColor: '#dc3545', color: '#fff' },
    statusCancelled_by_user: { backgroundColor: '#6c757d', color: '#fff' },
    statusIn_progress: { backgroundColor: '#17a2b8', color: '#fff' },
    statusCompleted: { backgroundColor: '#007bff', color: '#fff' },
});

export default UserBookingsScreen; 