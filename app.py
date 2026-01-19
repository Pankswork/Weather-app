import logging
import os
import time
import json
import threading
from datetime import datetime, timezone

import boto3
import requests
import mysql.connector
from mysql.connector import Error, pooling
from dotenv import load_dotenv
from flask import Flask, request, render_template, jsonify
from prometheus_client import Counter, CollectorRegistry, make_wsgi_app
from werkzeug.middleware.dispatcher import DispatcherMiddleware

load_dotenv()
app = Flask(__name__)

# Configure structured logging
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')
logger = logging.getLogger(__name__)

# Prometheus Metrics Setup
registry = CollectorRegistry()
WEATHER_QUERIES = Counter('weather_queries_total', 'Total queries', ['city', 'status'], registry=registry)

def get_secret():
    """Fetch database credentials from AWS Secrets Manager."""
    secret_name = os.getenv("AWS_SECRET_NAME", "weather-app-db-creds")
    region_name = os.getenv("AWS_REGION", "us-east-1")

    session = boto3.session.Session()
    client = session.client(service_name='secretsmanager', region_name=region_name)

    try:
        get_secret_value_response = client.get_secret_value(SecretId=secret_name)
        return json.loads(get_secret_value_response['SecretString'])
    except Exception as e:
        logger.error(f"Failed to retrieve secret {secret_name}: {e}")
        return None

# Determine Database Configuration
if os.getenv("USE_AWS_SECRETS", "false").lower() == "true":
    logger.info("Fetching configuration from AWS Secrets Manager...")
    creds = get_secret()
    if creds:
        db_config = {
            'host': creds['host'],
            'user': creds['username'],
            'password': creds['password'],
            'database': creds['dbname'],
            'port': creds['port'],
            'pool_name': 'weather_app_pool',
            'pool_size': 10
        }
    else:
        logger.critical("Could not load AWS secrets.")
        db_config = {}
else:
    db_config = {
        'host': os.getenv("DB_HOST", "db"),
        'user': os.getenv("DB_USER", "weatheruser"),
        'password': os.getenv("DB_PASSWORD", "weatherpass"),
        'database': os.getenv("DB_NAME", "weather_app"),
        'pool_name': 'weather_app_pool',
        'pool_size': 10
    }

# Initialize Connection Pool
db_pool = None
try:
    if db_config:
        db_pool = pooling.MySQLConnectionPool(**db_config)
        logger.info("✅ Database connection pool created.")
except Exception as e:
    logger.error(f"Failed to create connection pool: {e}")

def get_db_connection():
    """Get a connection from the pool."""
    try:
        if db_pool:
            return db_pool.get_connection()
        return mysql.connector.connect(**db_config)
    except Exception as err:
        logger.error(f"Database connection failed: {err}")
        return None

def init_db():
    """Wait for MySQL and initialize the table."""
    max_retries = 15
    for attempt in range(max_retries):
        conn = None
        try:
            logger.info(f"DB Init attempt {attempt + 1}/{max_retries}...")
            conn = get_db_connection()
            if conn and conn.is_connected():
                cursor = conn.cursor()
                cursor.execute("""
                    CREATE TABLE IF NOT EXISTS weather_history (
                        id INT AUTO_INCREMENT PRIMARY KEY,
                        city VARCHAR(255) NOT NULL,
                        temperature VARCHAR(50),
                        description VARCHAR(255),
                        timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP
                    )
                """)
                conn.commit()
                cursor.close()
                logger.info("✅ Database schema initialized!")
                return
            time.sleep(5)
        except Exception as e:
            logger.error(f"Error initializing DB: {e}")
            time.sleep(5)
        finally:
            if conn and conn.is_connected():
                conn.close()

init_db()

@app.route("/", methods=["GET", "POST"])
def index():
    weather_data, history_data = None, []
    if request.method == "POST":
        city = request.form.get("city", "").strip()
        try:
            api_key = os.getenv("WEATHER_API_KEY")
            url = f"http://api.weatherapi.com/v1/current.json?key={api_key}&q={city}"
            resp = requests.get(url, timeout=10)
            if resp.status_code == 200:
                data = resp.json()
                temp = f"{data['current']['temp_c']} °C"
                desc = data['current']['condition']['text']
                
                # --- SAVE TO DB ---
                conn = get_db_connection()
                if conn:
                    try:
                        cursor = conn.cursor()
                        cursor.execute(
                            "INSERT INTO weather_history (city, temperature, description) VALUES (%s, %s, %s)", 
                            (city, temp, desc)
                        )
                        conn.commit()
                        logger.info(f"📊 INSERT SUCCESS: Saved {city} to history.")
                        cursor.close()
                    except Exception as db_err:
                        logger.error(f"❌ DATABASE INSERT FAILED: {db_err}")
                    finally:
                        conn.close()
                else:
                    logger.error("❌ DB CONNECTION FAILED: Connection pool returned None")
                
                WEATHER_QUERIES.labels(city=city, status='success').inc()
                weather_data = {"city": city, "temperature": temp, "description": desc}
        except Exception as e:
            logger.error(f"Weather Fetch Error: {e}")

    # --- FETCH HISTORY ---
    conn = get_db_connection()
    if conn:
        try:
            cursor = conn.cursor()
            cursor.execute("SELECT city, temperature, description, timestamp FROM weather_history ORDER BY timestamp DESC LIMIT 10")
            history_data = cursor.fetchall()
            cursor.close()
            conn.close()
        except Exception as e:
            logger.error(f"History Fetch Error: {e}")
    
    return render_template("index.html", weather=weather_data, history=history_data)

@app.route("/health")
def health():
    return jsonify({"status": "healthy"}), 200

app.wsgi_app = DispatcherMiddleware(app.wsgi_app, {'/metrics': make_wsgi_app(registry)})

if __name__ == "__main__":
    app.run(host='0.0.0.0', port=5000)