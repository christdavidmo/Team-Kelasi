#Ce fichier configure la connexion à la base de données en utilisant SQLAlchemy. Il crée un moteur de connexion et une session pour interagir avec la base de données. 
# La fonction get_db est une dépendance qui peut être utilisée dans les routes pour obtenir une session de base de données.

from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from app.core.config import settings

# L'engine est le moteur de connexion
engine = create_engine(settings.DATABASE_URL)

# SessionLocal est ce qu'on utilisera pour créer des transactions (ajouter un élève, etc.)
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

# Cette fonction sera utilisée comme dépendance dans tes routes
def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()