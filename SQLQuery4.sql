--Covid 19 Data Exploration 


Select Location, date, total_cases, new_cases, total_deaths, population
From covid_death
order by 1,2

-- Select Data that we are going to be starting with
Select Location, date, total_cases, total_deaths, (total_deaths*100)/total_cases AS deathpercentage
From covid_death
order by 1,2

-- Total Cases vs Total Deaths

-- Shows likelihood of dying if you contract covid in your country
Select Location, date, total_cases, population, (total_cases*100)/population AS casespercentage
From covid_death
--where Location like 'Tunisia'
order by 1,2

-- Total Cases vs Population
-- Shows what percentage of population infected with Covid
Select Location, population, MAX(total_cases) HighestInfectionCount, MAX((total_cases*100))/population AS percentPopulationInfected
From covid_death
group by Location, population
order by 1

-- Countries with Highest Death Count per Population
Select Location, MAX(cast(total_deaths as int)) AS DeathCount 
From covid_death
where continent is not null
group by Location
order by DeathCount DESC

-- Showing contintents with the highest death count per population
Select continent, MAX(cast(total_deaths as int)) AS DeathCount 
From covid_death
where continent is not null
group by continent
order by DeathCount DESC

--Global numbers

Select SUM(new_cases) as total_cases, SUM(cast(new_deaths as int)) as total_deaths, SUM(cast(new_deaths as int))/SUM(New_Cases)*100 as DeathPercentage
From covid_death
where continent is not null 
--Group By date
order by 1,2

-- Total Population vs Vaccinations
-- Shows Percentage of Population that has recieved at least one Covid Vaccine

Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
From covid_death dea
Join covid_vaccination vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null 
order by 2,3

-- Using CTE to perform Calculation on Partition By in previous query

With PopvsVac (Continent, Location, Date, Population, New_Vaccinations, RollingPeopleVaccinated)
as
(
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
From covid_death dea
Join covid_vaccination vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null 
--order by 2,3
)
Select *, (RollingPeopleVaccinated/Population)*100 as percentage
From PopvsVac

-- Using Temp Table to perform Calculation on Partition By in previous query

DROP TABLE IF EXISTS #PercentPopulationVaccinated;

CREATE TABLE #PercentPopulationVaccinated
(
    Continent NVARCHAR(255),
    Location NVARCHAR(255),
    Date DATETIME,
    Population NUMERIC,
    New_vaccinations BIGINT, -- Change to BIGINT here
    RollingPeopleVaccinated NUMERIC
);

INSERT INTO #PercentPopulationVaccinated
SELECT
    dea.continent,
    dea.location,
    dea.date,
    dea.population,
    vac.new_vaccinations,
    SUM(CAST(vac.new_vaccinations AS BIGINT)) OVER (PARTITION BY dea.Location ORDER BY dea.location, dea.Date) as RollingPeopleVaccinated
FROM
    covid_death dea
JOIN
    covid_vaccination vac
ON
    dea.location = vac.location
    AND dea.date = vac.date;

-- calculate the percentage in a separate SELECT statement
SELECT
    *,
    (RollingPeopleVaccinated / Population) * 100 AS PercentPopulationVaccinated
FROM
    #PercentPopulationVaccinated;


-- Creating View to store data for later visualizations

Create View PercentPopulationVaccinated as
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
FROM
    covid_death dea
JOIN
    covid_vaccination vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null 
