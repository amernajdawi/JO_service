import React from 'react';
import { View, Text, Button, StyleSheet, ActivityIndicator } from 'react-native';
import { useAuth } from '../context/AuthContext';

const ProviderDashboard = ({ navigation }) => {
  const { signOut, userInfo, isLoading } = useAuth();

  const handleLogout = async () => {
    await signOut();
  };

  if (isLoading && !userInfo) { 
    return (
        <View style={styles.centeredContainer}>
            <ActivityIndicator size="large" color="#0000ff" />
        </View>
    );
  }

  return (
    <View style={styles.container}>
      <Text style={styles.title}>Provider Dashboard</Text>
      {userInfo ? (
        <Text style={styles.welcomeText}>Welcome, {userInfo.fullName || userInfo.email}!</Text>
      ) : (
        <Text style={styles.welcomeText}>Welcome, Provider!</Text>
      )}
      <Text style={styles.infoText}>Service Type: {userInfo?.serviceType || 'N/A'}</Text>
      {/* TODO: Add links to manage bookings, profile, availability etc. */}
      
      {isLoading ? (
        <ActivityIndicator size="small" color="#007AFF" style={{ marginTop: 20 }}/>
      ) : (
        <Button 
          title="Logout"
          onPress={handleLogout} 
          color="#FF3B30"
        />
      )}
    </View>
  );
};

const styles = StyleSheet.create({
  centeredContainer: { flex: 1, justifyContent: 'center', alignItems: 'center' },
  container: { flex: 1, justifyContent: 'center', alignItems: 'center', padding: 20 },
  title: { fontSize: 28, fontWeight: 'bold', marginBottom: 20 },
  welcomeText: { fontSize: 18, marginBottom: 15, textAlign: 'center' },
  infoText: { fontSize: 16, marginBottom: 30, textAlign: 'center' },
});

export default ProviderDashboard; 