--TABLE CREATION
create table Customers(
customer_id serial primary key,
name varchar(100) not null,
email varchar(100) unique not null,
phone varchar(15) unique not null
);

select * from customers;

create table movies(
movie_id serial primary key,
title varchar(200) not null,
genre varchar(50) not null,
release_year int not null
);

select * from movies;

create table rentals(
rental_id serial primary key,
customer_id int references Customers(customer_id) on delete set null,
movie_id int references movies(movie_id) on delete set null,
rental_date date not null,
return_date date
);

select * from rentals;

--INSERTING VALUES INTO TABLES

--INSERTING INTO CUSTOMERS
insert into customers(name,email,phone) values
('John Doe','johndoe@gmail.com','9483283376'),
('Jane Smith','janesmith@gmail.com','9474392038'),
('Alice Johnson','alice839@gmail.com','8765467890'),
('Bob Brown','bobbrown@gmail.com','5678465783'),
('Charlie Davis','charlie@gmail.com','8907865748');
select * from customers;

--INSERTING INTO MOVIES
insert into Movies(title,genre,release_year) values
('Inception','Sci-Fi',2010),
('The Dark Knight','Action',2008),
('Interstellar','Sci-Fi',2014),
('Parasite','Thriller',2019),
('Avengers:Endgame','Action',2019),
('The Matrix','Sci-Fi',1999),
('Titanic','Romance',1997),
('Joker','Drama',2019);
select * from movies;

--INSERTING INTO RENTALS
insert into Rentals(customer_id,movie_id,rental_date,return_date) values
(1,1,'2025-01-01','2025-01-08'),
(2,3,'2025-01-02','2025-01-12'),
(3,5,'2025-01-03','2025-01-09'),
(4,7,'2025-01-14','2025-01-25'),
(5,2,'2025-01-15','2025-01-24'),
(1,6,'2025-01-26','2025-01-31'),
(2,8,'2025-02-07','2025-02-09'),
(3,4,'2025-02-08','2025-02-16'),
(4,1,'2025-02-09','2025-02-22'),
(5,3,'2025-02-10','2025-02-20');
select * from rentals;

--QUERIES

--retrieve customers who have rented the most movies
select c.name,count(rental_id) as total_movies_rented
from customers c
join rentals r on c.customer_id=r.customer_id
group by c.name
order by total_movies_rented;

--find the movie that has been rented the longest on average
select m.title, avg(r.return_date-r.rental_date) as avg_rental_duration
from movies m
join rentals r on m.movie_id=r.movie_id
group by m.title
order by avg_rental_duration desc
limit 1;

--identify customers who have rented all available movies genre
select c.name
from customers c
join rentals r on c.customer_id=r.customer_id
join movies m on m.movie_id=r.movie_id
group by c.name
having count(distinct m.genre)=(select count(distinct genre) from movies);

--list the customers who have rented atleast 1 movie in any 2 month in 2025
select c.name
from customers c
join rentals r on c.customer_id=r.customer_id
where extract(year from r.rental_date)=2025
group by c.name
having count(distinct extract(month from r.rental_date))=2;

select * from rentals;

--find the most popular movie genre rented by customers
select m.genre, count(rental_id) as rental_count
from movies m
join rentals r on m.movie_id=r.movie_id
group by m.genre
order by rental_count desc
limit 1;

--find the most rented movie of each genre

select distinct on (m.genre) m.genre,m.title,count(r.rental_id) as rental_count
from rentals r
join movies m on r.movie_id=m.movie_id
group by m.genre,m.title
order by m.genre,rental_count desc;

--find customers who retured all their rentals late
SELECT c.name
FROM Customers c
WHERE NOT EXISTS (
    SELECT 1 FROM Rentals r
    WHERE r.customer_id = c.customer_id AND r.return_date - r.rental_date <= 7
);


-- 	TRIGGERS
--CREATING TABLE FOR TRIGGER
create table late_returns(
log_id serial primary key,
rental_id int references Rentals(rental_id) on delete set null,
customer_id int references customers(customer_id) on delete set null,
movie_id int references movies(movie_id) on delete set null,
logged_at timestamp default current_timestamp
);
select * from late_returns;
alter table late_returns add days_late int not null;






CREATE OR REPLACE FUNCTION log_late_returns() 
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.return_date - NEW.rental_date > 7 THEN
        INSERT INTO Late_Returns (rental_id, customer_id, movie_id, days_late)
        VALUES (NEW.rental_id, NEW.customer_id, NEW.movie_id, NEW.return_date - NEW.rental_date);
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;


CREATE TRIGGER check_late_returns
AFTER UPDATE ON Rentals
FOR EACH ROW
WHEN (NEW.return_date IS NOT NULL)
EXECUTE FUNCTION log_late_returns();


UPDATE Rentals 
SET return_date = rental_date + INTERVAL '10 days'
WHERE rental_id = 1;

select * from late_returns;

insert into Rentals(customer_id,movie_id,rental_date,return_date) values
(3,2,'2025-02-01','2025-02-20');
select * from late_returns;

DROP TRIGGER IF EXISTS check_late_returns ON Rentals;
DROP FUNCTION IF EXISTS log_late_returns;

CREATE OR REPLACE FUNCTION log_late_returns() RETURNS TRIGGER AS $$
BEGIN
    IF NEW.return_date - NEW.rental_date > 7 THEN
        INSERT INTO Late_Returns (rental_id, customer_id, movie_id, days_late)
        VALUES (NEW.rental_id, NEW.customer_id, NEW.movie_id, NEW.return_date - NEW.rental_date);
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;



CREATE TRIGGER check_late_returns
AFTER INSERT OR UPDATE ON Rentals
FOR EACH ROW
WHEN (NEW.return_date IS NOT NULL)
EXECUTE FUNCTION log_late_returns();


insert into Rentals(customer_id,movie_id,rental_date,return_date) values
(2,2,'2025-02-01','2025-02-20');

select * from late_returns;


--QUERIES

--list movies that have never been rented
select m.title
from movies  m
join rentals r on m.movie_id=r.movie_id
where r.movie_id=null;

--find the latest rental for each customer
select c.name, m.title, r.rental_date
from rentals r
join customers c on c.customer_id=r.customer_id
join movies m on m.movie_id=r.movie_id
where r.rental_date=(
select max(rental_date) from rentals r2
where r2.customer_id=r.customer_id
);

--find customers with more than 2 rentals
select c.name, count(r.rental_id) as rental_count
from customers c
join rentals r on r.customer_id=c.customer_id
group by c.name
having count(rental_id) >2;

--get the month with highest number of rentals
select extract(month from rental_date) as Month, count(*) as rental_count
from rentals
group by Month
order by rental_count desc;

--find customers who have rented more than 1 movie of same genre
select c.name,m.genre, count(*) as genre_rentals
from rentals r
join customers c on r.customer_id=c.customer_id
join movies m on m.movie_id=r.movie_id
group by c.name, m.genre
having count(*) >1;





