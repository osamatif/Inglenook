import 'dart:async';
import 'package:flutter/foundation.dart';

/// Centralized error logging service
/// Integrates with Firebase Crashlytics or other logging services
///
/// Usage:
/// ```dart
/// try {
///   // risky operation
/// } catch (e, stackTrace) {
///   ErrorLogger.logError(e, stackTrace);
/// }
/// ```

class ErrorLogger {
  static bool _initialized = false;

  /// Initialize error logging service
  /// Call this in main() before runApp()
  static Future<void> initialize() async {
    if (_initialized) return;

    // Set up Flutter error handling
    FlutterError.onError = (FlutterErrorDetails details) {
      FlutterError.presentError(details);
      logError(
        details.exception,
        details.stack,
        reason: details.context?.toString(),
      );
    };

    // Set up async error handling
    PlatformDispatcher.instance.onError = (error, stack) {
      logError(error, stack);
      return true;
    };

    _initialized = true;
    _log('ErrorLogger initialized');
  }

  /// Log an error
  static void logError(
    dynamic error,
    StackTrace? stackTrace, {
    String? reason,
    Map<String, dynamic>? additionalData,
  }) {
    // In debug mode, print to console
    if (kDebugMode) {
      print('ERROR: $error');
      if (reason != null) print('REASON: $reason');
      if (stackTrace != null) print('STACK TRACE:\n$stackTrace');
      if (additionalData != null) print('DATA: $additionalData');
    }

    // TODO: Send to Firebase Crashlytics
    // FirebaseCrashlytics.instance.recordError(error, stackTrace, reason: reason);

    // TODO: Send to custom analytics/logging service
    // _sendToAnalytics(error, stackTrace, reason, additionalData);
  }

  /// Log a non-fatal error
  static void logNonFatal(
    String message, {
    Map<String, dynamic>? additionalData,
  }) {
    if (kDebugMode) {
      print('NON-FATAL: $message');
      if (additionalData != null) print('DATA: $additionalData');
    }

    // TODO: Send to analytics
    // _sendToAnalytics(message, null, null, additionalData);
  }

  /// Log a warning
  static void logWarning(
    String message, {
    Map<String, dynamic>? additionalData,
  }) {
    if (kDebugMode) {
      print('WARNING: $message');
      if (additionalData != null) print('DATA: $additionalData');
    }

    // TODO: Send to analytics
  }

  /// Log an event (for analytics)
  static void logEvent(
    String eventName, {
    Map<String, dynamic>? parameters,
  }) {
    if (kDebugMode) {
      print('EVENT: $eventName');
      if (parameters != null) print('PARAMS: $parameters');
    }

    // TODO: Send to Firebase Analytics
    // FirebaseAnalytics.instance.logEvent(name: eventName, parameters: parameters);
  }

  /// Log network error
  static void logNetworkError(
    String url,
    int? statusCode,
    String? message, {
    Map<String, dynamic>? requestData,
  }) {
    logError(
      'Network Error: $url',
      StackTrace.current,
      reason: 'Status: $statusCode, Message: $message',
      additionalData: {
        'url': url,
        'statusCode': statusCode,
        'message': message,
        ...?requestData,
      },
    );
  }

  /// Log authentication error
  static void logAuthError(
    String operation,
    dynamic error, {
    String? userId,
  }) {
    logError(
      error,
      StackTrace.current,
      reason: 'Auth Error during: $operation',
      additionalData: {
        'operation': operation,
        'userId': userId,
      },
    );
  }

  /// Log payment error
  static void logPaymentError(
    String operation,
    dynamic error, {
    String? orderId,
    double? amount,
  }) {
    logError(
      error,
      StackTrace.current,
      reason: 'Payment Error during: $operation',
      additionalData: {
        'operation': operation,
        'orderId': orderId,
        'amount': amount,
      },
    );
  }

  /// Set user identifier (for Crashlytics)
  static void setUserId(String userId) {
    if (kDebugMode) {
      print('USER ID SET: $userId');
    }

    // TODO: Set in Crashlytics
    // FirebaseCrashlytics.instance.setUserIdentifier(userId);
  }

  /// Set custom key for debugging
  static void setCustomKey(String key, dynamic value) {
    if (kDebugMode) {
      print('CUSTOM KEY: $key = $value');
    }

    // TODO: Set in Crashlytics
    // FirebaseCrashlytics.instance.setCustomKey(key, value);
  }

  /// Helper method for internal logging
  static void _log(String message) {
    if (kDebugMode) {
      print('[ErrorLogger] $message');
    }
  }

  /// Track performance
  static Future<T> trackPerformance<T>(
    String operation,
    Future<T> Function() function,
  ) async {
    final stopwatch = Stopwatch()..start();

    try {
      final result = await function();
      stopwatch.stop();

      if (kDebugMode) {
        print('PERFORMANCE: $operation took ${stopwatch.elapsedMilliseconds}ms');
      }

      // TODO: Send to Firebase Performance
      // final trace = FirebasePerformance.instance.newTrace(operation);
      // await trace.start();
      // await trace.stop();

      return result;
    } catch (e, stackTrace) {
      stopwatch.stop();
      logError(
        e,
        stackTrace,
        reason: 'Error during $operation',
        additionalData: {
          'operation': operation,
          'duration_ms': stopwatch.elapsedMilliseconds,
        },
      );
      rethrow;
    }
  }
}
