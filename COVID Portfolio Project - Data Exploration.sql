/*
Covid 19 Data Exploration 

Skills used: Joins, CTE's, Temp Tables, Windows Functions, Aggregate Functions, Creating Views, Converting Data Types

*/
------------------------------------------------------------------------------------------------------------------------
--Data Inspection---------------------

SELECT  TOP 100 *
FROM Covid19.dbo.CovidCases

SELECT  TOP 100 *
FROM Covid19.dbo.CovidVaccinations

SELECT DISTINCT(continent)
FROM Covid19.dbo.CovidCases

----- [continent] contains null values,let inspect the rows where continent is null---
Select continent,Location, date, total_cases, new_cases, total_deaths, population
From Covid19.dbo.CovidCases
Where continent is null 
order by  2,3


SELECT * 
FROM  Covid19.dbo.CovidCases
WHERE Location in  (SELECT DISTINCT(continent)
FROM Covid19.dbo.CovidCases Where continent is not null);
---- there are rows in the Location that contains continent records--- we need to exclude this rows---

----SELECT CLEANED DATA FROM CovidCases Table INTO TEMP TABLE(#CovidCases) for  ANALYSIS--------------------------------------------------

DROP TABLE  IF EXISTs #CovidCases
SELECT * INTO #CovidCases
FROM(
	SELECT * 
	FROM  Covid19.dbo.CovidCases
	WHERE Location not in  (SELECT DISTINCT(continent)
	FROM Covid19.dbo.CovidCases Where continent is not null ) 
)a  where continent is not null  order by 3,4
;
------------------------------------------------------------------------------------------------------------------------------


-------- Inspect vacination table----

SELECT TOP 100 *
FROM Covid19.dbo.CovidVaccinations

SELECT DISTINCT(continent)
FROM Covid19.dbo.CovidVaccinations

Select continent,Location, date, new_vaccinations
From Covid19.dbo.CovidVaccinations
Where continent is null 
order by  2,3


SELECT * 
FROM  Covid19.dbo.CovidVaccinations
WHERE Location in  (SELECT DISTINCT(continent)
FROM Covid19.dbo.CovidVaccinations Where continent is not null);


----SELECT CLEANED DATA FROM CovidVaccinations Table IN TEMP TABLE(#Vaccine) for  ANALYSIS--------------------------------------------------
DROP TABLE IF EXISTS #Vaccince 
SELECT * INTO #Vaccince
FROM(
	SELECT * 
	FROM  Covid19.dbo.CovidVaccinations
	WHERE Location not in  (SELECT DISTINCT(continent)
	FROM Covid19.dbo.CovidVaccinations Where continent is not null ) 
)a  where continent is not null  order by 2,3
;


------------------------------------------------------------------------------------------------------------------------------

SELECT TOP 100 * FROM #CovidCases
SELECT TOP 100 * FROM #Vaccince

-------- GLOBAL NUMBERS-----------------------------------------------------------------

-----Global covid cases---


SELECT aaa.* ,GlobalCases/GlobalDeath as GlobalCase2Death,GlobalPeopleVacinnated/GlobalCases as GlobalVaccinated2GblobalCases,
			GlobalPeopleVacinnated/GlobalPopulation *100 as GlobalPercentVaccinated

FROM(
	SELECT  MAX(date) Date, SUM(Population) GlobalPopulation,
			SUM(TotalCases)as GlobalCases,
			SUM(TotalDeath) as GlobalDeath,
			SUM(TotalCases)/SUM(Population)*100 as GlobalCases2PopulationPercentage,
			SUM(TotalDeath)/SUM(Population)*100 as GlobalDeath2Populationpercentage,
			SUM(TotalPeopleVaccinated) GlobalPeopleVacinnated
	FROM (
	SELECT a.location, max(a.population) Population,
		   (select max(date) from #CovidCases) date,
		    SUM(cast(a.new_cases as bigint) )as TotalCases,
		   sum( cast(a.new_deaths as bigint) ) as TotalDeath,
		   max( cast(b.people_vaccinated as bigint)) TotalPeopleVaccinated
	FROM #CovidCases a
	join #Vaccince b on a.location = b.location and a.continent = b.continent AND a.date = b.date 
	GROUP BY a.location
	)aa
)aaa
/*


-- As at  2021-04-30 9.6 percent of global population has contacted covid, with 0.0869 percent global death
-- 70.657 percent of global population has been vaccinated against covid19
-- 7 times of people who contacted covid has been vaccinated
--- Global Recoverage rate of 110 and death rate of 1/110 (0.91%)


*/

--------------------------CONTINENTS NUMBERS-----------------------

SELECT aaa.* ,ContinentCases/ContinentDeath as RecoveryRate,ContinentPopulationVaccinated/ContinentCases ContinentVaccinated2Case,
			ContinentPopulationVaccinated/ContinentPopulation *100 as ContinentPopulationVaccinated
FROM(
	SELECT continent, SUM(Population) ContinentPopulation,
		   SUM(TotalCases)as ContinentCases,
		   SUM(TotalDeath) as ContinentDeath,
		   ROUND(SUM(TotalCases)/SUM(Population),4) as ContinentInfectionRate,
		   ROUND(SUM(TotalDeath)/SUM(Population)*100,4) as ContinentPopulationDeathPercentage ,
		   ROUND(SUM(TotalPeopleVaccinated),2) ContinentPopulationVaccinated
	FROM(
	SELECT 
		   a.continent, a.location, max(a.population) Population,
		   (select max(date) from #CovidCases) date,
		    sum(cast(a.new_cases as bigint) )as TotalCases,
		   sum( cast(a.new_deaths as bigint) ) as TotalDeath,
		   MAX( cast(b.people_vaccinated as bigint)) TotalPeopleVaccinated
	FROM #CovidCases a
	join #Vaccince b on a.location = b.location and a.continent = b.continent AND a.date = b.date 
	GROUP BY a.continent, a.location
	)aa GROUP BY aa.continent
)aaa  ORDER BY 3


/*
	-Asia, Europe, and North America are the top three continents with the highest number of COVID-19 cases.
    -Oceania, Europe, and North America have the highest population infection rates, while Africa has the lowest.
    -South America, North America, and Europe have the highest population death percentages, with Africa having the least.

    -Africa and South America have the lowest recovery rates.
     -The possibility of dying if you contract COVID-19 is highest in Africa, followed by North America.
     -South America has the highest vaccination rate (85.95%), followed by Asia (78.1%), North America (76.38%), and Africa with the least (38.98%).

	
*/


--------- COUNTRY NUMBERS---------------------------------------------------------------------------

SELECT     a.continent, a.location, max(a.population) Population,
		   (select max(date) from #CovidCases) date,
		    sum(cast(a.new_cases as bigint) )as TotalCases,
		    sum( cast(a.new_deaths as bigint) ) as TotalDeath,
		    max( cast(b.people_vaccinated as bigint)) TotalPeopleVaccinated
FROM #CovidCases a
join #Vaccince b on a.location = b.location and a.continent = b.continent AND a.date = b.date 
GROUP BY a.continent, a.location 

------ Country with highest covid cases, death and vaccinations---------

SELECT aa.*, TotalCases/Population  as PopulationInfectionRate,TotalCases/TotalDeath CovidRecoveryRate, 
		ROUND(TotalDeath/Population  * 100,2) as CountryPopulationDeathPercentage,
		ROUND(TotalPeopleVaccinated/Population * 100,2) PercentagePopulationVaccinated
FROM(
	SELECT a.continent as Region, a.location, max(a.population) Population,
		    (select max(date) from #CovidCases) Date,
		    sum(cast(a.total_cases as bigint) )as TotalCases,
		    sum( cast(a.total_deaths as bigint) ) as TotalDeath,
		    max( cast(b.people_vaccinated as bigint)) TotalPeopleVaccinated
	FROM #CovidCases a
	join #Vaccince b on a.location = b.location and a.continent = b.continent AND a.date = b.date 
	GROUP BY a.continent, a.location 
)aa --where Population >= 1000000 
order by 11 DESC 

/*
    - The United States, China, India, France, and Germany are the top five countries with the highest number of recorded COVID-19 cases.
   -  The United States, Brazil, India, Russia, and Mexico are the top five countries with the highest number of COVID-19 deaths.
   -  country where the population is greater than 1 million
*/


------ TIME SERIES ANALYSIS-----------------------------------------------------------------------------
-------- Yearly Cases, Death,Vaccinations and DeathRate------
SELECT *, total_cases/FIRST_VALUE(total_cases)over( order by CovidYear)-1 YearlyCaseIndex,
		   total_deaths/FIRST_VALUE(total_deaths)over( order by CovidYear)-1 YearlyDeathIndex,
		   TotalPeopleVaccinated/FIRST_VALUE(TotalPeopleVaccinated)over( order by CovidYear)-1 YearlyVaccinationIndex
FROM(
SELECT  YEAR(a.date) CovidYear, sum(cast(new_cases as bigint)) total_cases, sum(cast(total_deaths as bigint)) total_deaths, max(cast(people_vaccinated as bigint) ) TotalPeopleVaccinated
FROM #CovidCases a 
join #Vaccince   b on a.location = b.location and a.continent = b.continent AND a.date = b.date 
group by YEAR(a.date)  
)aa order by 2
/*
------ The covid records span through 4 years 2020-2023
------ The number of covid cases  and death increases exponentially from 2020 to 2022 but decreses in 2023
-------the highest number of covid cases and death were recorded in 2022 
------  There is steady increase in the number of people vaccinated from 2021 to 2023 

*/ 

---- Covid cases , deaths and Vaccinations by month and year---
SELECT *
FROM(
SELECT  YEAR(a.date) CovidYear,Month(a.date) CovidMonth,
	    sum(cast(new_cases as bigint)) total_cases, sum(cast(new_deaths as bigint)) total_deaths, max(cast(people_vaccinated as bigint) ) TotalPeopleVaccinated
FROM #CovidCases a 
join #Vaccince   b on a.location = b.location and a.continent = b.continent AND a.date = b.date 
group by YEAR(a.date),Month(a.date)   
)aa order by 4 desc

/*
--- Jan 2022 record the highest number of covid cases , then December, february and march
--- Covid deaths where highest in jan 2021, then may 2021 and April 2021 respectively

*/


---------------Compare covid cases , death and vaccinations by month ----------------------------

SELECT *, sum(total_cases)over(partition by CovidYear order by CovidYear) TotalYearCase,
          total_cases * 100 / sum(total_cases)over(partition by CovidYear order by CovidYear) PercentageYearCase,
		  sum(total_deaths)over(partition by CovidYear order by CovidYear) TotalYearDeath,
          total_deaths * 100/ sum(total_deaths)over(partition by CovidYear order by CovidYear) PercentageYearDeath,
          ( total_cases-LAG(total_cases,1)over(partition by CovidYear order by CovidYear))/LAG(total_cases,1)over(partition by CovidYear order by CovidYear) MoMCases,
		  ( total_deaths-LAG(total_deaths,1)over(partition by CovidYear order by CovidYear))/LAG(total_deaths,1)over(partition by CovidYear order by CovidYear) MoMDeath,
		  ( TotalPeopleVaccinated-LAG(TotalPeopleVaccinated,1)over(partition by CovidYear order by CovidYear))/LAG(TotalPeopleVaccinated,1)over(partition by CovidYear order by CovidYear) MoMTotalPeopleVaccinated
FROM(
SELECT  YEAR(a.date) CovidYear,Month(a.date) CovidMonth,
	    sum(cast(new_cases as bigint)) total_cases, sum(cast(new_deaths as bigint)) total_deaths, max(cast(people_vaccinated as bigint) ) TotalPeopleVaccinated
FROM #CovidCases a 
join #Vaccince   b on a.location = b.location and a.contine vnt = b.continent AND a.date = b.date 
group by YEAR(a.date),Month(a.date)   

)aa order by 1,2

/*
----- The highest number of increase in covid cases from previous month occurs in July 2021, the new cases is 706 times the previus month
---- and this month also record the highest number of death from previous month, the second of such occurs in June 2023 where we have 690 time previous month case in May and 245 times more death in may
---- The first dose of vaccines where available after 11 month of covid case that is by December 2020

*/


-------Rolling Covid cases and Rolling Covid death and  DailyDeathRate ---
SELECT  location,cast(date as date) as Date,
		new_cases,  sum(convert(bigint,new_cases) )over(partition by location order by date) as RollingCases,
		new_deaths, sum(convert(bigint,new_deaths) )over(partition by location order by date) as RollingDeath,
		new_deaths/nullif(population,0) InfectionRate,
		new_deaths/Nullif(new_cases,0)  as DailyDeathRate
FROM #CovidCases 



------ Highest infection in a single day by country--

SELECT location ,Date,max(InfectionRate) *100 HighestInfestion
FROM(
	SELECT  location,cast(date as date) as Date,
			new_cases,  sum(convert(bigint,new_cases) )over(partition by location order by date) as RollingCases,
			new_deaths, sum(convert(bigint,new_deaths) )over(partition by location order by date) as RollingDeath,
			new_deaths/nullif(population,0) InfectionRate,
			new_deaths/Nullif(new_cases,0)  as DailyDeathRate
	FROM #CovidCases 
)aa 
group by location , Date order by 3 desc



-- Creating View to store data for visualizations in tablue
;
DROP VIEW IF EXISTS Covid19View
CREATE VIEW Covid19View
as
Select a.iso_code as CountryCode,a.continent as Region, cast(a.date as date) Date,  cast(a.new_cases as bigint) as NewCases, cast(a.new_deaths as bigint) as NewDeaths,
       a.location Country, a.population Population, 
      convert(bigint,people_vaccinated) PeopleVaccinated
FROM  Covid19.dbo.CovidCases a
Join Covid19.dbo.CovidVaccinations b On a.location = b.location and a.date = b.date
WHERE a.Location not in  (SELECT DISTINCT(continent) FROM Covid19.dbo.CovidCases Where continent is not null)

SELECT  TOP 100 *
FROM Covid19View

-------------------------------END OF ANALYSIS----------------------------------------------- THANK YOU-----