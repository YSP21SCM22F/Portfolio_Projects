SELECT *
FROM Portfolio_Project..CovidDeaths$
--WHERE continent IS NOT NULL
ORDER BY 3, 4

SELECT *
FROM Portfolio_Project..CovidVaccinations$
--WHERE continent IS NOT NULL
ORDER BY 3, 4

SELECT Location, date, total_cases, new_cases, total_deaths, population
FROM Portfolio_Project..CovidDeaths$
WHERE continent IS NOT NULL
ORDER BY 1, 2

-- Looking at total cases vs total deaths
-- Shows likelihood of dying if you contract covid in your country
SELECT Location, date, total_cases, total_deaths, (total_deaths / total_cases) * 100 AS DeathPercentage
FROM Portfolio_Project..CovidDeaths$
WHERE Location LIKE '%state%' AND continent IS NOT NULL
ORDER BY 1, 2

-- Looking at total cases vs population
-- Shows what percentage of population got covid
SELECT Location, date, population, total_cases, (total_cases / population) * 100 AS PercentPopulationInfected
FROM Portfolio_Project..CovidDeaths$
--WHERE Location LIKE '%state%'
WHERE continent IS NOT NULL
ORDER BY 1, 2

--Looking at Countries with highest infection rate compared to population
--What percentage of your population has gotten covid, its been reported 
--Tableau table3
SELECT Location, Population, MAX(total_cases) AS HighestInfectionCount, MAX((total_cases / population)) * 100 AS PercentPopulationInfected
FROM Portfolio_Project..CovidDeaths$
GROUP BY Location, Population
ORDER BY PercentPopulationInfected DESC

--Tableau table4
SELECT Location, Population, date, MAX(total_cases) AS HighestInfectionCount, MAX((total_cases / population)) * 100 AS PercentPopulationInfected
FROM Portfolio_Project..CovidDeaths$
GROUP BY Location, Population, date
ORDER BY PercentPopulationInfected DESC

--Showing Countries with highest death count per population
SELECT Location, MAX(CAST(Total_deaths AS INT)) AS TotalDeathCount
FROM Portfolio_Project..CovidDeaths$
WHERE continent IS NOT NULL
GROUP BY Location
ORDER BY TotalDeathCount DESC

--Break things down by continent
SELECT location AS Continent, MAX(CAST(Total_deaths AS INT)) AS TotalDeathCount
FROM Portfolio_Project..CovidDeaths$
WHERE continent IS NULL
GROUP BY location
ORDER BY TotalDeathCount DESC

--Showing continents with the highest death count per population
SELECT continent, MAX(CAST(Total_deaths AS INT)) AS TotalDeathCount
FROM Portfolio_Project..CovidDeaths$
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY TotalDeathCount DESC

--GLOBAL NUMBERS
SELECT date, SUM(new_cases) AS total_cases, SUM(CAST(new_deaths AS INT)) AS total_deaths, SUM(CAST(new_deaths AS INT))/SUM(New_Cases) * 100 AS DeathPercentage
FROM Portfolio_Project..CovidDeaths$
WHERE continent IS NOT NULL
GROUP BY date
ORDER BY 1, 2 

--Tableau table1
SELECT SUM(new_cases) AS total_cases, SUM(CAST(new_deaths AS INT)) AS total_deaths, SUM(CAST(new_deaths AS INT))/SUM(New_Cases) * 100 AS DeathPercentage
FROM Portfolio_Project..CovidDeaths$
WHERE continent IS NOT NULL
ORDER BY 1, 2  

--Break things down by location
--Showing total death count in each continent
--Tableau table2
SELECT location, SUM(CAST(new_deaths as INT)) AS TotalDeathCount
FROM Portfolio_Project..CovidDeaths$
WHERE continent IS NULL
AND location NOT IN ('World', 'European Union', 'International')
GROUP BY location
ORDER BY TotalDeathCount DESC

--Looking at Total Population vs New Vaccinations
SELECT d.continent, d.location, d.date, d.population, v.new_vaccinations
FROM Portfolio_Project..CovidDeaths$ AS d
JOIN Portfolio_Project..CovidVaccinations$ AS v
	ON d.location = v.location
	AND d.date = v.date
WHERE d.continent IS NOT NULL
ORDER BY 2,3

--USE CTE
WITH PopvsVac AS(
	SELECT d.continent, d.location, d.date, d.population, v.new_vaccinations,
	SUM(CAST(v.new_vaccinations AS INT)) OVER (PARTITION BY d.location ORDER BY d.location, 
	d.date) AS RollingPeopleVac
	FROM Portfolio_Project..CovidDeaths$ AS d
	JOIN Portfolio_Project..CovidVaccinations$ AS v
		ON d.location = v.location
		AND d.date = v.date
	WHERE d.continent IS NOT NULL
	--ORDERY BY 2, 3
)

SELECT *, (RollingPeopleVac / population) * 100 AS PercentPopVac
FROM PopvsVac


--Temp Table
DROP TABLE IF EXISTS #PercentPopulationVaccinated
CREATE TABLE #PercentPopulationVaccinated
(
continent nvarchar(255),
location nvarchar(255),
date datetime,
population numeric,
new_vaccinations numeric,
RollingPeopleVac numeric
)

INSERT INTO #PercentPopulationVaccinated
SELECT d.continent, d.location, d.date, d.population, v.new_vaccinations,
SUM(CAST(v.new_vaccinations AS INT)) OVER (PARTITION BY d.location ORDER BY d.location, 
d.date) AS RollingPeopleVac
FROM Portfolio_Project..CovidDeaths$ AS d
JOIN Portfolio_Project..CovidVaccinations$ AS v
	ON d.location = v.location
	AND d.date = v.date
--WHERE d.continent IS NOT NULL
--ORDERY BY 2, 3

SELECT *, (RollingPeopleVac / population) * 100 AS PercentPopVac
FROM #PercentPopulationVaccinated

-- Creating view to store data for later visualizations
CREATE VIEW PercentPopulationVaccinated AS
SELECT d.continent, d.location, d.date, d.population, v.new_vaccinations,
SUM(CAST(v.new_vaccinations AS INT)) OVER (PARTITION BY d.location ORDER BY d.location, 
d.date) AS RollingPeopleVac
FROM Portfolio_Project..CovidDeaths$ AS d
JOIN Portfolio_Project..CovidVaccinations$ AS v
	ON d.location = v.location
	AND d.date = v.date
WHERE d.continent IS NOT NULL

SELECT * FROM PercentPopulationVaccinated