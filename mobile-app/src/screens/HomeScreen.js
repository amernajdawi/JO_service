import React from 'react';
import { View, Text, Button, StyleSheet, ActivityIndicator } from 'react-native';
import { useAuth } from '../context/AuthContext'; // Import useAuth

const HomeScreen = ({ navigation }) => {
  const { signOut, userInfo, isLoading } = useAuth(); // Get signOut, userInfo, and isLoading

  const handleLogout = async () => {
    await signOut();
    // Navigation to Auth stack is handled by AppNavigator due to userToken change in AuthContext
  };

  if (isLoading && !userInfo) { // Show loading only if user info isn't available yet (e.g. initial load)
    return (
        <View style={styles.centeredContainer}>
            <ActivityIndicator size="large" color="#0000ff" />
        </View>
    );
  }

  return (
    <View style={styles.container}>
      <Text style={styles.title}>Home Screen</Text>
      {userInfo ? (
        <Text style={styles.welcomeText}>Welcome, {userInfo.fullName || userInfo.email}!</Text>
      ) : (
        <Text style={styles.welcomeText}>Welcome!</Text>
      )}
      {/* TODO: Display provider listings or user-specific content */}
      
      {isLoading ? (
        <ActivityIndicator size="small" color="#007AFF" style={{ marginTop: 20 }}/>
      ) : (
        <Button 
          title="Logout"
          onPress={handleLogout} 
          color="#FF3B30" // A red color for logout
        />
      )}
    </View>
  );
};

const styles = StyleSheet.create({
  centeredContainer: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
  },
  container: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
    padding: 20,
  },
  title: {
    fontSize: 28,
    fontWeight: 'bold',
    marginBottom: 20,
  },
  welcomeText: {
    fontSize: 18,
    marginBottom: 30,
    textAlign: 'center',
  },
});

export default HomeScreen; 