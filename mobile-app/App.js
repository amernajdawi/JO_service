import 'react-native-gesture-handler'; // Should be at the top
import React from 'react';
import AppNavigator from './src/navigation/AppNavigator';
import { AuthProvider } from './src/context/AuthContext';

// Remove SafeAreaView, ScrollView, StatusBar, Text, useColorScheme, View, Colors imports if no longer directly used here.
// The AppNavigator will handle the screen rendering and safe areas via NavigationContainer.

function App() {
  // The main app content is now rendered by AppNavigator
  return (
    <AuthProvider>
      <AppNavigator />
    </AuthProvider>
  );
}

// The styles StyleSheet can be removed if App.js no longer renders its own UI elements directly.
// const styles = StyleSheet.create({...});

export default App; 