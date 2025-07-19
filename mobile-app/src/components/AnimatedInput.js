import React, { useState } from 'react';
import { 
  StyleSheet, 
  View, 
  TextInput, 
  Text, 
  Animated, 
  TouchableOpacity 
} from 'react-native';
import { COLORS, FONTS, SIZES, SHADOWS } from '../constants/theme';

const AnimatedInput = ({
  label,
  value,
  onChangeText,
  placeholder,
  secureTextEntry,
  keyboardType,
  autoCapitalize = 'none',
  error,
  style,
  inputStyle,
  icon,
  iconPosition = 'right',
  disabled = false,
  multiline = false,
  maxLength,
  editable = true,
  ...props
}) => {
  const [isFocused, setIsFocused] = useState(false);
  const [isPasswordVisible, setIsPasswordVisible] = useState(false);
  
  // Animation value for label movement
  const [animation] = useState(new Animated.Value(value ? 1 : 0));
  
  // Handle focus animation
  const handleFocus = () => {
    setIsFocused(true);
    Animated.timing(animation, {
      toValue: 1,
      duration: 200,
      useNativeDriver: false,
    }).start();
  };
  
  // Handle blur animation
  const handleBlur = () => {
    setIsFocused(false);
    if (!value) {
      Animated.timing(animation, {
        toValue: 0,
        duration: 200,
        useNativeDriver: false,
      }).start();
    }
  };
  
  // Interpolate label position and size
  const labelStyle = {
    position: 'absolute',
    left: 0,
    top: animation.interpolate({
      inputRange: [0, 1],
      outputRange: [18, 0],
    }),
    fontSize: animation.interpolate({
      inputRange: [0, 1],
      outputRange: [16, 14],
    }),
    color: animation.interpolate({
      inputRange: [0, 1],
      outputRange: [COLORS.grey, COLORS.primary],
    }),
  };
  
  // Toggle password visibility
  const togglePasswordVisibility = () => {
    setIsPasswordVisible(!isPasswordVisible);
  };

  // Calculate container styles
  const containerStyles = [
    styles.container,
    {
      borderColor: error 
        ? COLORS.danger 
        : isFocused 
          ? COLORS.primary 
          : COLORS.greyLight,
      backgroundColor: disabled ? COLORS.greyLight : COLORS.white,
    },
    style,
  ];

  return (
    <View style={styles.wrapper}>
      <View style={containerStyles}>
        <Animated.Text style={[styles.label, labelStyle]}>
          {label}
        </Animated.Text>
        
        {iconPosition === 'left' && icon && (
          <View style={styles.leftIcon}>{icon}</View>
        )}
        
        <TextInput
          style={[
            styles.input,
            inputStyle,
            iconPosition === 'left' ? { paddingLeft: 40 } : { paddingLeft: 0 },
            iconPosition === 'right' ? { paddingRight: 40 } : { paddingRight: 0 },
            multiline && styles.multilineInput,
          ]}
          value={value}
          onChangeText={onChangeText}
          placeholder={isFocused ? placeholder : ''}
          placeholderTextColor={COLORS.grey}
          secureTextEntry={secureTextEntry && !isPasswordVisible}
          keyboardType={keyboardType}
          autoCapitalize={autoCapitalize}
          onFocus={handleFocus}
          onBlur={handleBlur}
          editable={!disabled && editable}
          multiline={multiline}
          maxLength={maxLength}
          {...props}
        />
        
        {iconPosition === 'right' && icon && (
          <View style={styles.rightIcon}>{icon}</View>
        )}
        
        {secureTextEntry && (
          <TouchableOpacity
            style={styles.rightIcon}
            onPress={togglePasswordVisibility}
          >
            <Text style={styles.visibilityText}>
              {isPasswordVisible ? 'Hide' : 'Show'}
            </Text>
          </TouchableOpacity>
        )}
      </View>
      
      {error && (
        <Text style={styles.errorText}>{error}</Text>
      )}
    </View>
  );
};

const styles = StyleSheet.create({
  wrapper: {
    marginBottom: SIZES.padding,
    width: '100%',
  },
  container: {
    width: '100%',
    borderWidth: 1,
    borderRadius: SIZES.radius,
    paddingHorizontal: 15,
    paddingTop: 24,
    paddingBottom: 12,
    position: 'relative',
    ...SHADOWS.light,
  },
  input: {
    height: 24,
    fontSize: 16,
    color: COLORS.dark,
    padding: 0,
  },
  multilineInput: {
    height: 80,
    textAlignVertical: 'top',
  },
  label: {
    backgroundColor: 'transparent',
    paddingHorizontal: 4,
    left: 12,
  },
  leftIcon: {
    position: 'absolute',
    left: 15,
    top: '50%',
    marginTop: -10, // Adjust based on your icon size
  },
  rightIcon: {
    position: 'absolute',
    right: 15,
    top: '50%',
    marginTop: -10, // Adjust based on your icon size
  },
  visibilityText: {
    color: COLORS.primary,
    fontSize: 14,
  },
  errorText: {
    color: COLORS.danger,
    fontSize: 12,
    marginTop: 5,
    marginLeft: 10,
  },
});

export default AnimatedInput; 