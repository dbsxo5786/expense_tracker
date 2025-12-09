import 'package:flutter/material.dart';
import '../models/expense.dart';
import '../api/api_service.dart';

class ExpenseProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();

  List<Expense> _expenses = []; // 경비 목록
  bool _isLoading = false; // 목록 로딩 중 상태

  // --- AI 요약 관련 상태 변수 ---
  String _aiSummary = ""; // AI 요약 텍스트
  bool _isAnalyzing = false; // AI 분석 중 로딩 상태

  // --- Getter ---
  List<Expense> get expenses => _expenses;
  bool get isLoading => _isLoading;
  String get aiSummary => _aiSummary;
  bool get isAnalyzing => _isAnalyzing;

  // [API 2] 경비 목록을 불러오는 메서드
  Future<void> fetchExpenses() async {
    _isLoading = true;
    notifyListeners(); // UI에게 로딩 시작을 알림

    try {
      final List<Map<String, dynamic>> data = await _apiService.getExpenses();
      // Map 리스트를 Expense 객체 리스트로 변환
      _expenses = data.map((json) => Expense.fromJson(json)).toList();
    } catch (e) {
      print('fetchExpenses Error: $e');
      // 실제 앱에서는 사용자에게 오류 메시지를 보여주는 것이 좋습니다.
    } finally {
      _isLoading = false;
      notifyListeners(); // UI에게 로딩 끝을 알림
    }
  }

  // [API 1] 경비를 추가하는 메서드 (날짜 추가됨)
  Future<void> addExpense(
    double amount,
    String category,
    String description,
    DateTime timestamp, // 날짜 인자
  ) async {
    try {
      // API를 통해 서버에 먼저 추가 (날짜 전달)
      await _apiService.addExpense(
        amount,
        category,
        description,
        timestamp.toIso8601String(), // ISO 문자열로 변환
      );

      await fetchExpenses();

      // 새 경비가 추가되면 기존 AI 요약은 더 이상 유효하지 않으므로 초기화
      _aiSummary = "";

      notifyListeners(); // UI에게 목록 변경을 알림
    } catch (e) {
      print('addExpense Error: $e');
      // UI에 에러를 다시 전달하여 SnackBar 등에 표시할 수 있도록 함
      throw Exception('Failed to add expense');
    }
  }

  // [API 3] AI 요약 불러오기 함수
  Future<void> fetchAiSummary() async {
    _isAnalyzing = true;
    _aiSummary = ""; // 이전 요약 초기화
    notifyListeners();

    try {
      // API 서비스를 통해 Gemini 요약 요청
      _aiSummary = await _apiService.getAiSummary();
    } catch (e) {
      // API 서비스에서 throw한 Exception을 처리
      _aiSummary = "오류: 요약을 가져올 수 없습니다. ($e)";
    } finally {
      _isAnalyzing = false;
      notifyListeners(); // 분석 완료 또는 실패 시 UI 업데이트
    }
  }

  // [API 4] 경비 삭제
  Future<void> deleteExpense(int id) async {
    try {
      // 1. API를 통해 서버에서 삭제
      await _apiService.deleteExpense(id);

      // 2. 로컬 리스트에서 해당 항목 제거
      _expenses.removeWhere((expense) => expense.id == id);

      // 3. 데이터가 변경되었으므로 AI 요약 초기화
      _aiSummary = "";

      notifyListeners(); // UI에게 목록 변경을 알림
    } catch (e) {
      print('deleteExpense Error: $e');
      // UI에 에러를 다시 전달하여 SnackBar 등에 표시
      throw Exception('Failed to delete expense');
    }
  }

  // [API 5] 경비 수정 
  Future<void> updateExpense(
    int id,
    double amount,
    String category,
    String description,
    DateTime timestamp, // 날짜 인자
  ) async {
    try {
      // 1. API를 통해 서버에 수정 요청 (업데이트된 객체 반환)
      await _apiService.updateExpense(
        id,
        amount,
        category,
        description,
        timestamp.toIso8601String(), // ISO 문자열로 변환
      );

      await fetchExpenses();

      // 4. 데이터가 변경되었으므로 AI 요약 초기화
      _aiSummary = "";

      notifyListeners(); // UI에게 목록 변경을 알림
    } catch (e) {
      print('updateExpense Error: $e');
      // UI에 에러를 다시 전달
      throw Exception('Failed to update expense');
    }
  }
}
