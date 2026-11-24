-- 1. Najpopularniejszy gatunek filmowy dla każdej dekady
WITH number_of_rating_per_decade_per_genre AS (
	SELECT
		g.genre_id,
		g.genre_name,
		DATE_TRUNC('decade', r.rated_at) decade_of_ratings,
		COUNT(*) AS number_of_ratings,
		RANK() OVER (PARTITION BY DATE_TRUNC('decade', r.rated_at) ORDER BY COUNT(*) DESC) AS number_of_rank
	FROM rating r
	INNER JOIN movie m ON r.movie_id = m.movie_id
	INNER JOIN movie_genre mg ON m.movie_id = mg.movie_id
	INNER JOIN genre g ON mg.genre_id = g.genre_id
	GROUP BY decade_of_ratings, g.genre_id
)
SELECT
	tmp.genre_id,
	tmp.genre_name,
	EXTRACT(YEAR FROM tmp.decade_of_ratings) AS decade_of_ratings,
	tmp.number_of_ratings
FROM number_of_rating_per_decade_per_genre tmp
WHERE tmp.number_of_rank = 1
ORDER BY tmp.decade_of_ratings;

-- 2. Ranking filmów dla każdego gatunku top 3 filmy według średniej oceny i z przynajmniej 100 ocenami
WITH movie_statistics AS (
	SELECT
		movie_id,
		AVG(rating) AS avg_ratings,
		COUNT(*) AS number_of_ratings
	FROM rating
	GROUP BY movie_id
	HAVING COUNT(*) >= 100
),
ranked_movies AS (
	SELECT
		g.genre_id,
		g.genre_name,
		tmp1.movie_id,
		m.title,
		tmp1.avg_ratings,
		tmp1.number_of_ratings,
		RANK() OVER (PARTITION BY g.genre_id ORDER BY tmp1.avg_ratings DESC) AS number_of_rank
	FROM movie_statistics tmp1
	INNER JOIN movie m ON tmp1.movie_id = m.movie_id
	INNER JOIN movie_genre mg ON m.movie_id = mg.movie_id
	INNER JOIN genre g ON mg.genre_id = g.genre_id
)
SELECT
	*
FROM ranked_movies
WHERE number_of_rank <= 3
ORDER BY genre_id, number_of_rank;

-- 3. Porównanie średniej ocen każdego użytkownika ze średnią globalną
WITH rating_global AS (
	SELECT
		AVG(rating) AS avg_global
	FROM rating
),
rating_per_user AS (
	SELECT
		user_id,
		AVG(rating) AS avg_per_user
	FROM rating
	GROUP BY user_id
)
SELECT
	rating_per_user.user_id,
	rating_per_user.avg_per_user,
	rating_global.avg_global
FROM rating_per_user
CROSS JOIN rating_global
ORDER BY rating_per_user.user_id;

-- 4. Filmy, których średnia ocena jest wyższa niż średnia ocena w ich gatunku
WITH rating_per_genre AS (
	SELECT
		g.genre_id,
		g.genre_name,
		AVG(r.rating) AS avg_rating
	FROM rating r
	INNER JOIN movie m ON r.movie_id = m.movie_id
	INNER JOIN movie_genre mg ON m.movie_id = mg.movie_id
	INNER JOIN genre g ON mg.genre_id = g.genre_id
	GROUP BY g.genre_id
),
rating_per_movie AS (
	SELECT
		movie_id,
		AVG(rating) AS avg_rating
	FROM rating
	GROUP BY movie_id
)
SELECT
	g.genre_id,
	g.genre_name,
	m.movie_id,
	m.title,
	rpm.avg_rating AS avg_movie,
	rpg.avg_rating AS avg_global
FROM rating_per_movie rpm
INNER JOIN movie m ON rpm.movie_id = m.movie_id
INNER JOIN movie_genre mg ON m.movie_id = mg.movie_id
INNER JOIN genre g ON mg.genre_id = g.genre_id
INNER JOIN rating_per_genre rpg ON g.genre_id = rpg.genre_id
WHERE rpm.avg_rating > rpg.avg_rating
ORDER BY g.genre_id, avg_movie;

-- https://learnsql.com/blog/difference-between-two-rows-in-sql/
-- 5. Zmiana popularności każdego gatunku w czasie - dla każdego gatunku i dla każdego roku ze względu na ilość ocen
WITH rating_per_genre_per_year AS (
	SELECT
		mg.genre_id,
		EXTRACT(YEAR FROM DATE_TRUNC('year', r.rated_at)) AS year_of_ratings,
		COUNT(*) AS number_of_rating
	FROM rating r
	INNER JOIN movie m ON r.movie_id = m.movie_id
	INNER JOIN movie_genre mg ON m.movie_id = mg.movie_id
	GROUP BY mg.genre_id, year_of_ratings
),
rating_difference AS (
	SELECT
		*,
		number_of_rating - LAG(number_of_rating) OVER (PARTITION BY genre_id ORDER BY year_of_ratings) AS rating_diff
	FROM rating_per_genre_per_year
)
SELECT
	rd.genre_id,
	g.genre_name,
	rd.year_of_ratings,
	rd.number_of_rating,
	rd.rating_diff
FROM rating_difference rd
INNER JOIN genre g ON rd.genre_id = g.genre_id;
