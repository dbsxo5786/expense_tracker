# 파일: backend/app/__init__.py

from flask import Flask
from flask_sqlalchemy import SQLAlchemy
from flask_cors import CORS 

db = SQLAlchemy()

def create_app():
    app = Flask(__name__)
    
    # JSON 응답 시 ASCII 대신 UTF-8을 사용하도록 설정
    app.json.ensure_ascii = False 
    # ---------------------

    CORS(app) 

    app.config['SQLALCHEMY_DATABASE_URI'] = 'sqlite:///expenses.db'
    app.config['SQLALCHEMY_TRACK_MODIFICATIONS'] = False

    db.init_app(app)

    with app.app_context():
        from . import routes 
        from . import models
        
        db.create_all()

    return app