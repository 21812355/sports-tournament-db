-- =============================================
-- SPORTS TOURNAMENT DATABASE
-- SQL Queries (7 queries)
-- =============================================

-- Q1: Top scorers per tournament
-- Techniques: 4-table JOIN, GROUP BY, SUM, ORDER BY
SELECT
  t.name            AS tournament,
  p.full_name       AS player,
  tm.team_name      AS team,
  SUM(ms.goals)     AS total_goals,
  SUM(ms.assists)   AS total_assists
FROM match_stats ms
JOIN players    p  ON ms.player_id    = p.player_id
JOIN teams      tm ON p.team_id       = tm.team_id
JOIN matches    m  ON ms.match_id     = m.match_id
JOIN tournaments t ON m.tournament_id = t.tournament_id
GROUP BY t.name, p.full_name, tm.team_name
ORDER BY total_goals DESC;

-- ─────────────────────────────────────────────

-- Q2: Team standings with points
-- Techniques: JOIN, subquery, calculated field
SELECT
  tm.team_name,
  t.name AS tournament,
  tm.wins,
  tm.losses,
  (SELECT COUNT(*) FROM matches m
   WHERE (m.team_a_id = tm.team_id OR m.team_b_id = tm.team_id)
     AND m.score_a = m.score_b
     AND m.status  = 'completed') AS draws,
  (tm.wins * 3) AS points
FROM teams tm
JOIN tournaments t ON tm.tournament_id = t.tournament_id
ORDER BY points DESC;

-- ─────────────────────────────────────────────

-- Q3: Average goals per match per tournament
-- Techniques: AVG, COUNT, SUM, GROUP BY, WHERE, ROUND
SELECT
  t.name                                         AS tournament,
  COUNT(m.match_id)                              AS total_matches,
  SUM(m.score_a + m.score_b)                    AS total_goals,
  ROUND(AVG(m.score_a + m.score_b)::numeric, 2) AS avg_goals_per_match
FROM matches m
JOIN tournaments t ON m.tournament_id = t.tournament_id
WHERE m.status = 'completed'
GROUP BY t.name
ORDER BY avg_goals_per_match DESC;

-- ─────────────────────────────────────────────

-- Q4: Disciplinary report - players with cards
-- Techniques: Correlated subqueries x3, WHERE with subquery
SELECT
  p.full_name,
  tm.team_name,
  t.name AS tournament,
  (SELECT SUM(ms2.yellow_cards)
   FROM match_stats ms2
   WHERE ms2.player_id = p.player_id) AS total_yellows,
  (SELECT SUM(ms2.red_cards)
   FROM match_stats ms2
   WHERE ms2.player_id = p.player_id) AS total_reds
FROM players p
JOIN teams       tm ON p.team_id       = tm.team_id
JOIN tournaments t  ON tm.tournament_id = t.tournament_id
WHERE (
  SELECT SUM(ms3.yellow_cards + ms3.red_cards)
  FROM match_stats ms3
  WHERE ms3.player_id = p.player_id
) > 0
ORDER BY total_yellows DESC;

-- ─────────────────────────────────────────────

-- Q5: Full match results with team names
-- Techniques: Self-JOIN on teams, multi-table JOIN
SELECT
  t.name          AS tournament,
  ta.team_name    AS home_team,
  m.score_a       AS home_score,
  m.score_b       AS away_score,
  tb.team_name    AS away_team,
  m.match_date,
  m.venue,
  m.status
FROM matches m
JOIN tournaments t  ON m.tournament_id = t.tournament_id
JOIN teams       ta ON m.team_a_id     = ta.team_id
JOIN teams       tb ON m.team_b_id     = tb.team_id
ORDER BY m.match_date;

-- ─────────────────────────────────────────────

-- Q6: Player workload - minutes and goals
-- Techniques: COUNT, SUM, GROUP BY, HAVING
SELECT
  p.full_name,
  p.position,
  tm.team_name,
  COUNT(ms.match_id)      AS matches_played,
  SUM(ms.minutes_played)  AS total_minutes,
  SUM(ms.goals)           AS goals,
  SUM(ms.assists)         AS assists
FROM match_stats ms
JOIN players p  ON ms.player_id = p.player_id
JOIN teams   tm ON p.team_id    = tm.team_id
GROUP BY p.full_name, p.position, tm.team_name
HAVING SUM(ms.minutes_played) > 0
ORDER BY total_minutes DESC;

-- ─────────────────────────────────────────────

-- Q7: User group statistics
-- Techniques: LEFT JOIN, COUNT, GROUP BY, ORDER BY
SELECT
  ug.group_name,
  ug.permissions,
  COUNT(u.user_id) AS total_users
FROM user_groups ug
LEFT JOIN users u ON ug.group_id = u.group_id
GROUP BY ug.group_name, ug.permissions
ORDER BY total_users DESC;
