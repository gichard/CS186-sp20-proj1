DROP VIEW IF EXISTS q0, q1i, q1ii, q1iii, q1iv, q2i, q2ii, q2iii, q3i, q3ii, q3iii, q4i, q4ii, q4iii, q4iv, q4v;

-- Question 0
CREATE VIEW q0(era) 
AS
  SELECT MAX(era) FROM pitching
;

-- Question 1i
CREATE VIEW q1i(namefirst, namelast, birthyear)
AS
  SELECT namefirst, namelast, birthyear FROM people
  WHERE weight > 300
;

-- Question 1ii
CREATE VIEW q1ii(namefirst, namelast, birthyear)
AS
  SELECT namefirst, namelast, birthyear FROM people
  WHERE namefirst LIKE '% %'
;

-- Question 1iii
CREATE VIEW q1iii(birthyear, avgheight, count)
AS
  SELECT birthyear, AVG(height), COUNT(playerid) FROM people
  GROUP BY birthyear
  ORDER BY birthyear
;

-- Question 1iv
CREATE VIEW q1iv(birthyear, avgheight, count)
AS
  SELECT * FROM q1iii
  WHERE avgheight > 70
  ORDER BY birthyear
;

-- Question 2i
CREATE VIEW q2i(namefirst, namelast, playerid, yearid)
AS
  SELECT namefirst, namelast, h.playerid, h.yearid
  FROM halloffame AS h INNER JOIN people AS p
  ON h.playerid = p.playerid
  WHERE inducted = 'Y'
  ORDER BY h.yearid DESC
;

-- Question 2ii
CREATE VIEW q2ii(namefirst, namelast, playerid, schoolid, yearid)
AS
  SELECT namefirst, namelast, h.playerid, cp.schoolid, h.yearid
  FROM q2i AS h INNER JOIN collegeplaying AS cp
  ON h.playerid = cp.playerid
  WHERE cp.schoolid IN (
    SELECT schoolid FROM schools
    WHERE schoolstate = 'CA'
  )
  ORDER BY h.yearid DESC, cp.schoolid, h.playerid
;

-- Question 2iii
CREATE VIEW q2iii(playerid, namefirst, namelast, schoolid)
AS
  SELECT h.playerid, namefirst, namelast, schoolid
  FROM q2i as h LEFT OUTER JOIN collegeplaying AS cp
  ON h.playerid = cp.playerid
  ORDER BY h.playerid DESC, cp.schoolid
;

-- Question 3i
CREATE VIEW q3i(playerid, namefirst, namelast, yearid, slg)
AS
  SELECT p.playerid, namefirst, namelast, yearid, (CAST(h + h2b + 2*h3b + 3*hr AS FLOAT) / CAST(ab AS FLOAT)) slg
  FROM people AS p INNER JOIN batting AS b
  ON p.playerid = b.playerid
  WHERE ab > 50
  ORDER BY slg DESC, yearid, p.playerid
  LIMIT 10
;

-- Question 3ii
CREATE VIEW q3ii(playerid, namefirst, namelast, lslg)
AS
  SELECT p.playerid, namefirst, namelast, (CAST(SUM(h) + SUM(h2b) + 2*SUM(h3b) + 3*SUM(hr) AS FLOAT) / CAST(SUM(ab) AS FLOAT)) lslg
  FROM people AS p INNER JOIN batting AS b
  ON p.playerid = b.playerid
  GROUP BY p.playerid
  HAVING SUM(ab) > 50
  ORDER BY lslg DESC, playerid
  LIMIT 10
;

-- Question 3iii
CREATE VIEW q3iii(namefirst, namelast, lslg)
AS
  SELECT namefirst, namelast, (CAST(SUM(h) + SUM(h2b) + 2*SUM(h3b) + 3*SUM(hr) AS FLOAT) / CAST(SUM(ab) AS FLOAT)) lslg
  FROM people AS p INNER JOIN batting AS b
  ON p.playerid = b.playerid
  GROUP BY p.playerid
  HAVING SUM(ab) > 50 AND 
  (CAST(SUM(h) + SUM(h2b) + 2*SUM(h3b) + 3*SUM(hr) AS FLOAT) / CAST(SUM(ab) AS FLOAT)) > (
    SELECT (CAST(SUM(h) + SUM(h2b) + 2*SUM(h3b) + 3*SUM(hr) AS FLOAT) / CAST(SUM(ab) AS FLOAT))
    FROM batting
    GROUP BY playerid
    HAVING playerid = 'mayswi01'
)
;

-- Question 4i
CREATE VIEW q4i(yearid, min, max, avg, stddev)
AS
  SELECT yearid, MIN(salary), MAX(salary), AVG(salary), STDDEV(salary)
  FROM salaries
  GROUP BY yearid
  ORDER BY yearid
;

-- Question 4ii
CREATE VIEW q4ii(binid, low, high, count)
AS
  SELECT binid, MIN(low), MIN(high), COUNT(*)
  FROM (SELECT salary FROM salaries WHERE yearid = 2016) AS s
  INNER JOIN (SELECT (bin) binid, (min + bin * (max - min) / 10) low,
    (min + (bin + 1) * (max - min) / 10) high
    FROM (SELECT min, max FROM q4i WHERE yearid = 2016) AS smm
    , (SELECT generate_series AS bin FROM generate_series(0, 9)) AS b) AS bucket
  ON salary >= low AND (salary < high OR binid = 9)
  GROUP BY binid
  ORDER BY binid
;

-- Question 4iii
CREATE VIEW q4iii(yearid, mindiff, maxdiff, avgdiff)
AS
  SELECT n.yearid, n.min - p.min, n.max - p.max, n.avg - p.avg
  FROM q4i AS p INNER JOIN q4i AS n
  ON n.yearid - p.yearid = 1
  ORDER BY n.yearid
;

-- Question 4iv
CREATE VIEW q4iv(playerid, namefirst, namelast, salary, yearid)
AS
  SELECT p.playerid, p.namefirst, p.namelast, ms.salary, ms.yearid
  FROM people AS p INNER JOIN (SELECT * FROM salaries 
    WHERE (salaries.salary = (SELECT max FROM q4i WHERE q4i.yearid=2000) AND salaries.yearid=2000)
      OR (salaries.salary = (SELECT max FROM q4i WHERE q4i.yearid=2001) AND salaries.yearid=2001)) AS ms
  ON p.playerid = ms.playerid
;
-- Question 4v
CREATE VIEW q4v(team, diffAvg) AS
  SELECT a.teamid, MAX(s.salary) - min(s.salary)
  FROM (SELECT * FROM allstarfull WHERE yearid=2016) AS a 
    INNER JOIN (SELECT * FROM salaries WHERE yearid = 2016) AS s
  ON a.playerid = s.playerid
  GROUP BY a.teamid
  ORDER BY a.teamid
;

