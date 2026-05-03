import React, { useState } from 'react';
import { View, Text, TouchableOpacity, StyleSheet } from 'react-native';
import { FontAwesome5 } from '@expo/vector-icons';

export default function Navigation() {
  const [active, setActive] = useState('home'); // tab mặc định

  const tabs = [
    { key: 'home', label: 'Home', icon: 'home' },
    { key: 'pos', label: 'POS', icon: 'cash-register' },
    { key: 'products', label: 'Products', icon: 'archive' },
    { key: 'staff', label: 'Staff', icon: 'users' },
    { key: 'more', label: 'More', icon: 'ellipsis-h' },
  ];

  return (
    <View style={styles.container}>
      {tabs.map(tab => (
        <TouchableOpacity 
          key={tab.key} 
          style={styles.button} 
          onPress={() => setActive(tab.key)}
        >
          <FontAwesome5 
            name={tab.icon} 
            size={24} 
            color={active === tab.key ? '#ffcc00' : '#fff'} 
            solid
          />
          <Text style={[styles.text, active === tab.key && styles.activeText]}>
            {tab.label}
          </Text>
        </TouchableOpacity>
      ))}
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flexDirection: 'row',
    position: 'absolute',
    bottom: 0,
    left: 0,
    right: 0,
    backgroundColor: '#007bff',
    justifyContent: 'space-around',
    paddingVertical: 10,
  },
  button: {
    alignItems: 'center',
  },
  text: {
    color: '#fff',
    fontSize: 12,
    marginTop: 4,
  },
  activeText: {
    color: '#ffcc00',
    fontWeight: 'bold',
  },
});
