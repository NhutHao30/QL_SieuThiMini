import { Image } from 'expo-image';
import { Platform, StyleSheet, View, Text } from 'react-native';
import { Link } from 'expo-router';
import Navigation from '../components/Navigation';

export default function HomeScreen() {
  return (
    <View style={styles.container}>
      <Text style={styles.text}>Hello word</Text>
      <View style={styles.navigation}>
        <Navigation />
      </View>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    width: '100%',
    justifyContent: "center",
    alignItems: "center",
    backgroundColor: '#f0f0f0',
  },
  text: {
    fontSize: 18,
    color: '#333',
  },
  navigation: {
    position: "absolute",
    bottom: 0,
    left: 0,
    right: 0,
    height: 60,
    borderTopWidth: 1,
    borderTopColor: '#ccc',
    width: '100%',
    display: 'flex',
    justifyContent: 'center',
    alignItems: 'center',
  }
});
