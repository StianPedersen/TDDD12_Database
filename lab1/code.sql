/* Lab1,  felny523 - Felix Nyrfors,  stilo759 - Stian Pedersen*/



DROP TABLE IF EXISTS jbitem_lessavg CASCADE;
DROP VIEW IF EXISTS jbitem_lessavg_view CASCADE;
DROP VIEW IF EXISTS Total_debit_cost CASCADE;
DROP VIEW IF EXISTS Total_debit_cost2 CASCADE;
DROP VIEW IF EXISTS jbsale_supply CASCADE;

/* Task 1*/
SELECT name FROM jbemployee;
/*
Ross, Stanley
Ross, Stuart
Edwards, Peter
Thompson, Bob
Smythe, Carol
Hayes, Evelyn
Evans, Michael
Raveen, Lemont
James, Mary
Williams, Judy
Thomas, Tom
Jones, Tim
Bullock, J.D.
Collins, Joanne
Brunet, Paul C.
Schmidt, Herman
Iwano, Masahiro
Smith, Paul
Onstad, Richard
Zugnoni, Arthur A.
Choy, Wanda
Wallace, Maggie J.
Bailey, Chas M.
Bono, Sonny
Schwarz, Jason B.
*/
/* Task 2*/
SELECT name FROM jbdept ORDER BY name ASC;
/*
Bargain
Book
Candy
Children's
Children's
Furniture
Giftwrap
Jewelry
Junior Miss
Junior's
Linens
Major Appliances
Men's
Sportswear
Stationary
Toys
Women's
Women's
Women's
*/

/* Task 3*/
SELECT name FROM jbparts WHERE qoh=0;
/*
card reader
card punch
paper tape reader
paper tape punch
*/

/*Task 4*/
SELECT name, salary FROM jbemployee WHERE salary BETWEEN 9000 AND 10000;
/*
Edwards, Peter	9000
Smythe, Carol	9050
Williams, Judy	9000
Thomas, Tom	10000
*/

/*task 5*/
SELECT name, startyear-birthyear FROM jbemployee;
/*
Ross, Stanley	18
Ross, Stuart	1
Edwards, Peter	30
Thompson, Bob	40
Smythe, Carol	38
Hayes, Evelyn	32
Evans, Michael	22
Raveen, Lemont	24
James, Mary	49
Williams, Judy	34
Thomas, Tom	21
Jones, Tim	20
Bullock, J.D.	0
Collins, Joanne	21
Brunet, Paul C.	21
Schmidt, Herman	20
Iwano, Masahiro	26
Smith, Paul	21
Onstad, Richard	19
Zugnoni, Arthur A.	21
Choy, Wanda	23
Wallace, Maggie J.	19
Bailey, Chas M.	19
Bono, Sonny	24
Schwarz, Jason B.	15
*/

/*task6*/
SELECT name FROM jbemployee WHERE name LIKE '%son,%';
/*
Thompson, Bob
*/

/*task 7*/
SELECT name FROM jbitem WHERE supplier in (SELECT id FROM jbsupplier WHERE name = 'Fisher-Price');
/*
Maze
The 'Feel' Book
Squeeze Ball
*/

/*task8*/
SELECT a.name FROM jbitem a, jbsupplier b WHERE a.supplier = b.id AND b.name = 'Fisher-Price';
/*
Maze
The 'Feel' Book
Squeeze Ball
*/

/*task9*/
SELECT name FROM jbcity WHERE id in (SELECT city FROM jbsupplier);
/*
Amherst
Boston
New York
White Plains
Hickville
Atlanta
Madison
Paxton
Dallas
Denver
Salt Lake City
Los Angeles
San Diego
San Francisco
Seattle
*/


/*task 10*/
SELECT name, color FROM jbparts WHERE weight > (SELECT weight FROM jbparts where name = 'card reader');
/*
disk drive	black
tape drive	black
line printer	yellow
card punch	gray
*/

/*task 11*/
SELECT a.name, a.color FROM jbparts a join jbparts b WHERE b.name = 'card reader' and a.weight > b.weight;
/*
disk drive	black
tape drive	black
line printer	yellow
card punch	gray
*/
/*12. What is the average weight of all black parts?*/
SELECT avg(weight) from jbparts WHERE color = "black";
/*'347.2500'
*/

/*13. For every supplier in Massachusetts (?Mass?), retrieve the name and the
total weight of all parts that the supplier has delivered? Do not forget to
take the quantity of delivered parts into account. Note that one row
should be returned for each supplier*/


SELECT jbsupplier.name, sum(quan*weight)
from jbsupplier, jbsupply, jbparts
WHERE supplier IN (SELECT id from jbsupplier WHERE city IN (SELECT id from jbcity WHERE state = 'mass'))
AND jbsupply.part=jbparts.id AND jbsupplier.id=jbsupply.supplier GROUP BY jbsupplier.name;

/*
'DEC', '3120'
'Fisher-Price', '1135000'
*/

/*14. Create a new relation with the same attributes as the jbitems relation by
using the CREATE TABLE command where you define every attribute
explicitly (i.e., not as a copy of another table). Then, populate this new
relation with all items that cost less than the average price for all items.
Remember to define the primary key and foreign keys in your table!
*/
CREATE TABLE jbitem_lessavg (
	id INT,
    name VARCHAR(20),
    dept INT NOT NULL,
    price INT,
    qoh INT UNSIGNED /* or, if check constraints were enforced: INT CHECK (qoh >= 0)*/,
    supplier INT NOT NULL,
    CONSTRAINT pk_item2 PRIMARY KEY(id));
    
INSERT INTO jbitem_lessavg
SELECT * from jbitem WHERE jbitem.price < (SELECT avg(price) from jbitem);
COMMIT;

SELECT * from jbitem_lessavg;

/*
'11', 'Wash Cloth', '1', '75', '575', '213'
'19', 'Bellbottoms', '43', '450', '600', '33'
'21', 'ABC Blocks', '1', '198', '405', '125'
'23', '1 lb Box', '10', '215', '100', '42'
'25', '2 lb Box, Mix', '10', '450', '75', '42'
'26', 'Earrings', '14', '1000', '20', '199'
'43', 'Maze', '49', '325', '200', '89'
'106', 'Clock Book', '49', '198', '150', '125'
'107', 'The \'Feel\' Book', '35', '225', '225', '89'
'118', 'Towels, Bath', '26', '250', '1000', '213'
'119', 'Squeeze Ball', '49', '250', '400', '89'
'120', 'Twin Sheet', '26', '800', '750', '213'
'165', 'Jean', '65', '825', '500', '33'
'258', 'Shirt', '58', '650', '1200', '33'
*/

/*15. Create a view that contains the items that cost less than the average
price for items.*/
CREATE VIEW jbitem_lessavg_view AS SELECT * FROM jbitem_lessavg;
SELECT * from jbitem_lessavg_view;
/*
'11', 'Wash Cloth', '1', '75', '575', '213'
'19', 'Bellbottoms', '43', '450', '600', '33'
'21', 'ABC Blocks', '1', '198', '405', '125'
'23', '1 lb Box', '10', '215', '100', '42'
'25', '2 lb Box, Mix', '10', '450', '75', '42'
'26', 'Earrings', '14', '1000', '20', '199'
'43', 'Maze', '49', '325', '200', '89'
'106', 'Clock Book', '49', '198', '150', '125'
'107', 'The \'Feel\' Book', '35', '225', '225', '89'
'118', 'Towels, Bath', '26', '250', '1000', '213'
'119', 'Squeeze Ball', '49', '250', '400', '89'
'120', 'Twin Sheet', '26', '800', '750', '213'
'165', 'Jean', '65', '825', '500', '33'
'258', 'Shirt', '58', '650', '1200', '33'
*/

/*16. What is the difference between a table and a view? One is static and the
other is dynamic. Which is which and what do we mean by static
respectively dynamic?

ANSWER: The table is an actual or real table that exists in physical locations.
Views are the cirtual or logical table that does not exist in any physical location.
This implies that tables are dynamic since we can update the table with operations such as "add" and "delete".
Views are static and can not be updated in the same way since the view is only a copy of a table. 

*/

/*17. Create a view that calculates the total cost of each debit, by considering
price and quantity of each bought item. (To be used for charging
customer accounts). The view should contain the sale identifier (debit)
and the total cost. In the query that defines the view, capture the join
condition in the WHERE clause (i.e., do not capture the join in the
FROM clause by using keywords inner join, right join or left join)*/
CREATE VIEW Total_debit_cost AS
SELECT debit, sum(price*quantity) from jbsale,jbitem
WHERE id=item
GROUP BY debit;

SELECT * FROM Total_debit_cost;

/*18. Do the same as in the previous point, but now capture the join conditions
in the FROM clause by using only left, right or inner joins. Hence, the
WHERE clause must not contain any join condition in this case. Motivate
why you use type of join you do (left, right or inner), and why this is the
correct one (in contrast to the other types of joins).*/

CREATE VIEW Total_debit_cost2 AS
SELECT debit, sum(price*quantity) from jbsale
INNER JOIN jbitem ON id=item
GROUP BY debit;

SELECT * FROM Total_debit_cost2;


/*
19. Oh no! An earthquake!
a) Remove all suppliers in Los Angeles from the jbsupplier table. This
will not work right away. Instead, you will receive an error with error
code 23000 which you will have to solve by deleting some other
related tuples. However, do not delete more tuples from other tables
than necessary, and do not change the structure of the tables (i.e., do not remove foreign keys). 
Also, you are only allowed to use "Los Angeles" as a constant in your queries, not "199" or "900".
*/

SET SQL_SAFE_UPDATES=0;

DELETE FROM jbsale WHERE item IN 
(SELECT jbitem.id FROM jbitem WHERE supplier = 
(SELECT jbsupplier.id FROM jbsupplier WHERE city =
(SELECT jbcity.id FROM jbcity WHERE name = "Los Angeles")));

DELETE FROM jbitem WHERE supplier = 
(SELECT id FROM jbsupplier WHERE city =
(SELECT id FROM jbcity WHERE name = "Los Angeles"));

DELETE FROM jbsupplier WHERE city = 
(SELECT id FROM jbcity WHERE name = "Los Angeles");

SET SQL_SAFE_UPDATES=1;


SELECT * FROM jbsupplier;

/*
'5', 'Amdahl', '921'
'15', 'White Stag', '106'
'20', 'Wormley', '118'
'33', 'Levi-Strauss', '941'
'42', 'Whitman\'s', '802'
'62', 'Data General', '303'
'67', 'Edger', '841'
'89', 'Fisher-Price', '21'
'122', 'White Paper', '981'
'125', 'Playskool', '752'
'213', 'Cannon', '303'
'241', 'IBM', '100'
'440', 'Spooley', '609'
'475', 'DEC', '10'
'999', 'A E Neumann', '537'
*/
/*19 b) Explain what you did and why.

ANSWER:
We started by deleting from jbsupplier and then we removed the foreigns keys that
were referenced to jbsupplier in the error message and continued to do that until it worked.
So in the end we removed from jbsale, jbitem and jbsupplier. 
 */

/*
20. An employee has tried to find out which suppliers have delivered items
that have been sold. To this end, the employee has created a view and
a query that lists the number of items sold from a supplier.
*/
/*CREATE VIEW jbsale_supply(supplier, item, quantity) AS
SELECT jbsupplier.name, jbitem.id, jbsale.quantity
FROM jbsupplier, jbitem, jbsale
WHERE jbsupplier.id = jbitem.supplier;*/

CREATE VIEW jbsale_supply(supplier, item, quantity) AS
SELECT jbsupplier.name, jbitem.name, jbsale.quantity
FROM jbsupplier INNER JOIN (jbitem LEFT JOIN jbsale ON jbitem.id=jbsale.item) ON jbitem.supplier=jbsupplier.id;


SELECT supplier, sum(quantity)
FROM jbsale_supply GROUP BY supplier;

/*
'Cannon', '6'
'Fisher-Price', NULL
'Levi-Strauss', '1'
'Playskool', '2'
'White Stag', '4'
'Whitman\'s', '2'
*/





