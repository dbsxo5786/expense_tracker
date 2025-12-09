import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart'; // 날짜 포맷
import '../models/expense.dart'; // Expense 모델
import '../providers/expense_provider.dart';

class AddExpenseScreen extends StatefulWidget {
  // 수정할 Expense 객체를 받을 수 있도록 함
  final Expense? expenseToEdit;

  const AddExpenseScreen({
    super.key,
    this.expenseToEdit, // 생성자에 추가
  });

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  // 폼 입력을 제어하기 위한 컨트롤러
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();

  String? _selectedCategory; // 선택된 카테고리
  bool _isLoading = false;
  DateTime _selectedDate = DateTime.now(); 

  // 수정 모드인지 확인하는 getter
  bool get _isEditMode => widget.expenseToEdit != null;

  @override
  void initState() {
    super.initState();

    // 만약 수정 모드(expenseToEdit가 전달됨)라면
    if (_isEditMode) {
      // 폼 컨트롤러에 기존 값 채우기
      _amountController.text = widget.expenseToEdit!.amount.toStringAsFixed(0);
      _selectedCategory = widget.expenseToEdit!.category;
      _descriptionController.text = widget.expenseToEdit!.description;
      // [수정] 수정 모드일 때 기존 날짜로 설정
      _selectedDate = DateTime.parse(widget.expenseToEdit!.timestamp);
    }
  }

  // 날짜 선택기를 띄우는 함수
  Future<void> _presentDatePicker() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020), // 선택 가능한 가장 이른 날짜
      lastDate: DateTime.now(), // 선택 가능한 가장 늦은 날짜 (오늘)
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  // '저장' 또는 '수정' 버튼을 눌렀을 때 실행될 함수
  Future<void> _submitExpense() async {
    // 폼 유효성 검사
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    // 컨트롤러에서 값 읽기
    final double amount = double.tryParse(_amountController.text) ?? 0.0;
    final String category = _selectedCategory!; // Validator가 null이 아님을 보장
    final String description = _descriptionController.text;

    // [수정] 선택된 날짜(_selectedDate)를 timestamp 변수에 할당
    final DateTime timestamp = _selectedDate;

    try {
      final provider = Provider.of<ExpenseProvider>(context, listen: false);

      if (_isEditMode) {
        // --- 수정 모드 ---
        await provider.updateExpense(
          widget.expenseToEdit!.id, // ID 전달
          amount,
          category,
          description,
          timestamp, // [수정] timestamp 전달
        );
      } else {
        // --- 추가 모드 (기존 로직) ---
        await provider.addExpense(
          amount,
          category,
          description,
          timestamp, // [수정] timestamp 전달
        );
      }

      // 성공 시, 홈 화면으로 돌아가기
      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      // 에러 처리
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_isEditMode ? '수정 실패: $e' : '저장 실패: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // AppBar 제목 동적 변경
      appBar: AppBar(title: Text(_isEditMode ? '경비 수정' : '새 경비 추가')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: ListView(
                  children: [
                    TextFormField(
                      controller: _amountController,
                      decoration: const InputDecoration(
                        labelText: '금액',
                        icon: Icon(Icons.attach_money_rounded),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return '금액을 입력하세요.';
                        }
                        if (double.tryParse(value) == null) {
                          return '유효한 숫자를 입력하세요.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    DropdownButtonFormField<String>(
                      value: _selectedCategory,
                      decoration: const InputDecoration(
                        labelText: '카테고리',
                        icon: Icon(Icons.category_rounded),
                      ),
                      items: ['식비', '교통', '여가', '쇼핑', '기타']
                          .map(
                            (category) => DropdownMenuItem(
                              value: category,
                              child: Text(category),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedCategory = value;
                        });
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return '카테고리를 선택하세요.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // 날짜 선택기 UI
                    ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12.0,
                      ),
                      leading: const Icon(Icons.calendar_today_rounded),
                      title: const Text('날짜'),
                      subtitle: Text(
                        // 'intl' 패키지를 사용해 날짜 포맷
                        DateFormat(
                          'yyyy년 MM월 dd일 (E)',
                          'ko_KR',
                        ).format(_selectedDate),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      trailing: const Icon(Icons.arrow_drop_down),
                      onTap: _presentDatePicker,
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(
                        labelText: '설명 (선택)',
                        icon: Icon(Icons.edit_note_rounded),
                      ),
                    ),
                    const SizedBox(height: 32),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _submitExpense,
                        icon: const Icon(Icons.save_rounded),
                        label: Text(_isEditMode ? '수정하기' : '저장하기'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          textStyle: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
