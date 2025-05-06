import time
import os 
from sqlalchemy import create_engine, select
from sqlalchemy.orm import sessionmaker
from pymongo import MongoClient
from helios.components.internal_db.models import RequestResponseData, Feedback  # Import your SQLAlchemy models
from loguru import logger


# PostgreSQL connection setup
host = os.getenv("INTERNAL_DATABASE_HOST", "localhost")
port = os.getenv("INTERNAL_DATABASE_PORT", 5432)
user = os.getenv("INTERNAL_DATABASE_USER", "postgres")
password = os.getenv("INTERNAL_DATABASE_PASSWORD")

POSTGRES_URL = f"postgresql+psycopg2://{user}:{password}@{host}:{port}/titan-answers"
engine = create_engine(POSTGRES_URL)
Session = sessionmaker(bind=engine)

# MongoDB connection setup
mongo_password = os.getenv("MONGODB_PASSWORD")
MONGO_URI = os.getenv("MONGODB_CONNECTION_STRING").format(password=mongo_password)

mongo_client = MongoClient(MONGO_URI)
mongo_feedback_db_name = os.getenv("MONGODB_FEEDBACK_DB_NAME", "feedback")
mongo_db = mongo_client[mongo_feedback_db_name]
mongo_collection_requests = mongo_db["request_response_data"]
mongo_collection_feedback = mongo_db["feedback"]

# Define polling interval (in seconds) and convert to integer
POLL_INTERVAL = int(os.getenv("FEEDBACK_EXPORT_INTERVAL"))

logger.info(f"Feedback exporter interval set to: {POLL_INTERVAL} seconds")

def fetch_all_data(session, model):
    """
    Fetch all records from PostgreSQL.
    """
    query = select(model)
    return session.execute(query).scalars().all()


def sync_snapshot_to_mongodb():
    """
    Main function to sync snapshot data from PostgreSQL to MongoDB.
    """
    logger.info("Starting the PostgreSQL to MongoDB sync process...")

    while True:
        try:
            with Session() as session:
                logger.info("------------------------------------------------------------")
                # Sync RequestResponseData
                requests_data = fetch_all_data(session, RequestResponseData)
                logger.info(f"Fetched {len(requests_data)} records from request_response_data.")

                mongo_collection_requests.delete_many({})  # Clear existing data
                if requests_data:
                    request_docs = [
                        {
                            "id": req.id,
                            "request_id": req.request_id,
                            "time_created": req.time_created,
                            "time_updated": req.time_updated,
                            "endpoint": req.endpoint,
                            "input": req.input,
                            "output": req.output,
                        }
                        for req in requests_data
                    ]
                    mongo_collection_requests.insert_many(request_docs)
                    logger.info(f"Inserted {len(request_docs)} records into MongoDB: request_response_data.")

                # Sync Feedback
                feedback_data = fetch_all_data(session, Feedback)
                logger.info(f"Fetched {len(feedback_data)} records from feedback.")

                mongo_collection_feedback.delete_many({})  # Clear existing data
                if feedback_data:
                    feedback_docs = [
                        {
                            "id": fb.id,
                            "request_id": fb.request_id,
                            "feedback": fb.feedback,
                            "chunk_id": fb.chunk_id,
                            "time_created": fb.time_created,
                            "time_updated": fb.time_updated,
                        }
                        for fb in feedback_data
                    ]
                    mongo_collection_feedback.insert_many(feedback_docs)
                    logger.info(f"Inserted {len(feedback_docs)} records into MongoDB: feedback.")

            logger.info("Sync completed. Waiting for the next polling interval...")
            logger.info("------------------------------------------------------------")
        except Exception as e:
            logger.error(f"An error occurred: {e}")

        # Wait for the next poll
        time.sleep(POLL_INTERVAL)
        
        
if __name__ == "__main__":
    sync_snapshot_to_mongodb()
