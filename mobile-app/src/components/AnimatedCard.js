import React, { useEffect } from 'react';
import { StyleSheet, View, Text, Dimensions } from 'react-native';
import Animated, {
  useSharedValue,
  useAnimatedStyle,
  withTiming,
  withSpring,
  withDelay,
  Easing,
} from 'react-native-reanimated';
import { TouchableOpacity } from 'react-native-gesture-handler';
import * as Animatable from 'react-native-animatable';
import { COLORS, FONTS, SHADOWS, SIZES } from '../constants/theme';

const { width } = Dimensions.get('window');

const AnimatedCard = ({
  title,
  description,
  image,
  onPress,
  style,
  delay = 0,
  icon,
  children,
  variant = 'default', // 'default', 'outline', 'minimal'
  animated = true,
}) => {
  // Animation values
  const scale = useSharedValue(animated ? 0.8 : 1);
  const opacity = useSharedValue(animated ? 0 : 1);
  const translateY = useSharedValue(animated ? 20 : 0);

  useEffect(() => {
    if (animated) {
      // Start entry animations
      scale.value = withDelay(
        delay,
        withSpring(1, { damping: 12, stiffness: 100 })
      );
      opacity.value = withDelay(
        delay,
        withTiming(1, { duration: 400, easing: Easing.out(Easing.quad) })
      );
      translateY.value = withDelay(
        delay,
        withTiming(0, { duration: 400, easing: Easing.out(Easing.quad) })
      );
    }
  }, []);

  // Handle press animation
  const handlePressIn = () => {
    scale.value = withSpring(0.97, { damping: 10 });
  };

  const handlePressOut = () => {
    scale.value = withSpring(1, { damping: 10 });
  };

  // Card variant styles
  const getVariantStyle = () => {
    switch (variant) {
      case 'outline':
        return {
          backgroundColor: COLORS.white,
          borderWidth: 1,
          borderColor: COLORS.greyLight,
        };
      case 'minimal':
        return {
          backgroundColor: 'transparent',
          elevation: 0,
          shadowOpacity: 0,
        };
      case 'default':
      default:
        return {
          backgroundColor: COLORS.white,
          ...SHADOWS.medium,
        };
    }
  };

  // Create animated styles
  const animatedStyles = useAnimatedStyle(() => {
    return {
      transform: [
        { scale: scale.value },
        { translateY: translateY.value },
      ],
      opacity: opacity.value,
    };
  });

  return (
    <Animated.View
      style={[
        styles.container,
        getVariantStyle(),
        animatedStyles,
        style,
      ]}
    >
      <TouchableOpacity
        style={styles.touchable}
        onPress={onPress}
        onPressIn={handlePressIn}
        onPressOut={handlePressOut}
        activeOpacity={0.9}
        disabled={!onPress}
      >
        {image && (
          <Animatable.View
            animation="pulse"
            iterationCount="infinite"
            duration={2000}
            style={styles.iconContainer}
          >
            {image}
          </Animatable.View>
        )}
        {icon && (
          <View style={styles.iconContainer}>
            {icon}
          </View>
        )}
        {title && (
          <Text style={[FONTS.h3, styles.title]}>{title}</Text>
        )}
        {description && (
          <Text style={[FONTS.body4, styles.description]}>{description}</Text>
        )}
        {children}
      </TouchableOpacity>
    </Animated.View>
  );
};

const styles = StyleSheet.create({
  container: {
    borderRadius: SIZES.radius,
    overflow: 'hidden',
    marginBottom: SIZES.padding,
    width: width - (SIZES.padding * 2),
  },
  touchable: {
    padding: SIZES.padding,
  },
  iconContainer: {
    marginBottom: SIZES.base,
    alignItems: 'center',
  },
  title: {
    color: COLORS.dark,
    marginBottom: SIZES.base,
  },
  description: {
    color: COLORS.grey,
  },
});

export default AnimatedCard; 