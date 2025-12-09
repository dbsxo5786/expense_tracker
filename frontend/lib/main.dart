// 파일: frontend/lib/main.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart'; // 날짜 초기화

import 'providers/expense_provider.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('ko_KR', null); // 한국어 날짜 포맷 초기화

  runApp(
    ChangeNotifierProvider(
      create: (context) => ExpenseProvider(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      // [수정] 이 줄을 추가하여 DEBUG 리본을 없앱니다.
      debugShowCheckedModeBanner: false,

      title: '경비 추적기',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        // (선택사항) 앱 전체 폰트나 스타일을 여기서 더 꾸밀 수도 있습니다.
        scaffoldBackgroundColor: Colors.white,
        useMaterial3: true, // 최신 머티리얼 3 디자인 적용
      ),
      home: const HomeScreen(),
    );
  }
}
