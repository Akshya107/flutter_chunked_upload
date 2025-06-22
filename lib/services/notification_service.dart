import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/foundation.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();

  factory NotificationService() => _instance;

  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    try {
      const AndroidInitializationSettings androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      const DarwinInitializationSettings iosSettings =
          DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      const InitializationSettings settings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      final bool? initialized = await _plugin.initialize(settings);
      debugPrint('NotificationService initialized: $initialized');

      // Create notification channel for Android
      await _createNotificationChannel();
    } catch (e) {
      debugPrint('Failed to initialize NotificationService: $e');
    }
  }

  Future<void> _createNotificationChannel() async {
    if (defaultTargetPlatform == TargetPlatform.android) {
      const AndroidNotificationChannel channel = AndroidNotificationChannel(
        'uploads_channel',
        'Uploads',
        description: 'Upload completion notifications',
        importance: Importance.max,
        playSound: true,
        enableVibration: true,
      );

      await _plugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);

      debugPrint('Notification channel created');
    }
  }

  Future<void> showUploadSuccessNotification(String uploadId) async {
    try {
      const AndroidNotificationDetails androidDetails =
          AndroidNotificationDetails(
        'uploads_channel',
        'Uploads',
        channelDescription: 'Upload completion notifications',
        importance: Importance.max,
        priority: Priority.high,
        showWhen: true,
        enableVibration: true,
        playSound: true,
      );

      const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const NotificationDetails details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _plugin.show(
        uploadId.hashCode,
        'Upload Completed',
        'Job $uploadId completed successfully.',
        details,
      );

      debugPrint('Success notification shown for: $uploadId');
    } catch (e) {
      debugPrint('Failed to show success notification: $e');
    }
  }

  Future<void> showUploadFailedAndRetryNotification(String uploadId) async {
    try {
      const AndroidNotificationDetails androidDetails =
          AndroidNotificationDetails(
        'uploads_channel',
        'Uploads',
        channelDescription: 'Upload retry notifications',
        importance: Importance.max,
        priority: Priority.high,
        showWhen: true,
        enableVibration: true,
        playSound: true,
      );

      const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const NotificationDetails details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _plugin.show(
        uploadId.hashCode,
        'Upload Failed - Retrying',
        'Job $uploadId failed and will retry.',
        details,
      );

      debugPrint('Retry notification shown for: $uploadId');
    } catch (e) {
      debugPrint('Failed to show retry notification: $e');
    }
  }

  Future<void> showUploadFailedNotification(String uploadId) async {
    try {
      const AndroidNotificationDetails androidDetails =
          AndroidNotificationDetails(
        'uploads_channel',
        'Uploads',
        channelDescription: 'Upload failed notifications',
        importance: Importance.max,
        priority: Priority.high,
        showWhen: true,
        enableVibration: true,
        playSound: true,
      );

      const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const NotificationDetails details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _plugin.show(
        uploadId.hashCode,
        'Upload Failed',
        'Job $uploadId failed permanently.',
        details,
      );

      debugPrint('Failure notification shown for: $uploadId');
    } catch (e) {
      debugPrint('Failed to show failure notification: $e');
    }
  }
}
