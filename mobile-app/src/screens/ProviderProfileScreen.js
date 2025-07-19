import React, { useState, useEffect } from 'react';
import {
  View,
  Text,
  StyleSheet,
  ScrollView,
  TouchableOpacity,
  Image,
  TextInput,
  Alert,
  ActivityIndicator
} from 'react-native';
import { launchImageLibrary } from 'react-native-image-picker';
import AsyncStorage from '@react-native-async-storage/async-storage';
import axios from 'axios';
import { API_URL } from '../config/constants';

const ProviderProfileScreen = ({ navigation }) => {
  const [loading, setLoading] = useState(true);
  const [uploading, setUploading] = useState(false);
  const [profile, setProfile] = useState(null);
  const [formData, setFormData] = useState({
    fullName: '',
    companyName: '',
    serviceType: '',
    serviceDescription: '',
    address: '',
    phone: '',
    hourlyRate: '',
    availability: ''
  });

  useEffect(() => {
    fetchProfile();
  }, []);

  const fetchProfile = async () => {
    try {
      const token = await AsyncStorage.getItem('userToken');
      if (!token) {
        navigation.navigate('Login');
        return;
      }

      const response = await axios.get(`${API_URL}/api/providers/me`, {
        headers: { Authorization: `Bearer ${token}` }
      });

      setProfile(response.data);
      
      // Populate form data from profile
      setFormData({
        fullName: response.data.fullName || '',
        companyName: response.data.companyName || '',
        serviceType: response.data.serviceType || '',
        serviceDescription: response.data.serviceDescription || '',
        address: response.data.location?.addressText || '',
        phone: response.data.contactInfo?.phone || '',
        hourlyRate: response.data.hourlyRate?.toString() || '',
        availability: response.data.availabilityDetails || ''
      });
      
      setLoading(false);
    } catch (error) {
      console.error('Error fetching profile:', error);
      Alert.alert('Error', 'Failed to load profile. Please try again later.');
      setLoading(false);
    }
  };

  const handleUpdateProfile = async () => {
    try {
      setLoading(true);
      const token = await AsyncStorage.getItem('userToken');
      
      // Prepare data for API
      const updateData = {
        fullName: formData.fullName,
        companyName: formData.companyName,
        serviceType: formData.serviceType,
        serviceDescription: formData.serviceDescription,
        location: {
          addressText: formData.address
        },
        contactInfo: {
          phone: formData.phone
        },
        hourlyRate: parseFloat(formData.hourlyRate),
        availabilityDetails: formData.availability
      };

      const response = await axios.put(`${API_URL}/api/providers/me`, updateData, {
        headers: { Authorization: `Bearer ${token}` }
      });

      setProfile(response.data.provider);
      Alert.alert('Success', 'Profile updated successfully');
      setLoading(false);
    } catch (error) {
      console.error('Error updating profile:', error);
      Alert.alert('Error', 'Failed to update profile. Please try again.');
      setLoading(false);
    }
  };

  const handleChoosePhoto = () => {
    const options = {
      mediaType: 'photo',
      includeBase64: false,
      maxHeight: 2000,
      maxWidth: 2000,
    };

    launchImageLibrary(options, async (response) => {
      if (response.didCancel) {
        return;
      } else if (response.errorCode) {
        console.error('ImagePicker Error: ', response.errorMessage);
        Alert.alert('Error', 'Failed to pick image');
        return;
      }
      
      const selectedImage = response.assets[0];
      
      try {
        setUploading(true);
        const token = await AsyncStorage.getItem('userToken');
        
        // Create form data for image upload
        const formData = new FormData();
        formData.append('profilePicture', {
          uri: selectedImage.uri,
          type: selectedImage.type,
          name: selectedImage.fileName || 'photo.jpg',
        });

        const response = await axios.post(
          `${API_URL}/api/providers/me/profile-picture`,
          formData,
          {
            headers: {
              'Content-Type': 'multipart/form-data',
              Authorization: `Bearer ${token}`
            }
          }
        );

        // Update profile with new image URL
        setProfile({
          ...profile,
          profilePictureUrl: response.data.profilePictureUrl
        });
        
        Alert.alert('Success', 'Profile picture uploaded successfully');
        setUploading(false);
      } catch (error) {
        console.error('Error uploading profile picture:', error);
        Alert.alert('Error', 'Failed to upload profile picture. Please try again.');
        setUploading(false);
      }
    });
  };

  if (loading) {
    return (
      <View style={styles.loaderContainer}>
        <ActivityIndicator size="large" color="#0066CC" />
      </View>
    );
  }

  return (
    <ScrollView style={styles.container}>
      <View style={styles.header}>
        <Text style={styles.title}>My Provider Profile</Text>
      </View>

      <View style={styles.profileImageContainer}>
        {uploading ? (
          <ActivityIndicator size="large" color="#0066CC" />
        ) : (
          <>
            <Image
              source={
                profile?.profilePictureUrl
                  ? { uri: profile.profilePictureUrl }
                  : require('../assets/default-profile.png')
              }
              style={styles.profileImage}
            />
            <TouchableOpacity style={styles.uploadButton} onPress={handleChoosePhoto}>
              <Text style={styles.uploadButtonText}>Upload Photo</Text>
            </TouchableOpacity>
          </>
        )}
      </View>

      <View style={styles.formContainer}>
        <Text style={styles.label}>Full Name</Text>
        <TextInput
          style={styles.input}
          value={formData.fullName}
          onChangeText={(text) => setFormData({...formData, fullName: text})}
          placeholder="Your full name"
        />

        <Text style={styles.label}>Company Name</Text>
        <TextInput
          style={styles.input}
          value={formData.companyName}
          onChangeText={(text) => setFormData({...formData, companyName: text})}
          placeholder="Your company name"
        />

        <Text style={styles.label}>Service Type</Text>
        <TextInput
          style={styles.input}
          value={formData.serviceType}
          onChangeText={(text) => setFormData({...formData, serviceType: text})}
          placeholder="e.g. Plumbing, Electrical, etc."
        />

        <Text style={styles.label}>Service Description</Text>
        <TextInput
          style={[styles.input, styles.textArea]}
          value={formData.serviceDescription}
          onChangeText={(text) => setFormData({...formData, serviceDescription: text})}
          placeholder="Describe your services"
          multiline
          numberOfLines={4}
        />

        <Text style={styles.label}>Address</Text>
        <TextInput
          style={styles.input}
          value={formData.address}
          onChangeText={(text) => setFormData({...formData, address: text})}
          placeholder="Your address"
        />

        <Text style={styles.label}>Phone</Text>
        <TextInput
          style={styles.input}
          value={formData.phone}
          onChangeText={(text) => setFormData({...formData, phone: text})}
          placeholder="Your contact number"
          keyboardType="phone-pad"
        />

        <Text style={styles.label}>Hourly Rate ($)</Text>
        <TextInput
          style={styles.input}
          value={formData.hourlyRate}
          onChangeText={(text) => setFormData({...formData, hourlyRate: text})}
          placeholder="Your hourly rate"
          keyboardType="numeric"
        />

        <Text style={styles.label}>Availability</Text>
        <TextInput
          style={[styles.input, styles.textArea]}
          value={formData.availability}
          onChangeText={(text) => setFormData({...formData, availability: text})}
          placeholder="e.g. Monday-Friday, 9AM-5PM"
          multiline
          numberOfLines={2}
        />

        <TouchableOpacity style={styles.saveButton} onPress={handleUpdateProfile}>
          <Text style={styles.saveButtonText}>Save Changes</Text>
        </TouchableOpacity>
      </View>
    </ScrollView>
  );
};

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#F5F5F5',
  },
  loaderContainer: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
  },
  header: {
    backgroundColor: '#0066CC',
    padding: 20,
    alignItems: 'center',
  },
  title: {
    fontSize: 24,
    fontWeight: 'bold',
    color: 'white',
  },
  profileImageContainer: {
    alignItems: 'center',
    marginTop: 20,
    marginBottom: 20,
  },
  profileImage: {
    width: 150,
    height: 150,
    borderRadius: 75,
    borderWidth: 3,
    borderColor: '#0066CC',
  },
  uploadButton: {
    backgroundColor: '#0066CC',
    padding: 10,
    borderRadius: 5,
    marginTop: 10,
  },
  uploadButtonText: {
    color: 'white',
    fontWeight: 'bold',
  },
  formContainer: {
    padding: 20,
  },
  label: {
    fontSize: 16,
    fontWeight: 'bold',
    marginBottom: 5,
    color: '#333',
  },
  input: {
    backgroundColor: 'white',
    borderWidth: 1,
    borderColor: '#DDD',
    borderRadius: 5,
    padding: 10,
    marginBottom: 15,
  },
  textArea: {
    height: 100,
    textAlignVertical: 'top',
  },
  saveButton: {
    backgroundColor: '#0066CC',
    padding: 15,
    borderRadius: 5,
    alignItems: 'center',
    marginTop: 10,
  },
  saveButtonText: {
    color: 'white',
    fontWeight: 'bold',
    fontSize: 16,
  },
});

export default ProviderProfileScreen; 