// Notification service — handles local notifications for order status updates.
//
// Uses flutter_local_notifications to display status change alerts
// when the app is in the foreground or background. Notifications
// are triggered by Supabase Realtime order status changes.

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Service for displaying local notifications about order updates.
///
/// Initialization should happen on the first order placement, not
/// on app start, to avoid unnecessary permission prompts.
class NotificationService {
  static final NotificationService _instance = NotificationService._();
  factory NotificationService() => _instance;
  NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  /// Initializes the notification plugin with platform-specific settings.
  ///
  /// Call this before placing the first order. On Android, creates a
  /// notification channel. On iOS, requests permission.
  Future<bool> initialize() async {
    if (_initialized) return true;

    try {
      const androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      const iosSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      const settings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      final result = await _plugin.initialize(
        settings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );

      _initialized = result ?? false;
      debugPrint('[NotificationService] Initialized: $_initialized');
      return _initialized;
    } catch (e) {
      debugPrint('[NotificationService] Initialization failed: $e');
      return false;
    }
  }

  /// Requests notification permissions (iOS only, Android handles via channel).
  Future<void> requestPermissions() async {
    try {
      await _plugin
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(alert: true, badge: true, sound: true);
    } catch (e) {
      debugPrint('[NotificationService] Permission request failed: $e');
    }
  }

  /// Shows a local notification for an order status update.
  ///
  /// [orderId] is used as the notification ID for grouping.
  /// [newStatus] is the updated order status.
  /// [isArabic] determines the notification language.
  Future<void> showOrderStatusUpdate({
    required String orderId,
    required String newStatus,
    bool isArabic = false,
  }) async {
    if (!_initialized) {
      final ok = await initialize();
      if (!ok) return;
    }

    try {
      final title = isArabic ? 'تحديث الطلب' : 'Mise à jour de commande';
      final statusLabel = _getStatusLabel(newStatus, isArabic);
      final shortId = orderId.length > 8
          ? orderId.substring(0, 8).toUpperCase()
          : orderId.toUpperCase();
      final body = isArabic
          ? 'طلبك #$shortId أصبح الآن: $statusLabel'
          : 'Votre commande #$shortId est maintenant: $statusLabel';

      const androidDetails = AndroidNotificationDetails(
        'order_updates',
        'Order Updates',
        channelDescription: 'Notifications about order status changes',
        importance: Importance.high,
        priority: Priority.high,
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      // Use orderId hashCode as notification ID for potential updates.
      await _plugin.show(orderId.hashCode, title, body, details);

      debugPrint(
          '[NotificationService] Notification shown: $shortId -> $newStatus');
    } catch (e) {
      debugPrint('[NotificationService] Error showing notification: $e');
    }
  }

  /// Returns a localized status label.
  String _getStatusLabel(String status, bool isArabic) {
    if (isArabic) {
      return switch (status.toLowerCase()) {
        'pending' => 'قيد الانتظار',
        'confirmed' => 'مؤكد',
        'shipped' => 'تم الشحن',
        'delivered' => 'تم التسليم',
        'cancelled' => 'ملغي',
        _ => status,
      };
    }
    return switch (status.toLowerCase()) {
      'pending' => 'En attente',
      'confirmed' => 'Confirmé',
      'shipped' => 'Expédié',
      'delivered' => 'Livré',
      'cancelled' => 'Annulé',
      _ => status,
    };
  }

  /// Handles notification tap — navigates to the order detail screen.
  ///
  /// Deep linking to order detail is handled by the router configuration.
  static void _onNotificationTapped(dynamic response) {
    debugPrint(
        '[NotificationService] Notification tapped: ${response.payload}');
  }
}
