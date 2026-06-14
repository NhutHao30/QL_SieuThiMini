import 'dart:convert';
import 'dart:io';

void main() async {
  final url = Uri.parse('https://bdzvjxsymdwvxkrdnopj.supabase.co/rest/v1/congno?limit=1');
  final req = await HttpClient().getUrl(url);
  req.headers.add('apikey', 'sb_publishable_9OHzKxRCgOLTHMDS5hD59w_GfvOhN1t');
  final res = await req.close();
  final body = await res.transform(utf8.decoder).join();
  print('CONGNO_RES: $body');
}
