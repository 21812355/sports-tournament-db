-- =============================================
-- SPORTS TOURNAMENT DATABASE
-- PL/SQL Blocks (5 blocks)
-- Procedures, Functions, Triggers
-- =============================================

-- PL/SQL 1: PROCEDURE - Register a new team
-- Validates tournament is upcoming before inserting
CREATE OR REPLACE PROCEDURE register_team(
  p_tournament_id INT,
  p_manager_id    INT,
  p_team_name     VARCHAR,
  p_country       VARCHAR
)
LANGUAGE plpgsql AS $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM tournaments
    WHERE tournament_id = p_tournament_id
      AND status = 'upcoming'
  ) THEN
    RAISE EXCEPTION 'Tournament % does not exist or is not upcoming',
      p_tournament_id;
  END IF;

  INSERT INTO teams (tournament_id, manager_id, team_name, country)
  VALUES (p_tournament_id, p_manager_id, p_team_name, p_country);

  RAISE NOTICE 'Team "%" registered successfully in tournament %',
    p_team_name, p_tournament_id;
END;
$$;

-- Test:
CALL register_team(1, 3, 'Portugal FC', 'Portugal');

-- ─────────────────────────────────────────────

-- PL/SQL 2: FUNCTION - Get total goals for a player
-- Returns total goals scored by a given player_id
CREATE OR REPLACE FUNCTION get_player_goals(p_player_id INT)
RETURNS INT
LANGUAGE plpgsql AS $$
DECLARE
  v_total INT;
BEGIN
  SELECT COALESCE(SUM(goals), 0)
  INTO v_total
  FROM match_stats
  WHERE player_id = p_player_id;

  RETURN v_total;
END;
$$;

-- Test (player_id=1 is Neymar):
SELECT get_player_goals(1) AS neymar_total_goals;

-- ─────────────────────────────────────────────

-- PL/SQL 3: TRIGGER - Auto-update team wins/losses
-- Fires after a match is marked as completed
CREATE OR REPLACE FUNCTION update_team_record()
RETURNS TRIGGER
LANGUAGE plpgsql AS $$
BEGIN
  IF NEW.status = 'completed' AND OLD.status <> 'completed' THEN
    IF NEW.score_a > NEW.score_b THEN
      UPDATE teams SET wins   = wins   + 1 WHERE team_id = NEW.team_a_id;
      UPDATE teams SET losses = losses + 1 WHERE team_id = NEW.team_b_id;
    ELSIF NEW.score_b > NEW.score_a THEN
      UPDATE teams SET wins   = wins   + 1 WHERE team_id = NEW.team_b_id;
      UPDATE teams SET losses = losses + 1 WHERE team_id = NEW.team_a_id;
    END IF;
  END IF;
  RETURN NEW;
END;
$$;

CREATE OR REPLACE TRIGGER trg_match_result
AFTER UPDATE ON matches
FOR EACH ROW
EXECUTE FUNCTION update_team_record();

-- Test:
UPDATE matches SET status='completed', score_a=2, score_b=0
WHERE match_id=5;

-- ─────────────────────────────────────────────

-- PL/SQL 4: FUNCTION - Tournament summary report
-- Returns total teams, matches, goals, and top scorer
CREATE OR REPLACE FUNCTION tournament_summary(p_tournament_id INT)
RETURNS TABLE (
  total_teams   INT,
  total_matches INT,
  total_goals   INT,
  top_scorer    VARCHAR
)
LANGUAGE plpgsql AS $$
BEGIN
  RETURN QUERY
  SELECT
    (SELECT COUNT(*)::INT FROM teams
     WHERE tournament_id = p_tournament_id),
    (SELECT COUNT(*)::INT FROM matches
     WHERE tournament_id = p_tournament_id
       AND status = 'completed'),
    (SELECT COALESCE(SUM(ms.goals), 0)::INT
     FROM match_stats ms
     JOIN matches m ON ms.match_id = m.match_id
     WHERE m.tournament_id = p_tournament_id),
    (SELECT p.full_name
     FROM match_stats ms
     JOIN matches m ON ms.match_id  = m.match_id
     JOIN players p ON ms.player_id = p.player_id
     WHERE m.tournament_id = p_tournament_id
     GROUP BY p.full_name
     ORDER BY SUM(ms.goals) DESC
     LIMIT 1);
END;
$$;

-- Test:
SELECT * FROM tournament_summary(1);

-- ─────────────────────────────────────────────

-- PL/SQL 5: TRIGGER - Prevent duplicate match scheduling
-- Fires before INSERT or UPDATE on matches
CREATE OR REPLACE FUNCTION prevent_duplicate_match()
RETURNS TRIGGER
LANGUAGE plpgsql AS $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM matches
    WHERE tournament_id = NEW.tournament_id
      AND DATE(match_date) = DATE(NEW.match_date)
      AND match_id <> COALESCE(NEW.match_id, -1)
      AND (
        (team_a_id = NEW.team_a_id AND team_b_id = NEW.team_b_id)
        OR
        (team_a_id = NEW.team_b_id AND team_b_id = NEW.team_a_id)
      )
  ) THEN
    RAISE EXCEPTION 'These two teams already have a match scheduled on this date';
  END IF;
  RETURN NEW;
END;
$$;

CREATE OR REPLACE TRIGGER trg_no_duplicate_match
BEFORE INSERT OR UPDATE ON matches
FOR EACH ROW
EXECUTE FUNCTION prevent_duplicate_match();
