-- =============================================
-- SPORTS TOURNAMENT DATABASE
-- DML - Data Manipulation Language
-- Sample INSERT statements
-- =============================================

-- 1. USER GROUPS
INSERT INTO user_groups (group_name, permissions) VALUES
('admin',         'full_access'),
('employee',      'manage_teams,manage_matches,manage_players'),
('team_manager',  'manage_own_team,view_matches'),
('player',        'view_own_stats,view_matches'),
('viewer',        'view_only');

-- 2. USERS
INSERT INTO users (group_id, username, email, password_hash, full_name) VALUES
(1, 'admin1',       'admin@tournament.com',    '$2b$12$demohashadmin111111111', 'Ahmad Al-Admin'),
(2, 'emp_sara',     'sara@tournament.com',     '$2b$12$demohashemp1111111111',  'Sara Johnson'),
(3, 'mgr_brazil',   'brazil_mgr@teams.com',    '$2b$12$demohashemgr111111111',  'Carlos Silva'),
(3, 'mgr_germany',  'germany_mgr@teams.com',   '$2b$12$demohashemgr211111111',  'Hans Mueller'),
(3, 'mgr_france',   'france_mgr@teams.com',    '$2b$12$demohashemgr311111111',  'Pierre Dupont'),
(3, 'mgr_spain',    'spain_mgr@teams.com',     '$2b$12$demohashemgr411111111',  'Miguel Garcia'),
(4, 'player_neymar','neymar@players.com',      '$2b$12$demohashply1111111111',  'Neymar Jr'),
(4, 'player_muller','muller@players.com',      '$2b$12$demohashply2111111111',  'Thomas Muller'),
(4, 'player_mbappe','mbappe@players.com',      '$2b$12$demohashply3111111111',  'Kylian Mbappe'),
(4, 'player_morata','morata@players.com',      '$2b$12$demohashply4111111111',  'Alvaro Morata'),
(5, 'viewer1',      'viewer1@gmail.com',       '$2b$12$demohashvwr1111111111',  'John Viewer');

-- 3. TOURNAMENTS
INSERT INTO tournaments (created_by, name, sport_type, start_date, end_date, status, location) VALUES
(1, 'World Cup 2026',          'Football',   '2026-06-01', '2026-06-30', 'upcoming',  'Istanbul, Turkey'),
(1, 'Champions League 2025',   'Football',   '2025-09-01', '2025-12-15', 'completed', 'Madrid, Spain'),
(2, 'Basketball World Trophy', 'Basketball', '2026-07-01', '2026-07-20', 'upcoming',  'Paris, France');

-- 4. TEAMS
INSERT INTO teams (tournament_id, manager_id, team_name, country, wins, losses) VALUES
(1, 3, 'Brazil National',  'Brazil',  3, 1),
(1, 4, 'Germany United',   'Germany', 2, 2),
(1, 5, 'France Elite',     'France',  4, 0),
(1, 6, 'Spain FC',         'Spain',   1, 3),
(2, 3, 'Brazil Champions', 'Brazil',  5, 2),
(2, 4, 'Bayern Stars',     'Germany', 6, 1);

-- 5. PLAYERS
INSERT INTO players (team_id, user_id, full_name, position, dob, nationality) VALUES
(1, 7,    'Neymar Jr',        'Forward',    '1992-02-05', 'Brazilian'),
(1, NULL, 'Vinicius Jr',      'Forward',    '2000-07-12', 'Brazilian'),
(1, NULL, 'Casemiro',         'Midfielder', '1992-02-23', 'Brazilian'),
(2, 8,    'Thomas Muller',    'Forward',    '1989-09-13', 'German'),
(2, NULL, 'Joshua Kimmich',   'Midfielder', '1995-02-08', 'German'),
(2, NULL, 'Manuel Neuer',     'Goalkeeper', '1986-03-27', 'German'),
(3, 9,    'Kylian Mbappe',    'Forward',    '1998-12-20', 'French'),
(3, NULL, 'Antoine Griezmann','Midfielder', '1991-03-21', 'French'),
(3, NULL, 'Hugo Lloris',      'Goalkeeper', '1986-12-26', 'French'),
(4, 10,   'Alvaro Morata',    'Forward',    '1992-10-23', 'Spanish'),
(4, NULL, 'Pedri',            'Midfielder', '2002-11-25', 'Spanish'),
(4, NULL, 'Unai Simon',       'Goalkeeper', '1997-06-11', 'Spanish');

-- 6. MATCHES
INSERT INTO matches (tournament_id, team_a_id, team_b_id, match_date, venue, score_a, score_b, status) VALUES
(1, 1, 2, '2026-06-05 18:00:00', 'Ataturk Stadium, Istanbul',    3, 1, 'completed'),
(1, 3, 4, '2026-06-05 21:00:00', 'Besiktas Arena, Istanbul',     2, 0, 'completed'),
(1, 1, 3, '2026-06-10 20:00:00', 'Galatasaray Park, Istanbul',   1, 2, 'completed'),
(1, 2, 4, '2026-06-10 17:00:00', 'Fenerbahce Stadium, Istanbul', 3, 3, 'completed'),
(1, 1, 4, '2026-06-15 20:00:00', 'Ataturk Stadium, Istanbul',    0, 0, 'scheduled'),
(1, 2, 3, '2026-06-15 20:00:00', 'Besiktas Arena, Istanbul',     0, 0, 'scheduled');

-- 7. MATCH STATS
INSERT INTO match_stats (match_id, player_id, goals, assists, yellow_cards, red_cards, minutes_played) VALUES
(1, 1,  2, 1, 0, 0, 90),
(1, 2,  1, 0, 1, 0, 85),
(1, 3,  0, 2, 0, 0, 90),
(1, 4,  1, 0, 0, 0, 90),
(1, 5,  0, 1, 1, 0, 90),
(2, 7,  1, 1, 0, 0, 90),
(2, 8,  1, 0, 0, 0, 88),
(2, 10, 0, 0, 1, 0, 90),
(3, 1,  0, 1, 0, 0, 90),
(3, 7,  2, 0, 0, 0, 90),
(3, 8,  0, 1, 0, 0, 75),
(4, 4,  2, 0, 0, 0, 90),
(4, 5,  1, 1, 0, 0, 90),
(4, 10, 2, 0, 1, 0, 90),
(4, 11, 1, 0, 0, 0, 90);
