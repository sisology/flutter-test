import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:permission_handler/permission_handler.dart';


// 알림 표시 함수를 top-level 함수로 변경
@pragma('vm:entry-point')
void showNotification() async {
  print("Alarm triggered at ${DateTime.now()}");
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();



  const androidPlatformChannelSpecifics = AndroidNotificationDetails(
    'daily_alarm_channel',
    'Daily Alarm Notifications',
    importance: Importance.max,
    priority: Priority.high,
    showWhen: true,
    icon: 'notification_logo',
  );

  const platformChannelSpecifics = NotificationDetails(android: androidPlatformChannelSpecifics);

  await flutterLocalNotificationsPlugin.show(
    0,
    '일기 쓸 시간이에요',
    '오늘 하루는 어땠나요? 일기를 작성해보세요.',
    platformChannelSpecifics,
  );
}

class AlarmSettingPage extends StatefulWidget {
  const AlarmSettingPage({Key? key}) : super(key: key);

  @override
  _AlarmSettingPageState createState() => _AlarmSettingPageState();
}

class _AlarmSettingPageState extends State<AlarmSettingPage> {
  TimeOfDay selectedTime = TimeOfDay(hour: 11, minute: 30);
  bool isAlarmEnabled = false;

  late FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin;
  final supabase = Supabase.instance.client;
  String userId = '';

  @override
  void initState() {
    super.initState();
    tz.initializeTimeZones();
    _initializeNotifications();
    _loadAlarmSettings();
    _checkAndRequestPermissions();
    _checkAndRequestExactAlarmPermission();
    _requestBatteryOptimizationExemption();
  }

  // 정확한 알람 권한 확인 및 요청 함수
  Future<void> _checkAndRequestExactAlarmPermission() async {
    if (await Permission.scheduleExactAlarm.isDenied) {
      if (await Permission.scheduleExactAlarm.request().isGranted) {
        print("Exact alarm permission granted");
      } else {
        print("Exact alarm permission denied");
      }
    }
  }

  // 배터리 최적화 예외 요청 함수
  Future<void> _requestBatteryOptimizationExemption() async {
    if (await Permission.ignoreBatteryOptimizations.isDenied) {
      await Permission.ignoreBatteryOptimizations.request();
    }
  }

  Future<void> _checkAndRequestPermissions() async {
    var status = await Permission.notification.status;
    if (!status.isGranted) {
      await Permission.notification.request();
    }

    if (await Permission.ignoreBatteryOptimizations.isDenied) {
      await Permission.ignoreBatteryOptimizations.request();
    }
  }

  void _initializeNotifications() async {
    flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
    const initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');
    final initializationSettings = InitializationSettings(android: initializationSettingsAndroid);
    await flutterLocalNotificationsPlugin.initialize(initializationSettings);
    await AndroidAlarmManager.initialize();
    print('Local notifications and AlarmManager initialized in AlarmSettingPage.');
  }

  Future<void> _scheduleDailyNotification(TimeOfDay time) async {
    final now = DateTime.now();
    final scheduledDate = DateTime(now.year, now.month, now.day, time.hour, time.minute);
    final id = 0;

    // 기존 알람 취소
    await AndroidAlarmManager.cancel(id);

    // 새 알람 설정
    final success = await AndroidAlarmManager.periodic(
      const Duration(days: 1),
      id,
      showNotification,
      exact: true,
      wakeup: true,
      rescheduleOnReboot: true,
      startAt: scheduledDate,
      allowWhileIdle: true,

    );

    print('Daily alarm scheduled: $success for ${scheduledDate.toIso8601String()}');
  }

  // 알람 설정 불러오기
  Future<void> _loadAlarmSettings() async {
    final user = supabase.auth.currentUser;
    if (user?.id != null) {
      final response = await supabase
          .from('member')
          .select('alarm_enabled, alarm_time')
          .eq('member_id', user?.id as Object)
          .single();

      if (response != null) {
        setState(() {
          isAlarmEnabled = response['alarm_enabled'] ?? false;
          if (response['alarm_time'] != null) {
            // 데이터베이스에서 불러온 시간을 UTC로 간주하고 로컬 시간으로 변환
            final utcTime = DateTime.parse('1970-01-01 ${response['alarm_time']}Z');
            final localTime = utcTime.toLocal();

            selectedTime = TimeOfDay(hour: localTime.hour, minute: localTime.minute);

            print('UTC time from DB: ${response['alarm_time']}');
            print('Converted local time: ${localTime.toString()}');
            print('Selected time: ${selectedTime.format(context)}');
          }
        });
        print('Loaded alarm settings: enabled = $isAlarmEnabled, time = ${selectedTime.format(context)}');
      } else {
        print('No alarm settings found for user.');
      }
    } else {
      print('No user logged in.');
    }
  }

  Future<void> _saveAlarmSettings() async {
    final user = supabase.auth.currentUser;
    if (user?.id != null) {
      // 알람 시간도 UTC 시간으로 변환하여 저장
      final localTime = DateTime(1970, 1, 1, selectedTime.hour, selectedTime.minute);
      final utcTime = localTime.toUtc();

      final response = await supabase.from('member').update({
        'alarm_enabled': isAlarmEnabled,
        'alarm_time': isAlarmEnabled
            ? '${utcTime.hour.toString().padLeft(2, '0')}:${utcTime.minute.toString().padLeft(2, '0')}:00'
            : null,
      }).eq('member_id', user?.id as Object);

      print("Alarm settings saved (UTC time): $response");

      if (isAlarmEnabled) {
        await _scheduleDailyNotification(selectedTime);
      } else {
        await flutterLocalNotificationsPlugin.cancelAll();
        print('All notifications canceled.');
      }
    } else {
      print('No user logged in.');
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: selectedTime,
    );
    if (picked != null && picked != selectedTime) {
      setState(() {
        selectedTime = picked;
      });
      print('Selected time: ${selectedTime.format(context)}');
      await _saveAlarmSettings();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Image.asset(
          'assets/wisely-diary-logo.png', // 이미지 경로
          height: 30, // 원하는 크기로 조정
          fit: BoxFit.contain,
        ),
        centerTitle: true,
      ),
      body: Center(
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16.0),
          margin: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                '알림 설정',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              SizedBox(height: 16),
              Card(
                color: Color(0xFFFFFAE1),
                child: SwitchListTile(
                  title: Text('알림 활성화'),
                  value: isAlarmEnabled,
                  onChanged: (bool value) async {
                    setState(() {
                      isAlarmEnabled = value;
                    });
                    print('Alarm enabled state changed: $isAlarmEnabled');
                    await _saveAlarmSettings();
                  },
                  activeColor: Color(0xFFA18BFF),
                  inactiveThumbColor: Colors.grey,

                ),
              ),
              if (isAlarmEnabled)
                SizedBox(height: 16),
              if (isAlarmEnabled)
                Card(
                  color: Color(0xFFFFFAE1),
                  child: ListTile(
                    title: Text('시간'),
                    subtitle: Center(
                      child: Text(
                        '${selectedTime.format(context)}',
                        style: TextStyle(fontSize: 48),
                      ),
                    ),
                    onTap: () {
                      _selectTime(context);
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}