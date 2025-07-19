import React from 'react';
import { StyleSheet, Text } from 'react-native';
import Animated, { 
  useSharedValue,
  useAnimatedStyle,
  withSpring,
  withTiming,
  interpolateColor
} from 'react-native-reanimated';
import { TouchableOpacity } from 'react-native-gesture-handler';
import { COLORS, FONTS, SHADOWS } from '../constants/theme';

const AnimatedTouchable = Animated.createAnimatedComponent(TouchableOpacity);

const AnimatedButton = ({ 
  title, 
  onPress, 
  style, 
  textStyle, 
  variant = 'filled', // filled, outlined
  size = 'medium', // small, medium, large
  disabled = false,
  fullWidth = false,
  icon = null,
}) => {
  const scale = useSharedValue(1);
  
  // Handle press animation
  const handlePressIn = () => {
    scale.value = withSpring(0.95, { damping: 10 });
  };
  
  const handlePressOut = () => {
    scale.value = withSpring(1, { damping: 10 });
  };
  
  // Generate button size style
  const getSizeStyle = () => {
    switch (size) {
      case 'small':
        return {
          paddingVertical: 8,
          paddingHorizontal: 16,
          borderRadius: 8,
        };
      case 'large':
        return {
          paddingVertical: 16,
          paddingHorizontal: 32,
          borderRadius: 12,
        };
      case 'medium':
      default:
        return {
          paddingVertical: 12,
          paddingHorizontal: 24,
          borderRadius: 10,
        };
    }
  };
  
  // Generate variant styles
  const getVariantStyle = () => {
    switch (variant) {
      case 'outlined':
        return {
          backgroundColor: 'transparent',
          borderWidth: 2,
          borderColor: disabled ? COLORS.greyLight : COLORS.primary,
        };
      case 'filled':
      default:
        return {
          backgroundColor: disabled ? COLORS.greyLight : COLORS.primary,
          ...SHADOWS.medium,
        };
    }
  };
  
  // Generate text style based on variant
  const getTextStyle = () => {
    switch (variant) {
      case 'outlined':
        return {
          color: disabled ? COLORS.grey : COLORS.primary,
        };
      case 'filled':
      default:
        return {
          color: COLORS.white,
        };
    }
  };
  
  // Create animated style for the button
  const animatedStyle = useAnimatedStyle(() => {
    return {
      transform: [{ scale: scale.value }],
    };
  });
  
  return (
    <AnimatedTouchable
      onPress={disabled ? null : onPress}
      onPressIn={handlePressIn}
      onPressOut={handlePressOut}
      style={[
        styles.container,
        getSizeStyle(),
        getVariantStyle(),
        fullWidth && styles.fullWidth,
        animatedStyle,
        style,
      ]}
      activeOpacity={0.8}
    >
      {icon && icon}
      <Text style={[
        styles.text,
        FONTS.h4,
        getTextStyle(),
        textStyle,
      ]}>
        {title}
      </Text>
    </AnimatedTouchable>
  );
};

const styles = StyleSheet.create({
  container: {
    flexDirection: 'row',
    justifyContent: 'center',
    alignItems: 'center',
    backgroundColor: COLORS.primary,
  },
  fullWidth: {
    width: '100%',
  },
  text: {
    color: COLORS.white,
    fontWeight: '600',
  },
});

export default AnimatedButton; 