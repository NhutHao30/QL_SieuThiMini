import 'package:supabase/supabase.dart';

void main() async {
  final client = SupabaseClient(
    'https://bdzvjxsymdwvxkrdnopj.supabase.co',
    'sb_publishable_9OHzKxRCgOLTHMDS5hD59w_GfvOhN1t',
  );

  print('Subscribing...');
  client.channel('public:chat_messages_notifications').onPostgresChanges(
    event: PostgresChangeEvent.insert,
    schema: 'public',
    table: 'chat_messages',
    callback: (payload) {
      print('New message: ${payload.newRecord}');
    }
  ).subscribe((status, [error]) {
    print('Status: $status, error: $error');
  });

  await Future.delayed(Duration(seconds: 10));
}
