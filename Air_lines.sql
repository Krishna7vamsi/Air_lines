/* 1. Creating route_deatail table as routes using suitable data types for the fields. */
CREATE TABLE routes(
	route_id BIGINT,
	Flight_num BIGINT,
	Origin_airport VARCHAR,
	Destination_airport VARCHAR,
	Aircraft_id VARCHAR,
	Distance_miles BIGINT)
	
/* 2. Query to display all the passengers (customers) who have travelled in routes 01 to 25. */
SELECT CONCAT(first_name, ' ', last_name) AS name, seat_number, aircraft_id, route_id, departure, arrival
FROM passengers_on_flights pof
JOIN customer c
ON pof.customer_id = c.customer_id
WHERE route_id BETWEEN 1 AND 25
ORDER BY route_id;

/* 3. Query to identify top 3 the passenger name and total revenue in bussiness class 
	from the ticket_details table. */
WITH t1 AS 
		(SELECT td.customer_id, CONCAT(first_name, ' ', last_name) AS passenger_name, 
				class_id,(no_of_tickets * price_per_ticket) AS total_revenue 
		 FROM ticket_details td 
		 JOIN customer c 
		 ON td.customer_id = c.customer_id 
		 WHERE class_id = 'Bussiness' 
		 ORDER BY total_revenue DESC),
	 t2 AS 
	 	(SELECT *, DENSE_RANK( ) OVER(ORDER BY total_revenue DESC) AS rnk 
		 FROM t1),
	t3 AS
		(SELECT * 
		 FROM t2 
		 WHERE rnk <= 3)
SELECT passenger_name, class_id, total_revenue
FROM t3

/* 4. Query to extract the customers who have registered and booked a ticket. */

SELECT td.customer_id, CONCAT(first_name, ' ', last_name) AS customer, aircraft_id, no_of_tickets
FROM customer c
JOIN ticket_details td
ON c.customer_id = td.customer_id
GROUP BY td.customer_id, CONCAT(first_name, ' ', last_name), aircraft_id, no_of_tickets
ORDER BY td.customer_id

/* 5. Query to identify whether the revenue has crossed 10000. */

WITH t1 AS 
		(SELECT (no_of_tickets * price_per_ticket) AS total_revenue 
		 FROM ticket_details),
	t2 AS (SELECT 
		   		CASE 
		   			WHEN SUM(total_revenue) > 10000 THEN 'Meet the traget' 
		   			ELSE 'Not meet the target' 
		   		END
		   FROM t1)
SELECT *
FROM t2

/* 6. Query to find the maximum ticket price for each class. */
SELECT class_id, price_per_ticket
FROM (
  	SELECT class_id, price_per_ticket, 
	MAX(price_per_ticket) OVER (PARTITION BY class_id) AS max_ticket_price 
	FROM ticket_details 
	GROUP BY class_id, price_per_ticket 
	ORDER BY price_per_ticket DESC) AS ticket_price
WHERE price_per_ticket = max_ticket_price;

/* 7. Query to create a view with only business class customers along with the brand of airlines. */

WITH t1 AS
		(SELECT customer_id,class_id, avation_brand 
		 FROM ticket_details
		 WHERE class_id = 'Bussiness'
		 GROUP BY customer_id,class_id, avation_brand 
		 ORDER BY customer_id)
SELECT t1.customer_id, CONCAT(first_name, ' ', last_name) AS customer_name, avation_brand
FROM t1
JOIN customer c
ON t1.customer_id = c.customer_id;

/* 8. Query to create a stored procedure to get the details of all passengers flying between 
	a range of routes defined in run time. Also, return an error message if the table doesn't exist. */

CREATE OR REPLACE PROCEDURE get_passenger_details(source_route VARCHAR, destination_route VARCHAR)
LANGUAGE plpgsql
AS $$
BEGIN
    -- Check if the table exists
    IF NOT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'passengers_on_flights') THEN
        RAISE EXCEPTION 'The table passengers_on_flights does not exist.';
    END IF;

    -- Retrieve passenger details for the given routes
    SELECT *
    FROM passengers_on_flights
    WHERE route BETWEEN p_source_route AND p_destination_route;
END;
$$;

CALL get_passenger_details('SourceRoute', 'DestinationRoute');

/* 9. Query to create a stored procedure that groups the distance travelled by each flight into three categories. 
	The categories are, short distance travel (SDT) for >=0 AND <= 2000 miles, 
	intermediate distance travel (IDT) for >2000 AND <=6500, and long-distance travel (LDT) for >6500. */
CREATE OR REPLACE PROCEDURE flight_distance(min_distance INT, max_distance INT)
LANGUAGE plpgsql
AS $$
BEGIN
    CREATE TEMPORARY TABLE flight_distance_categories (
        flight_id INT,
        distance INT,
        category VARCHAR
    );
    
    -- Insert flight distance categories
    INSERT INTO flight_distance_categories (flight_id, distance, category)
    SELECT flight_id, distance,
        CASE
            WHEN distance >= 0 AND distance <= 2000 THEN 'SDT' -- Short Distance Travel
            WHEN distance > 2000 AND distance <= 6500 THEN 'IDT' -- Intermediate Distance Travel
            WHEN distance > 6500 THEN 'LDT' -- Long Distance Travel
        END
    FROM flights
    WHERE distance >= p_min_distance AND distance <= p_max_distance;

    -- Retrieve the categorized flight distances
    SELECT * FROM flight_distance_categories;
    
    -- Drop the temporary table
    DROP TABLE IF EXISTS flight_distance_categories;
END;
$$;

	