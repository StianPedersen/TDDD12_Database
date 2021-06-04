DROP FUNCTION IF EXISTS calculateFreeSeats;
DROP FUNCTION IF EXISTS calculatePrice;
DROP FUNCTION IF EXISTS create_ticketnumber;
DROP PROCEDURE IF EXISTS addContact;
DROP PROCEDURE IF EXISTS addDay;
DROP PROCEDURE IF EXISTS addDestination;
DROP PROCEDURE IF EXISTS addFlight;
DROP PROCEDURE IF EXISTS addPassenger;
DROP PROCEDURE IF EXISTS addPayment;
DROP PROCEDURE IF EXISTS addReservation;
DROP PROCEDURE IF EXISTS addRoute;
DROP PROCEDURE IF EXISTS addYear;
DROP TRIGGER IF EXISTS ticketnumber_trigger;
DROP TABLE IF EXISTS booking CASCADE;
DROP TABLE IF EXISTS traveller CASCADE;
DROP TABLE IF EXISTS reservation CASCADE;
DROP TABLE IF EXISTS flight CASCADE;
DROP TABLE IF EXISTS weekly_schedule CASCADE;
DROP TABLE IF EXISTS d_ay CASCADE;
DROP TABLE IF EXISTS y_ear CASCADE;
DROP TABLE IF EXISTS route CASCADE;
DROP TABLE IF EXISTS airport CASCADE;
DROP TABLE IF EXISTS passenger CASCADE;
DROP TABLE IF EXISTS payment CASCADE;
DROP VIEW IF EXISTS allFlights CASCADE;
SELECT 'Creating tables' AS 'Message';

CREATE TABLE y_ear
	(y_ear INT,
	 profitfactor DOUBLE,
     CONSTRAINT PRIMARY KEY(y_ear)) ENGINE=InnoDB;
     
CREATE TABLE d_ay
	(weekday VARCHAR(10),
     weekdayfactor DOUBLE,
     y_ear INT,
     CONSTRAINT PRIMARY KEY(weekday, y_ear)) ENGINE=InnoDB;
    
CREATE TABLE weekly_schedule
	(id INT NOT NULL AUTO_INCREMENT,
	 departure_time TIME,
     route_id INT,
     d_ay VARCHAR(10),
     y_ear INT,
     CONSTRAINT PRIMARY KEY(id)) ENGINE=InnoDB;
     
CREATE TABLE flight
	(flight_id INT NOT NULL AUTO_INCREMENT,
     weeknumber INT,
     week_id INT,
     CONSTRAINT PRIMARY KEY (flight_id)) ENGINE=InnoDB;

CREATE TABLE route
	(route_id INT NOT NULL AUTO_INCREMENT,
     routeprice DOUBLE,
     y_ear INT,
     arrival_airportcode VARCHAR(3),
     departure_airportcode VARCHAR(3),
     CONSTRAINT PRIMARY KEY (route_id)) ENGINE=InnoDB;
     
CREATE TABLE airport
	(airportcode VARCHAR(3),
	 country VARCHAR(30),
	 airportname VARCHAR(30),
CONSTRAINT PRIMARY KEY (airportcode)) ENGINE=InnoDB;

CREATE TABLE reservation
	(reservation_id INT,
	 flight_id INT,
	 pass_number INT,
	 phone_number BIGINT,
	 email VARCHAR(30),
CONSTRAINT PRIMARY KEY (reservation_id)) ENGINE=InnoDB;

CREATE TABLE passenger
	(pass_number INT,
     human_name VARCHAR(30),
CONSTRAINT PRIMARY KEY (pass_number)) ENGINE=InnoDB;

CREATE TABLE traveller
	(reservation_id INT,
     pass_number INT,
     ticket_number BIGINT,
CONSTRAINT PRIMARY KEY (reservation_id,pass_number)) ENGINE=InnoDB;
     
CREATE TABLE booking
	(reservation_id INT,
     paid_price DOUBLE,
     card_number BIGINT,
CONSTRAINT PRIMARY KEY (reservation_id)) ENGINE=InnoDB;
     
CREATE TABLE payment
	(card_number BIGINT,
     credit_card_holder VARCHAR(30),
CONSTRAINT PRIMARY KEY (card_number)) ENGINE=InnoDB;

ALTER TABLE d_ay ADD CONSTRAINT fk_d_ay_year FOREIGN KEY (y_ear) REFERENCES y_ear(y_ear);

ALTER TABLE weekly_schedule ADD CONSTRAINT fk_weekly_schedule_day FOREIGN KEY (d_ay,y_ear) REFERENCES d_ay(weekday, y_ear);
ALTER TABLE weekly_schedule ADD CONSTRAINT fk_weekly_schedule FOREIGN KEY (route_id) REFERENCES route(route_id);

ALTER TABLE flight ADD CONSTRAINT fk_flight FOREIGN KEY (week_id) REFERENCES weekly_schedule(id);
ALTER TABLE reservation ADD CONSTRAINT fk_reservation_flight FOREIGN KEY (flight_id) REFERENCES flight(flight_id);
ALTER TABLE reservation ADD CONSTRAINT fk_reservation_pass FOREIGN KEY (pass_number) REFERENCES passenger(pass_number);

ALTER TABLE booking ADD CONSTRAINT fk_booking_card FOREIGN KEY (card_number) REFERENCES payment(card_number);
ALTER TABLE booking ADD CONSTRAINT fk_booking_reservation FOREIGN KEY (reservation_id) REFERENCES reservation(reservation_id);

ALTER TABLE traveller ADD CONSTRAINT fk_traveller_reservation FOREIGN KEY (reservation_id) REFERENCES reservation(reservation_id);
ALTER TABLE traveller ADD CONSTRAINT fk_traveller_passenger FOREIGN KEY (pass_number) REFERENCES passenger(pass_number);

ALTER TABLE route ADD CONSTRAINT fk_route_arrival FOREIGN KEY (arrival_airportcode) REFERENCES airport(airportcode);
ALTER TABLE route ADD CONSTRAINT fk_route_departure FOREIGN KEY (departure_airportcode) REFERENCES airport(airportcode);

DELIMITER //
CREATE FUNCTION create_ticketnumber() 
RETURNS INTEGER
BEGIN
DECLARE new_ticket_number INT;
LOOP
	SET new_ticket_number = FLOOR(RAND()*(10000-1+1)+1);
    IF NOT EXISTS (SELECT ticket_number FROM traveller WHERE traveller.ticket_number=new_ticket_number) THEN
		RETURN new_ticket_number;
	END IF;
END LOOP;
END//
DELIMITER ;


DELIMITER //
CREATE TRIGGER ticketnumber_trigger
AFTER INSERT ON booking FOR EACH ROW
BEGIN
UPDATE traveller 
SET traveller.ticket_number = create_ticketnumber() 
WHERE traveller.reservation_id=NEW.reservation_id;


END//
DELIMITER ;



DELIMITER //
CREATE PROCEDURE addContact(reservation_nr INT, passport_number INT, email VARCHAR(30), phone BIGINT)
BEGIN
DECLARE res_id INT;
set res_id = (SELECT reservation_id FROM traveller WHERE reservation_nr = traveller.reservation_id AND passport_number = traveller.pass_number);

IF (reservation_nr NOT IN (SELECT reservation_id FROM reservation)) THEN
	SELECT "The given reservation number does not exist";

ELSEIF (res_id IS NULL) THEN
	SELECT "The person is not a passenger of the reservation";

ELSE
SET SQL_SAFE_UPDATES=0;
	UPDATE reservation
    SET
    reservation.email=email,
    reservation.phone_number=phone,
    reservation.pass_number=passport_number
	WHERE
    reservation.reservation_id = reservation_nr;
SET SQL_SAFE_UPDATES=1;
    
END IF;
END //
DELIMITER ;

DELIMITER //
CREATE PROCEDURE addDay(IN y INT, IN d VARCHAR(10), IN factor DOUBLE)
BEGIN
INSERT INTO d_ay(weekday,weekdayfactor, y_ear)
	VALUES (d,factor, y);
END //
DELIMITER ;

DELIMITER //
CREATE PROCEDURE addDestination(IN airport_code VARCHAR(3), IN airport_name VARCHAR(30), IN country VARCHAR(30))
BEGIN
INSERT INTO airport(airportcode, airportname, country)
VALUES (airport_code, airport_name, country);
END //
DELIMITER ;

DELIMITER //
CREATE PROCEDURE addFlight(IN departure_airport_code VARCHAR(3), IN arrival_airport_code VARCHAR(3), IN new_year INT, IN new_day VARCHAR(10), IN departure_time TIME)
BEGIN

DECLARE weekno INT DEFAULT 1;
DECLARE r_id, week_id INT;
set r_id = (SELECT route_id FROM route
WHERE (arrival_airportcode = arrival_airport_code AND departure_airportcode = departure_airport_code AND y_ear=new_year));


INSERT INTO weekly_schedule(id, departure_time, route_id, d_ay, y_ear)
VALUES (id, departure_time, r_id, new_day, new_year);

set week_id = (SELECT id FROM weekly_schedule WHERE weekly_schedule.departure_time=departure_time AND 
				weekly_schedule.route_id=r_id AND weekly_schedule.d_ay=new_day AND weekly_schedule.y_ear=new_year);

WHILE weekno <= 52 do
	INSERT INTO flight(flight_id, weeknumber, week_id)
    VALUES (flight_id, weekno, week_id);
    SET weekno = weekno+1;
END WHILE;
END //
DELIMITER ;

DELIMITER //
CREATE PROCEDURE addPassenger(reservation_nr INT, passport_number INT, n_ame VARCHAR(30))
BEGIN

IF (reservation_nr IN (SELECT reservation_id FROM booking)) THEN
	SELECT "The booking has already been payed and no futher passengers can be added";
ELSEIF (reservation_nr IN (SELECT reservation_id FROM reservation)) THEN
	IF (passport_number NOT IN (SELECT pass_number FROM passenger)) THEN
		INSERT INTO passenger(pass_number, human_name)
		VALUES (passport_number, n_ame);
    END IF;
    INSERT INTO traveller(reservation_id, pass_number, ticket_number)
    VALUES (reservation_nr, passport_number, NULL);

ELSE
	SELECT "The given reservation number does not exist";

END IF;

END //
DELIMITER ;

DELIMITER //
CREATE PROCEDURE addPayment(reservation_nr INT, cardholder_name VARCHAR(30), credit_card_number BIGINT)
BEGIN

DECLARE pass_numb BIGINT;
DECLARE flightnr, numb_of_passenger INT;
#SELECT "HELOOOOOADOASDOA";
set pass_numb = (SELECT pass_number FROM reservation WHERE reservation.reservation_id=reservation_nr);
set flightnr = (SELECT flight_id FROM reservation WHERE reservation.reservation_id=reservation_nr);
set numb_of_passenger = (SELECT COUNT(*) FROM traveller WHERE traveller.reservation_id=reservation_nr);
IF (reservation_nr NOT IN (SELECT reservation_id FROM reservation)) THEN
	SELECT "The given reservation number does not exist";

ELSEIF ((SELECT pass_number FROM reservation WHERE reservation.reservation_id=reservation_nr) IS NULL) THEN
	SELECT "The reservation has no contact yet";

ELSEIF (reservation_nr IN (SELECT reservation_id FROM booking)) THEN
	SELECT "The booking has already been payed and no futher passengers can be added";

ELSEIF(calculateFreeSeats(flightnr) < numb_of_passenger) THEN
	DELETE FROM traveller WHERE traveller.reservation_id = reservation_nr;
	DELETE FROM reservation WHERE reservation.reservation_id = reservation_nr;
	SELECT "There are not enough seats available on the flight anymore, deleting reservation";

ELSE
    IF (credit_card_number NOT IN (SELECT card_number from payment)) THEN
	INSERT INTO payment(card_number, credit_card_holder)
    VALUES(credit_card_number, cardholder_name);
    END IF;
	INSERT INTO booking(reservation_id, paid_price, card_number)
    VALUES (reservation_nr, calculatePrice(flightnr), credit_card_number);
END IF;
END //
DELIMITER ;

DELIMITER //
CREATE PROCEDURE addReservation(departure_airport_code VARCHAR(3), arrival_airport_code VARCHAR(3), y_ear INT, week INT, d_ay VARCHAR(10), 
t_ime TIME, number_of_passengers INT, OUT output_reservation_nr INT)
BEGIN
DECLARE route_id2, week_id2, flight_id2, free_seats, reserv_id INT;
set route_id2 = (SELECT route_id FROM route WHERE departure_airport_code=departure_airportcode AND arrival_airport_code = arrival_airportcode AND y_ear=route.y_ear);
set week_id2 = (SELECT id FROM weekly_schedule WHERE route_id2 = weekly_schedule.route_id AND d_ay=weekly_schedule.d_ay AND t_ime=departure_time AND y_ear=weekly_schedule.y_ear);
set flight_id2 = (SELECT flight_id FROM flight WHERE week_id2 = flight.week_id AND week=weeknumber);


IF (week_id2 IS NULL OR flight_id2 IS NULL) THEN
	SELECT "There exist no flight for the given route, date and time";

ELSE
	set free_seats = calculateFreeSeats(flight_id2);
	IF (free_seats < number_of_passengers) THEN
		SELECT "There are not enough seats available on the chosen flight";

	ELSE
		set reserv_id = FLOOR(RAND()*(10000-1+1)+1);
		WHILE (reserv_id IN (SELECT reservation_id FROM reservation)) DO
			set reserv_id = FLOOR(RAND()*(10000-1+1)+1);
		END WHILE;
		INSERT INTO reservation(reservation_id, flight_id, pass_number, phone_number, email)
		VALUES (reserv_id, flight_id2, pass_number, phone_number, email);
		set output_reservation_nr = reserv_id;
	END IF;
END IF;

END //
DELIMITER ;

DELIMITER //
CREATE PROCEDURE addRoute(IN departure_airport_code VARCHAR(3), IN arrival_airport_code VARCHAR(3), IN y_ear INT, IN routeprice DOUBLE)
BEGIN
INSERT INTO route(routeprice, y_ear, arrival_airportcode, departure_airportcode)
VALUES (routeprice, y_ear, arrival_airport_code, departure_airport_code);
END//
DELIMITER ;

DELIMITER //
CREATE PROCEDURE addYear(IN y INT, IN factor DOUBLE)
BEGIN
	INSERT INTO y_ear(y_ear,profitfactor)
	VALUES (y,factor);
END//
DELIMITER ;

DELIMITER //
CREATE FUNCTION calculateFreeSeats(flightnumber INT) RETURNS int(11)
BEGIN
DECLARE count INT;
set count = (SELECT COUNT(*) FROM traveller WHERE traveller.ticket_number IS NOT NULL AND traveller.reservation_id IN 
(SELECT reservation_id FROM reservation WHERE flightnumber=reservation.flight_id));
IF (count IS NULL) THEN
	set count=0;
END IF;
RETURN (40-count);
END//
DELIMITER ;


DELIMITER //
CREATE FUNCTION calculatePrice (flightnumber INT) RETURNS double
BEGIN
DECLARE weekly_id, route_id2, r_p, booked_passengers, y_ear2 INT;
DECLARE d_ay2 VARCHAR(10);
DECLARE w_f, p_f, Totalprice DOUBLE;

set weekly_id = (SELECT week_id FROM flight WHERE flightnumber = flight.flight_id);
set route_id2 = (SELECT route_id FROM weekly_schedule WHERE weekly_id = weekly_schedule.id);
set r_p = (SELECT routeprice FROM route WHERE route_id2 = route.route_id); #ROUTEPRICE

set d_ay2 = (SELECT d_ay FROM weekly_schedule WHERE weekly_id = weekly_schedule.id);
set w_f = (SELECT weekdayfactor FROM d_ay WHERE d_ay2 = d_ay.weekday); #WEEKDAYFACTOR
set booked_passengers = 40-calculateFreeSeats(flightnumber); #BOOKED PASSENGERS

set y_ear2 = (SELECT y_ear FROM d_ay WHERE d_ay2 = d_ay.weekday);
set p_f = (SELECT profitfactor FROM y_ear WHERE y_ear2 = y_ear.y_ear);

set Totalprice = (r_p * w_f*p_f*(booked_passengers+1)/40);
RETURN Totalprice;
END//
DELIMITER ;

CREATE VIEW allFlights AS SELECT 
f.airportname AS departure_city_name, 
t.airportname AS destination_city_name, 
weekly_schedule.departure_time AS departure_time,
weekly_schedule.d_ay AS departure_day, 
flight.weeknumber AS departure_week, 
weekly_schedule.y_ear AS departure_year, 
calculateFreeSeats(flight.flight_id) AS nr_of_free_seats,
calculatePrice(flight.flight_id) AS current_price_per_seat FROM flight
INNER JOIN weekly_schedule ON flight.week_id = weekly_schedule.id
INNER JOIN route ON route.route_id=weekly_schedule.route_id
INNER JOIN airport AS f ON route.departure_airportcode = f.airportcode
INNER JOIN airport AS t ON route.arrival_airportcode = t.airportcode;