import React, { useEffect } from 'react';
import { 
  View, 
  Text, 
  StyleSheet, 
  ScrollView, 
  SafeAreaView, 
  StatusBar, 
  FlatList 
} from 'react-native';
import * as Animatable from 'react-native-animatable';
import { useAuth } from '../context/AuthContext';
import { COLORS, FONTS, SIZES, SHADOWS } from '../constants/theme';
import AnimatedButton from '../components/AnimatedButton';
import AnimatedCard from '../components/AnimatedCard';
import LottieLoader from '../components/LottieLoader';

// Sample service data
const services = [
  {
    id: '1',
    title: 'House Cleaning',
    description: 'Professional house cleaning services',
    icon: '🧹',
  },
  {
    id: '2',
    title: 'Plumbing',
    description: 'Expert plumbing repair and installation',
    icon: '🔧',
  },
  {
    id: '3',
    title: 'Electrical',
    description: 'Electrical repair and installation services',
    icon: '⚡',
  },
  {
    id: '4',
    title: 'Gardening',
    description: 'Garden maintenance and landscaping',
    icon: '🌱',
  },
  {
    id: '5',
    title: 'Painting',
    description: 'Interior and exterior painting services',
    icon: '🖌️',
  },
];

const ServiceCard = ({ item, index, onPress }) => {
  return (
    <AnimatedCard
      title={item.title}
      description={item.description}
      image={
        <Text style={styles.serviceIcon}>{item.icon}</Text>
      }
      onPress={onPress}
      delay={index * 100}
      style={styles.serviceCard}
    />
  );
};

const HomeScreen = ({ navigation }) => {
  const { signOut, userInfo, isLoading } = useAuth();

  const handleLogout = async () => {
    await signOut();
  };

  const handleServicePress = (service) => {
    // Handle service selection
    console.log('Selected service:', service);
    // Navigate to service details or booking screen
  };

  if (isLoading && !userInfo) {
    return (
      <View style={styles.centeredContainer}>
        <LottieLoader type="loading" message="Loading..." fullScreen />
      </View>
    );
  }

  return (
    <SafeAreaView style={styles.container}>
      <StatusBar barStyle="dark-content" backgroundColor={COLORS.white} />
      
      <View style={styles.header}>
        <Animatable.View animation="fadeInDown" duration={800}>
          <Text style={[FONTS.h1, styles.headerTitle]}>
            Hello, {userInfo?.fullName || 'User'}!
          </Text>
          <Text style={[FONTS.body4, styles.headerSubtitle]}>
            What service do you need today?
          </Text>
        </Animatable.View>
        
        <Animatable.View animation="fadeIn" delay={300} duration={800}>
          <AnimatedButton
            title="Logout"
            onPress={handleLogout}
            variant="outlined"
            size="small"
          />
        </Animatable.View>
      </View>
      
      <ScrollView 
        showsVerticalScrollIndicator={false}
        contentContainerStyle={styles.scrollContainer}
      >
        <Animatable.View animation="fadeInUp" duration={800}>
          <Text style={[FONTS.h2, styles.sectionTitle]}>Featured Services</Text>
        </Animatable.View>
        
        <FlatList
          data={services}
          keyExtractor={(item) => item.id}
          renderItem={({ item, index }) => (
            <ServiceCard 
              item={item} 
              index={index}
              onPress={() => handleServicePress(item)} 
            />
          )}
          horizontal
          showsHorizontalScrollIndicator={false}
          contentContainerStyle={styles.servicesList}
        />
        
        <Animatable.View animation="fadeInUp" delay={400} duration={800}>
          <Text style={[FONTS.h2, styles.sectionTitle]}>Recent Bookings</Text>
          
          {/* Placeholder for when no bookings exist */}
          <AnimatedCard
            title="No Recent Bookings"
            description="Your recent bookings will appear here"
            icon={
              <View style={styles.emptyIcon}>
                <Text style={styles.emptyIconText}>📅</Text>
              </View>
            }
            variant="outline"
            delay={500}
          />
        </Animatable.View>
        
        <Animatable.View animation="fadeInUp" delay={600} duration={800} style={styles.bottomSection}>
          <AnimatedButton
            title="Browse All Services"
            onPress={() => console.log('Browse all services')}
            fullWidth
            size="large"
          />
        </Animatable.View>
      </ScrollView>
    </SafeAreaView>
  );
};

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: COLORS.light,
  },
  centeredContainer: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
  },
  header: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    paddingHorizontal: SIZES.padding,
    paddingTop: SIZES.padding,
    paddingBottom: SIZES.padding / 2,
    backgroundColor: COLORS.white,
    ...SHADOWS.medium,
  },
  headerTitle: {
    color: COLORS.dark,
    marginBottom: SIZES.base / 2,
  },
  headerSubtitle: {
    color: COLORS.grey,
  },
  scrollContainer: {
    paddingBottom: SIZES.padding * 2,
  },
  sectionTitle: {
    marginHorizontal: SIZES.padding,
    marginTop: SIZES.padding,
    marginBottom: SIZES.base,
    color: COLORS.dark,
  },
  servicesList: {
    paddingLeft: SIZES.padding,
    paddingRight: SIZES.padding / 2,
  },
  serviceCard: {
    width: 200,
    marginRight: SIZES.padding / 2,
    marginVertical: SIZES.padding / 2,
  },
  serviceIcon: {
    fontSize: 40,
    marginBottom: SIZES.base,
  },
  emptyIcon: {
    alignItems: 'center',
    justifyContent: 'center',
    marginBottom: SIZES.base,
  },
  emptyIconText: {
    fontSize: 50,
  },
  bottomSection: {
    marginTop: SIZES.padding,
    paddingHorizontal: SIZES.padding,
  },
});

export default HomeScreen; 