import 'package:http/http.dart' as http;
import 'package:logbook/logbook.dart';

/// A wrapper around [http.Client] that logs requests and responses to [Logbook].
class LogbookHttpClient extends http.BaseClient {
  final http.Client _inner;

  LogbookHttpClient({http.Client? inner}) : _inner = inner ?? http.Client();

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final stopwatch = Stopwatch()..start();
    final logbook = Logbook();

    try {
      // Log Request
      logbook.info(
        'HTTP Request: ${request.method} ${request.url}',
        category: LogCategory.network,
      );
      // Note: We might want to log headers or body, but body is a stream in BaseRequest
      // so it's tricky to read without consuming it unless we copy it.
      // For now, let's just log the basics to avoid performance issues or stream consumption issues.

      final response = await _inner.send(request);
      stopwatch.stop();

      // Log Response
      logbook.info(
        'HTTP Response: ${response.statusCode} - ${request.url} (${stopwatch.elapsedMilliseconds}ms)',
        category: LogCategory.network,
      );

      return response;
    } catch (e, stackTrace) {
      stopwatch.stop();
      logbook.error(
        'HTTP Error: ${request.method} ${request.url} (${stopwatch.elapsedMilliseconds}ms)',
        category: LogCategory.network,
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }
}
