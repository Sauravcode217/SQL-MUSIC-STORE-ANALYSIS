-- OBJECTIVE OF QUERYING:-
-- To Analyze the Music Store Database and Examine the dataset with SQL
-- And help the Music Store to Undersatand their Bussiness Growth
-- By Sampling Answering KPI Questions. 


CREATE DATABASE Music_Database;
USE Music_Database;

-- Q.1  Who is the senior most employee based on job title?
SELECT * FROM employee ORDER BY levels desc LIMIT 1;

-- Q.2 Which countries have the most invoices?
SELECT billing_country, COUNT(invoice_id) AS CI FROM invoice GROUP BY billing_country ORDER BY CI  desc; 

-- Q.3 What are top 3 values of total invoices?
SELECT total FROM invoice ORDER BY total desc LIMIT 3;

-- Q.4 Which city has the best customers? We would like to throw a promotional Music Festival in the city we made the most money.
-- Write a query that returns one city that has the highest sum of invoice totals.
-- Return both the city name & sum of all invoice totals.
SELECT billing_city, sum(total) AS ST FROM invoice GROUP BY billing_city ORDER BY ST DESC LIMIT 1;

-- Q.5 Who is the best customer? The customer who has spent the most money will be declared the best customer.
-- Write a query that returns the person who has spent the most money.
SELECT customer.customer_id, customer.first_name, customer.last_name, SUM(invoice.total) AS ST 
FROM customer INNER JOIN invoice  
ON customer.customer_id = invoice.customer_id 
GROUP BY customer.customer_id, customer.first_name, customer.last_name 
ORDER BY ST DESC LIMIT 1;


-- Q.6  Write query to return the email, first name, last name, & Genre of all Rock Music Listeners.
-- Return your list ordered alphabetically by email starting with A. 
SELECT DISTINCT email, first_name, last_name from customer join invoice ON customer.customer_id = invoice.customer_id 
JOIN invoice_line ON invoice.invoice_id= invoice_line.invoice_id WHERE track_id IN 
(SELECT track_id from track INNER join genre on track.genre_id = genre.genre_id  WHERE genre.name like 'Rock' )
ORDER BY email;


-- Q.7 Let's invite the artists who have written the most rock music in our dataset.
-- Write a query that returns the Artist name and total track count of the top 10 rock bands.
SELECT artist.artist_id , artist.name, COUNT(artist.artist_id) AS No_of_songs
FROM track
INNER JOIN album ON album.album_id = track.album_id 
INNER JOIN artist ON artist.artist_id = album.artist_id
INNER Join genre ON genre.genre_id = track.genre_id
WHERE genre.name LIKE 'ROCK'
GROUP BY artist.artist_id
ORDER BY No_of_songs DESC
LIMIT 10;


-- Q.8 Return all the track who names that have a song length longer than the average song length.
-- Return the Name and Milliseconds for each track.
-- Order by the song length with the longest songs listed first.
SELECT DISTINCT name, milliseconds FROM track 
Where milliseconds > ( SELECT AVG(milliseconds) As avg_track_length 
FROM track) ORDER BY milliseconds DESC;



-- Q.9 Find how much amount spent by each customer on artists?
-- Write a query to return customer name, artist name and total spent.
WITH best_selling_artist AS (
     SELECT artist.artist_id AS artist_id, artist.name AS artist_name,
     SUM(invoice_line.unit_price*invoice_line.track_id) AS total_sales
     FROM invoice_line
     JOIN track ON track.track_id = invoice_line.track_id
     JOIN album ON album.album_id = track.album_id
     JOIN artist ON artist.artist_id = album.artist_id
     GROUP BY 1
     ORDER BY 3 DESC
     LIMIT 1
     )
SELECT  c.customer_id, c.first_name, c.last_name, bsa.artist_name, 
SUM(il.unit_price*il.quantity) AS amount_spent
FROM invoice i
join customer c ON c.customer_id = i.customer_id
join invoice_line il on il.invoice_id = i.invoice_id
join track t on  t.track_id = il.track_id 
join album alb on   alb.album_id = t.album_id
join best_selling_artist bsa on bsa.artist_id = alb.artist_id
GROUP BY 1,2,3,4
ORDER BY 5 DESC;


-- Q.10 We want to find out the most popular music genre for each country.
-- We determine the most popular genre wiht the highestamount of purchases.
-- Write a query that returns each country along wiht the top Genre.
-- For countries where the maxomum number of purchases os shared return all Genres.

WITH popular_genre AS
(    
     SELECT COUNT(invoice_line.quantity) AS purchase, customer.country, genre.name, genre.genre_id,
     ROW_NUMBER() OVER(PARTITION BY customer.country ORDER BY COUNT(invoice_line.quantity) DESC) AS RowNo
     FROM invoice_line
     JOIN invoice ON invoice.invoice_id = invoice_line.invoice_id
     JOIN customer ON customer.customer_id = invoice.customer_id
     JOIN track ON track.track_id = invoice_line.track_id
     JOIN genre ON genre.genre_id = track.genre_id
     GROUP BY 2,3,4
     ORDER BY 2 ASC, 1 DESC
)
SELECT * FROM popular_genre WHERE RowNo <= 1; 

-- Method 2

     WITH sales_per_country AS (
    SELECT COUNT(*) AS purchases_per_genre, customer.country, genre.name AS genre_name, genre.genre_id
    FROM invoice_line 
    JOIN invoice ON invoice.invoice_id = invoice_line.invoice_id
    JOIN customer ON customer.customer_id = invoice.customer_id
    JOIN track ON track.track_id = invoice_line.track_id
    JOIN genre ON genre.genre_id = track.genre_id
    GROUP BY customer.country, genre.name, genre.genre_id
),
max_genre_per_country AS (
    SELECT MAX(purchases_per_genre) AS max_genre_number, country
    FROM sales_per_country
    GROUP BY country
)
SELECT sales_per_country.purchases_per_genre, sales_per_country.country, sales_per_country.genre_name, sales_per_country.genre_id
FROM sales_per_country
JOIN max_genre_per_country ON sales_per_country.country = max_genre_per_country.country
WHERE sales_per_country.purchases_per_genre = max_genre_per_country.max_genre_number
ORDER BY sales_per_country.country, sales_per_country.purchases_per_genre DESC;

-- Q.11 Write aquery that determine the customer that has spent the most on music for each country.
-- Write a query that returns the country along with the top customer and how much theyspent.
-- For countries where the top amount spent is shared, provide all customerr who spent this amount.

WITH Customer_with_country AS (
         SELECT customer.customer_id, first_name,last_name, billing_country, SUM(total) AS total_spending,
         ROW_NUMBER() OVER(PARTITION BY billing_country ORDER BY SUM(total) DESC) AS RowNo
         FROM invoice
         JOIN customer ON customer.customer_id = invoice.customer_id
         GROUP BY 1,2,3,4
         ORDER BY 4 ASC, 5 DESC )
SELECT * FROM Customer_with_country WHERE RowNo <= 1;  

-- METHOD 2
WITH RECURSIVE
     customer_with_country AS (
     SELECT customer.customer_id, first_name, last_name, billing_country, SUM(total) AS total_spending
     FROM invoice
     JOIN customer ON customer.customer_id = invoice.customer_id
     GROUP BY 1,2,3,4
     ORDER BY 2,3 DESC),
     
     country_max_spending AS(
          SELECT billing_country, MAX(total_spending) AS max_spending
          FROM customer_with_country
          GROUP BY billing_country)
SELECT cc.billing_country, cc.total_spending, cc.first_name, cc.last_name, cc.customer_id
FROM customer_with_country cc
JOIN country_max_spending ms
ON cc.billing_country = ms.billing_country 
ORDER BY 1;       
          
          
         


















