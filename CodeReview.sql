--TABLE CREATION
CREATE TABLE #CodeReviews (
JIRATicket varchar(100),
DateAdded Date,
Person varchar(50),
Reason varchar(50),
PassOrFail char(4),
TimeSpent numeric(5,2),
Type varchar(15)
)

CREATE TABLE #CodeReviewFinal (
Name varchar(255),
TimeSpent numeric(5,2),
PassRate float,
NumberOfCodeReviews int
)


/*inserting each person into temporary table

Removed employee names/JIRA links for confidentiality
*/

SELECT DISTINCT cr.Person 
INTO #tempPeopleTable
FROM #CodeReviews cr 


--Main Insert/Select

INSERT INTO #CodeReviewFinal(Name,TimeSpent,PassRate,NumberOfCodeReviews)
SELECT 
	cr.Person,
	SUM(cr.TimeSpent) AS 'Total Time Spent in Hours',
	(	SELECT CAST(COUNT(cr.PassOrFail)AS FLOAT) 
		FROM #CodeReviews cr 
		WHERE cr.PassOrFail = 'Pass' AND cr.Person = t.Person) /
	((		SELECT CAST(COUNT(cr.PassOrFail)AS FLOAT)
			FROM #CodeReviews cr 
			WHERE cr.Person = t.Person)) * 100  AS 'Pass Rate (%)',
			count(cr.PassOrFail) as 'Number of Code Reviews'
FROM #CodeReviews cr 
INNER JOIN #tempPeopleTable t ON cr.Person = t.Person
WHERE cr.Person = t.Person
GROUP BY cr.Person,t.[Person]


--Final Select

SELECT 
	crf.Name,
	crf.TimeSpent as 'Total Time Spent in Hours',
	CONCAT(crf.PassRate,'%') AS 'Pass Rate',
	crf.NumberOfCodeReviews as 'Number of Code Reviews'
FROM #CodeReviewFinal crf
ORDER BY crf.PassRate DESC


--STATISTICS--

--Finding the developer who has spent the most amount of time on code reviews
SELECT 
	crf.Name,
	crf.TimeSpent as 'Total Time Spent in Hours',
	CONCAT(crf.PassRate,'%') AS 'Pass Rate' 
FROM #CodeReviewFinal crf
where crf.TimeSpent = (select MAX(crf2.TimeSpent) from #CodeReviewFinal crf2)
ORDER BY crf.PassRate DESC


--Finding the people who have a less than average passrate, run subquery to find average passrate

SELECT crf.Name,crf.PassRate,count(cr.PassOrFail) as 'Number of Code Reviews'
FROM #CodeReviewFinal crf join #CodeReviews cr on cr.Person = crf.Name
WHERE crf.PassRate < (SELECT AVG(crf2.PassRate) as 'Average Pass Rate' FROM #CodeReviewFinal crf2 WHERE crf2.Name IS NOT NULL) 
group by crf.Name,crf.PassRate
ORDER BY crf.PassRate asc


--Finding the people who have a greater than average timespent, run subquery to find average timespent

SELECT crf.Name,crf.TimeSpent,crf.PassRate,count(cr.PassOrFail) as 'Number of Code Reviews'
FROM #CodeReviewFinal crf join #CodeReviews cr on cr.Person = crf.Name
WHERE crf.TimeSpent > (SELECT AVG(crf2.TimeSpent) as 'Average Total Time Spent' FROM #CodeReviewFinal crf2 WHERE crf2.Name IS NOT NULL) 
group by crf.Name,crf.TimeSpent,crf.PassRate
ORDER BY crf.TimeSpent desc




--Average timespent based on reason

SELECT AVG(cr.TimeSpent) AS TimeSpent,cr.Reason 
FROM #CodeReviews cr 
WHERE cr.Reason != ' ' AND cr.PassOrFail = 'Fail' 
GROUP BY cr.Reason 
ORDER BY TimeSpent DESC

--Max timespent based on reason

SELECT MAX(cr.TimeSpent) AS TimeSpent,cr.Reason 
FROM #CodeReviews cr 
WHERE cr.Reason != ' ' AND cr.PassOrFail = 'Fail'  
GROUP BY cr.Reason 
ORDER BY TimeSpent DESC

--Total TimeSpent Based on Reason

select SUM(cr.TimeSpent) as 'Total Time Spent',cr.Reason
FROM #CodeReviews cr
where cr.Reason is not null and cr.PassOrFail = 'Fail'
group by cr.Reason
order by [Total Time Spent] desc

--Count of how many times a Reason of Failure occurs

SELECT COUNT(*) AS 'Count',cr.Reason 
FROM #CodeReviews cr 
WHERE cr.Reason != ' ' and cr.PassOrFail = 'Fail'
GROUP BY cr.Reason 
ORDER BY COUNT DESC




--Finding the max reason why a certain person failed

--insert

SELECT DISTINCT cr.Person 
INTO #tempPeopleFailTable 
FROM #CodeReviews cr 
WHERE cr.PassOrFail = 'Fail'

--insert

SELECT 
COUNT(cr.Reason) AS 'Number of Reasons',cr.Reason,tp.Person
INTO #tempReasonPeople 
FROM #CodeReviews cr inner join #tempPeopleFailTable tp ON cr.Person = tp.Person 
WHERE cr.Person = tp.Person and cr.PassOrFail = 'Fail' 
GROUP BY tp.person,cr.Reason 
ORDER BY tp.Person DESC


--select

SELECT trp.Person, trp.Reason
FROM #tempReasonPeople trp
INNER JOIN #tempPeopleFailTable tp ON tp.Person = trp.Person
WHERE trp.[Number of Reasons] = 
(SELECT MAX(t.[Number of Reasons]) FROM #tempReasonPeople t WHERE t.Person = tp.Person)
ORDER BY trp.Reason DESC


--drop temp tables for statistic queries
DROP TABLE #tempPeopleTable
DROP TABLE #tempReasonPeople
DROP TABLE #tempPeopleFailTable
--drop temp tables from inserts
DROP TABLE #CodeReviews
DROP TABLE #CodeReviewFinal
*/
