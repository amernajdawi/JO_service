import React from 'react';
import { View, Text, StyleSheet, ActivityIndicator } from 'react-native';

const AuthLoadingScreen = ({ navigation }) => {
  // TODO: Add logic here to check for an existing token
  // For now, we'll just navigate to Login after a delay
  React.useEffect(() => {
    setTimeout(() => {
      // navigation.navigate('Login'); // Example navigation
      console.log("AuthLoadingScreen: TODO - Implement token check and navigation");
      navigation.replace('Login'); // Use replace to prevent going back to this screen
    }, 1500);
  }, [navigation]);

  return (
    <View style={styles.container}>
      <ActivityIndicator size="large" />
      <Text style={styles.text}>Loading...</Text>
    </View>
  );
};

const styles = StyleSheet.create({
  container: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
    backgroundColor: '#f5f5f5',
  },
  text: {
    marginTop: 10,
    fontSize: 16,
  },
});

export default AuthLoadingScreen; 