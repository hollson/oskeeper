from sqlalchemy import Column, Integer, String, DateTime, Boolean
# 从ClickHouse兼容性角度修改，移除PostgreSQL特定类型
from .base import Base
import uuid
from datetime import datetime


class User(Base):
    __tablename__ = 'users'

    id = Column(Integer, primary_key=True, autoincrement=True)
    # 修改UUID字段以更好地兼容ClickHouse
    uuid = Column(String, default=lambda: str(uuid.uuid4()), unique=True)
    username = Column(String, nullable=False, unique=True)
    email = Column(String, nullable=False, unique=True)
    first_name = Column(String)
    last_name = Column(String)
    age = Column(Integer)
    is_active = Column(Boolean, default=True)
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow,
                        onupdate=datetime.utcnow)

    def __repr__(self):
        return f"<User(id={self.id}, username='{self.username}', email='{self.email}')>"
