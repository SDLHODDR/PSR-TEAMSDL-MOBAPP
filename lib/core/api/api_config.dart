class ApiConfig {
  const ApiConfig._();

  static const baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    //defaultValue: 'http://192.168.1.2:8080',
    //defaultValue: 'http://192.168.24.113:8080',
    //defaultValue: 'http://192.168.24.144:8080',
    defaultValue: 'http://172.16.255.10:8080',
    //defaultValue: 'http://192.168.21.168:8080',
    //defaultValue: 'http://192.168.191.11:8080',
  );

  // Tour plans use the backend by default. The bundled data can still be used
  // explicitly for offline UI work with --dart-define=USE_MOCK_DATA=true.
  static const useMockData = bool.fromEnvironment(
    'USE_MOCK_DATA',
    defaultValue: false,
  );
}
