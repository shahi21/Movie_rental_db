# Movie_rental_db

# Movie Rental Database - PostgreSQL

## Overview
This project is a PostgreSQL-based movie rental system implemented in **pgAdmin**. The database tracks customers, movies, rentals, and late returns. It includes advanced SQL queries for analysis and a **trigger mechanism** to log late returns automatically.

## Database Schema
### **Tables:**
1. **Customers**: Stores customer details.
2. **Movies**: Stores movie information.
3. **Rentals**: Records movie rentals.
4. **Late_Returns**: Logs late movie returns via a trigger.

### **Table Definitions:**
#### Customers Table
```sql
CREATE TABLE Customers (
    customer_id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    phone VARCHAR(15) UNIQUE NOT NULL
);
```

#### Movies Table
```sql
CREATE TABLE Movies (
    movie_id SERIAL PRIMARY KEY,
    title VARCHAR(200) NOT NULL,
    genre VARCHAR(50) NOT NULL,
    release_year INT NOT NULL
);
```

#### Rentals Table
```sql
CREATE TABLE Rentals (
    rental_id SERIAL PRIMARY KEY,
    customer_id INT REFERENCES Customers(customer_id) ON DELETE SET NULL,
    movie_id INT REFERENCES Movies(movie_id) ON DELETE SET NULL,
    rental_date DATE NOT NULL,
    return_date DATE
);
```

#### Late_Returns Table
```sql
CREATE TABLE Late_Returns (
    log_id SERIAL PRIMARY KEY,
    rental_id INT REFERENCES Rentals(rental_id) ON DELETE SET NULL,
    customer_id INT REFERENCES Customers(customer_id) ON DELETE SET NULL,
    movie_id INT REFERENCES Movies(movie_id) ON DELETE SET NULL,
    logged_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    days_late INT NOT NULL
);
```

## **Trigger for Late Returns Logging**
### **Trigger Function**
```sql
CREATE OR REPLACE FUNCTION log_late_returns() RETURNS TRIGGER AS $$
BEGIN
    IF NEW.return_date - NEW.rental_date > 7 THEN
        INSERT INTO Late_Returns (rental_id, customer_id, movie_id, days_late)
        VALUES (NEW.rental_id, NEW.customer_id, NEW.movie_id, NEW.return_date - NEW.rental_date);
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;
```

### **Trigger Creation**
```sql
CREATE TRIGGER check_late_returns
AFTER INSERT OR UPDATE ON Rentals
FOR EACH ROW
WHEN (NEW.return_date IS NOT NULL)
EXECUTE FUNCTION log_late_returns();
```

## **Queries for Data Analysis**
### 1. Retrieve customers who rented the most movies
```sql
SELECT c.name, COUNT(r.rental_id) AS total_movies_rented
FROM Customers c
JOIN Rentals r ON c.customer_id = r.customer_id
GROUP BY c.name
ORDER BY total_movies_rented DESC;
```

### 2. Find the longest-rented movie on average
```sql
SELECT m.title, AVG(r.return_date - r.rental_date) AS avg_rental_duration
FROM Movies m
JOIN Rentals r ON m.movie_id = r.movie_id
GROUP BY m.title
ORDER BY avg_rental_duration DESC
LIMIT 1;
```

### 3. Identify customers who rented at least one movie in any two months in 2025
```sql
SELECT c.name
FROM Customers c
JOIN Rentals r ON c.customer_id = r.customer_id
WHERE EXTRACT(YEAR FROM r.rental_date) = 2025
GROUP BY c.name
HAVING COUNT(DISTINCT EXTRACT(MONTH FROM r.rental_date)) >= 2;
```

### 4. Find the most popular movie genre rented by customers
```sql
SELECT m.genre, COUNT(r.rental_id) AS rental_count
FROM Movies m
JOIN Rentals r ON m.movie_id = r.movie_id
GROUP BY m.genre
ORDER BY rental_count DESC
LIMIT 1;
```

## **How to Run This Project in pgAdmin**
### **Step 1: Create the Database**
1. Open **pgAdmin**.
2. Create a new database **movie_rental_db**.
3. Open the Query Tool and execute the provided SQL scripts.

### **Step 2: Insert Sample Data**
1. Run the provided **INSERT statements** for Customers, Movies, and Rentals.

### **Step 3: Set Up the Trigger**
1. Execute the trigger function **log_late_returns**.
2. Create the **check_late_returns** trigger.

### **Step 4: Test the Trigger**
1. Insert a rental with a return date more than **7 days after the rental date**:
```sql
INSERT INTO Rentals(customer_id, movie_id, rental_date, return_date)
VALUES (3, 2, '2025-02-01', '2025-02-20');
```
2. Check the **Late_Returns** table:
```sql
SELECT * FROM Late_Returns;
```
If a record appears, the trigger is working correctly.

### **Step 5: Running Queries**
Run the provided SQL queries to analyze rental trends and customer behavior.

## **Design Choices**
- **Referential Integrity**: `ON DELETE SET NULL` ensures that if a customer or movie is deleted, rentals are preserved.
- **Trigger for Late Returns**: Automates logging of late returns to **reduce manual tracking**.
- **Aggregations & Filters**: Queries provide insights into **customer activity, movie popularity, and late returns**.




