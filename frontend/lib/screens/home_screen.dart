import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/scheduler.dart';
import 'package:intl/intl.dart'; // 날짜 포맷
import 'package:table_calendar/table_calendar.dart'; // 캘린더 패키지

import '../providers/expense_provider.dart';
import '../models/expense.dart';
import 'add_expense_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // 캘린더 상태 변수
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay; // 앱 시작 시 오늘 날짜 선택

    // 데이터 로드
    SchedulerBinding.instance.addPostFrameCallback((_) {
      Provider.of<ExpenseProvider>(context, listen: false).fetchExpenses();
    });
  }

  /// 특정 날짜(day)에 해당하는 지출 내역만 필터링해서 반환하는 함수
  List<Expense> _getExpensesForDay(DateTime day, List<Expense> allExpenses) {
    return allExpenses.where((expense) {
      // expense.timestamp는 ISO 문자열이므로 DateTime으로 변환 후 비교
      final expenseDate = DateTime.parse(expense.timestamp);
      return isSameDay(expenseDate, day);
    }).toList();
  }

  /// 특정 날짜의 지출 총합을 계산하는 함수
  double _getTotalAmountForDay(DateTime day, List<Expense> allExpenses) {
    final dailyExpenses = _getExpensesForDay(day, allExpenses);
    if (dailyExpenses.isEmpty) return 0.0;
    return dailyExpenses.fold(0.0, (sum, item) => sum + item.amount);
  }

  @override
  Widget build(BuildContext context) {
    // Provider로부터 전체 데이터를 가져옴
    final provider = Provider.of<ExpenseProvider>(context);
    final allExpenses = provider.expenses;

    // 현재 선택된 날짜의 지출 목록 (하단 리스트용)
    final selectedExpenses = _getExpensesForDay(_selectedDay!, allExpenses);

    return Scaffold(
      // [디자인] 깔끔한 앱바 유지
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 2,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.calendar_month_rounded, color: Colors.blue.shade700),
            const SizedBox(width: 8),
            const Text(
              '월별 지출 현황',
              style: TextStyle(
                color: Colors.black87,
                fontWeight: FontWeight.w800,
                fontSize: 20,
              ),
            ),
          ],
        ),
        actions: [
          // AI 분석 버튼을 앱바 우측으로 이동 (공간 효율)
          IconButton(
            icon: Icon(
              Icons.auto_awesome_rounded,
              color: provider.isAnalyzing ? Colors.grey : Colors.amber,
            ),
            onPressed: provider.isAnalyzing
                ? null
                : () {
                    _showAiSummaryDialog(context, provider);
                  },
          ),
          const SizedBox(width: 8),
        ],
      ),

      body: Column(
        children: [
          // ---------------- [1] 캘린더 영역 ----------------
          Card(
            margin: const EdgeInsets.all(8.0),
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: TableCalendar(
              locale: 'ko_KR', // 한국어 달력
              firstDay: DateTime.utc(2020, 1, 1),
              lastDay: DateTime.utc(2030, 12, 31),
              focusedDay: _focusedDay,
              calendarFormat: _calendarFormat,

              // 날짜 선택 로직
              selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
              onDaySelected: (selectedDay, focusedDay) {
                setState(() {
                  _selectedDay = selectedDay;
                  _focusedDay = focusedDay;
                });
              },
              onFormatChanged: (format) {
                setState(() {
                  _calendarFormat = format;
                });
              },
              onPageChanged: (focusedDay) {
                _focusedDay = focusedDay;
              },

              // 캘린더 스타일 커스터마이징
              headerStyle: const HeaderStyle(
                formatButtonVisible: false, // '2주', '월' 버튼 숨김
                titleCentered: true,
                titleTextStyle: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              calendarStyle: CalendarStyle(
                todayDecoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.5),
                  shape: BoxShape.circle,
                ),
                selectedDecoration: BoxDecoration(
                  color: Colors.blue.shade700,
                  shape: BoxShape.circle,
                ),
              ),

              //  날짜 셀 커스텀 빌더 (총액 표시)
              calendarBuilders: CalendarBuilders(
                // 날짜 아래에 마커(총액)를 표시하는 빌더
                markerBuilder: (context, date, events) {
                  // 해당 날짜의 총액 계산
                  final totalAmount = _getTotalAmountForDay(date, allExpenses);

                  if (totalAmount > 0) {
                    return Positioned(
                      right: 1,
                      bottom: 1,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: Colors.red.shade200),
                        ),
                        child: Text(
                          // 금액을 '1.5만', '3000' 등으로 짧게 표시하면 좋지만
                          // 여기선 단순히 포맷팅해서 보여줌
                          NumberFormat.compact(
                            locale: "ko_KR",
                          ).format(totalAmount),
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.red.shade800,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    );
                  }
                  return null;
                },
              ),
            ),
          ),

          const Divider(height: 1),

          // ---------------- [2] 선택된 날짜의 상세 리스트 ----------------
          Expanded(
            child: provider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : Column(
                    children: [
                      // 리스트 헤더 (선택된 날짜 표시)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              DateFormat(
                                'M월 d일 (E)',
                                'ko_KR',
                              ).format(_selectedDay!),
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            Text(
                              '총 ${_getTotalAmountForDay(_selectedDay!, allExpenses).toStringAsFixed(0)}원',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue.shade800,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // 실제 리스트
                      Expanded(
                        child: selectedExpenses.isEmpty
                            ? Center(
                                child: Text(
                                  '지출 내역이 없습니다.',
                                  style: TextStyle(color: Colors.grey.shade500),
                                ),
                              )
                            : ListView.builder(
                                itemCount: selectedExpenses.length,
                                itemBuilder: (context, index) {
                                  return ExpenseListItemCard(
                                    expense: selectedExpenses[index],
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
          ),
        ],
      ),

      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddExpenseScreen()),
          ).then((_) {
            // 돌아왔을 때 데이터 갱신 (선택된 날짜 유지)
            provider.fetchExpenses();
          });
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  /// AI 분석 다이얼로그 (캘린더 뷰로 바뀌면서 팝업 형태로 변경 제안)
  void _showAiSummaryDialog(BuildContext context, ExpenseProvider provider) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.5,
          minChildSize: 0.3,
          maxChildSize: 0.8,
          expand: false,
          builder: (context, scrollController) {
            return SingleChildScrollView(
              controller: scrollController,
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      const Icon(Icons.auto_awesome, color: Colors.amber),
                      const SizedBox(width: 8),
                      const Text(
                        'Gemini AI 지출 분석',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  if (provider.aiSummary.isEmpty && !provider.isAnalyzing)
                    Center(
                      child: ElevatedButton(
                        onPressed: () {
                          provider.fetchAiSummary();
                          // setState가 필요할 수 있으나 Provider Consumer가 상위라면 자동 갱신됨.
                          // 여기서는 ModalSheet 내부라 Consumer를 따로 감싸주는게 좋음.
                        },
                        child: const Text("지금 분석 시작"),
                      ),
                    ),

                  // Consumer를 사용하여 상태 변화 감지
                  Consumer<ExpenseProvider>(
                    builder: (context, prov, child) {
                      if (prov.isAnalyzing) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (prov.aiSummary.isNotEmpty) {
                        return Text(
                          prov.aiSummary,
                          style: const TextStyle(fontSize: 16, height: 1.6),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class ExpenseListItemCard extends StatelessWidget {
  final Expense expense;

  const ExpenseListItemCard({super.key, required this.expense});

  IconData _getIconForCategory(String category) {
    switch (category.toLowerCase()) {
      case '식비':
        return Icons.fastfood_rounded;
      case '교통':
        return Icons.directions_bus_rounded;
      case '여가':
        return Icons.sports_esports_rounded;
      case '쇼핑':
        return Icons.shopping_bag_rounded;
      default:
        return Icons.receipt_long_rounded;
    }
  }

  String _formatTimestamp(String isoTimestamp) {
    final DateTime date = DateTime.parse(isoTimestamp);
    return DateFormat.jm('ko_KR').format(date);
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0, // 리스트 내부라 평평하게
      color: Colors.grey.shade50, // 살짝 배경색
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.blue.shade100,
          child: Icon(
            _getIconForCategory(expense.category),
            color: Colors.blue.shade800,
            size: 20,
          ),
        ),
        title: Text(
          expense.category,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          expense.description.isNotEmpty
              ? expense.description
              : _formatTimestamp(expense.timestamp),
        ),
        trailing: Text(
          '${NumberFormat('#,###').format(expense.amount)}원', // 천단위 콤마 추가
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 15,
            color: Colors.blueGrey,
          ),
        ),
        onTap: () {
          _showOptionsDialog(context, expense);
        },
      ),
    );
  }

  // 수정/삭제 옵션 다이얼로그를 표시하는 함수
  void _showOptionsDialog(BuildContext context, Expense expense) {
    final provider = Provider.of<ExpenseProvider>(context, listen: false);

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text(expense.category),
          content: Text(
            '${expense.amount.toStringAsFixed(0)}원\n${expense.description.isNotEmpty ? expense.description : "설명 없음"}',
          ),
          actions: <Widget>[
            // 버튼
            TextButton.icon(
              icon: Icon(Icons.edit_rounded, color: Colors.blue.shade700),
              label: Text('수정', style: TextStyle(color: Colors.blue.shade700)),
              onPressed: () {
                Navigator.pop(dialogContext); // 다이얼로그 닫기

                // AddExpenseScreen으로 이동 (수정 모드)
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        AddExpenseScreen(expenseToEdit: expense),
                  ),
                );
              },
            ),
            // [삭제] 버튼
            TextButton.icon(
              icon: Icon(Icons.delete_rounded, color: Colors.red.shade700),
              label: Text('삭제', style: TextStyle(color: Colors.red.shade700)),
              onPressed: () {
                Navigator.pop(dialogContext); // 옵션 다이얼로그 닫기
                _showDeleteConfirmDialog(context, provider, expense.id);
              },
            ),
          ],
        );
      },
    );
  }

  // 삭제 확인 다이얼로그
  void _showDeleteConfirmDialog(
    BuildContext context,
    ExpenseProvider provider,
    int id,
  ) {
    showDialog(
      context: context,
      builder: (BuildContext confirmContext) {
        return AlertDialog(
          title: const Text('삭제 확인'),
          content: const Text('정말로 이 지출 내역을 삭제하시겠습니까?'),
          actions: [
            TextButton(
              child: const Text('취소'),
              onPressed: () {
                Navigator.pop(confirmContext); // 확인 다이얼로그 닫기
              },
            ),
            TextButton(
              child: Text('삭제', style: TextStyle(color: Colors.red.shade700)),
              onPressed: () async {
                try {
                  // Provider를 통해 삭제 실행
                  await provider.deleteExpense(id);
                  Navigator.pop(confirmContext); // 확인 다이로그 닫기

                  if (context.mounted) {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(const SnackBar(content: Text('삭제되었습니다.')));
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text('삭제 실패: $e')));
                  }
                }
              },
            ),
          ],
        );
      },
    );
  }
}
