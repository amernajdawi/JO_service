import React from 'react';
import { NavigationContainer } from '@react-navigation/native';
import { createStackNavigator } from '@react-navigation/stack';
import { createBottomTabNavigator } from '@react-navigation/bottom-tabs'; // Import Tab Navigator
import { useAuth } from '../context/AuthContext'; // Import useAuth
// Icons library (optional, but recommended for tabs)
// import Ionicons from 'react-native-vector-icons/Ionicons';

// Screens
import AuthLoadingScreen from '../screens/AuthLoadingScreen'; // This will be a generic loading screen
import LoginScreen from '../screens/LoginScreen';
import SignupScreen from '../screens/SignupScreen'; // Import SignupScreen
import ProviderSignupScreen from '../screens/ProviderSignupScreen'; // Import ProviderSignupScreen
import HomeScreen from '../screens/HomeScreen'; // User Home/Dashboard
import UserBookingsScreen from '../screens/UserBookingsScreen'; // User Bookings List
import UserProfileScreen from '../screens/UserProfileScreen'; // User Profile Screen
import ProviderDashboard from '../screens/ProviderDashboard'; // Provider Home
import ProviderBookingsScreen from '../screens/ProviderBookingsScreen'; // Import Provider Bookings
import ProviderProfileScreen from '../screens/ProviderProfileScreen'; // Import Provider Profile Screen
// Import other screens like SignupScreen, ProviderDetailsScreen etc. as they are created

const AuthStack = createStackNavigator();
const UserTab = createBottomTabNavigator(); // User Tab Navigator
const ProviderTab = createBottomTabNavigator(); // Provider Tab Navigator

const AuthStackNavigator = () => {
  return (
    <AuthStack.Navigator screenOptions={{ headerShown: false }}>
      <AuthStack.Screen name="Login" component={LoginScreen} />
      <AuthStack.Screen name="Signup" component={SignupScreen} />
      <AuthStack.Screen name="ProviderSignup" component={ProviderSignupScreen} /> {/* Add ProviderSignupScreen */}
      {/* <AuthStack.Screen name="ForgotPassword" component={ForgotPasswordScreen} /> */}
    </AuthStack.Navigator>
  );
};

const UserMainNavigator = () => { // Now uses Tabs
  return (
    // Screen options can configure tab bar appearance, icons etc.
    // Example with icons (requires react-native-vector-icons setup):
    // screenOptions={({ route }) => ({
    //   tabBarIcon: ({ focused, color, size }) => {
    //     let iconName;
    //     if (route.name === 'Home') iconName = focused ? 'home' : 'home-outline';
    //     else if (route.name === 'MyBookings') iconName = focused ? 'list' : 'list-outline';
    //     // else if (route.name === 'Profile') iconName = focused ? 'person' : 'person-outline';
    //     return <Ionicons name={iconName} size={size} color={color} />;
    //   },
    //   tabBarActiveTintColor: '#007AFF', 
    //   tabBarInactiveTintColor: 'gray',
    // })}
    <UserTab.Navigator>
      <UserTab.Screen 
        name="Home" 
        component={HomeScreen} 
        options={{ title: 'Home' /* tabBarLabel: 'Home' */ }} 
      />
      <UserTab.Screen 
        name="MyBookings" 
        component={UserBookingsScreen} 
        options={{ title: 'My Bookings' }} 
      />
      <UserTab.Screen 
        name="UserProfile" 
        component={UserProfileScreen} 
        options={{ title: 'My Profile' }} 
      />
    </UserTab.Navigator>
  );
};

const ProviderMainNavigator = () => { // Now uses Tabs
  return (
    // Add screenOptions for icons later if desired
    <ProviderTab.Navigator>
      <ProviderTab.Screen 
        name="ProviderDashboard" 
        component={ProviderDashboard} 
        options={{ title: 'Dashboard' }} 
      />
      <ProviderTab.Screen 
        name="ProviderBookings" 
        component={ProviderBookingsScreen} 
        options={{ title: 'Bookings' }} 
      />
      <ProviderTab.Screen 
        name="ProviderProfile" 
        component={ProviderProfileScreen} 
        options={{ title: 'My Profile' }} 
      />
      {/* Add other PROVIDER tabs here (e.g., Availability) */}
    </ProviderTab.Navigator>
  );
};

const AppNavigator = () => {
  const { userToken, isLoading, userType } = useAuth(); // Get userType

  if (isLoading) {
    // We haven't finished checking for the token yet
    // You can render any loading Skeletons here
    return <AuthLoadingScreen />;
  }

  return (
    <NavigationContainer>
      {userToken == null ? (
        // No token found, user isn't signed in
        <AuthStackNavigator />
      ) : (
        // Conditionally render main stacks based on userType
        userType === 'provider' 
          ? <ProviderMainNavigator /> // Use the new Provider Navigator
          : <UserMainNavigator /> // Use the renamed User Navigator
      )}
    </NavigationContainer>
  );
};

export default AppNavigator; 