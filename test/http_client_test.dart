import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:logbook/logbook.dart';

void main() {
  test('LogbookHttpClient logs request and response', () async {
    final logbook = Logbook();
    final logs = <LogEntry>[];
    final subscription = logbook.logStream.listen(logs.add);

    final innerClient = MockClient((request) async {
      return http.Response('{"title": "Test"}', 200);
    });

    final client = LogbookHttpClient(inner: innerClient);

    await client.get(Uri.parse('https://example.com/test'));

    await Future.delayed(Duration.zero); // Wait for stream to propagate

    expect(
      logs.any(
        (l) => l.message.contains('HTTP Request: GET https://example.com/test'),
      ),
      isTrue,
    );
    expect(logs.any((l) => l.message.contains('HTTP Response: 200')), isTrue);

    await subscription.cancel();
  });
}
