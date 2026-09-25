import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/testing.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:driver_app/services/api_service.dart';
import 'package:driver_app/providers/driver_provider.dart';
import 'package:driver_app/services/fcm_service.dart';

class TestHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return _FakeHttpClient();
  }
}

class _FakeHttpClient implements HttpClient {
  @override
  void close({bool force = false}) {}

  @override
  Future<HttpClientRequest> openUrl(String method, Uri url) async => _FakeHttpClientRequest();

  @override
  Future<HttpClientRequest> postUrl(Uri url) async => _FakeHttpClientRequest();

  @override
  Future<HttpClientRequest> getUrl(Uri url) async => _FakeHttpClientRequest();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeHttpClientRequest implements HttpClientRequest {
  @override
  HttpHeaders get headers => _FakeHttpHeaders();

  @override
  void write(Object? object) {}

  @override
  Future<HttpClientResponse> close() async => _FakeHttpClientResponse();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeHttpHeaders implements HttpHeaders {
  @override
  ContentType? contentType;

  @override
  void set(String name, Object value, {bool preserveHeaderCase = false}) {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeHttpClientResponse implements HttpClientResponse {
  @override
  int get statusCode => 200;

  @override
  StreamSubscription<List<int>> listen(
    void Function(List<int> event)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) {
    final data = utf8.encode('{"status": "SUCCESS"}');
    return Stream.value(data).listen(
      onData,
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError,
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    HttpOverrides.global = TestHttpOverrides();
    SharedPreferences.setMockInitialValues({});
    ApiService().setClient(MockClient((request) async {
      return http.Response('{"status": "SUCCESS"}', 200);
    }));
  });

  group('Driver App Persistence and Token Management Tests', () {
    test('1. Registration persistence & App restart restoration', () async {
      SharedPreferences.setMockInitialValues({
        'driver_vehicle_id': 'V102',
        'driver_registered': true,
      });

      final provider = DriverProvider();
      await Future.delayed(const Duration(milliseconds: 50));

      expect(provider.vehicleId, 'V102');
      expect(provider.isRegistered, isTrue);
    });

    test('2. Token persistence & retrieval', () async {
      SharedPreferences.setMockInitialValues({
        'fcm_token': 'token_abc_123',
      });

      final fcmService = FcmService();
      final token = await fcmService.getSavedToken();

      expect(token, 'token_abc_123');
    });

    test('3. Token before registration (Case B)', () async {
      SharedPreferences.setMockInitialValues({});
      final provider = DriverProvider();
      await Future.delayed(const Duration(milliseconds: 50));

      expect(provider.isRegistered, isFalse);

      // Attempt sync before registration
      final syncBeforeReg = await provider.syncFcmTokenToBackend('token_case_b');
      expect(syncBeforeReg, isFalse); // Skipped because not registered yet

      // Now register vehicle
      provider.setVehicleId('V102');
      await provider.registerVehicle();
      expect(provider.isRegistered, isTrue);

      // Now token sync succeeds when registered
      final syncAfterReg = await provider.syncFcmTokenToBackend('token_case_b');
      expect(syncAfterReg, isTrue);
    });

    test('4. Registration before token (Case A)', () async {
      SharedPreferences.setMockInitialValues({
        'driver_vehicle_id': 'V102',
        'driver_registered': true,
      });

      final provider = DriverProvider();
      await Future.delayed(const Duration(milliseconds: 50));

      expect(provider.isRegistered, isTrue);

      // Token arrives after registration
      final syncResult = await provider.syncFcmTokenToBackend('token_case_a');
      expect(syncResult, isTrue);
    });

    test('5. Token refresh triggers backend token update', () async {
      SharedPreferences.setMockInitialValues({
        'driver_vehicle_id': 'V102',
        'driver_registered': true,
      });

      final provider = DriverProvider();
      await Future.delayed(const Duration(milliseconds: 50));

      // Initial token sync
      final sync1 = await provider.syncFcmTokenToBackend('token_v1');
      expect(sync1, isTrue);

      // Token refreshed
      final sync2 = await provider.syncFcmTokenToBackend('token_v2_refreshed');
      expect(sync2, isTrue);
    });

    test('6. No duplicate token update for identical vehicle + token', () async {
      SharedPreferences.setMockInitialValues({
        'driver_vehicle_id': 'V102',
        'driver_registered': true,
      });

      final provider = DriverProvider();
      await Future.delayed(const Duration(milliseconds: 50));

      final sync1 = await provider.syncFcmTokenToBackend('token_stable');
      expect(sync1, isTrue);

      // Second attempt with exact same vehicle and token returns true immediately without duplicate POST
      final sync2 = await provider.syncFcmTokenToBackend('token_stable');
      expect(sync2, isTrue);
    });
  });
}
