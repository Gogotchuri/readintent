-- Articles table
-- +goose Up
CREATE TABLE articles (
    id SERIAL PRIMARY KEY,
    url VARCHAR(255) NOT NULL UNIQUE,
    status VARCHAR(50) NOT NULL,
    title VARCHAR(255),
    author VARCHAR(255),
    published_date DATE,
    extracted_html TEXT,
    pure_text TEXT,
    categories VARCHAR(255), -- Comma-separated list of categories
    description TEXT,
    image_url VARCHAR(255),
    phonemizer_data JSONB,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- User Articles table (many-to-many relationship between users and articles)
CREATE TABLE user_articles (
    user_id VARCHAR NOT NULL,
    article_id INT NOT NULL,
    PRIMARY KEY (user_id, article_id),
    FOREIGN KEY (user_id) REFERENCES users(id),
    FOREIGN KEY (article_id) REFERENCES articles(id) ON DELETE CASCADE
);

-- +goose Down
DROP TABLE user_articles;
DROP TABLE articles;
