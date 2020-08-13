/* Welcome to the SQL mini project. You will carry out this project partly in
the PHPMyAdmin interface, and partly in Jupyter via a Python connection.

This is Tier 2 of the case study, which means that there'll be less guidance for you about how to setup
your local SQLite connection in PART 2 of the case study. This will make the case study more challenging for you: 
you might need to do some digging, aand revise the Working with Relational Databases in Python chapter in the previous resource.

Otherwise, the questions in the case study are exactly the same as with Tier 1. 

PART 1: PHPMyAdmin
You will complete questions 1-9 below in the PHPMyAdmin interface. 
Log in by pasting the following URL into your browser, and
using the following Username and Password:

URL: https://sql.springboard.com/
Username: student
Password: learn_sql@springboard

The data you need is in the "country_club" database. This database
contains 3 tables:
    i) the "Bookings" table,
    ii) the "Facilities" table, and
    iii) the "Members" table.

In this case study, you'll be asked a series of questions. You can
solve them using the platform, but for the final deliverable,
paste the code for each solution into this script, and upload it
to your GitHub.

Before starting with the questions, feel free to take your time,
exploring the data, and getting acquainted with the 3 tables. */


/* QUESTIONS 
/* Q1: Some of the facilities charge a fee to members, but some do not.
Write a SQL query to produce a list of the names of the facilities that do. */

SELECT name
FROM Facilities
WHERE membercost > 0

/* Q2: How many facilities do not charge a fee to members? */

SELECT COUNT(*)
FROM Facilities
WHERE membercost = 0

/* Q3: Write an SQL query to show a list of facilities that charge a fee to members,
where the fee is less than 20% of the facility's monthly maintenance cost.
Return the facid, facility name, member cost, and monthly maintenance of the
facilities in question. */

SELECT facid, name, membercost, monthlymaintenance
FROM Facilities
WHERE membercost > 0 AND membercost< 0.2*monthlymaintenance

/* Q4: Write an SQL query to retrieve the details of facilities with ID 1 and 5.
Try writing the query without using the OR operator. */

SELECT *
FROM Facilities
WHERE facid IN(1,5)

/* Q5: Produce a list of facilities, with each labelled as
'cheap' or 'expensive', depending on if their monthly maintenance cost is
more than $100. Return the name and monthly maintenance of the facilities
in question. */

SELECT name, monthlymaintenance,
    CASE WHEN monthlymaintenance < 100 THEN 'cheap'
        ELSE 'expensive' END as cost_qual
FROM Facilities

/* Q6: You'd like to get the first and last name of the last member(s)
who signed up. Try not to use the LIMIT clause for your solution. */

SELECT surname, firstname
FROM Members
ORDER BY memID DESC

/* Q7: Produce a list of all members who have used a tennis court.
Include in your output the name of the court, and the name of the member
formatted as a single column. Ensure no duplicate data, and order by
the member name. */

SELECT DISTINCT f.name as fac_name, (m.firstname || ' ' || m.surname) as full_name
FROM Facilities as f
INNER JOIN Bookings as b
USING(facid)
INNER JOIN members as m
USING(memid)
WHERE f.facid IN(0,1)
ORDER BY full_name

/* Q8: Produce a list of bookings on the day of 2012-09-14 which
will cost the member (or guest) more than $30. Remember that guests have
different costs to members (the listed costs are per half-hour 'slot'), and
the guest user's ID is always 0. Include in your output the name of the
facility, the name of the member formatted as a single column, and the cost.
Order by descending cost, and do not use any subqueries. */

SELECT f.name, (m.firstname || ' ' || m.surname) as full_name,
    CASE WHEN b.memid = 0 THEN f.guestcost*b.slots
        ELSE f.membercost*b.slots END as cost_booking
FROM Bookings as b
INNER JOIN Facilities as f
USING(facid)
INNER JOIN Members as m
USING(memid)
WHERE b.starttime LIKE '2012-09-14%' AND
    (f.membercost*b.slots > 30 OR (f.guestcost*b.slots > 30 AND b.memid = 0))
ORDER BY cost_booking DESC

/* Q9: This time, produce the same result as in Q8, but using a subquery. */

SELECT 
    f.name,
    (m.firstname || ' ' || m.surname) as full_name, 
    (f.guestcost * fac_slot.guest_slot + 
        f.membercost * fac_slot.mem_slot) as tot_cost
FROM (
    SELECT bookid, memid, facid, ifnull(mem_slot,0) as mem_slot, ifnull(guest_slot,0) as guest_slot
    FROM (
        WITH guest_b AS (
            SELECT bookid, memid, facid, slots
                FROM bookings
                WHERE memid = 0
                ),
        mem_b AS (
            SELECT bookid, memid, facid, slots
                FROM bookings
                WHERE memid != 0
                )
        SELECT b.bookid, b.memid, b.facid,
            mem_b.slots AS mem_slot,
            guest_b.slots AS guest_slot
        FROM bookings as b
        LEFT JOIN mem_b
        ON mem_b.bookid = b.bookid
        LEFT JOIN guest_b
        ON guest_b.bookid = b.bookid
        WHERE b.starttime LIKE '2012-09-14%')) as fac_slot
INNER JOIN members as m
USING(memid)
INNER JOIN facilities as f
USING(facid)    
WHERE (tot_cost > 30)
ORDER BY tot_cost DESC

/* PART 2: SQLite

Export the country club data from PHPMyAdmin, and connect to a local SQLite instance from Jupyter notebook 
for the following questions.  

QUESTIONS:
/* Q10: Produce a list of facilities with a total revenue less than 1000.
The output of facility name and total revenue, sorted by revenue. Remember
that there's a different cost for guests and members! */

SELECT f.name,
    (f.guestcost * fac_slot.guest_slot_tot + 
        f.membercost * fac_slot.mem_slot_tot) as tot_rev
FROM  
    (WITH guest_b AS (
        SELECT bookid, facid, slots
            FROM bookings
            WHERE memid = 0
            ),
    mem_b AS (
        SELECT bookid, facid, slots
            FROM bookings
            WHERE memid != 0
            )
    SELECT b.facid,
        SUM(mem_b.slots) AS mem_slot_tot,
        SUM(guest_b.slots) AS guest_slot_tot
    FROM bookings as b
    LEFT JOIN mem_b
    ON mem_b.bookid = b.bookid
    LEFT JOIN guest_b
    ON guest_b.bookid = b.bookid
    GROUP BY b.facid) as fac_slot
INNER JOIN facilities as f
USING(facid)
WHERE tot_rev < 1000
ORDER BY tot_rev desc

/* Q11: Produce a report of members and who recommended them in alphabetic surname,firstname order */

SELECT surname || ', ' || firstname as name
FROM Members
WHERE memid IN(
    SELECT DISTINCT recommendedby
    FROM Members
    WHERE recommendedby NOT NULL)

/* Q12: Find the facilities with their usage by member, but not guests */

SELECT facid, memid, SUM(slots)
FROM Bookings
WHERE memid !=0
GROUP BY facid, memid

/* Q13: Find the facilities usage by month, but not guests */

SELECT 
    strftime('%m', starttime) as month_group,
    facid, 
    SUM(slots) as usage
FROM Bookings
WHERE memid != 0
GROUP BY month_group, facid