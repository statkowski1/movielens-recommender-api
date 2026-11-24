#!/usr/bin/env bash

# Przerwij wykonywanie skryptu przy pierwszym błędzie
set -euo pipefail

# Komenda dla git-bash.exe, aby ścieżki nie zostały zmienione
export MSYS_NO_PATHCONV=1

# Stworzenie schematu bazy danych
echo "--> 0/9 - schemat bazy danych"
docker cp sql/schema.sql movielens-db:/tmp/schema.sql
docker exec -i movielens-db psql -U movielens_user -d movielens -f /tmp/schema.sql

# Dodanie danych do tabeli genre
echo "--> 1/9 - INSERT genre"
docker exec -i movielens-db psql -U movielens_user -d movielens -c "INSERT INTO genre (genre_id, genre_name) VALUES (1, 'Action'), (2, 'Adventure'), (3, 'Animation'), (4, 'Children'), (5, 'Comedy'), (6, 'Crime'), (7, 'Documentary'), (8, 'Drama'), (9, 'Fantasy'), (10, 'Film-Noir'), (11, 'Horror'), (12, 'IMAX'), (13, 'Musical'), (14, 'Mystery'), (15, 'Romance'), (16, 'Sci-Fi'), (17, 'Thriller'), (18, 'War'), (19, 'Western'), (20, '(no genres listed)')"

# Dodanie danych do tabeli movie z pliku movies.csv
echo "--> 2/9 - INSERT movie"
docker cp data/ml-25m/movies.csv movielens-db:/tmp/movies.csv
docker exec -i movielens-db psql -U movielens_user -d movielens -c "\copy movie (movie_id, title, genres_raw) FROM /tmp/movies.csv WITH (FORMAT csv, HEADER true)"

# Dodanie danych do tabeli genome_tag z pliku genome-tags.csv
echo "--> 3/9 - INSERT genome_tag"
docker cp data/ml-25m/genome-tags.csv movielens-db:/tmp/genome-tags.csv
docker exec -i movielens-db psql -U movielens_user -d movielens -c "\copy genome_tag (tag_id, tag) FROM /tmp/genome-tags.csv WITH (FORMAT csv, HEADER true)"

# Utworzenie tabeli tymczasowej rating_tmp oraz dodanie do niej danych z pliku ratings.csv, wstawienie danych do tabeli users
echo "--> 4/9 - INSERT rating_tmp"
docker cp data/ml-25m/ratings.csv movielens-db:/tmp/ratings.csv
docker exec -i movielens-db psql -U movielens_user -d movielens -c "CREATE TABLE rating_tmp (user_id INT, movie_id INT, rating NUMERIC(2, 1), ts BIGINT);"
echo "--> 5/9 - INSERT users"
docker exec -i movielens-db psql -U movielens_user -d movielens -c "\copy rating_tmp (user_id, movie_id, rating, ts) FROM /tmp/ratings.csv WITH (FORMAT csv, HEADER true)"
docker exec -i movielens-db psql -U movielens_user -d movielens -c "INSERT INTO users (user_id) SELECT DISTINCT user_id FROM rating_tmp;"

# Dodanie danych do tabeli rating i usunięcie tymczasowej tabeli rating_tmp
echo "--> 6/9 INSERT rating, DROP rating_tmp"
docker exec -i movielens-db psql -U movielens_user -d movielens -c "INSERT INTO rating (user_id, movie_id, rating, rated_at) SELECT user_id, movie_id, rating, to_timestamp(ts) FROM rating_tmp;"
docker exec -i movielens-db psql -U movielens_user -d movielens -c "DROP TABLE rating_tmp;"

# https://medium.com/@suhasthakral/split-strings-lists-into-rows-in-postgres-82bfa5dbef53
# Dodanie danych do tabeli movie_genre
echo "--> 7/9 - INSERT movie_genre"
docker exec -i movielens-db psql -U movielens_user -d movielens -c "INSERT INTO movie_genre (movie_id, genre_id) WITH movie_and_genre_name AS (SELECT movie_id, UNNEST(regexp_split_to_array(genres_raw, '\|')) AS genre_name_raw FROM movie) SELECT movie_and_genre_name.movie_id, genre.genre_id FROM movie_and_genre_name INNER JOIN genre ON movie_and_genre_name.genre_name_raw = genre.genre_name;"

# Dodanie danych do tabeli genome_score z pliku genome-scores.csv
echo "--> 8/9 - INSERT genome_score"
docker cp data/ml-25m/genome-scores.csv movielens-db:/tmp/genome-scores.csv
docker exec -i movielens-db psql -U movielens_user -d movielens -c "\copy genome_score (movie_id, tag_id, relevance) FROM /tmp/genome-scores.csv WITH (FORMAT csv, HEADER true)"

# https://www.geeksforgeeks.org/sql/regular-expressions-in-sql/
# Modyfikacja tabeli movie - uzupełnienie pustej kolumny release_year na podstawie tytułu każdego filmu
echo "--> 9/9 - UPDATE movie: release_year"
docker exec -i movielens-db psql -U movielens_user -d movielens -c "WITH movie_year AS (SELECT movie_id, REGEXP_SUBSTR(title, '\d{4}(?=\)$)')::SMALLINT AS release_year FROM movie) UPDATE movie SET release_year = movie_year.release_year FROM movie_year WHERE movie.movie_id = movie_year.movie_id;"
