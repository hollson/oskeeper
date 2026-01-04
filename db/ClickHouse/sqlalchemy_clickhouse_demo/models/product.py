from sqlalchemy import Column, Integer, String, DateTime, Float, Boolean
# 从ClickHouse兼容性角度修改，移除PostgreSQL特定类型
from .base import Base
import uuid
from datetime import datetime


class Product(Base):
    __tablename__ = 'products'

    id = Column(Integer, primary_key=True, autoincrement=True)
    # 修改UUID字段以更好地兼容ClickHouse
    uuid = Column(String, default=lambda: str(uuid.uuid4()), unique=True)
    name = Column(String, nullable=False)
    description = Column(String)
    price = Column(Float, nullable=False)
    stock_quantity = Column(Integer, default=0)
    category = Column(String)
    is_active = Column(Boolean, default=True)
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow,
                        onupdate=datetime.utcnow)

    def __repr__(self):
        return f"<Product(id={self.id}, name='{self.name}', price={self.price})>"
