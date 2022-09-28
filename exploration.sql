-- SQL ASSIGNMENT QUESTIONS TO ANSWER

use airline_db;

-- 1.	Find out the airline company which has a greater number of flight movement.

select 
	cd.Carrier_code,
	count(FlightId) as number_of_flights
from carrier_detail as cd left join flight_detail
	on cd.Carrier_ID=flight_detail.carrierId
group by flight_detail.carrierId
order by count(FlightId) desc;

-- 2.	Get the details of the first five flights that has high airtime.

select 
	flightId,
    airtime
from flight_detail
order by airtime desc limit 5;

-- 3. Compute the maximum difference between the scheduled and actual arrival 
--    and departure time for the flights and categorize it by the airline companies.

select 
	carrierId,
	max(arrivaldelay) as "max_arrival_delay(in min)",
    max(departuredelay) as "max_departure_delay(in min)"
from flight_detail
group by carrierId;

-- SELECT * from INFORMATION_SCHEMA.columns where table_schema = 'airline_db' and table_name = 'flight_detail';
-- to check the above results re correct or not : 
-- select * from flight_detail where time_to_sec(timediff(ScheduledArrivaltime,Arrivaltime))=86040;

-- 4.	Find the month in which the flight delays happened to be more.

select 
	flight_month,
    max(arrivaldelay)
from flight_detail
group by flight_month
order by max(arrivaldelay) desc limit 1;
    
-- select distinct flight_month from flight_detail;
    
-- 5.	Get the flight count for each state and identify the top 1.

select 
	state_detail.stateId,
    count(flight_detail.FlightId) as num_of_flights
from flight_detail join route_detail
		on flight_detail.routeId=route_detail.route_ID
     join airport_detail
		on airport_detail.locationId=route_detail.origincode
	 join state_detail
		on state_detail.stateId=airport_detail.stateId
group by state_detail.stateId
order by count(flight_detail.FlightId) desc;

-- 6. A customer wants to book a flight under an emergency situation. Which airline would you suggest him to book. Justify your answer.

select 
	carrier_detail.Carrier_code,
    avg(flight_detail.arrivaldelay) as arrival_delay,
    avg(flight_detail.departuredelay) as departure_delay,
    count(
    avg(speed),
    avg(carrierdelay) as carrier_delay,
	avg(securitydelay) as security_delay,
    avg(Late_aircraft_delay) as aircraft_delay,
    avg(taxiIn),
    avg(taxiOut)
from flight_detail join carrier_detail
	on flight_detail.carrierId=carrier_detail.Carrier_ID
where arrivaldelay>0 
group by flight_detail.carrierId
order by arrival_delay,departure_delay,carrier_delay,security_delay,aircraft_delay,avg(taxiIn),avg(taxiOut) ;

-- 7.	Find the dates in each month on which the flight delays are more.

select 
	flight_month,
	daymonth
from flight_detail 
where arrivaldelay in (select max(arrivaldelay) from flight_detail group by flight_month);

-- 8.	Calculate the percentage of flights that are delayed compared to flights that arrived on time.

with cte1 as (Select count(FlightId) as delayedflight from flight_detail where arrivaldelay>0),
	 cte2 as (select count(FlightId) as ontimeflight from flight_detail where arrivaldelay=0),
     cte3 as (select count(FlightId) as total_flight from flight_detail)
select 
	(cte1.delayedflight)/cte3.total_flight *100 as percentage_of_delayed_flight,
    (cte2.ontimeflight)/cte3.total_flight *100 as percentage_of_ontime_flight
from cte1,cte2,cte3;
    
-- 9. Identify the routes that has more delay time.

with cte1 as (select route_detail.route_ID as routeId,
				airport_detail.airport_name as origin_airport 
				from route_detail join airport_detail 
					on route_detail.origincode=airport_detail.locationId),
	cte2 as ( select route_detail.route_ID as routeId,
				airport_detail.airport_name as destination_airport 
				from route_detail join airport_detail 
					on route_detail.destinationcode=airport_detail.locationId),
	cte3 as ( select 
				routeId, max(arrivaldelay)  as delay from flight_detail group by routeId)
select 
    cte3.routeId,
    cte3.delay,
    cte1.origin_airport,
    cte2.destination_airport 
    from cte1 join cte2
		on cte1.routeId=cte2.routeId
	join cte3
        on cte2.routeId=cte3.routeId;

-- Error Code: 2013. Lost connection to MySQL server during query

 select 
		routeId,
        max(arrivaldelay)  as delay 
	from flight_detail 
	group by routeId;
    
-- 10.	Find out on which day of week the flight delays happen more.

select 
	dayweek,
    count(arrivaldelay)
from flight_detail
where arrivaldelay>0
group by dayweek
order by count(arrivaldelay) desc ;

-- 11.	Identify at which part of day flights arrive late.
with cte1 as (
select 
	count(ScheduledArrivaltime) as late_at_daytime
from flight_detail
where time_to_sec(ScheduledArrivaltime)>=21600 and time_to_sec(ScheduledArrivaltime)<64800 and arrivaldelay>0),
cte2 as(
select 
	count(ScheduledArrivaltime) as late_at_night
from flight_detail
where time_to_sec(ScheduledArrivaltime)>=64800 and time_to_sec(ScheduledArrivaltime)<86400 and arrivaldelay>0)

select cte1.late_at_daytime as late_at_daytime,
	   cte2.late_at_night as late_at_night
from cte1,cte2;

 -- 12.	Compute the maximum, minimum and average TaxiIn and TaxiOut time.
 
 select 
	max(taxiIn), min(taxiIn), avg(taxiIn),
    max(taxiOut),min(taxiOut),avg(taxiOut)
from flight_detail;

-- 13.	Get the details of origin and destination with maximum flight movement.
with cte1 as (select route_detail.route_ID as routeId,
				airport_detail.airport_name as origin_airport 
				from route_detail join airport_detail 
					on route_detail.origincode=airport_detail.locationId),
	cte2 as ( select route_detail.route_ID as routeId,
				airport_detail.airport_name as destination_airport 
				from route_detail join airport_detail 
					on route_detail.destinationcode=airport_detail.locationId)
select 
	flight_detail.FlightId,
    flight_detail.airtime,
    flight_detail.routeId,
    cte1.origin_airport,
    cte2.destination_airport
from flight_detail join cte1
	on flight_detail.routeId=cte1.routeId
join cte2
	on flight_detail.routeId=cte2.routeId
where flight_detail.airtime = (select max(airtime) from flight_detail);

-- 14.	Find out which delay cause occurrence is maximum.
with cte1 as(
select 
	count(carrierdelay)
from flight_detail
where carrierdelay>0),
cte2 as (select 
	count(weatherdelay)
from flight_detail
where weatherdelay>0),
cte3 as (select 
	count(NASdelay)
from flight_detail
where NASdelay>0),
cte4 as (select 
	count(securitydelay)
from flight_detail
where securitydelay>0)
 select cte1.*,cte2.*, cte3.*,cte4.*
 from cte1,cte2,cte3,cte4;

-- 15.	Get details of flight whose speed is between 400 to 600 miles/hr for each airline company.

select * from flight_detail
where speed>=400 and speed<=600 
order by carrierId;

select 
	carrierId,
	count(FlightId) 
from flight_detail 
where speed>=400 and speed<=600 
group by carrierId;

-- 16.	Identify the best time in a day to book a flight for a customer to reduce the delay.

select 
	case
		when ScheduledArrivaltime>="00:00:00" and ScheduledArrivaltime<"02:00:00" then "12am to 2am"
		when ScheduledArrivaltime>="02:00:00" and ScheduledArrivaltime<"04:00:00" then "2am to 4am" 
        when ScheduledArrivaltime>="04:00:00" and ScheduledArrivaltime<"06:00:00" then "4am to 6am"
        when ScheduledArrivaltime>="06:00:00" and ScheduledArrivaltime<"08:00:00" then "6am to 8am"
        when ScheduledArrivaltime>="08:00:00" and ScheduledArrivaltime<"10:00:00" then "8am to 10am"
        when ScheduledArrivaltime>="10:00:00" and ScheduledArrivaltime<"12:00:00" then "10am to 12pm"
        when ScheduledArrivaltime>="12:00:00" and ScheduledArrivaltime<"14:00:00" then "12pm to 2pm"
        when ScheduledArrivaltime>="14:00:00" and ScheduledArrivaltime<"16:00:00" then "2pm to 4pm"
        when ScheduledArrivaltime>="16:00:00" and ScheduledArrivaltime<"18:00:00" then "4pm to 6pm"
        when ScheduledArrivaltime>="18:00:00" and ScheduledArrivaltime<"20:00:00" then "6pm to 8pm"
        when ScheduledArrivaltime>="20:00:00" and ScheduledArrivaltime<"22:00:00" then "8pm to 10pm"
        when ScheduledArrivaltime>="22:00:00" and ScheduledArrivaltime<="23:59:59" then "10pm to 12am"
	end as differentdaytime ,
    avg(arrivaldelay)
    from flight_detail
    group by differentdaytime
    having differentdaytime is NOT NULL
    order by avg(arrivaldelay);
    
-- 17.	Get the route details with airline company code ‘AQ’
with cte1 as (select route_detail.route_ID as routeId,
				airport_detail.airport_name as origin_airport 
				from route_detail join airport_detail 
					on route_detail.origincode=airport_detail.locationId),
	cte2 as ( select route_detail.route_ID as routeId,
				airport_detail.airport_name as destination_airport 
				from route_detail join airport_detail 
					on route_detail.destinationcode=airport_detail.locationId)
 select 
	flight_detail.FlightId,
    carrier_detail.Carrier_code,
    flight_detail.routeId,
    cte1.origin_airport,
    cte2.destination_airport
from flight_detail join carrier_detail
	on flight_detail.carrierId=carrier_detail.Carrier_ID
join cte1
	on flight_detail.routeId = cte1.routeId
join cte2
	on flight_detail.routeId = cte2.routeId 
where carrier_detail.Carrier_code='UA\r';

-- 18.	Identify on which dates in a year flight movement is large.

select 
	flight_date,
	sum(airtime)
from flight_detail
group by flight_date
order by sum(airtime) desc;

-- 19.	Find out which delay cause is occurring more for each airline company.

select 
	carrierId,
	avg(carrierdelay),
    avg(weatherdelay),
    avg(NASdelay)
from flight_detail
group by carrierId;

select 
	carrierId,
    case
		when (avg(carrierdelay)>avg(weatherdelay)) and (avg(carrierdelay)>avg(NASdelay)) then "carrierdelay"
        when (avg(carrierdelay)<avg(weatherdelay)) and (avg(carrierdelay)>avg(NASdelay)) then "weatherdelay"
        when (avg(NASdelay)>avg(weatherdelay)) and (avg(carrierdelay)<avg(NASdelay)) then "NASdelay"
	end as delaycause
from flight_detail
group by carrierId;
    
-- 20.	 Write a query that represent your unique observation in the database.

