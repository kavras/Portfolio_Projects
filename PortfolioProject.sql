-- Getting to know the dataset

SELECT *
FROM CovidDeathsA
WHERE continent != ''
ORDER BY 3,4

SELECT *
FROM CovidVaccs
WHERE continent != ''
ORDER BY 3,4

SELECT Location, date, total_cases, new_cases, total_deaths, new_deaths, population
FROM CovidDeathsA
WHERE continent != ''
ORDER BY Location, date

-- Looking at Total cases vs Total deaths showing the death rate percentage

SELECT Location, date, total_cases, total_deaths, 
CONVERT(DECIMAL(15,2),(total_deaths/total_cases)*100) AS 'death_rate(%)'
FROM CovidDeathsA
WHERE continent != '' and location = 'United States'
ORDER BY  [death_rate(%)] DESC, Location, date

-- Total cases, total, deaths and max death rate % per country

SELECT DISTINCT
	Location, 
	MAX(total_cases) AS Total_Cases, 
	MAX(total_deaths) AS Total_Deaths, 
	CONVERT(DECIMAL(15,2),MAX(total_deaths/total_cases)*100) AS 'max_death_rate(%)'
FROM CovidDeathsA
WHERE continent != ''
GROUP BY location
ORDER BY  Location, [max_death_rate(%)] DESC

-- Total cases vs Population | MAX % of cases to population that was observed per country | highest infection rate

SELECT DISTINCT Location, 
MAX(total_cases) AS Total_Cases, 
MAX(population) AS Population, 
CONVERT(DECIMAL(15,2),(MAX(total_cases/population))*100) AS 'Covid_Rate(%)'
FROM CovidDeathsA
WHERE continent != ''
GROUP BY LOCATION
ORDER BY [Covid_Rate(%)] DESC

-- Percentage of population that got covid per day and country

SELECT Location, date, total_cases, population,
CONVERT(DECIMAL(15,2),(total_cases/population)*100) AS 'covid_rate(%)'
FROM CovidDeathsA
WHERE continent != ''
ORDER BY 1, 2


SELECT Location, MAX(Total_deaths) AS Max_Deaths
FROM CovidDeathsA
WHERE continent != ''
GROUP BY location
ORDER BY Max_Deaths DESC

-- Analysis per continent

SELECT 
	continent, 
	MAX(population) AS Population,
	MAX(Total_deaths) AS TotalDeathCount,
	CONVERT(DECIMAL(15,2), max(total_deaths/population)*100) AS '% of deaths'
FROM CovidDeathsA
WHERE continent != ''
GROUP BY continent
ORDER BY TotalDeathCount DESC

-- Total cases vs Population | MAX % of cases to population that was observed per continent | highest infection rate

SELECT DISTINCT continent, 
MAX(total_cases) AS Total_Cases, 
MAX(population) AS Population, 
CONVERT(DECIMAL(15,2),(MAX(total_cases/population))*100) AS 'Covid_Rate(%)'
FROM CovidDeathsA
WHERE continent != ''
GROUP BY continent
ORDER BY [Covid_Rate(%)] DESC

-- Global Numbers

-- Global Covid rate % per day

SELECT 
	date, 
	SUM(new_cases) AS GlobalNewCases,
	SUM(population) AS GlobalPopulation,
	CONVERT(DECIMAL(15,5), SUM(new_cases) / SUM(population)*100) AS 'CovidRate(%)'
FROM CovidDeathsA
WHERE continent != ''
GROUP BY date
ORDER BY date

-- Covid global death rate

SELECT 
	SUM(new_cases) AS GlobalNewCases,
	SUM(new_deaths) AS GlobalNewDeaths,
	CONVERT(DECIMAL(15,2), SUM(new_deaths) / SUM(new_cases)*100) AS 'DeathRate(%)'
FROM CovidDeathsA
WHERE continent != ''

SELECT date, location, total_vaccinations
FROM CovidVaccs
ORDER BY location, date, total_vaccinations DESC

-- Joining and using CTEs

-- Total population vs Vaccinations

WITH CTE_VACS AS(
SELECT
dea.continent,
dea.location,
dea.date, 
dea.population,
vac.new_vaccinations,
SUM(vac.new_vaccinations) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS Rolling_People_Vaccinated
FROM CovidDeathsA dea
JOIN CovidVaccs vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent != ''
)

SELECT 
	*,
	(CONVERT(DECIMAL(15,3), Rolling_People_Vaccinated/population*100)) AS '%_of_People_Vaccinated'
FROM CTE_VACS
WHERE location='Gibraltar'
ORDER BY 2, 3

-- % OF PEOPLE VACCINATED PER COUNTRY

WITH CTE_VACS AS(
SELECT
dea.continent,
dea.location,
dea.date, 
dea.population,
vac.new_vaccinations,
SUM(vac.new_vaccinations) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS Rolling_People_Vaccinated
FROM CovidDeathsA dea
JOIN CovidVaccs vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent != ''
)

SELECT 
	location, population,
	(CONVERT(DECIMAL(15,3), MAX(Rolling_People_Vaccinated/population*100))) AS '%_of_People_Vaccinated'
FROM CTE_VACS
GROUP BY location, population
ORDER BY 3 DESC


-- TEMP TABLE - same queries with cte

DROP TABLE IF EXISTS #PercentPopulationVaccinated -- use this first if you want to change anything in the temp table
CREATE TABLE #PercentPopulationVaccinated
(
continent nvarchar(255),
location nvarchar(255),
date date,
Population float,
New_vaccinations float,
RollingPeopleVaccinated float
)

INSERT INTO #PercentPopulationVaccinated
SELECT
dea.continent,
dea.location,
dea.date, 
dea.population,
vac.new_vaccinations,
SUM(vac.new_vaccinations) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS Rolling_People_Vaccinated
FROM CovidDeathsA dea
JOIN CovidVaccs vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent != ''

SELECT 
	*,
	(CONVERT(DECIMAL(15,3), RollingPeopleVaccinated/population*100)) AS '%_of_People_Vaccinated'
FROM #PercentPopulationVaccinated
--WHERE location='Gibraltar'
ORDER BY 2, 3

SELECT 
	location, population,
	(CONVERT(DECIMAL(15,3), MAX(RollingPeopleVaccinated/population*100))) AS '%_of_People_Vaccinated'
FROM #PercentPopulationVaccinated
GROUP BY location, population
ORDER BY 3 DESC

-- Creating VIEW to store data for later visualisation

CREATE VIEW PercentPopulationVaccinated AS
(
SELECT
dea.continent,
dea.location,
dea.date, 
dea.population,
vac.new_vaccinations,
SUM(vac.new_vaccinations) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS Rolling_People_Vaccinated
FROM CovidDeathsA dea
JOIN CovidVaccs vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent != ''
)
SELECT * FROM PercentPopulationVaccinated

CREATE VIEW max_percent_people_vaccinated_per_country AS
(
SELECT 
	location, population,
	(CONVERT(DECIMAL(15,3), MAX(Rolling_People_Vaccinated/population*100))) AS Percent_of_People_Vaccinated
FROM PercentPopulationVaccinated
GROUP BY location, population
)

SELECT * FROM max_percent_people_vaccinated_per_country ORDER BY 3 DESC