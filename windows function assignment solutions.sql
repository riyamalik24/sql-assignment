use mavenmovies;
select * from rental;
SELECT c.customer_id, c.first_name, c.last_name, SUM(p.amount) AS total_amount_spent,
    RANK() OVER (ORDER BY SUM(p.amount) DESC) AS customer_rank FROM customer c
JOIN rental r ON c.customer_id = r.customer_id JOIN payment p ON r.rental_id = p.rental_id
GROUP BY c.customer_id, c.first_name, c.last_name
ORDER BY total_amount_spent DESC;



SELECT f.film_id, f.title, p.payment_date,
    SUM(p.amount) OVER ( PARTITION BY f.film_id ORDER BY p.payment_date ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW)
    AS cumulative_revenue
FROM film f JOIN  inventory i ON f.film_id = i.film_id JOIN rental r ON i.inventory_id = r.inventory_id
JOIN payment p ON r.rental_id = p.rental_id
ORDER BY f.film_id, p.payment_date;



WITH FilmRentalDuration AS ( SELECT f.film_id, f.title, f.length, DATEDIFF(r.return_date, r.rental_date) AS rental_duration
    FROM film f JOIN inventory i ON f.film_id = i.film_id
    JOIN rental r ON i.inventory_id = r.inventory_id WHERE r.return_date IS NOT NULL )
SELECT f.length AS film_length, f.title, AVG(f.rental_duration) AS average_rental_duration
FROM FilmRentalDuration f
GROUP BY f.length, f.title
ORDER BY f.length ASC, average_rental_duration DESC;



WITH FilmRentalCounts AS ( SELECT c.name AS category_name, f.film_id, f.title, COUNT(r.rental_id) AS rental_count,
RANK() OVER (PARTITION BY c.name ORDER BY COUNT(r.rental_id) DESC) AS film_rank
FROM category c JOIN film_category fc ON c.category_id = fc.category_id
JOIN film f ON fc.film_id = f.film_id
JOIN inventory i ON f.film_id = i.film_id
JOIN rental r ON i.inventory_id = r.inventory_id
GROUP BY c.name, f.film_id, f.title )
SELECT category_name, film_id, title, rental_count FROM FilmRentalCounts
WHERE film_rank <= 3 ORDER BY category_name, film_rank;



WITH CustomerRentalCounts AS (SELECT c.customer_id, c.first_name, c.last_name, COUNT(r.rental_id) AS total_rentals
FROM customer c JOIN rental r ON c.customer_id = r.customer_id GROUP BY c.customer_id, c.first_name, c.last_name ),
AverageRentals AS ( SELECT AVG(total_rentals) AS avg_rentals FROM CustomerRentalCounts )
SELECT crc.customer_id, crc.first_name, crc.last_name, crc.total_rentals, ar.avg_rentals, 
crc.total_rentals - ar.avg_rentals AS rental_difference
FROM CustomerRentalCounts crc
JOIN AverageRentals ar
ORDER BY rental_difference DESC;



SELECT EXTRACT(YEAR FROM p.payment_date) AS year, EXTRACT(MONTH FROM p.payment_date) AS month,
SUM(p.amount) AS monthly_revenue
FROM payment p
GROUP BY EXTRACT(YEAR FROM p.payment_date),  EXTRACT(MONTH FROM p.payment_date)
ORDER BY year ASC, month ASC;



WITH CustomerSpending AS ( SELECT c.customer_id, c.first_name, c.last_name, SUM(p.amount) AS total_spending
FROM customer c JOIN payment p ON c.customer_id = p.customer_id
GROUP BY c.customer_id, c.first_name, c.last_name ),
SpendingRank AS ( SELECT total_spending, NTILE(5) OVER (ORDER BY total_spending DESC) AS spending_percentile
FROM CustomerSpending )
SELECT cs.customer_id, cs.first_name, cs.last_name, cs.total_spending
FROM CustomerSpending cs
JOIN SpendingRank sr ON cs.total_spending = sr.total_spending
WHERE sr.spending_percentile = 1 ORDER BY cs.total_spending DESC;




WITH CategoryRentalCounts AS ( SELECT c.name AS category_name, COUNT(r.rental_id) AS rental_count
FROM category c JOIN film_category fc ON c.category_id = fc.category_id
JOIN film f ON fc.film_id = f.film_id JOIN inventory i ON f.film_id = i.film_id
JOIN rental r ON i.inventory_id = r.inventory_id
GROUP BY c.name )
SELECT category_name, rental_count, SUM(rental_count) OVER (ORDER BY rental_count DESC) AS running_total_rentals
FROM CategoryRentalCounts ORDER BY rental_count DESC;



WITH FilmRentalCounts AS ( SELECT f.film_id, f.title, c.name AS category_name, COUNT(r.rental_id) AS rental_count
FROM film f JOIN film_category fc ON f.film_id = fc.film_id
JOIN category c ON fc.category_id = c.category_id JOIN inventory i ON f.film_id = i.film_id
JOIN rental r ON i.inventory_id = r.inventory_id
GROUP BY f.film_id, f.title, c.name),
CategoryAverageRentals AS ( SELECT category_name, AVG(rental_count) AS avg_rental_count FROM
FilmRentalCounts GROUP BY category_name)
SELECT fr.film_id, fr.title, fr.category_name, fr.rental_count, ca.avg_rental_count
FROM FilmRentalCounts fr
JOIN CategoryAverageRentals ca ON fr.category_name = ca.category_name
WHERE rental_count < ca.avg_rental_count
ORDER BY fr.category_name, fr.rental_count;




WITH MonthlyRevenue AS ( SELECT DATE_FORMAT(p.payment_date, '%Y-%m') AS month, SUM(p.amount) AS total_revenue
FROM payment p GROUP BY DATE_FORMAT(p.payment_date, '%Y-%m'))
SELECT month, total_revenue FROM MonthlyRevenue ORDER BY total_revenue DESC LIMIT 5;




