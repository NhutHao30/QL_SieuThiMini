import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_ringtone_player/flutter_ringtone_player.dart';
import '../services/supabase_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'user_viewmodel.dart';
import 'dart:async';

class ChatViewModel extends ChangeNotifier {
  UserViewModel? userVM;
  int unreadCount = 0;
  bool isChatOpen = false;
  RealtimeChannel? _channel;
  Map<String, dynamic>? latestMessage;
  
  StreamSubscription<List<Map<String, dynamic>>>? _subscription;
  int? _lastProcessedMessageId;

  void updateUser(UserViewModel newUserVM) {
    userVM = newUserVM;
    if (userVM?.currentUser != null && _subscription == null) {
      _init();
    } else if (userVM?.currentUser == null && _subscription != null) {
      _disposeChannel();
    }
  }

  void _init() async {
    print('ChatViewModel: initializing...');
    final prefs = await SharedPreferences.getInstance();
    final lastReadTimeStr = prefs.getString('lastReadChatTime');
    DateTime? lastReadTime;
    if (lastReadTimeStr != null) {
      lastReadTime = DateTime.parse(lastReadTimeStr);
      print('ChatViewModel: lastReadTime = $lastReadTime');
    }

    // Use stream for more robust realtime updates
    _subscription = SupabaseService.client
        .from('chat_messages')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .listen((data) {
      if (data.isNotEmpty) {
        final newRecord = data.first;
        final newId = newRecord['id'];
        
        // Only process if it's a truly new message
        if (_lastProcessedMessageId != null && newId > _lastProcessedMessageId!) {
          _handleNewMessage(newRecord);
        }
        
        // Update highest seen ID
        if (_lastProcessedMessageId == null || newId > _lastProcessedMessageId!) {
          _lastProcessedMessageId = newId;
        }
      }
    });

    // Fetch initial unread count
    if (lastReadTime != null) {
      try {
        final response = await SupabaseService.client
          .from('chat_messages')
          .select('id, created_at')
          .gt('created_at', lastReadTime.toIso8601String());
        
        unreadCount = response.length;
        notifyListeners();
      } catch (e) {
        print('Error fetching unread messages: $e');
      }
    } else {
      unreadCount = 0;
    }
  }

  void _handleNewMessage(Map<String, dynamic> record) async {
    final currentUsername = userVM?.currentUser?.username;
    if (record['sender_username'] == currentUsername) {
      // User sent this message, don't notify or increment
      return;
    }

    if (isChatOpen) {
      // Chat is open, auto read
      return;
    }

    unreadCount++;
    latestMessage = record;
    notifyListeners();

    // Play notification sound
    try {
      FlutterRingtonePlayer().playNotification();
    } catch (e) {
      print('Ringtone error: $e');
    }
  }

  void openChat() async {
    isChatOpen = true;
    unreadCount = 0;
    latestMessage = null;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('lastReadChatTime', DateTime.now().toUtc().toIso8601String());
  }

  void closeChat() async {
    isChatOpen = false;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('lastReadChatTime', DateTime.now().toUtc().toIso8601String());
  }

  void clearLatestMessage() {
    latestMessage = null;
    notifyListeners();
  }

  void _disposeChannel() {
    _channel?.unsubscribe();
    _channel = null;
    _subscription?.cancel();
    _subscription = null;
  }

  @override
  void dispose() {
    _disposeChannel();
    super.dispose();
  }
}
