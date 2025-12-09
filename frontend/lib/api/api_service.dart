import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'dart:convert'; // jsonDecode, jsonEncode, utf8

class ApiService {
  // kIsWeb을 사용해 웹/모바일(안드로이드) IP 자동 전환
  static final String _baseUrl = kIsWeb
      ? 'http://localhost:8000' // 웹으로 실행 시
      : 'http://10.0.2.2:8000'; // 안드로이드 에뮬레이터로 실행 시

  // [API 2: GET /api/v1/expenses]
  // 모든 경비 목록을 가져오는 함수
  Future<List<Map<String, dynamic>>> getExpenses() async {
    final response = await http.get(Uri.parse('$_baseUrl/api/v1/expenses'));

    if (response.statusCode == 200) {
      // 한글 처리를 위해 utf8.decode 사용
      final List<dynamic> data = jsonDecode(utf8.decode(response.bodyBytes));
      return data.cast<Map<String, dynamic>>();
    } else {
      throw Exception('Failed to load expenses');
    }
  }

  // [API 1: POST /api/v1/expenses] 
  Future<Map<String, dynamic>> addExpense(
    double amount,
    String category,
    String description,
    String timestamp,
  ) async {
    final Map<String, dynamic> body = {
      'amount': amount,
      'category': category,
      'description': description,
      'timestamp': timestamp, 
    };

    final response = await http.post(
      Uri.parse('$_baseUrl/api/v1/expenses'),
      headers: {'Content-Type': 'application/json; charset=UTF-8'},
      body: jsonEncode(body),
    );

    if (response.statusCode == 201) {
      // 201 Created
      // 한글 처리를 위해 utf8.decode 사용
      return jsonDecode(utf8.decode(response.bodyBytes));
    } else {
      throw Exception('Failed to add expense');
    }
  }

  // [API 3: GET /api/v1/expenses/summary-ai]
  // AI 지출 요약을 가져오는 함수
  Future<String> getAiSummary() async {
    final response = await http.get(
      Uri.parse('$_baseUrl/api/v1/expenses/summary-ai'),
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(
        utf8.decode(response.bodyBytes),
      );
      return data['summary']; // "summary" 키의 텍스트 값만 반환
    } else {
      // API에서 에러 메시지를 보냈을 경우 (예: {"error": "..."})
      final Map<String, dynamic> data = jsonDecode(
        utf8.decode(response.bodyBytes),
      );
      if (data.containsKey('error')) {
        throw Exception(data['error']); // Flask에서 보낸 에러 메시지를 그대로 throw
      }
      throw Exception('AI 요약을 불러오는데 실패했습니다.');
    }
  }

  // [API 4: DELETE /api/v1/expenses/<id>]
  // 경비를 삭제하는 함수
  Future<void> deleteExpense(int id) async {
    final response = await http.delete(
      Uri.parse('$_baseUrl/api/v1/expenses/$id'),
    );

    if (response.statusCode != 200) {
      // 200 OK가 아니면 실패로 간주
      throw Exception('Failed to delete expense');
    }
  }

  // [API 5: PUT /api/v1/expenses/<id>]
  // 경비를 수정하는 함수
  // [API 5: PUT /api/v1/expenses/<id>] 
  Future<Map<String, dynamic>> updateExpense(
    int id,
    double amount,
    String category,
    String description,
    String timestamp, 
  ) async {
    final Map<String, dynamic> body = {
      'amount': amount,
      'category': category,
      'description': description,
      'timestamp': timestamp, 
    };

    final response = await http.put(
      Uri.parse('$_baseUrl/api/v1/expenses/$id'),
      headers: {'Content-Type': 'application/json; charset=UTF-8'},
      body: jsonEncode(body), // Map을 JSON 문자열로 인코딩
    );

    if (response.statusCode == 200) {
      return jsonDecode(utf8.decode(response.bodyBytes));
    } else {
      throw Exception('Failed to update expense');
    }
  }
}
