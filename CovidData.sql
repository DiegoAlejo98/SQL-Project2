-- Select data that we are going to be using
SELECT location, date, total_cases, new_cases, total_deaths, population
FROM PortfolioProject..CovidDeathsNEW


-- Looking at total cases vs total deaths
-- Shows likelihood of dying if you contract Covid in your country
SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as death_percentage
FROM PortfolioProject..CovidDeathsNEW
WHERE location LIKE '%states%'


-- Looking at total cases vs population
-- Shows what percentage of population got Covid
SELECT location, date, total_cases, population, (total_cases/population)*100 as infection_percentage
FROM PortfolioProject..CovidDeathsNEW
WHERE location LIKE '%states%'


-- Looking at countries with highest infection rate relative to population
SELECT location, population, MAX(total_cases) as highest_infection_count, MAX((total_cases/population))*100 as infection_percentage
FROM PortfolioProject..CovidDeathsNEW
WHERE continent IS NOT NULL
GROUP BY location, population
ORDER BY infection_percentage DESC


-- Looking at countries with highest death count relative to population
SELECT location, MAX(total_deaths) as total_death_count
FROM PortfolioProject..CovidDeathsNEW
WHERE continent IS NOT NULL
GROUP BY location
ORDER BY total_death_count DESC


-- Ordering continents by the highest death count
SELECT location, MAX(total_deaths) as total_death_count
FROM PortfolioProject..CovidDeathsNEW
WHERE continent IS NULL
GROUP BY location
ORDER BY total_death_count DESC


-- Global numbers
SELECT date, SUM(new_cases) as total_new_cases,SUM(new_deaths) as total_new_deaths, SUM(new_deaths)/SUM(new_cases)*100 as global_death_percentage
FROM PortfolioProject..CovidDeathsNEW
WHERE continent IS NOT NULL
GROUP BY date
ORDER BY 1,2


-- Looking at vaccination count per location
SELECT deaths.continent, deaths.location, deaths.date, deaths.population, vax.new_vaccinations,
SUM(vax.new_vaccinations) OVER(PARTITION BY deaths.location ORDER BY deaths.location, deaths.date) as rolling_vax_count
FROM PortfolioProject..CovidDeathsNEW deaths
JOIN PortfolioProject..CovidVaccinationsNEW vax
	ON deaths.location = vax.location
	AND deaths.date = vax.date
WHERE deaths.continent IS NOT NULL
ORDER BY 2,3


-- Looking at percentage of a location's population that has been vaccinated (CTE)
WITH PopVsVax(continent, location, date, population, new_vaccinations, rolling_vax_count)
AS
(
	SELECT deaths.continent, deaths.location, deaths.date, deaths.population, vax.new_vaccinations,
	SUM(vax.new_vaccinations) OVER(PARTITION BY deaths.location ORDER BY deaths.location, deaths.date) as rolling_vax_count
	FROM PortfolioProject..CovidDeathsNEW deaths
	JOIN PortfolioProject..CovidVaccinationsNEW vax
		ON deaths.location = vax.location
		AND deaths.date = vax.date
	WHERE deaths.continent IS NOT NULL
	--ORDER BY 2,3
)
SELECT *, (rolling_vax_count/population)*100 as pop_percentage_vaxxed
FROM PopVsVax


-- Looking at percentage of a location's population that has been vaccinated (Temp Table)
DROP TABLE IF EXISTS #PercentPopulationVaccinated
CREATE TABLE #PercentPopulationVaccinated
(continent nvarchar(255), location nvarchar(255), date datetime, population numeric, new_vaccinations numeric, rolling_vax_count numeric)

INSERT INTO #PercentPopulationVaccinated
	SELECT deaths.continent, deaths.location, deaths.date, deaths.population, vax.new_vaccinations,
	SUM(vax.new_vaccinations) OVER(PARTITION BY deaths.location ORDER BY deaths.location, deaths.date) as rolling_vax_count
	FROM PortfolioProject..CovidDeathsNEW deaths
	JOIN PortfolioProject..CovidVaccinationsNEW vax
		ON deaths.location = vax.location
		AND deaths.date = vax.date
	WHERE deaths.continent IS NOT NULL
	--ORDER BY 2,3

SELECT *, (rolling_vax_count/population)*100 as pop_percentage_vaxxed
FROM #PercentPopulationVaccinated


-- Creating view to store data for later visualizations
--DROP VIEW IF EXISTS PercentPopulationVaccinated
CREATE VIEW PercentPopulationVaccinated as 
	SELECT deaths.continent, deaths.location, deaths.date, deaths.population, vax.new_vaccinations,
	SUM(vax.new_vaccinations) OVER(PARTITION BY deaths.location ORDER BY deaths.location, deaths.date) as rolling_vax_count
	FROM PortfolioProject..CovidDeathsNEW deaths
	JOIN PortfolioProject..CovidVaccinationsNEW vax
		ON deaths.location = vax.location
		AND deaths.date = vax.date
	WHERE deaths.continent IS NOT NULL
	--ORDER BY 2,3

SELECT *
FROM PercentPopulationVaccinated