export const COLORS = {
  primary: '#6C63FF', // Main purple
  secondary: '#FF6584', // Pink accent
  accent: '#38CFDC', // Teal accent
  success: '#43CA79', // Green
  warning: '#F8B546', // Yellow
  danger: '#FF5F58', // Red
  dark: '#202046', // Dark blue
  light: '#F7F9FC', // Light background
  grey: '#A7A7A7', // Grey
  greyLight: '#EBEBEB', // Light grey
  white: '#FFFFFF',
  black: '#000000',
  transparent: 'transparent',
};

export const SIZES = {
  // global sizes
  base: 8,
  font: 14,
  radius: 12,
  padding: 24,
  margin: 20,

  // font sizes
  largeTitle: 40,
  h1: 30,
  h2: 22,
  h3: 18,
  h4: 16,
  h5: 14,
  body1: 30,
  body2: 22,
  body3: 16,
  body4: 14,
  body5: 12,
  small: 10,
};

export const FONTS = {
  largeTitle: { fontSize: SIZES.largeTitle, fontWeight: 'bold' },
  h1: { fontSize: SIZES.h1, fontWeight: 'bold' },
  h2: { fontSize: SIZES.h2, fontWeight: 'bold' },
  h3: { fontSize: SIZES.h3, fontWeight: '600' },
  h4: { fontSize: SIZES.h4, fontWeight: '600' },
  h5: { fontSize: SIZES.h5, fontWeight: '600' },
  body1: { fontSize: SIZES.body1 },
  body2: { fontSize: SIZES.body2 },
  body3: { fontSize: SIZES.body3 },
  body4: { fontSize: SIZES.body4 },
  body5: { fontSize: SIZES.body5 },
  small: { fontSize: SIZES.small },
};

export const SHADOWS = {
  light: {
    shadowColor: COLORS.black,
    shadowOffset: {
      width: 0,
      height: 2,
    },
    shadowOpacity: 0.1,
    shadowRadius: 3.84,
    elevation: 2,
  },
  medium: {
    shadowColor: COLORS.black,
    shadowOffset: {
      width: 0,
      height: 4,
    },
    shadowOpacity: 0.15,
    shadowRadius: 4.65,
    elevation: 4,
  },
  dark: {
    shadowColor: COLORS.black,
    shadowOffset: {
      width: 0,
      height: 6,
    },
    shadowOpacity: 0.2,
    shadowRadius: 5.45,
    elevation: 6,
  },
};

export default { COLORS, SIZES, FONTS, SHADOWS }; 