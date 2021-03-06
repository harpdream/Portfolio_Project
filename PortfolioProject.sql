--SQL Project using data from https://ourworldindata.org/covid-deaths

--Tableau illustrations:

--   https://public.tableau.com/app/profile/harper.ream/viz/GlobalCovidDashboard3-22-2022/Dashboard1?publish=yes

--Tableau code illustrations are at the end of this code.


-- Insert Data
SELECT *
FROM PortfolioProject..CovidDeaths
Order by 3,4


SELECT *
FROM PortfolioProject..CovidVaccinations
Order by 3,4

--Select Data

Select Location, date, total_cases, new_cases, total_deaths, population
FROM PortfolioProject..CovidDeaths
Order By 1,2

--Total Cases vs Total Deaths

Select Location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as Death_Percentage
FROM PortfolioProject..CovidDeaths
--Where location like '%states%'
Order By 1,2

--Total Population vs Total Cases

Select Location, population, MAX(total_cases), (total_cases/population)*100 as PercentInfected
FROM PortfolioProject..CovidDeaths
group by location, population
Order By 1,2

-- Different Countries Infection Rate vs Population

Select Location, population, MAX(total_cases) as HighestInfectionCount, MAX((total_cases/population))*100 as TotalInfectedPopulation
FROM PortfolioProject..CovidDeaths
Where total_cases is not NULL
Group By location, population
Order By TotalInfectedPopulation desc

-- Different Countries Death Rate vs Population

Select Location, MAX(cast(total_deaths as int)) as HighestDeathCount, MAX((total_deaths/population))*100 as TotalDeathsPopulation
FROM PortfolioProject..CovidDeaths
Where continent is not NULL
Group By location
Order By HighestDeathCount desc

--Create CTE of different Countries Death Rate vs Population

With DeathsvsPops (Location, HighestDeathCount, TotalDeathsPopulation) as 
(
Select Location, MAX(cast(total_deaths as int)) as HighestDeathCount, MAX((total_deaths/population))*100 as TotalDeathsPopulation
FROM PortfolioProject..CovidDeaths
Where continent is not NULL
and total_deaths is not NULL
Group By location
)
Select *
FROM DeathsvsPops

--Create View of DeathsvsPops

Create View DeathsvsPops as
(SELECT Location, MAX(cast(total_deaths as int)) as HighestDeathCount, MAX((total_deaths/population))*100 as TotalDeathsPopulation
FROM PortfolioProject..CovidDeaths
Where continent is not NULL
and total_deaths is not NULL
Group By location)

--Create Table from the View
Select *
INTO DeathsvsPops_table
From PortfolioProject..DeathsvsPops

-- Death Count vs Population by Continent and Household Income

Select Location, MAX(cast(total_deaths as int)) as HighestDeathCount
FROM PortfolioProject..CovidDeaths
Where continent is NULL
Group By location
Order By HighestDeathCount desc


-- Global Numbers by date

Select SUM(new_cases) as SUM_new_cases, SUM(cast(new_deaths as int)) as SUM_new_deaths, SUM(cast(new_deaths as int))/SUM(new_cases) * 100 as Global_Death_Rate
FROM PortfolioProject..CovidDeaths
Where continent is not NULL and new_deaths is not NULL
Order By 1,2

--Join second table

Select *
From PortfolioProject..CovidDeaths deaths
Join PortfolioProject..CovidVaccinations vacs
	On deaths.location = vacs.location
	and deaths.date = vacs.date

--Total Population vs Total Vaccinated

Select deaths.continent, deaths.location, deaths.date, deaths.population, vacs.new_vaccinations
	, SUM(CONVERT(bigint, vacs.new_vaccinations)) 
	OVER (Partition by deaths.location order by deaths.location, deaths.date) as Rolling_Vacs
From PortfolioProject..CovidDeaths deaths
Join PortfolioProject..CovidVaccinations vacs
	On deaths.location = vacs.location
	and deaths.date = vacs.date
where deaths.continent is not NULL and new_vaccinations is not NULL
order by 2,3



-- Create CTE for Total Population vs Total Vaccinated

With PopvsVacs (Continent, Location, date, population, new_vaccinations, new_cases, Rolling_Vacs) as 
(
Select deaths.continent, deaths.location, deaths.date, deaths.population,deaths.new_cases, vacs.new_vaccinations
	, SUM(CONVERT(bigint, vacs.new_vaccinations)) 
	OVER (Partition by deaths.location order by deaths.location, deaths.date) as Rolling_Vacs
From PortfolioProject..CovidDeaths deaths
Join PortfolioProject..CovidVaccinations vacs
	On deaths.location = vacs.location
	and deaths.date = vacs.date
where deaths.continent is not NULL and vacs.new_vaccinations is not NULL
--order by 2,3
)
Select *, (Rolling_Vacs/Population)*100 as Rolling_Vacs_Rate
FROM PopvsVacs

--Create CTE for Total Population vs Vaccinations for just the US

With PopvsVacs_US (Continent, Location, date, population, new_vaccinations, Rolling_Vacs) as 
(
Select deaths.continent, deaths.location, deaths.date, deaths.population, vacs.new_vaccinations
	, SUM(CONVERT(bigint, vacs.new_vaccinations)) 
	OVER (Partition by deaths.location order by deaths.location, deaths.date) as Rolling_Vacs
From PortfolioProject..CovidDeaths deaths
Join PortfolioProject..CovidVaccinations vacs
	On deaths.location = vacs.location
	and deaths.date = vacs.date
where deaths.continent is not NULL --and vacs.new_vaccinations is not NULL
and deaths.location like '%states%'
--order by 2,3
)
Select *, (Rolling_Vacs/Population)*100 as Rolling_Vacs_Rate
FROM PopvsVacs_US


--Temp Table for Total Population vs Vaccinations

Drop table if exists #TT_PopsvsVacs
Create Table #TT_PopsvsVacs
(
Continent nvarchar(255),
Location nvarchar(255),
date datetime,
Population numeric,
new_vaccinations bigint,
Rolling_Vacs numeric
)
Insert into #TT_PopsvsVacs
Select deaths.continent, deaths.location, deaths.date, deaths.population, vacs.new_vaccinations
	, SUM(CONVERT(bigint, vacs.new_vaccinations)) 
	OVER (Partition by deaths.location order by deaths.location, deaths.date) as Rolling_Vacs
From PortfolioProject..CovidDeaths deaths
Join PortfolioProject..CovidVaccinations vacs
	On deaths.location = vacs.location
	and deaths.date = vacs.date
where deaths.continent is not NULL and new_vaccinations is not NULL
order by 2,3

Select *, (Rolling_Vacs/Population)*100 as Rolling_Vacs_Rate
FROM #TT_PopsvsVacs

--Create a View of Population vs Vaccinations in the United States


CREATE VIEW
PopvsVacs_US2 as 
(
Select deaths.continent, deaths.location, deaths.date, deaths.population, vacs.new_vaccinations
	, SUM(CONVERT(bigint, vacs.new_vaccinations)) 
	OVER (Partition by deaths.location order by deaths.location, deaths.date) as Rolling_Vacs
From PortfolioProject..CovidDeaths deaths
Join PortfolioProject..CovidVaccinations vacs
	On deaths.location = vacs.location
	and deaths.date = vacs.date
where deaths.continent is not NULL --and vacs.new_vaccinations is not NULL
and deaths.location like '%states%'
--order by 2,3
)



-- I have to manually make excel files because I don't have the premium version of Tableau

--Tableau Graph #1

-- Different Countries Infection Rate vs Population 


Select Location, population, MAX(total_cases) as HighestInfectionCount, MAX((total_cases/population))*100 as TotalInfectedPopulation
FROM PortfolioProject..CovidDeaths
Where total_cases is not NULL
and location not in ('World', 'Upper middle income', 'High income', 'Lower middle income', 'European Union','Low Income', 'International')
Group By location, population
Order By TotalInfectedPopulation desc

--Tableau Graph #2

--Different Countries Infection Rate vs Population, Grouped by date

Select Location, population, date, MAX(total_cases) as HighestInfectionCount, MAX((total_cases/population))*100 as TotalInfectedPopulation
FROM PortfolioProject..CovidDeaths
Where total_cases is not NULL
and location not in ('World', 'Upper middle income', 'High income', 'Lower middle income', 'European Union','Low Income', 'International')
Group By location, population, date
Order By TotalInfectedPopulation desc



--Tableau Graph #3

-- Death Count vs Population by Continent

Select Location, MAX(cast(total_deaths as int)) as HighestDeathCount
FROM PortfolioProject..CovidDeaths
Where continent is NULL
and location not in ('World', 'Upper middle income', 'High income', 'Lower middle income', 'European Union','Low Income', 'International')
Group By location
Order By HighestDeathCount desc

--Tableau Graph #4

Select SUM(new_cases) as SUM_new_cases, SUM(cast(new_deaths as int)) as SUM_new_deaths, SUM(cast(new_deaths as int))/SUM(new_cases) * 100 as Global_Death_Rate
FROM PortfolioProject..CovidDeaths
Where continent is not NULL and new_deaths is not NULL
Order By 1,2


