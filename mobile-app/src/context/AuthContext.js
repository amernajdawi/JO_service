import React, { createContext, useEffect, useMemo, useReducer } from 'react';
import AsyncStorage from '@react-native-async-storage/async-storage';
import { 
  loginUserApi, 
  registerUserApi, 
  loginProviderApi, 
  registerProviderApi 
} from '../services/authService';

export const AuthContext = createContext(null);

const AUTH_ACTIONS = {
  RETRIEVE_STATE: 'RETRIEVE_STATE',
  LOGIN_USER: 'LOGIN_USER',
  LOGIN_PROVIDER: 'LOGIN_PROVIDER',
  LOGOUT: 'LOGOUT',
  REGISTER_USER: 'REGISTER_USER',
  REGISTER_PROVIDER: 'REGISTER_PROVIDER',
  SET_LOADING: 'SET_LOADING',
};

const authReducer = (prevState, action) => {
  switch (action.type) {
    case AUTH_ACTIONS.RETRIEVE_STATE:
      return {
        ...prevState,
        userToken: action.token,
        userType: action.userType,
        userInfo: action.userInfo, // Can be user or provider info based on userType
        isLoading: false,
      };
    case AUTH_ACTIONS.LOGIN_USER:
    case AUTH_ACTIONS.REGISTER_USER:
      return {
        ...prevState,
        userToken: action.token,
        userType: 'user',
        userInfo: action.userInfo,
        isLoading: false,
      };
     case AUTH_ACTIONS.LOGIN_PROVIDER:
     case AUTH_ACTIONS.REGISTER_PROVIDER:
      return {
        ...prevState,
        userToken: action.token,
        userType: 'provider',
        userInfo: action.userInfo, // Store provider info here too
        isLoading: false,
      };
    case AUTH_ACTIONS.LOGOUT:
      return {
        ...prevState,
        userToken: null,
        userType: null,
        userInfo: null,
        isLoading: false,
      };
    case AUTH_ACTIONS.SET_LOADING:
      return {
        ...prevState,
        isLoading: action.isLoading,
      };
    default:
      return prevState;
  }
};

export const AuthProvider = ({ children }) => {
  const initialState = {
    isLoading: true,
    userToken: null,
    userType: null, // 'user' or 'provider'
    userInfo: null, // Will hold user OR provider info object
  };

  const [state, dispatch] = useReducer(authReducer, initialState);

  useEffect(() => {
    const bootstrapAsync = async () => {
      let userToken = null;
      let userType = null;
      let storedUserInfo = null;
      try {
        userToken = await AsyncStorage.getItem('userToken');
        userType = await AsyncStorage.getItem('userType');
        const userInfoString = await AsyncStorage.getItem('userInfo');
        if (userInfoString) {
          storedUserInfo = JSON.parse(userInfoString);
        }
      } catch (e) {
        console.error('Restoring auth state failed', e);
        // Consider clearing storage if corrupt
        await AsyncStorage.multiRemove(['userToken', 'userType', 'userInfo']);
        userToken = null; userType = null; storedUserInfo = null;
      }
      dispatch({ 
        type: AUTH_ACTIONS.RETRIEVE_STATE, 
        token: userToken, 
        userType: userType, 
        userInfo: storedUserInfo 
      });
    };
    bootstrapAsync();
  }, []);

  const authContextValue = useMemo(() => ({
    // --- User Auth ---
    signInUser: async (email, password) => {
      dispatch({ type: AUTH_ACTIONS.SET_LOADING, isLoading: true });
      try {
        const data = await loginUserApi(email, password);
        await AsyncStorage.setItem('userToken', data.token);
        await AsyncStorage.setItem('userType', 'user');
        await AsyncStorage.setItem('userInfo', JSON.stringify(data.user));
        dispatch({ type: AUTH_ACTIONS.LOGIN_USER, token: data.token, userInfo: data.user });
        return { success: true };
      } catch (error) {
        console.error('Sign in User error:', error.message);
        dispatch({ type: AUTH_ACTIONS.LOGOUT }); 
        return { success: false, error: error.message, validationErrors: error.errors };
      }
    },
    signUpUser: async (userData) => {
      dispatch({ type: AUTH_ACTIONS.SET_LOADING, isLoading: true });
      try {
        const data = await registerUserApi(userData);
        await AsyncStorage.setItem('userToken', data.token);
        await AsyncStorage.setItem('userType', 'user');
        await AsyncStorage.setItem('userInfo', JSON.stringify(data.user));
        dispatch({ type: AUTH_ACTIONS.REGISTER_USER, token: data.token, userInfo: data.user });
        return { success: true };
      } catch (error) {
        console.error('Sign up User error:', error.message);
        dispatch({ type: AUTH_ACTIONS.LOGOUT }); 
        return { success: false, error: error.message, validationErrors: error.errors };
      }
    },
    // --- Provider Auth ---
    signInProvider: async (email, password) => {
      dispatch({ type: AUTH_ACTIONS.SET_LOADING, isLoading: true });
      try {
        const data = await loginProviderApi(email, password);
        await AsyncStorage.setItem('userToken', data.token);
        await AsyncStorage.setItem('userType', 'provider');
        await AsyncStorage.setItem('userInfo', JSON.stringify(data.provider)); // Store provider info
        dispatch({ type: AUTH_ACTIONS.LOGIN_PROVIDER, token: data.token, userInfo: data.provider });
        return { success: true };
      } catch (error) {
        console.error('Sign in Provider error:', error.message);
        dispatch({ type: AUTH_ACTIONS.LOGOUT }); 
        return { success: false, error: error.message, validationErrors: error.errors };
      }
    },
    signUpProvider: async (providerData) => {
      dispatch({ type: AUTH_ACTIONS.SET_LOADING, isLoading: true });
      try {
        const data = await registerProviderApi(providerData);
        await AsyncStorage.setItem('userToken', data.token);
        await AsyncStorage.setItem('userType', 'provider');
        await AsyncStorage.setItem('userInfo', JSON.stringify(data.provider));
        dispatch({ type: AUTH_ACTIONS.REGISTER_PROVIDER, token: data.token, userInfo: data.provider });
        return { success: true };
      } catch (error) {
        console.error('Sign up Provider error:', error.message);
        dispatch({ type: AUTH_ACTIONS.LOGOUT }); 
        return { success: false, error: error.message, validationErrors: error.errors };
      }
    },
    // --- General ---
    signOut: async () => {
      dispatch({ type: AUTH_ACTIONS.SET_LOADING, isLoading: true });
      try {
        await AsyncStorage.multiRemove(['userToken', 'userType', 'userInfo']);
      } catch (e) {
        console.error('Signing out failed', e);
      }
      dispatch({ type: AUTH_ACTIONS.LOGOUT });
    },
    // --- State Access ---
    userToken: state.userToken,
    userInfo: state.userInfo, // Contains user OR provider info
    userType: state.userType,   // 'user', 'provider', or null
    isLoading: state.isLoading,
  }), [state.userToken, state.userInfo, state.userType, state.isLoading]);

  return (
    <AuthContext.Provider value={authContextValue}>
      {children}
    </AuthContext.Provider>
  );
};

export const useAuth = () => {
  const context = React.useContext(AuthContext);
  if (!context) {
    throw new Error('useAuth must be used within an AuthProvider');
  }
  return context;
}; 