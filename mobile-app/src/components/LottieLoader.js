import React from 'react';
import { StyleSheet, View, Text, Dimensions, ActivityIndicator } from 'react-native';
import LottieView from 'lottie-react-native';
import { COLORS, FONTS } from '../constants/theme';

// Default Lottie animations
const defaultAnimations = {
  loading: require('../assets/animations/loading.json'),
  success: require('../assets/animations/success.json'),
};

// Try to load these animations, but don't fail if they don't exist
let errorAnimation = null;
let emptyAnimation = null;

try {
  errorAnimation = require('../assets/animations/error.json');
} catch (e) {
  console.log('Error animation not found');
}

try {
  emptyAnimation = require('../assets/animations/empty.json');
} catch (e) {
  console.log('Empty animation not found');
}

// Add the optional animations only if they loaded successfully
if (errorAnimation) defaultAnimations.error = errorAnimation;
if (emptyAnimation) defaultAnimations.empty = emptyAnimation;

const { width, height } = Dimensions.get('window');

const LottieLoader = ({
  type = 'loading', // loading, success, error, empty, or custom
  source,
  message,
  fullScreen = false,
  size = 150,
  autoPlay = true,
  loop = true,
  speed = 1,
  style,
  onAnimationFinish,
}) => {
  // Determine the animation source
  const animationSource = source || defaultAnimations[type];
  
  // Calculate container styles
  const containerStyles = [
    styles.container,
    fullScreen && styles.fullScreen,
    style,
  ];
  
  return (
    <View style={containerStyles}>
      {animationSource ? (
        <LottieView
          source={animationSource}
          style={[styles.animation, { width: size, height: size }]}
          autoPlay={autoPlay}
          loop={loop}
          speed={speed}
          onAnimationFinish={onAnimationFinish}
        />
      ) : (
        <ActivityIndicator size="large" color={COLORS.primary} />
      )}
      
      {message && (
        <Text style={[FONTS.h4, styles.message]}>{message}</Text>
      )}
    </View>
  );
};

const styles = StyleSheet.create({
  container: {
    alignItems: 'center',
    justifyContent: 'center',
    padding: 20,
  },
  fullScreen: {
    width,
    height,
    backgroundColor: COLORS.white,
    position: 'absolute',
    top: 0,
    left: 0,
    zIndex: 999,
  },
  animation: {
    alignSelf: 'center',
  },
  message: {
    color: COLORS.dark,
    textAlign: 'center',
    marginTop: 20,
  },
});

export default LottieLoader; 