-- 1. Wyświetlenie 20 filmów z najlepszą oceną, które posiadają przynajmniej 1000 ocen
SELECT
	r.movie_id,
	m.title,
	COUNT(*) AS number_of_rating,
	AVG(r.rating) AS avg_movie_rating
FROM rating r
INNER JOIN movie m ON r.movie_id = m.movie_id
GROUP BY r.movie_id, m.title
HAVING COUNT(*) >= 1000
ORDER BY avg_movie_rating DESC
LIMIT 20;

-- 2. Rozkład ocen w tabeli rating i łączna ich ilość
SELECT
	rating,
	COUNT(*) AS number_of_rating
FROM rating
GROUP BY rating
ORDER BY rating ASC;

-- 3. Ilość ocen filmów wystawionych w każdym roku
-- https://neon.com/postgresql/date-functions/extract
SELECT
	EXTRACT(YEAR FROM DATE_TRUNC('year', rated_at)) AS year_of_ratings,
	COUNT(*) AS number_of_ratings
FROM rating
GROUP BY year_of_ratings
ORDER BY year_of_ratings;
