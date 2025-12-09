import os  # 환경 변수 사용을 위해 임포트
from datetime import datetime # datetime 임포트
from dateutil.parser import isoparse # 날짜 문자열 파싱을 위해 임포트
from google import genai  # 새 라이브러리 임포트
from flask import current_app, jsonify, request
from .models import db, Expense

# --- Gemini Client 초기화 ---
try:
    # 1. API 키를 환경 변수에서 로드합니다.
    #    'GEMINI_API_KEY'라는 이름의 환경 변수를 설정해야 합니다.
    #    genai.Client()는 인자 없이 호출 시 자동으로 'GEMINI_API_KEY'를 읽어옵니다.
    client = genai.Client()

except Exception as e:
    print(f"Gemini Client 초기화 실패: {e}")
    print(">>> 중요: 터미널에서 'GEMINI_API_KEY' 환경 변수가 올바르게 설정되었는지 확인하세요.")
    client = None  # 초기화 실패 시 client를 None으로 설정

# [API 1: POST /api/v1/expenses]
@current_app.route('/api/v1/expenses', methods=['POST'])
def add_expense():
    data = request.json
    if not data or not 'amount' in data or not 'category' in data:
        return jsonify({'error': 'Missing required fields (amount, category)'}), 400
    
    # 1. 'timestamp' 값을 JSON에서 받습니다.
    timestamp_str = data.get('timestamp')
    
    # 2. 값이 있으면 ISO 8601 문자열을 datetime 객체로 변환
    #    값이 없으면 (혹은 비어있으면) 지금 시간을 기본값으로 사용
    if timestamp_str:
        try:
            expense_time = isoparse(timestamp_str)
        except ValueError:
            return jsonify({'error': 'Invalid timestamp format. Use ISO 8601.'}), 400
    else:
        expense_time = datetime.utcnow()
    # -------------

    new_expense = Expense(
        amount=data['amount'],
        description=data.get('description'),
        category=data['category'],
        timestamp=expense_time 
    )
    try:
        db.session.add(new_expense)
        db.session.commit()
        return jsonify(new_expense.to_dict()), 201
    except Exception as e:
        db.session.rollback()
        return jsonify({'error': str(e)}), 500
    
@current_app.route('/api/v1/expenses', methods=['GET'])
def get_expenses():
    try:
        expenses = db.session.execute(db.select(Expense).order_by(Expense.timestamp.desc())).scalars()
        expense_list = [expense.to_dict() for expense in expenses]
        return jsonify(expense_list), 200
    except Exception as e:
        return jsonify({'error': str(e)}), 500


# [API 3: AI 기반 지출 요약 ]
@current_app.route('/api/v1/expenses/summary-ai', methods=['GET'])
def get_ai_summary():
    #  'gemini_model' 대신 'client'가 None인지 확인
    if not client:
        return jsonify({"error": "Gemini API가 설정되지 않았습니다."}), 500

    try:
        expenses = db.session.execute(db.select(Expense).order_by(Expense.timestamp.desc())).scalars()
        expense_list = [expense.to_dict() for expense in expenses]

        if not expense_list:
            return jsonify({"summary": "분석할 지출 내역이 없습니다."}), 200

        prompt = f"""
        당신은 친절하고 전문적인 금융 비서입니다.
        다음은 사용자의 최근 지출 내역(JSON 리스트)입니다:
        {expense_list}
        
        이 지출 내역을 바탕으로 최근 일주일 이내 지출내역을 다음 항목들을 분석해주세요:
        1.  총 지출액: 
        2.  주요 지출 카테고리 Top 3: (가장 많이 쓴 카테고리 3개와 각각의 총액)
        3.  간단한 소비 패턴 분석 및 조언: (예: "식비 비중이 높습니다. 배달 대신 요리를 고려해보세요.")
        
        위 3가지 항목으로 인한 분석 결과를 바탕으로 다음 내용만 출력해주세요!
        1. 일주일 동안의 지출액: (일주일 동안 얼마나 썼는지)
        2. 주요 지출 카테고리 TOP 3:
        3. 분석 및 조언: (여기는 간단하게 2~3줄 정도로만)
        """

        #  'client.models.generate_content' 메서드 사용
        # - 'model' 인자에 모델 이름을 문자열로 전달
        # - 프롬프트는 'contents' 인자에 전달
        response = client.models.generate_content(
            model="gemini-2.5-flash",  # 모델 이름
            contents=prompt    
        )

        return jsonify({"summary": response.text}), 200

    except Exception as e:
        print(f"Gemini API 호출 오류: {e}")
        return jsonify({"error": f"AI 요약 생성 중 오류 발생: {e}"}), 500
    
# [API 4: DELETE /api/v1/expenses/<id>]
@current_app.route('/api/v1/expenses/<int:id>', methods=['DELETE'])
def delete_expense(id):
    try:
        # 1. ID로 지출 내역 찾기
        expense = db.session.get(Expense, id)
        
        # 2. 없으면 404
        if not expense:
            return jsonify({'error': 'Expense not found'}), 404

        # 3. 있으면 삭제 후 커밋
        db.session.delete(expense)
        db.session.commit()
        
        # 4. 성공 응답
        return jsonify({'message': 'Expense deleted successfully'}), 200
    except Exception as e:
        db.session.rollback()
        return jsonify({'error': str(e)}), 500

# [API 5: PUT /api/v1/expenses/<id>]
@current_app.route('/api/v1/expenses/<int:id>', methods=['PUT'])
def update_expense(id):
    try:
        expense = db.session.get(Expense, id)
        if not expense:
            return jsonify({'error': 'Expense not found'}), 404

        data = request.json
        if not data or not 'amount' in data or not 'category' in data:
            return jsonify({'error': 'Missing required fields (amount, category)'}), 400

        expense.amount = data['amount']
        expense.category = data['category']
        expense.description = data.get('description', expense.description) 

        # 1. 'timestamp' 값을 JSON에서 받습니다.
        timestamp_str = data.get('timestamp')
        
        # 2. 값이 있으면 ISO 8601 문자열을 datetime 객체로 변환
        if timestamp_str:
            try:
                expense.timestamp = isoparse(timestamp_str)
            except ValueError:
                return jsonify({'error': 'Invalid timestamp format. Use ISO 8601.'}), 400
        # (값이 없으면 기존 timestamp는 변경하지 않음)
        # -------------

        db.session.commit()
        return jsonify(expense.to_dict()), 200
    except Exception as e:
        db.session.rollback()
        return jsonify({'error': str(e)}), 500