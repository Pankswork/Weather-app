USE weather_app;

CREATE TABLE IF NOT EXISTS weather_history (
    id INT AUTO_INCREMENT PRIMARY KEY,
    city VARCHAR(255) NOT NULL,
    temperature VARCHAR(50),
    description VARCHAR(255),
    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);