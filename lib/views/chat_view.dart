import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../viewmodels/user_viewmodel.dart';
import '../viewmodels/chat_viewmodel.dart';
import '../services/supabase_service.dart';
import '../theme/app_theme.dart';
import 'package:intl/intl.dart';

class ChatMessage {
  final int id;
  final String senderUsername;
  final String senderName;
  final String message;
  final DateTime createdAt;

  ChatMessage({
    required this.id,
    required this.senderUsername,
    required this.senderName,
    required this.message,
    required this.createdAt,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'],
      senderUsername: json['sender_username'] ?? '',
      senderName: json['sender_name'] ?? 'Unknown',
      message: json['message'] ?? '',
      createdAt: DateTime.parse(json['created_at']).toLocal(),
    );
  }
}

class ChatView extends StatefulWidget {
  const ChatView({super.key});

  @override
  State<ChatView> createState() => _ChatViewState();
}

class _ChatViewState extends State<ChatView> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late final Stream<List<Map<String, dynamic>>> _messagesStream;

  late ChatViewModel _chatVM;

  @override
  void initState() {
    super.initState();
    _chatVM = context.read<ChatViewModel>();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _chatVM.openChat();
    });
    // Lắng nghe realtime từ bảng chat_messages
    _messagesStream = SupabaseService.client
        .from('chat_messages')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false) // mới nhất ở trên
        .limit(100); // Lấy 100 tin nhắn gần nhất
  }

  @override
  void dispose() {
    _chatVM.closeChat();
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    final userVM = context.read<UserViewModel>();
    final currentUser = userVM.currentUser;

    if (currentUser == null) return;

    _controller.clear();

    try {
      await SupabaseService.client.from('chat_messages').insert({
        'sender_username': currentUser.username,
        'sender_name': currentUser.hoten,
        'message': text,
      });
      // Scroll to bottom manually not needed since list is reversed
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi gửi tin nhắn: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUsername = context.read<UserViewModel>().currentUser?.username ?? '';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Group Chat Nội Bộ', style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(CupertinoIcons.back, color: AppTheme.primary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: _messagesStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text('Đã xảy ra lỗi kết nối: ${snapshot.error}', style: const TextStyle(color: Colors.red)));
                }

                final data = snapshot.data ?? [];
                
                return ListView.builder(
                  reverse: true, // Hiển thị từ dưới lên
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: data.length,
                  itemBuilder: (context, index) {
                    final msg = ChatMessage.fromJson(data[index]);
                    final isMe = msg.senderUsername == currentUsername;

                    return GestureDetector(
                      onLongPress: () async {
                        if (!isMe) return;
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (c) => AlertDialog(
                            title: const Text('Thu hồi tin nhắn'),
                            content: const Text('Bạn có chắc chắn muốn thu hồi tin nhắn này không?'),
                            actions: [
                              TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Hủy')),
                              TextButton(onPressed: () => Navigator.pop(c, true), child: const Text('Thu hồi', style: TextStyle(color: Colors.red))),
                            ],
                          ),
                        ) ?? false;

                        if (confirm && context.mounted) {
                          try {
                            await SupabaseService.client.from('chat_messages').delete().eq('id', msg.id);
                          } catch (e) {
                            if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
                          }
                        }
                      },
                      child: Align(
                        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isMe ? AppTheme.primary : Colors.white,
                            borderRadius: BorderRadius.circular(16).copyWith(
                              bottomRight: isMe ? const Radius.circular(0) : const Radius.circular(16),
                              bottomLeft: isMe ? const Radius.circular(16) : const Radius.circular(0),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 5,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (!isMe)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 4),
                                  child: Text(
                                    msg.senderName,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.primary,
                                    ),
                                  ),
                                ),
                              Text(
                                msg.message,
                                style: TextStyle(
                                  color: isMe ? Colors.white : AppTheme.textPrimary,
                                  fontSize: 15,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                DateFormat('HH:mm').format(msg.createdAt),
                                style: TextStyle(
                                  fontSize: 10,
                                  color: isMe ? Colors.white70 : AppTheme.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          )
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: TextField(
                  controller: _controller,
                  maxLines: null,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _sendMessage(),
                  decoration: const InputDecoration(
                    hintText: 'Nhập tin nhắn...',
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            GestureDetector(
              onTap: _sendMessage,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: const BoxDecoration(
                  color: AppTheme.primary,
                  shape: BoxShape.circle,
                ),
                child: const Icon(CupertinoIcons.paperplane_fill, color: Colors.white, size: 20),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
