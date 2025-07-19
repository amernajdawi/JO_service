import React, { useState, useEffect } from 'react';
import {
  View,
  Text,
  StyleSheet,
  KeyboardAvoidingView,
  Platform,
  Image,
  StatusBar,
} from 'react-native';
import * as Animatable from 'react-native-animatable';
import { TouchableOpacity } from 'react-native-gesture-handler';
import { useAuth } from '../context/AuthContext';
import { COLORS, FONTS, SIZES, SHADOWS } from '../constants/theme';
import AnimatedButton from '../components/AnimatedButton';
import AnimatedInput from '../components/AnimatedInput';
import LottieLoader from '../components/LottieLoader';

// Simple Segmented Control simulation with animation
const RoleSelector = ({ selectedRole, onSelectRole }) => {
  return (
    <Animatable.View 
      style={styles.roleSelectorContainer}
      animation="fadeIn"
      duration={800}
      delay={300}
    >
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
    </Animatable.View>
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
      <StatusBar barStyle="dark-content" backgroundColor={COLORS.white} />
      <View style={styles.container}>
        <Animatable.View animation="fadeIn" duration={1000} style={styles.logoContainer}>
          <Animatable.Text
            animation="pulse"
            iterationCount="infinite"
            duration={2000}
            style={styles.logoText}
          >
            OnDemand
          </Animatable.Text>
        </Animatable.View>

        <Animatable.View animation="fadeInUp" duration={800} delay={200}>
          <Text style={[FONTS.h1, styles.title]}>Welcome Back!</Text>
          <Text style={[FONTS.body4, styles.subtitle]}>Log in as a {selectedRole}</Text>
        </Animatable.View>
        
        <RoleSelector selectedRole={selectedRole} onSelectRole={setSelectedRole} />

        {errorMessage ? (
          <Animatable.Text 
            animation="shake" 
            style={styles.errorText}
          >
            {errorMessage}
          </Animatable.Text>
        ) : null}

        <Animatable.View animation="fadeInUp" duration={800} delay={400} style={styles.formContainer}>
          <AnimatedInput
            label="Email Address"
            value={email}
            onChangeText={setEmail}
            keyboardType="email-address"
            autoCapitalize="none"
            autoCorrect={false}
            style={styles.inputMargin}
          />
          
          <AnimatedInput
            label="Password"
            value={password}
            onChangeText={setPassword}
            secureTextEntry
            style={styles.inputMargin}
          />
        </Animatable.View>

        {isLoading ? (
          <LottieLoader 
            type="loading" 
            size={100} 
            message="Logging in..." 
          />
        ) : (
          <Animatable.View animation="fadeInUp" duration={800} delay={600}>
            <AnimatedButton
              title={`Log In as ${selectedRole === 'user' ? 'User' : 'Provider'}`}
              onPress={handleLogin}
              size="large"
              fullWidth
              style={styles.loginButton}
            />
          </Animatable.View>
        )}

        <Animatable.View animation="fadeInUp" duration={800} delay={700} style={styles.footer}>
          <Text style={[FONTS.body4, styles.footerText]}>Don't have a user account? </Text>
          <TouchableOpacity onPress={() => navigation.navigate('Signup')}> 
            <Text style={styles.signupText}>Sign Up</Text>
          </TouchableOpacity>
        </Animatable.View>

        <Animatable.View animation="fadeInUp" duration={800} delay={800} style={styles.footer}>
          <Text style={[FONTS.body4, styles.footerText]}>Want to offer services? </Text>
          <TouchableOpacity onPress={() => navigation.navigate('ProviderSignup')}> 
            <Text style={styles.signupText}>Register as Provider</Text>
          </TouchableOpacity>
        </Animatable.View>
      </View>
    </KeyboardAvoidingView>
  );
};

const styles = StyleSheet.create({
  keyboardAvoidingContainer: {
    flex: 1,
    backgroundColor: COLORS.white,
  },
  container: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
    padding: SIZES.padding,
    backgroundColor: COLORS.white,
  },
  logoContainer: {
    alignItems: 'center',
    marginBottom: SIZES.padding * 2,
  },
  logoText: {
    ...FONTS.largeTitle,
    color: COLORS.primary,
    fontWeight: 'bold',
    fontSize: 40,
  },
  title: {
    color: COLORS.dark,
    marginBottom: SIZES.base,
    textAlign: 'center',
  },
  subtitle: {
    color: COLORS.grey,
    marginBottom: SIZES.padding,
    textAlign: 'center',
  },
  roleSelectorContainer: {
    flexDirection: 'row',
    marginBottom: SIZES.padding,
    borderWidth: 1,
    borderColor: COLORS.primary,
    borderRadius: SIZES.radius,
    overflow: 'hidden',
    ...SHADOWS.light,
  },
  roleButton: {
    flex: 1,
    paddingVertical: 12,
    alignItems: 'center',
    backgroundColor: COLORS.white,
  },
  roleButtonSelected: {
    backgroundColor: COLORS.primary,
  },
  roleButtonText: {
    fontSize: 16,
    color: COLORS.primary,
  },
  roleButtonTextSelected: {
    color: COLORS.white,
    fontWeight: 'bold',
  },
  formContainer: {
    width: '100%',
    marginBottom: SIZES.padding,
  },
  inputMargin: {
    marginBottom: SIZES.padding,
  },
  loginButton: {
    marginTop: SIZES.base,
  },
  errorText: {
    color: COLORS.danger,
    marginBottom: SIZES.padding,
    textAlign: 'center',
  },
  footer: {
    flexDirection: 'row',
    marginTop: SIZES.padding,
  },
  footerText: {
    color: COLORS.grey,
  },
  signupText: {
    ...FONTS.h4,
    color: COLORS.primary,
  },
});

export default LoginScreen; 