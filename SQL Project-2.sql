-- Creation of Database and importation the tables--

CREATE database Library;

-- Task 1. Create a new book record
-- "978-1-60129-456-2', 'To Kill a Mockingbird', 'Classic', 6.00, 'yes', 'Harper Lee', 'J.B. Lippincott & Co.')"
insert into books(isbn,book_title,category,rental_price,status,author,publisher)
values('978-1-60129-456-2', 'To Kill a Mockingbird', 'Classic', 6.00, 'yes', 'Harper Lee', 'J.B. Lippincott & Co.');
SELECT 
    *
FROM
    books;

-- Task 2. Update an Existing Member's Address
UPDATE members 
SET 
    member_address = '130 Oak St'
WHERE
    member_id = 'C103';
SELECT 
    *
FROM
    members;

-- Task 3. Delete a Record from the Issued Status Table 
-- Objective: Delete the record with issued_id = 'IS121' from the issued_status table.
DELETE FROM issued_status 
WHERE
    issued_id = 'IS121';

-- Task 4. Retrieve All Books Issued by a Specific Employee 
-- Objective: Select all books issued by the employee with emp_id = 'E101'.
SELECT 
    *
FROM
    issued_status
WHERE
    issued_emp_id = 'E101';

-- Task 5.  List Members Who Have Issued More Than One Book 
-- Objective: Use GROUP BY to find members who have issued more than one book.
SELECT 
    issued_emp_id, COUNT(*)
FROM
    issued_status
GROUP BY issued_emp_id
HAVING COUNT(*) > 1;

-- Task 6. Create Summary Tables: Used CTAS to generate new tables based on query results - each book and total book_issued_cnt**
CREATE TABLE book_issued_cnt AS SELECT b.isbn, b.book_title, COUNT(a.issued_id) AS issue_count FROM
    issued_status AS a
        JOIN
    books AS b ON a.issued_book_isbn = b.isbn
GROUP BY b.isbn , b.book_title;

-- Task 7. Retrieve All Books in a Specific Category
SELECT 
    *
FROM
    books
WHERE
    category = 'history';

-- Task 8: Find Total Rental Income by Category
SELECT 
    b.category, SUM(b.rental_price), COUNT(*)
FROM
    issued_status AS a
        JOIN
    books AS b ON a.issued_book_isbn = b.isbn
GROUP BY b.category;

-- Task 9: List Members Who Registered in the Last 180 Days
SELECT 
    *
FROM
    members
WHERE
    reg_date >= DATE_SUB(CURDATE(), INTERVAL 180 DAY);

-- Task 10 : List Employees with Their Branch Manager's Name and their branch details
SELECT 
    e1.emp_id,
    e1.emp_name,
    e1.position,
    e1.salary,
    b.*,
    e2.emp_name AS manager
FROM
    employees AS e1
        JOIN
    branch AS b ON e1.branch_id = b.branch_id
        JOIN
    employees AS e2 ON e2.emp_id = b.manager_id;

-- Task 11: Create a Table of Books with Rental Price Above a Certain Threshold
CREATE TABLE expensive_books AS SELECT * FROM
    books
WHERE
    rental_price > 7.00;

-- Task 12: Retrieve the List of Books Not Yet Returned
SELECT 
    *
FROM
    issued_status AS a
        LEFT JOIN
    return_status AS b ON a.issued_id = b.issued_id
WHERE
    b.return_id IS NULL; 

-- Task 13: Identify Members with Overdue Books
-- Write a query to identify members who have overdue books (assume a 30-day return period). Display the member's_id, member's name, book title, issue date, and days overdue.
SELECT 
    ist.issued_member_id,
    m.member_name,
    bk.book_title,
    ist.issued_date,
    -- rs.return_date,
    CURDATE() - ist.issued_date as over_dues_days
FROM issued_status as ist
JOIN 
members as m
    ON m.member_id = ist.issued_member_id
JOIN 
books as bk
    ON bk.isbn = ist.issued_book_isbn
LEFT JOIN 
return_status as rs
    ON rs.issued_id = ist.issued_id
WHERE 
    rs.return_date IS NULL
    AND
    (CURDATE() - ist.issued_date) > 30
ORDER BY ist.issued_member_id;

-- Task 14:  Update Book Status on Return
-- Write a query to update the status of books in the books table to "Yes" when they are returned (based on entries in the return_status table).
DELIMITER $$

CREATE PROCEDURE add_return_records(
    IN p_return_id VARCHAR(10), 
    IN p_issued_id VARCHAR(10), 
    IN p_book_quality VARCHAR(10)
)
BEGIN
    DECLARE v_isbn VARCHAR(50);
    DECLARE v_book_name VARCHAR(80);
    
    -- all your logic and code
    -- inserting into returns based on users input
    INSERT INTO return_status(return_id, issued_id, return_date, book_quality)
    VALUES (p_return_id, p_issued_id, CURDATE(), p_book_quality);

    SELECT issued_book_isbn, issued_book_name 
    INTO v_isbn, v_book_name
    FROM issued_status
    WHERE issued_id = p_issued_id;

    UPDATE books
    SET status = 'yes'
    WHERE isbn = v_isbn;

    SELECT CONCAT('Thank you for returning the book: ', v_book_name) AS notice_message;
    END$$

DELIMITER 

-- Task 15: Branch Performance Report
-- Create a query that generates a performance report for each branch, showing the number of books issued, the number of books returned, and the total revenue generated from book rentals.
CREATE TABLE branch_reports 
AS 
SELECT 
    b.branch_id, 
    b.manager_id, 
    COUNT(ist.issued_id) AS number_book_issued, 
    COUNT(rs.return_id) AS number_of_book_return, 
    SUM(bk.rental_price) AS total_revenue 
FROM issued_status AS ist 
JOIN employees AS e ON e.emp_id = ist.issued_emp_id 
JOIN branch AS b ON e.branch_id = b.branch_id 
LEFT JOIN return_status AS rs ON rs.issued_id = ist.issued_id 
JOIN books AS bk ON ist.issued_book_isbn = bk.isbn 
GROUP BY b.branch_id, b.manager_id; 

SELECT * FROM branch_reports;

-- Task 16: CTAS: Create a Table of Active Members
-- Use the CREATE TABLE AS (CTAS) statement to create a new table active_members containing members who have issued at least one book in the last 2 months.
CREATE TABLE active_members 
AS 
SELECT DISTINCT 
    m.member_id, 
    m.member_name, 
    m.email, 
    m.phone, 
    m.join_date 
FROM members AS m
INNER JOIN issued_status AS ist 
    ON m.member_id = ist.issued_member_id 
WHERE ist.issued_date >= DATE_SUB(CURDATE(), INTERVAL 2 MONTH);

SELECT * FROM active_members;

-- Task 17: Find Employees with the Most Book Issues Processed**  
-- Write a query to find the top 3 employees who have processed the most book issues. Display the employee name, number of books processed, and their branch.
SELECT 
    e.emp_name,
    b.*,
    COUNT(ist.issued_id) as no_book_issued
FROM issued_status as ist
JOIN
employees as e
ON e.emp_id = ist.issued_emp_id
JOIN
branch as b
ON e.branch_id = b.branch_id
GROUP BY 1, 2;

-- Task 18: Stored Procedure**
-- Create a stored procedure to manage the status of books in a library system.

CREATE OR REPLACE PROCEDURE issue_book(p_issued_id VARCHAR(10), p_issued_member_id VARCHAR(30), p_issued_book_isbn VARCHAR(30), p_issued_emp_id VARCHAR(10))
LANGUAGE plpgsql
AS $$

DECLARE
-- all the variabable
    v_status VARCHAR(10);

BEGIN
-- all the code
    -- checking if book is available 'yes'
    SELECT 
        status 
        INTO
        v_status
    FROM books
    WHERE isbn = p_issued_book_isbn;

    IF v_status = 'yes' THEN

        INSERT INTO issued_status(issued_id, issued_member_id, issued_date, issued_book_isbn, issued_emp_id)
        VALUES
        (p_issued_id, p_issued_member_id, CURRENT_DATE, p_issued_book_isbn, p_issued_emp_id);

        UPDATE books
            SET status = 'no'
        WHERE isbn = p_issued_book_isbn;

        RAISE NOTICE 'Book records added successfully for book isbn : %', p_issued_book_isbn;


    ELSE
        RAISE NOTICE 'Sorry to inform you the book you have requested is unavailable book_isbn: %', p_issued_book_isbn;
    END IF;
END;
$$

-- Testing The function
SELECT * FROM books;
-- "978-0-553-29698-2" -- yes
-- "978-0-375-41398-8" -- no
SELECT * FROM issued_status;

CALL issue_book('IS155', 'C108', '978-0-553-29698-2', 'E104');
CALL issue_book('IS156', 'C108', '978-0-375-41398-8', 'E104');

SELECT * FROM books
WHERE isbn = '978-0-375-41398-8';

