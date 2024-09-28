/*
Covid-19 Data Exploration

Skills used: Joins, CTEs, Temp Tables, Windows Functions, Aggregate Functions, Creating Views, Converting Data Types

Description: This script performs exploratory data analysis on Covid-19 datasets, including calculations of infection and death rates, and vaccinations coverage.

Table Name: COVID19Dataset
*/

-- Selecting initial data for exploration
-- Fetching records where continent is not null and ordering by location and date
SELECT Location, Date, Total_Cases, New_Cases, Total_Deaths, Population
FROM COVID19Dataset
WHERE Continent IS NOT NULL
ORDER BY Location, Date;

-- Total Cases vs Total Deaths
-- Shows the likelihood of dying from Covid-19 in different locations
SELECT Location, Date, Total_Cases, Total_Deaths, 
    (Total_Deaths / Total_Cases) * 100 AS DeathPercentage
FROM COVID19Dataset
WHERE Location LIKE '%states%'
  AND Continent IS NOT NULL
ORDER BY Location, Date;

-- Total Cases vs Population
-- Calculates the percentage of the population infected with Covid-19
SELECT Location, Date, Population, Total_Cases, 
    (Total_Cases / Population) * 100 AS PercentPopulationInfected
FROM COVID19Dataset
ORDER BY Location, Date;

-- Countries with Highest Infection Rate compared to Population
-- Identifies countries with the highest percentage of population infected
SELECT Location, Population, 
    MAX(Total_Cases) AS HighestInfectionCount, 
    MAX((Total_Cases / Population) * 100) AS PercentPopulationInfected
FROM COVID19Dataset
GROUP BY Location, Population
ORDER BY PercentPopulationInfected DESC;

-- Countries with Highest Death Count per Population
-- Identifies countries with the highest death count
SELECT Location, 
    MAX(CAST(Total_Deaths AS INT)) AS TotalDeathCount
FROM COVID19Dataset
WHERE Continent IS NOT NULL
GROUP BY Location
ORDER BY TotalDeathCount DESC;

-- Breaking down data by continent
-- Showing continents with the highest death count
SELECT Continent, 
    MAX(CAST(Total_Deaths AS INT)) AS TotalDeathCount
FROM COVID19Dataset
WHERE Continent IS NOT NULL
GROUP BY Continent
ORDER BY TotalDeathCount DESC;

-- Global Numbers
-- Aggregates global Covid-19 cases and death percentages
SELECT SUM(New_Cases) AS Total_Cases, 
       SUM(CAST(New_Deaths AS INT)) AS Total_Deaths, 
       (SUM(CAST(New_Deaths AS INT)) / SUM(New_Cases)) * 100 AS DeathPercentage
FROM COVID19Dataset
WHERE Continent IS NOT NULL;

-- Total Population vs Vaccinations
-- Shows the percentage of the population that has received at least one Covid-19 vaccine
SELECT dea.Continent, dea.Location, dea.Date, dea.Population, vac.New_Vaccinations,
    SUM(CONVERT(INT, vac.New_Vaccinations)) OVER (PARTITION BY dea.Location ORDER BY dea.Date) AS RollingPeopleVaccinated
FROM COVID19Dataset dea
JOIN COVID19Vaccinations vac
    ON dea.Location = vac.Location
    AND dea.Date = vac.Date
WHERE dea.Continent IS NOT NULL
ORDER BY dea.Location, dea.Date;

-- Using CTE to calculate the rolling total of vaccinated people
WITH PopVsVac AS (
    SELECT dea.Continent, dea.Location, dea.Date, dea.Population, vac.New_Vaccinations,
        SUM(CONVERT(INT, vac.New_Vaccinations)) OVER (PARTITION BY dea.Location ORDER BY dea.Date) AS RollingPeopleVaccinated
    FROM COVID19Dataset dea
    JOIN COVID19Vaccinations vac
        ON dea.Location = vac.Location
        AND dea.Date = vac.Date
    WHERE dea.Continent IS NOT NULL
)
SELECT *, (RollingPeopleVaccinated / Population) * 100 AS PercentPopulationVaccinated
FROM PopVsVac;

-- Using Temp Table to perform calculations
-- Creating a temp table to store and calculate vaccination percentages
DROP TABLE IF EXISTS #PercentPopulationVaccinated;

CREATE TABLE #PercentPopulationVaccinated (
    Continent NVARCHAR(255),
    Location NVARCHAR(255),
    Date DATETIME,
    Population NUMERIC,
    New_Vaccinations NUMERIC,
    RollingPeopleVaccinated NUMERIC
);

INSERT INTO #PercentPopulationVaccinated
SELECT dea.Continent, dea.Location, dea.Date, dea.Population, vac.New_Vaccinations,
    SUM(CONVERT(INT, vac.New_Vaccinations)) OVER (PARTITION BY dea.Location ORDER BY dea.Date) AS RollingPeopleVaccinated
FROM COVID19Dataset dea
JOIN COVID19Vaccinations vac
    ON dea.Location = vac.Location
    AND dea.Date = vac.Date;

-- Selecting from temp table to get vaccination coverage
SELECT *, (RollingPeopleVaccinated / Population) * 100 AS PercentPopulationVaccinated
FROM #PercentPopulationVaccinated;

-- Creating View for persistent access to vaccination data
CREATE VIEW PercentPopulationVaccinated AS
SELECT dea.Continent, dea.Location, dea.Date, dea.Population, vac.New_Vaccinations,
    SUM(CONVERT(INT, vac.New_Vaccinations)) OVER (PARTITION BY dea.Location ORDER BY dea.Date) AS RollingPeopleVaccinated
FROM COVID19Dataset dea
JOIN COVID19Vaccinations vac
    ON dea.Location = vac.Location
    AND dea.Date = vac.Date
WHERE dea.Continent IS NOT NULL;
