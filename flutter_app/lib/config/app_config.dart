class AppConfig {
  AppConfig._();

  static const String appName = 'Flame';

  // API Configuration
  static const String apiBaseUrl = 'http://10.0.2.2:8080/api/v1';
  static const String wsBaseUrl = 'ws://10.0.2.2:8080/ws';

  // Timeouts
  static const Duration connectionTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
  static const Duration wsReconnectDelay = Duration(seconds: 3);
  static const Duration heartbeatInterval = Duration(seconds: 30);

  // Pagination
  static const int defaultPageSize = 20;
  static const int maxPhotos = 6;

  // Swipe
  static const int swipeCardPreloadCount = 5;
  static const double swipeThreshold = 100.0;

  // Storage Keys
  static const String tokenKey = 'jwt_token';
  static const String userIdKey = 'user_id';
  static const String userDataKey = 'user_data';

  // Validation
  static const int minPasswordLength = 6;
  static const int maxBioLength = 500;
  static const int minAge = 18;
  static const int maxAge = 100;
}
