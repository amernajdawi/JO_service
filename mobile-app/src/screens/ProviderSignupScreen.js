import React, { useState } from 'react';
import {
  View,
  Text,
  TextInput,
  StyleSheet,
  ActivityIndicator,
  TouchableOpacity,
  KeyboardAvoidingView,
  Platform,
  ScrollView,
  Alert
} from 'react-native';
import { useAuth } from '../context/AuthContext';
// Consider adding a Picker or Dropdown component for serviceType if you have many options
// import { Picker } from '@react-native-picker/picker';

const ProviderSignupScreen = ({ navigation }) => {
  // Common fields
  const [fullName, setFullName] = useState('');
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [confirmPassword, setConfirmPassword] = useState('');
  
  // Provider specific fields
  const [serviceType, setServiceType] = useState(''); // e.g., 'Plumber', 'Electrician'
  const [hourlyRate, setHourlyRate] = useState('');
  const [addressText, setAddressText] = useState(''); // Simple address for now
  // Lat/Lon might require a map input or geolocation later
  const [availabilityDetails, setAvailabilityDetails] = useState('');
  const [serviceDescription, setServiceDescription] = useState('');

  const [errorMessage, setErrorMessage] = useState('');
  const { signUpProvider, isLoading } = useAuth();

  const handleSignup = async () => {
    // Basic Validations
    if (!fullName || !email || !password || !confirmPassword || !serviceType) {
      setErrorMessage('Please fill in all required fields (Full Name, Email, Password, Service Type).');
      return;
    }
    if (password !== confirmPassword) {
      setErrorMessage('Passwords do not match.');
      return;
    }
    if (password.length < 6) {
      setErrorMessage('Password must be at least 6 characters long.');
      return;
    }
    const rate = parseFloat(hourlyRate);
    if (hourlyRate && (isNaN(rate) || rate < 0)) {
        setErrorMessage('Please enter a valid non-negative hourly rate.');
        return;
    }

    setErrorMessage('');

    const providerData = {
      fullName: fullName.trim(),
      email: email.trim().toLowerCase(),
      password,
      serviceType: serviceType.trim(),
      hourlyRate: hourlyRate ? rate : undefined,
      // locationLatitude, locationLongitude - Needs map/geo input
      addressText: addressText.trim(),
      availabilityDetails: availabilityDetails.trim(),
      serviceDescription: serviceDescription.trim(),
    };

    const result = await signUpProvider(providerData);
    if (!result.success) {
      let displayError = result.error || 'Registration failed. Please try again.';
      if (result.validationErrors && result.validationErrors.length > 0) {
        displayError = result.validationErrors.join('\n');
      }
      setErrorMessage(displayError);
    } else {
      Alert.alert('Signup Successful', 'Your provider account is registered.');
      // Navigation handled by AuthContext state change
    }
  };

  return (
    <KeyboardAvoidingView
      behavior={Platform.OS === "ios" ? "padding" : "height"}
      style={styles.keyboardAvoidingContainer}
    >
      <ScrollView contentContainerStyle={styles.scrollContainer}>
        <View style={styles.container}>
          <Text style={styles.title}>Provider Signup</Text>
          <Text style={styles.subtitle}>Register your service</Text>

          {errorMessage ? <Text style={styles.errorText}>{errorMessage}</Text> : null}

          <TextInput style={styles.input} placeholder="Full Name *" value={fullName} onChangeText={setFullName} autoCapitalize="words" />
          <TextInput style={styles.input} placeholder="Email Address *" value={email} onChangeText={setEmail} keyboardType="email-address" autoCapitalize="none" autoCorrect={false} />
          <TextInput style={styles.input} placeholder="Service Type * (e.g., Plumber)" value={serviceType} onChangeText={setServiceType} autoCapitalize="words" />
          <TextInput style={styles.input} placeholder="Hourly Rate (Optional, e.g., 45.50)" value={hourlyRate} onChangeText={setHourlyRate} keyboardType="numeric" />
          <TextInput style={styles.input} placeholder="Main Service Address (Optional)" value={addressText} onChangeText={setAddressText} />
          <TextInput style={styles.input} placeholder="Availability (e.g., Mon-Fri 9am-5pm)" value={availabilityDetails} onChangeText={setAvailabilityDetails} />
          <TextInput style={[styles.input, styles.textArea]} placeholder="Service Description (Optional)" value={serviceDescription} onChangeText={setServiceDescription} multiline numberOfLines={3} />
          <TextInput style={styles.input} placeholder="Password (min. 6 chars) *" value={password} onChangeText={setPassword} secureTextEntry />
          <TextInput style={styles.input} placeholder="Confirm Password *" value={confirmPassword} onChangeText={setConfirmPassword} secureTextEntry />

          {isLoading ? (
            <ActivityIndicator size="large" color="#007AFF" style={styles.loader} />
          ) : (
            <TouchableOpacity style={styles.signupButton} onPress={handleSignup}>
              <Text style={styles.signupButtonText}>Register as Provider</Text>
            </TouchableOpacity>
          )}

          <View style={styles.footer}>
            <Text style={styles.footerText}>Already have an account? </Text>
            <TouchableOpacity onPress={() => navigation.goBack()}> 
              <Text style={styles.loginText}>Log In</Text>
            </TouchableOpacity>
          </View>
        </View>
      </ScrollView>
    </KeyboardAvoidingView>
  );
};

// Reuse styles from SignupScreen or create specific ones
const styles = StyleSheet.create({
  keyboardAvoidingContainer: { flex: 1 },
  scrollContainer: { flexGrow: 1, justifyContent: 'center' },
  container: { justifyContent: 'center', alignItems: 'center', padding: 20, backgroundColor: '#f7f7f7' },
  title: { fontSize: 28, fontWeight: 'bold', color: '#333', marginBottom: 10 },
  subtitle: { fontSize: 16, color: '#666', marginBottom: 25 },
  input: {
    width: '100%', height: 50, backgroundColor: '#fff', borderWidth: 1, borderColor: '#ddd',
    borderRadius: 8, paddingHorizontal: 15, marginBottom: 12, fontSize: 16
  },
  textArea: {
    height: 80, // Adjust height for multiline
    textAlignVertical: 'top', // Align text to top for multiline
    paddingTop: 15,
  },
  signupButton: {
    width: '100%', backgroundColor: '#28A745', paddingVertical: 15, borderRadius: 8,
    alignItems: 'center', marginTop: 10
  },
  signupButtonText: { color: '#fff', fontSize: 18, fontWeight: 'bold' },
  errorText: { color: 'red', marginBottom: 15, textAlign: 'center' },
  loader: { marginVertical: 20 },
  footer: { flexDirection: 'row', marginTop: 20 },
  footerText: { fontSize: 14, color: '#666' },
  loginText: { fontSize: 14, color: '#007AFF', fontWeight: 'bold' },
});

export default ProviderSignupScreen; 