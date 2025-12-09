from . import db  # __init__.py에서 생성한 db 객체를 임포트
from datetime import datetime # 시간 기록을 위해 임포트

class Expense(db.Model):
    
    id = db.Column(db.Integer, primary_key=True)
    amount = db.Column(db.Float, nullable=False)
    description = db.Column(db.String(200), nullable=True)
    category = db.Column(db.String(50), nullable=False)
    # timestamp는 기본값으로 현재 시간을 자동 저장하도록 설정
    timestamp = db.Column(db.DateTime, default=datetime.utcnow)

    # JSON으로 쉽게 변환하기 위한 헬퍼 함수
    def to_dict(self):
        return {
            'id': self.id,
            'amount': self.amount,
            'description': self.description,
            'category': self.category,
            'timestamp': self.timestamp.isoformat() # 날짜를 문자열로 변환
        }