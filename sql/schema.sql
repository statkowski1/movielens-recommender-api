CREATE TABLE movie (
    movie_id INT PRIMARY KEY,
    title TEXT,
    release_year SMALLINT,
    genres_raw VARCHAR(145)
);

CREATE TABLE users (
    user_id INT PRIMARY KEY
);

CREATE TABLE rating (
    user_id INT,
    movie_id INT,
    rating NUMERIC(2, 1),
    rated_at TIMESTAMPTZ,
    PRIMARY KEY (user_id, movie_id),
    FOREIGN KEY (user_id) REFERENCES users(user_id),
    FOREIGN KEY (movie_id) REFERENCES movie(movie_id)
);

CREATE TABLE genre (
    genre_id INT PRIMARY KEY,
    genre_name VARCHAR(45) UNIQUE NOT NULL
);

CREATE TABLE movie_genre (
    movie_id INT,
    genre_id INT,
    PRIMARY KEY (movie_id, genre_id),
    FOREIGN KEY (movie_id) REFERENCES movie(movie_id),
    FOREIGN KEY (genre_id) REFERENCES genre(genre_id)
);

CREATE TABLE genome_tag (
    tag_id INT PRIMARY KEY,
    tag VARCHAR(145)
);

CREATE TABLE genome_score (
    movie_id INT,
    tag_id INT,
    relevance NUMERIC(4, 3),
    PRIMARY KEY (movie_id, tag_id),
    FOREIGN KEY (movie_id) REFERENCES movie(movie_id),
    FOREIGN KEY (tag_id) REFERENCES genome_tag(tag_id)
);
