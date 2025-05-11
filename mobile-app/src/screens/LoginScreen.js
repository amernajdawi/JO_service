import React, { useState } from 'react';
import {
  View,
  Text,
  TextInput,
  Button,
  StyleSheet,
  ActivityIndicator,
  Alert,
  TouchableOpacity,
  KeyboardAvoidingView,
  Platform,
} from 'react-native';
import { useAuth } from '../context/AuthContext';

// Simple Segmented Control simulation
const RoleSelector = ({ selectedRole, onSelectRole }) => {
  return (
    <View style={styles.roleSelectorContainer}>
      <TouchableOpacity 
        style={[styles.roleButton, selectedRole === 'user' && styles.roleButtonSelected]}
        onPress={() => onSelectRole('user')}
      >
        <Text style={[styles.roleButtonText, selectedRole === 'user' && styles.roleButtonTextSelected]}>User</Text>
      </TouchableOpacity>
      <TouchableOpacity 
        style={[styles.roleButton, selectedRole === 'provider' && styles.roleButtonSelected]}
        onPress={() => onSelectRole('provider')}
      >
        <Text style={[styles.roleButtonText, selectedRole === 'provider' && styles.roleButtonTextSelected]}>Provider</Text>
      </TouchableOpacity>
    </View>
  );
};

const LoginScreen = ({ navigation }) => {
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [selectedRole, setSelectedRole] = useState('user'); // Default to 'user'
  const [errorMessage, setErrorMessage] = useState('');
  const { signInUser, signInProvider, isLoading } = useAuth();

  const handleLogin = async () => {
    if (!email || !password) {
      setErrorMessage('Please enter both email and password.');
      return;
    }
    setErrorMessage('');

    let result;
    if (selectedRole === 'user') {
      result = await signInUser(email.trim(), password);
    } else {
      result = await signInProvider(email.trim(), password);
    }

    if (!result.success) {
      setErrorMessage(result.error || 'Login failed. Please check your credentials.');
    }
    // Success navigation handled by AppNavigator
  };

  return (
    <KeyboardAvoidingView
      behavior={Platform.OS === "ios" ? "padding" : "height"}
      style={styles.keyboardAvoidingContainer}
    >
      <View style={styles.container}>
        <Text style={styles.title}>Welcome Back!</Text>
        <Text style={styles.subtitle}>Log in as a {selectedRole}</Text>
        
        <RoleSelector selectedRole={selectedRole} onSelectRole={setSelectedRole} />

        {errorMessage ? <Text style={styles.errorText}>{errorMessage}</Text> : null}

        <TextInput
          style={styles.input}
          placeholder="Email Address"
          value={email}
          onChangeText={setEmail}
          keyboardType="email-address"
          autoCapitalize="none"
          autoCorrect={false}
        />
        <TextInput
          style={styles.input}
          placeholder="Password"
          value={password}
          onChangeText={setPassword}
          secureTextEntry
        />

        {isLoading ? (
          <ActivityIndicator size="large" color="#007AFF" style={styles.loader} />
        ) : (
          <TouchableOpacity style={styles.loginButton} onPress={handleLogin}>
            <Text style={styles.loginButtonText}>Log In as {selectedRole === 'user' ? 'User' : 'Provider'}</Text>
          </TouchableOpacity>
        )}

        <View style={styles.footer}>
          <Text style={styles.footerText}>Don't have a user account? </Text>
          <TouchableOpacity onPress={() => navigation.navigate('Signup')}> 
            <Text style={styles.signupText}>Sign Up</Text>
          </TouchableOpacity>
        </View>

        {/* Add separate link/button for provider signup */}
        <View style={styles.footer}>
            <Text style={styles.footerText}>Want to offer services? </Text>
            <TouchableOpacity onPress={() => navigation.navigate('ProviderSignup')}> 
                <Text style={styles.signupText}>Register as Provider</Text>
            </TouchableOpacity>
        </View>
        
        {/* Temporary button to bypass login, remove in production */}
        {/* <Button 
          title="Go to Home (TEMP)" 
          onPress={() => navigation.replace('Main', { screen: 'Home'})} 
        /> */}
      </View>
    </KeyboardAvoidingView>
  );
};

const styles = StyleSheet.create({
  keyboardAvoidingContainer: {
    flex: 1,
  },
  container: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
    padding: 20,
    backgroundColor: '#f7f7f7',
  },
  title: {
    fontSize: 28,
    fontWeight: 'bold',
    color: '#333',
    marginBottom: 10,
  },
  subtitle: {
    fontSize: 16,
    color: '#666',
    marginBottom: 20, // Reduced margin
  },
  roleSelectorContainer: {
    flexDirection: 'row',
    marginBottom: 20,
    borderWidth: 1,
    borderColor: '#007AFF',
    borderRadius: 8,
    overflow: 'hidden', // Ensure borders look connected
  },
  roleButton: {
    flex: 1,
    paddingVertical: 10,
    alignItems: 'center',
    backgroundColor: '#fff',
  },
  roleButtonSelected: {
    backgroundColor: '#007AFF',
  },
  roleButtonText: {
    fontSize: 16,
    color: '#007AFF',
  },
  roleButtonTextSelected: {
    color: '#fff',
    fontWeight: 'bold',
  },
  input: {
    width: '100%',
    height: 50,
    backgroundColor: '#fff',
    borderWidth: 1,
    borderColor: '#ddd',
    borderRadius: 8,
    paddingHorizontal: 15,
    marginBottom: 15,
    fontSize: 16,
  },
  loginButton: {
    width: '100%',
    backgroundColor: '#007AFF',
    paddingVertical: 15,
    borderRadius: 8,
    alignItems: 'center',
    marginBottom: 20,
  },
  loginButtonText: {
    color: '#fff',
    fontSize: 18,
    fontWeight: 'bold',
  },
  errorText: {
    color: 'red',
    marginBottom: 15,
    textAlign: 'center',
  },
  loader: {
    marginVertical: 20,
  },
  footer: {
    flexDirection: 'row',
    marginTop: 15, // Adjusted margin
  },
  footerText: {
    fontSize: 14,
    color: '#666',
  },
  signupText: {
    fontSize: 14,
    color: '#007AFF',
    fontWeight: 'bold',
  },
});

export default LoginScreen; 