-- 1.
-- What range of years for baseball games played does the provided database cover? 

SELECT MIN(year) AS first_year, MAX(year) AS last_year
FROM homegames;


-- 2.
-- Find the name and height of the shortest player in the database. How many games did he play in? What is the name of the team for which he played?

SELECT 
	CONCAT(namefirst, ' ', namelast) AS player_name, 
	g_all AS total_apperances, name AS team
FROM people INNER JOIN appearances USING(playerid)
			INNER JOIN teams USING(teamid, yearid)
WHERE height = (SELECT MIN(height) FROM people);


-- 3.
-- Find all players in the database who played at Vanderbilt University. Create a list showing each player’s first and last names as well as the total salary they earned in the major leagues. 
-- Sort this list in descending order by the total salary earned. Which Vanderbilt player earned the most money in the majors?

WITH vandy_players AS (SELECT DISTINCT playerid, namefirst, namelast
						FROM collegeplaying INNER JOIN schools USING(schoolid)
											INNER JOIN people USING(playerid)
						WHERE schoolid LIKE 'vandy')

SELECT 
	namefirst, 
	namelast, 
	SUM(salary)::numeric::money AS total_salary
FROM vandy_players INNER JOIN salaries USING(playerid)
GROUP BY namefirst, namelast
ORDER BY total_salary DESC;



-- 4.
-- Using the fielding table, group players into three groups based on their position: 
-- label players with position OF as "Outfield", those with position "SS", "1B", "2B", and "3B" as "Infield", and those with position "P" or "C" as "Battery".
-- Determine the number of putouts made by each of these three groups in 2016.

SELECT SUM(CASE WHEN pos IN ('P','C') THEN po END) AS battery_po,
		SUM(CASE WHEN pos = 'OF' THEN po END) AS outfield_po,
		SUM(CASE WHEN pos IN ('SS','1B','2B','3B') THEN po END) AS infield_po
FROM fielding
WHERE yearid = 2016;




-- 5.
-- Find the average number of strikeouts per game by decade since 1920. Round the numbers you report to 2 decimal places. 
-- Do the same for home runs per game. Do you see any trends?

WITH decades AS (SELECT CONCAT((yearid / 10 * 10)::text,'''s') AS decade, *
				FROM teams
				WHERE yearid >= 1920)

SELECT decade, 
		ROUND(SUM(hr)/(SUM(g)::numeric/2),2) AS hr_per_game,
		ROUND(SUM(so)/(SUM(g)::numeric/2),2) AS so_per_game
FROM decades
GROUP BY decade
ORDER BY decade;




-- 6.
-- Find the player who had the most success stealing bases in 2016, where __success__ is measured as the percentage of stolen base attempts which are successful.
-- (A stolen base attempt results either in a stolen base or being caught stealing.) Consider only players who attempted _at least_ 20 stolen bases.

SELECT 
	namefirst, 
	namelast, 
	CONCAT(ROUND((SUM(sb)::numeric/(SUM(sb)+SUM(cs)))*100,2)::text, '%') AS stolen_base_success_rate
FROM people INNER JOIN batting USING(playerid)
WHERE yearid = 2016
GROUP BY namefirst, namelast
HAVING SUM(sb) + SUM(cs) >= 20
ORDER BY stolen_base_success_rate;

-- 7.
-- From 1970 – 2016, what is the largest number of wins for a team that did not win the world series? 
-- What is the smallest number of wins for a team that did win the world series? 
-- Doing this will probably result in an unusually small number of wins for a world series champion – determine why this is the case. 
-- Then redo your query, excluding the problem year. 
-- How often from 1970 – 2016 was it the case that a team with the most wins also won the world series? What percentage of the time?

WITH most_wins AS (SELECT yearid, MAX(w) AS most_wins
					FROM teams
					WHERE yearid BETWEEN 1970 AND 2016 AND yearid <> 1981 AND yearid <> 1994
					GROUP BY yearid)

SELECT *
FROM most_wins INNER JOIN teams USING(yearid)
WHERE w = most_wins



	
-- 8.
-- Using the attendance figures from the homegames table, find the teams and parks which had the top 5 average attendance per game in 2016 
-- (where average attendance is defined as total attendance divided by number of games). 
-- Only consider parks where there were at least 10 games played. Report the park name, team name, and average attendance. 
-- Repeat for the lowest 5 average attendance.

(SELECT name, teams.park, homegames.attendance/games AS avg_attendance, 'top_5' AS attendance_rank
FROM teams INNER JOIN homegames ON team = teamid AND year = yearid
WHERE yearid = 2016 AND games >= 10
ORDER BY avg_attendance DESC
LIMIT 5)
UNION
(SELECT name, teams.park, homegames.attendance/games AS avg_attendance, 'bottom_5' AS attendance_rank
FROM teams INNER JOIN homegames ON team = teamid AND year = yearid
WHERE yearid = 2016 AND games >= 10
ORDER BY avg_attendance ASC
LIMIT 5)
ORDER BY avg_attendance DESC;

-- 9.
-- Which managers have won the TSN Manager of the Year award in both the National League (NL) and the American League (AL)? 
-- Give their full name and the teams that they were managing when they won the award.

SELECT namefirst, namelast, yearid, name, awardid, awardsmanagers.lgid
FROM awardsmanagers INNER JOIN managers USING(playerid, yearid)
					INNER JOIN people USING(playerid)
					INNER JOIN teams USING(teamid, yearid)
WHERE playerid IN (SELECT playerid 
					FROM awardsmanagers INNER JOIN managers USING(playerid, yearid)
					WHERE awardid LIKE 'TSN%' AND awardsmanagers.lgid IN ('AL','NL')
					GROUP BY playerid
					HAVING COUNT(DISTINCT awardsmanagers.lgid) = 2) 
AND awardid LIKE 'TSN%'
ORDER BY yearid;



	
-- 10.
-- Find all players who hit their career highest number of home runs in 2016. 
-- Consider only players who have played in the league for at least 10 years, and who hit at least one home run in 2016. 
-- Report the players' first and last names and the number of home runs they hit in 2016.

WITH most_hr AS (SELECT playerid, MAX(hr) AS most_hr
				FROM batting
				GROUP BY playerid)

SELECT namefirst, namelast, hr
FROM most_hr INNER JOIN batting USING(playerid)
			INNER JOIN people USING(playerid)
WHERE hr = most_hr AND yearid = 2016 AND hr > 0 AND LEFT (debut, 4)::numeric <= 2007
ORDER BY hr DESC;



