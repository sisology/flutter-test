import 'dart:convert';
import 'dart:ffi';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart' as kakao;
import 'package:wisely_diary/alarm/alarm_setting_page.dart';
import 'package:wisely_diary/statistics/monthly_emotion_screens.dart';
import 'package:wisely_diary/today_cartoon.dart';
import 'add_photo_screens.dart';
import 'diary_summary_screens.dart';
import 'custom_scaffold.dart';
import 'home_screens.dart';
import 'kakao/kakao_login.dart';
import 'kakao/main_view_model.dart';
import 'member_information.dart';
import 'test_page.dart';
import 'login_screens.dart';
import 'create_diary_screens.dart';
import 'wait_screens.dart';
import 'select_type_screens.dart';
import 'record_screens.dart';
import 'text_screens.dart';
import 'my_page.dart';
import 'package:gotrue/src/types/user.dart' as gotrue;
import 'package:flutter_dotenv/flutter_dotenv.dart';


// FCM 관련 import
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'alarm/fcm_helper.dart';
import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';

import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // .env 파일 로드
  await dotenv.load(fileName: ".env");

  // Firebase 초기화
  await Firebase.initializeApp();

  // 앱 권한 요청
  await FCMHelper.requestPermissions();

  // 알림 채널 생성 및 초기화
  await FCMHelper.createNotificationChannel();
  await FCMHelper.setupFlutterNotifications();

  // Supabase 초기화
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL'] ?? '',
    anonKey: dotenv.env['SUPABASE_KEY'] ?? '',
  );

  // 안드로이드 알람 매니저 초기화
  await AndroidAlarmManager.initialize();

  // Kakao SDK 초기화
  kakao.KakaoSdk.init(nativeAppKey: dotenv.env['KAKAO_APP_KEY'] ?? '');

  // 로케일 초기화
  await initializeDateFormatting('ko_KR', null);

  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String? memberId;

  @override
  void initState() {
    super.initState();
    _fetchUserId();
  }

  Future<void> _fetchUserId() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      final memberResponse = await Supabase.instance.client
          .from('member')
          .select('member_id')
          .eq('member_id', user.id)
          .single();

      setState(() {
        memberId = memberResponse['member_id'];
      });
    }
  }

  Future<void> _signOut() async {
    await Supabase.instance.client.auth.signOut();
    final GoogleSignIn googleSignIn = GoogleSignIn();
    await googleSignIn.signOut();

    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => MyApp()),
      (Route<dynamic> route) => false,
    );
  }

  Future<void> _saveUserToDatabase(gotrue.User user) async {
    final userData = {
      'member_code': int.parse(user.id.hashCode.toString()),
      'member_email': user.email,
      'join_at': DateTime.now().toIso8601String(),
      'member_name': user.userMetadata?['full_name'],
      'member_status': 'active',
      'password': 'password',
      'member_id': user.id,
    };

    final response = await Supabase.instance.client
        .from('member')
        .upsert(userData)
        .maybeSingle();
  }

  Future<void> _saveKakaoUserToDatabase(
      gotrue.User user, String memberName) async {
    final userData = {
      'member_code': int.parse(user.id.hashCode.toString()),
      'member_email': user.email,
      'join_at': DateTime.now().toIso8601String(),
      'member_name': memberName,
      'member_status': 'active',
      'password': 'password',
      'member_id': user.id,
    };

    final response = await Supabase.instance.client
        .from('member')
        .upsert(userData)
        .maybeSingle();

    final updateResponse = await Supabase.instance.client.auth.updateUser(
      UserAttributes(data: {'full_name': memberName}),
    );
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ));
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      localizationsDelegates: [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: [
        const Locale('ko', 'KR'),
      ],
      locale: const Locale('ko', 'KR'),
      title: 'Wisely Diary',
      theme: ThemeData(
        fontFamily: 'NanumSquareRoundB',
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        scaffoldBackgroundColor: Color(0xFFFDFBF0),
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => LoginPage(),
        '/create-diary-screens': (context) => CreateDiaryPage(),
        '/mypage': (context) => CustomScaffold(
              body: MyPage(),
              title: '마이페이지',
            ),
        '/statistics': (context) => MonthlyEmotionScreen(),
        '/notifications': (context) => AlarmSettingPage(),
        '/today-cartoon': (context) {
          final arguments =
              ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
          final int diaryCode = arguments['diaryCode'];
          return TodayCartoonPage(diaryCode: diaryCode, cartoonUrls: []);
        },
      },
      onGenerateRoute: (settings) {
        if (memberId == null) {
          return MaterialPageRoute(
            builder: (context) => Scaffold(
              body: Center(child: CircularProgressIndicator()),
            ),
          );
        }

        if (settings.name == '/home') {
          final String userId = settings.arguments as String? ?? '';
          return MaterialPageRoute(
            builder: (context) => HomeScreens(userId: memberId!),
          );
        }
        if (settings.name == '/wait') {
          final int emotionNumber = settings.arguments as int;
          return MaterialPageRoute(
            builder: (context) => WaitPage(emotionNumber: emotionNumber),
          );
        }
        if (settings.name == '/text') {
          final int emotionNumber = settings.arguments as int;
          return MaterialPageRoute(
            builder: (context) => TextPage(emotionNumber: emotionNumber),
          );
        }
        if (settings.name == '/select-type') {
          final int emotionNumber = settings.arguments as int;
          return MaterialPageRoute(
            builder: (context) => SelectTypePage(emotionNumber: emotionNumber),
          );
        }
        if (settings.name == '/record') {
          final int emotionNumber = settings.arguments as int;
          return MaterialPageRoute(
            builder: (context) => RecordScreen(emotionNumber: emotionNumber),
          );
        }
        if (settings.name == '/add-photo') {
          final Map<String, dynamic> args =
              settings.arguments as Map<String, dynamic>;
          final String transcription = args['transcription'] ?? '';
          final int diaryCode = args['diaryCode'] ?? 0;

          return MaterialPageRoute(
            builder: (context) => AddPhotoScreen(
              transcription: transcription,
              diaryCode: diaryCode,
            ),
          );
        }
        if (settings.name == '/summary') {
          final Map<String, dynamic> args =
              settings.arguments as Map<String, dynamic>;
          final String transcription = args['transcription'] ?? '';
          final List<File> imageFiles = args['imageFiles'] ?? [];
          final int diaryCode = args['diaryCode'] ?? 0;

          return MaterialPageRoute(
            builder: (context) => DiarySummaryScreen(
              userId: memberId!,
              transcription: transcription,
              imageFiles: imageFiles,
              diaryCode: diaryCode,
            ),
          );
        }
        return null;
      },
    );
  }
}