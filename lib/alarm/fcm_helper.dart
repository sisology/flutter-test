import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// FCM(Firebase Cloud Messaging) 관련 기능을 처리하는 헬퍼 클래스
class FCMHelper {
  /// 필요한 권한을 요청하는 메서드
  static Future<void> requestPermissions() async {
    FirebaseMessaging messaging = FirebaseMessaging.instance;

    // Android 13 이상에서는 명시적 권한 요청이 필요
    if (defaultTargetPlatform == TargetPlatform.android && Platform.isAndroid && await _isAndroid13OrAbove()) {
      NotificationSettings settings = await messaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );
      print('User granted permission: ${settings.authorizationStatus}');
    } else {
      print('No explicit permission required on this OS version.');
    }

    // 알림 권한 요청
    if (await Permission.notification.isDenied) {
      await Permission.notification.request();
      print('Notification permission requested.');
    } else {
      print('Notification permission already granted or not required.');
    }

    // Android 12 이상에서 정확한 알람 권한 요청
    if (Platform.isAndroid) {
      if (await _isAndroid12OrAbove()) {
        var status = await Permission.scheduleExactAlarm.status;
        if (status.isDenied || status.isRestricted || status.isPermanentlyDenied) {
          status = await Permission.scheduleExactAlarm.request();
          print('Exact alarm permission requested.');
        }
        if (!status.isGranted) {
          print("Exact alarms are not permitted");
        } else {
          print("Exact alarms are permitted");
        }
      }
    }
  }

  /// 알림 채널 생성 메서드 (Android 전용)
  static Future<void> createNotificationChannel() async {
    if (Platform.isAndroid) {
      final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
      const AndroidNotificationChannel channel = AndroidNotificationChannel(
        'daily_alarm_channel',
        'Daily Alarm Notifications',
        description: 'This channel is used for daily alarm notifications.',
        importance: Importance.high,
      );

      await flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);

      print('Notification channel created.');
    }
  }

  /// Flutter 로컬 알림 설정 메서드
  static Future<void> setupFlutterNotifications() async {
    final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

    const AndroidInitializationSettings initializationSettingsAndroid =
    AndroidInitializationSettings('@mipmap/ic_launcher');

    final InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
    );

    await flutterLocalNotificationsPlugin.initialize(initializationSettings);

    print('Local notifications initialized.');
  }

  /// FCM 토큰을 가져오고 저장하는 메서드
  static Future<void> getFCMTokenAndSave(String userId) async {
    try {
      String? fcmToken = await FirebaseMessaging.instance.getToken();
      if (fcmToken != null) {
        await _saveFCMToken(userId, fcmToken);
      }
    } catch (e) {
      print('Error getting FCM token: $e');
    }
  }

  /// FCM 토큰을 Supabase에 저장하는 메서드
  static Future<void> _saveFCMToken(String userId, String token) async {
    try {
      final response = await Supabase.instance.client
          .from('fcm_tokens')
          .upsert({
        'member_id': userId,
        'token': token,
      }, onConflict: 'member_id');
      print('FCM token saved or updated: $response');
    } catch (e) {
      print('Error saving FCM token: $e');
    }
  }


  /// Android 버전이 13 이상인지 확인하는 메서드
  static Future<bool> _isAndroid13OrAbove() async {
    if (Platform.isAndroid) {
      var version = await _getAndroidVersion();
      return version != null && version >= 33;
    }
    return false;
  }

  /// Android 버전이 12 이상인지 확인하는 메서드
  static Future<bool> _isAndroid12OrAbove() async {
    if (Platform.isAndroid) {
      var version = await _getAndroidVersion();
      return version != null && version >= 31;
    }
    return false;
  }

  /// Android 버전을 가져오는 메서드
  static Future<int?> _getAndroidVersion() async {
    final DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
    final AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
    return androidInfo.version.sdkInt;
  }
}