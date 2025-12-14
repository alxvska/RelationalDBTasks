-- 1. Write a query that will return for each year the most popular rental film among films released in one year.

SELECT 
    f.release_year,
    f.title AS most_popular_film,
    COUNT(r.rental_id) AS rental_count
FROM film f
JOIN inventory i ON f.film_id = i.film_id
JOIN rental r ON i.inventory_id = r.inventory_id
GROUP BY f.release_year, f.film_id, f.title
HAVING COUNT(r.rental_id) = (
    SELECT MAX(rental_count)
    FROM (
        SELECT COUNT(r2.rental_id) AS rental_count
        FROM film f2
        JOIN inventory i2 ON f2.film_id = i2.film_id
        JOIN rental r2 ON i2.inventory_id = r2.inventory_id
        WHERE f2.release_year = f.release_year
        GROUP BY f2.film_id
    ) AS year_rentals
)
ORDER BY f.release_year;

-- 2. Write a query that will return the Top-5 actors who have appeared in Comedies more than anyone else.

SELECT 
    a.actor_id,
    a.first_name,
    a.last_name,
    COUNT(f.film_id) AS comedy_count
FROM actor a
JOIN film_actor fa ON a.actor_id = fa.actor_id
JOIN film_category fc ON fa.film_id = fc.film_id
JOIN category c ON fc.category_id = c.category_id
JOIN film f ON fa.film_id = f.film_id
WHERE c.name = 'Comedy'
GROUP BY a.actor_id, a.first_name, a.last_name
ORDER BY comedy_count DESC
LIMIT 5;

-- 3. Write a query that will return the names of actors who have not starred in "Action" films.

SELECT 
    a.actor_id,
    a.first_name,
    a.last_name
FROM actor a
WHERE a.actor_id NOT IN (
    SELECT fa.actor_id
    FROM film_actor fa
    JOIN film_category fc ON fa.film_id = fc.film_id
    JOIN category c ON fc.category_id = c.category_id
    WHERE c.name = 'Action'
)
ORDER BY a.last_name, a.first_name;

-- 4. Write a query that will return the three most popular rental films by each genre.

WITH rental_by_genre AS (
    SELECT 
        c.name AS genre,
        f.title AS film_title,
        COUNT(r.rental_id) AS rental_count,
        ROW_NUMBER() OVER (PARTITION BY c.name ORDER BY COUNT(r.rental_id) DESC) AS rank
    FROM category c
    JOIN film_category fc ON c.category_id = fc.category_id
    JOIN film f ON fc.film_id = f.film_id
    JOIN inventory i ON f.film_id = i.film_id
    JOIN rental r ON i.inventory_id = r.inventory_id
    GROUP BY c.name, f.film_id, f.title
)
SELECT genre, film_title, rental_count
FROM rental_by_genre
WHERE rank <= 3
ORDER BY genre, rank;

-- 5. Calculate the number of films released each year and cumulative total by the number of films.

SELECT 
    release_year,
    COUNT(film_id) AS films_this_year,
    SUM(COUNT(film_id)) OVER (ORDER BY release_year) AS cumulative_total
FROM film
GROUP BY release_year
ORDER BY release_year;

-- 6. Calculate a monthly statistic based on "rental_date" field from "Rental" table that for each month will show the percentage of "Animation" films from the total number of rentals.

SELECT 
    TO_CHAR(r.rental_date, 'YYYY-MM') AS rental_month,
    COUNT(r.rental_id) AS total_rentals,
    COUNT(CASE WHEN c.name = 'Animation' THEN 1 END) AS animation_rentals,
    ROUND(
        COUNT(CASE WHEN c.name = 'Animation' THEN 1 END) * 100.0 / COUNT(r.rental_id), 
        2
    ) AS animation_percentage
FROM rental r
JOIN inventory i ON r.inventory_id = i.inventory_id
JOIN film f ON i.film_id = f.film_id
JOIN film_category fc ON f.film_id = fc.film_id
JOIN category c ON fc.category_id = c.category_id
GROUP BY TO_CHAR(r.rental_date, 'YYYY-MM')
ORDER BY rental_month;

-- 7. Write a query that will return the names of actors who have starred in "Action" films more than in Drama film.

SELECT 
    a.actor_id,
    a.first_name,
    a.last_name,
    COUNT(CASE WHEN c.name = 'Action' THEN 1 END) AS action_count,
    COUNT(CASE WHEN c.name = 'Drama' THEN 1 END) AS drama_count
FROM actor a
JOIN film_actor fa ON a.actor_id = fa.actor_id
JOIN film_category fc ON fa.film_id = fc.film_id
JOIN category c ON fc.category_id = c.category_id
WHERE c.name IN ('Action', 'Drama')
GROUP BY a.actor_id, a.first_name, a.last_name
HAVING COUNT(CASE WHEN c.name = 'Action' THEN 1 END) > COUNT(CASE WHEN c.name = 'Drama' THEN 1 END)
ORDER BY action_count DESC;

-- 8. Write a query that will return the top-5 customers who spent the most money watching Comedies.

SELECT 
    c.customer_id,
    c.first_name,
    c.last_name,
    SUM(p.amount) AS total_spent
FROM customer c
JOIN payment p ON c.customer_id = p.customer_id
JOIN rental r ON p.rental_id = r.rental_id
JOIN inventory i ON r.inventory_id = i.inventory_id
JOIN film f ON i.film_id = f.film_id
JOIN film_category fc ON f.film_id = fc.film_id
JOIN category cat ON fc.category_id = cat.category_id
WHERE cat.name = 'Comedy'
GROUP BY c.customer_id, c.first_name, c.last_name
ORDER BY total_spent DESC
LIMIT 5;

-- 9. In the Address table, in the address field, the last word indicates the type of a street: Street, Lane, Way, etc. Write a query that will return all types of streets and the number of addresses related to this type.

SELECT 
    SUBSTRING(address FROM '[^ ]+$') AS street_type,
    COUNT(*) AS address_count
	
FROM address
GROUP BY SUBSTRING(address FROM '[^ ]+$')
ORDER BY address_count DESC;

-- 10. Write a query that will return a list of movie ratings, indicate for each rating the total number of films with this rating, the top-3 categories by the number of films in this category and the number of films in this category with this

WITH category_counts AS (
    SELECT 
        f.rating,
        c.name AS category,
        COUNT(f.film_id) AS film_count,
        ROW_NUMBER() OVER (PARTITION BY f.rating ORDER BY COUNT(f.film_id) DESC) AS rank
    FROM film f
    JOIN film_category fc ON f.film_id = fc.film_id
    JOIN category c ON fc.category_id = c.category_id
    GROUP BY f.rating, c.name
),
top_categories AS (
    SELECT 
        rating,
        category,
        film_count,
        rank
    FROM category_counts
    WHERE rank <= 3
)
SELECT 
    f.rating AS mpaa_rating,
    COUNT(DISTINCT f.film_id) AS total_bigint,
    MAX(CASE WHEN tc.rank = 1 THEN tc.category || ': ' || tc.film_count END) AS category1_text,
    MAX(CASE WHEN tc.rank = 2 THEN tc.category || ': ' || tc.film_count END) AS category2_text,
    MAX(CASE WHEN tc.rank = 3 THEN tc.category || ': ' || tc.film_count END) AS category3_text
FROM film f
LEFT JOIN top_categories tc ON f.rating = tc.rating
GROUP BY f.rating
ORDER BY total_bigint DESC;