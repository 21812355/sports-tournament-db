-- =============================================
-- SPORTS TOURNAMENT DATABASE
-- DDL - Data Definition Language
-- All CREATE TABLE statements
-- =============================================

-- 1. USER GROUPS (create first - USERS depends on it)
CREATE TABLE user_groups (
  group_id   SERIAL PRIMARY KEY,
  group_name VARCHAR(50)  NOT NULL UNIQUE,
  permissions TEXT        NOT NULL
);

-- 2. USERS
CREATE TABLE users (
  user_id       SERIAL PRIMARY KEY,
  group_id      INT          NOT NULL REFERENCES user_groups(group_id),
  username      VARCHAR(50)  NOT NULL UNIQUE,
  email         VARCHAR(100) NOT NULL UNIQUE,
  password_hash VARCHAR(255) NOT NULL,
  full_name     VARCHAR(100) NOT NULL,
  created_at    TIMESTAMP    DEFAULT NOW()
);

-- 3. TOURNAMENTS
CREATE TABLE tournaments (
  tournament_id SERIAL PRIMARY KEY,
  created_by    INT          NOT NULL REFERENCES users(user_id),
  name          VARCHAR(100) NOT NULL,
  sport_type    VARCHAR(50)  NOT NULL,
  start_date    DATE         NOT NULL,
  end_date      DATE         NOT NULL,
  status        VARCHAR(20)  DEFAULT 'upcoming'
                             CHECK (status IN ('upcoming','ongoing','completed')),
  location      VARCHAR(100)
);

-- 4. TEAMS
CREATE TABLE teams (
  team_id       SERIAL PRIMARY KEY,
  tournament_id INT          NOT NULL REFERENCES tournaments(tournament_id),
  manager_id    INT          NOT NULL REFERENCES users(user_id),
  team_name     VARCHAR(100) NOT NULL,
  country       VARCHAR(60),
  wins          INT          DEFAULT 0 CHECK (wins >= 0),
  losses        INT          DEFAULT 0 CHECK (losses >= 0)
);

-- 5. PLAYERS
CREATE TABLE players (
  player_id   SERIAL PRIMARY KEY,
  team_id     INT          NOT NULL REFERENCES teams(team_id),
  user_id     INT          REFERENCES users(user_id),
  full_name   VARCHAR(100) NOT NULL,
  position    VARCHAR(50),
  dob         DATE,
  nationality VARCHAR(60)
);

-- 6. MATCHES
CREATE TABLE matches (
  match_id      SERIAL PRIMARY KEY,
  tournament_id INT       NOT NULL REFERENCES tournaments(tournament_id),
  team_a_id     INT       NOT NULL REFERENCES teams(team_id),
  team_b_id     INT       NOT NULL REFERENCES teams(team_id),
  match_date    TIMESTAMP NOT NULL,
  venue         VARCHAR(100),
  score_a       INT       DEFAULT 0 CHECK (score_a >= 0),
  score_b       INT       DEFAULT 0 CHECK (score_b >= 0),
  status        VARCHAR(20) DEFAULT 'scheduled'
                            CHECK (status IN ('scheduled','live','completed')),
  CHECK (team_a_id <> team_b_id)
);

-- 7. MATCH STATS
CREATE TABLE match_stats (
  stat_id        SERIAL PRIMARY KEY,
  match_id       INT NOT NULL REFERENCES matches(match_id),
  player_id      INT NOT NULL REFERENCES players(player_id),
  goals          INT DEFAULT 0 CHECK (goals >= 0),
  assists        INT DEFAULT 0 CHECK (assists >= 0),
  yellow_cards   INT DEFAULT 0 CHECK (yellow_cards >= 0),
  red_cards      INT DEFAULT 0 CHECK (red_cards >= 0),
  minutes_played INT DEFAULT 0 CHECK (minutes_played >= 0),
  UNIQUE (match_id, player_id)
);
