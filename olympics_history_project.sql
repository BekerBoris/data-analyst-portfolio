

-->>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>Olymics_history_project<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<


--Dataset was downloaded from Kagel https://www.kaggle.com/datasets/heesoo37/120-years-of-olympic-history-athletes-and-results
--All  quaries are origenly done in Postgresql

-- The First step is to create a table with the sam structure as the original and then load data to the database using PGadmin4.
CREATE TABLE IF NOT EXISTS olympics_history 
(
  id     INT,
  name   VARCHAR,
  sex    VARCHAR,
  age    VARCHAR,
  height VARCHAR,
  weight VARCHAR,
  team   VARCHAR,
  noc    VARCHAR,
  games  VARCHAR,
  year   INT,
  season VARCHAR,
  city   VARCHAR,
  sport  VARCHAR,
  event  VARCHAR,
  medal  VARCHAR
);

-- Same thing as the first table I created a table and then loaded the data.
-- In this table noc (national Olympic committee) acts as primary key and column "region" represents country/region
CREATE TABLE IF NOT EXISTS noc_regions 
(
  noc    VARCHAR,
  region VARCHAR,
  nots   VARCHAR
);

--Hire I made a spelling mistake when naming one column so rectify that
ALTER TABLE IF EXISTS public.noc_regions 
    RENAME nots TO notes;

--Hire I wanted to check are all dat loaded to the database correctly.
--Count from this query should be the same as the row count when I open the original table with Excel.
select count(*) from olympics_history 

--I have done same for second table also
select count(*) from noc_regions


-- >>>>>>>>>>>>>>>>>>>>>>>>>>1.Identify the sport which was played in all summer olympics.<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
--      I used WITH (Common Table Expressions-CTE) not subquary

-- t1 is counting number of summer games 
with t1 as 
	(select count(distinct games) as num_of_summer_games
	 from olympics_history
	 where season='Summer'),

-- t2 shows all sports played on every summer Olympic game	 
t2 as 
	(select distinct sport, games
	 from olympics_history
	 where season='Summer'),

-- using result from t2 I counted sports so I got number of games each sport appeard. That is stored in t3.
t3 as 
	(select sport, count(games) as num_of_games_per_sport
	 from t2
	 group by sport)

-- at the end I joined results from t1 and t3 and evry sport which appired same number time as total number of summer games(t1) is shown.
-- And in that way I showed sport which was played in all summer olympics, as was requred in tas description.
select * 
from t3 
join t1 on t1.num_of_summer_games=t3.num_of_games_per_sport;


/*>>>>>>>>>>>>>>>>>>>>>>>>>>>>. 2. Fetch the top 5 athletes who have won the most gold medals.<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<*/

-- t1 counts number of gold medals on summer games for etch atlehlets and ordered in desending way. 
with t1 as 
	(Select name, count(medal) as num_of_medals
	from olympics_history
	where medal='Gold' and Season='Summer'
	group by name
	order by num_of_medals desc),

-- In t2 I added rank culumn using window function so atleath with higest number of gold medals is ranked as 1, second higest 2....
t2 as 
	(select *, rank() over(order by num_of_medals desc) as medal_rank
	from t1)
-- At the end I showed all athleat that have rank equal or lower then 5. 
-- That way I got 5 Atleate with most gold medals on olimpyc games as requred. 
select *
from t2
where medal_rank<=5

/*>>>>>>>>>>>>>>>>>>>>>>> 3. List down total gold, silver and broze medals won by each country.<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<*/

--For this task we are using crostab function which is PostgeSQL version of pivoting.
--first time (just first time) that we are using this function we need to import extencion TABLEFUNC with this code
-- CREATE EXTENSION TABLEFUNC
-- Everithing inside crostab function need to be string that why we have quotes. 
-- Also iside crosstab function we can have just 3 columns, first is grouping column, second is column that will be pivoted and third is values that will populate that new pivoted columns.
-- where medal<>'NA' this part ensure that countries that did not won any medales are skiped
select country,
-- coasce() function transform NULL values int 0
coalesce (gold, 0) as gold,
coalesce (silver, 0) as silver,
coalesce (bronze, 0) as bronze
from crosstab
			('select nr.region as country, medal, count(region) as total_medals
			 from olympics_history as oh
			 join noc_regions as nr on oh.noc=nr.noc
			 where medal<> ''NA''
			 group by nr.region, medal
			 order by nr. region, medal',
			 'Values (''Bronze''),(''Gold''),(''Silver'')')
		as result (country varchar, bronze bigint, gold bigint, silver bigint)
order by gold desc, silver desc, bronze desc



-->>>>>>>>>>>>>>>>>>>>>>4. Which nation has participated in all of the olympic games<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

with t1 as -- count total number of olimpic games
	(select count(distinct games)as total_games
	 from olympics_history),
	t2 as -- joinig to tables so we can also have names of countries.
	(select games, region as country
	from olympics_history as oh
	join noc_regions as nr on nr.noc=oh.noc
	group by games, region),
	t3 as -- counts total number of games for each country
	(select country, count(games) as participatio_per_country
	from t2
	group by country)
select t3.*
from t3
-- joining t3 and t1 in a way that only country wit same number of participation as total number of games will be selected. 
join t1 on t1.total_games=t3.participatio_per_country


-->>>>>>>>>>>>>>>>>>>>>>5. Fetch the total no of sports played in each olympic games.<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

--Hire I count distinct sports for each games.
-- I use distinct becaus in record sports are appiring multiple times because multiple players that play same sport.
select games, count(distinct sport) as no_of_sports 
from olympics_history
group by games
order by no_of_sports desc

