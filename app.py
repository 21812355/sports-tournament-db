import streamlit as st
import requests
import pandas as pd

SUPABASE_URL = "https://erasxbvtzurkcqxcmdxh.supabase.co"
SUPABASE_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImVyYXN4YnZ0enVya2NxeGNtZHhoIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzYyNDE3OTMsImV4cCI6MjA5MTgxNzc5M30.-qHDtFTeNIWxpaYvUSkExb2OVHrCbHDDkZmau4YZgJU"

H = {
    "apikey": SUPABASE_KEY,
    "Authorization": f"Bearer {SUPABASE_KEY}",
    "Content-Type": "application/json",
    "Prefer": "return=representation"
}

def sg(table, select="*", filters=None):
    url = f"{SUPABASE_URL}/rest/v1/{table}?select={select}"
    if filters:
        for k, v in filters.items():
            url += f"&{k}=eq.{v}"
    r = requests.get(url, headers=H)
    data = r.json()
    if isinstance(data, list):
        return data
    return []

def si(table, data):
    r = requests.post(f"{SUPABASE_URL}/rest/v1/{table}", headers=H, json=data)
    return r.status_code in (200, 201)

def su(table, data, col, val):
    r = requests.patch(f"{SUPABASE_URL}/rest/v1/{table}?{col}=eq.{val}", headers=H, json=data)
    return r.status_code in (200, 204)

def sd(table, col, val):
    r = requests.delete(f"{SUPABASE_URL}/rest/v1/{table}?{col}=eq.{val}", headers=H)
    return r.status_code in (200, 204)

def sc(table):
    r = requests.get(f"{SUPABASE_URL}/rest/v1/{table}?select=count",
                     headers={**H, "Prefer": "count=exact"})
    try:
        return int(r.headers.get("content-range", "0/0").split("/")[-1])
    except Exception:
        return 0

st.set_page_config(page_title="Sports Tournament Manager", page_icon="🏆", layout="wide")

if "logged_in" not in st.session_state:
    st.session_state.logged_in = False
if "user_id" not in st.session_state:
    st.session_state.user_id = None
if "username" not in st.session_state:
    st.session_state.username = None
if "group_name" not in st.session_state:
    st.session_state.group_name = None


def login_page():
    st.title("🏆 Sports Tournament Manager")
    st.subheader("Login")
    col1, col2 = st.columns(2)
    with col1:
        username = st.text_input("Username")
        st.text_input("Password", type="password")
        if st.button("Login", use_container_width=True):
            rows = sg("users", select="user_id,username,user_groups(group_name)",
                      filters={"username": username})
            if not rows:
                st.error("User not found.")
            else:
                u = rows[0]
                st.session_state.logged_in = True
                st.session_state.user_id = u["user_id"]
                st.session_state.username = u["username"]
                st.session_state.group_name = u["user_groups"]["group_name"]
                st.rerun()
    with col2:
        st.info("Demo accounts (any password):\n\n"
                "admin1 → admin\n\n"
                "emp_sara → employee\n\n"
                "mgr_brazil → team manager\n\n"
                "viewer1 → viewer")


def dashboard_page():
    st.title("📊 Dashboard")
    st.caption("Logged in as: " + st.session_state.username + " (" + st.session_state.group_name + ")")

    c1, c2, c3, c4 = st.columns(4)
    c1.metric("Tournaments", sc("tournaments"))
    c2.metric("Teams", sc("teams"))
    c3.metric("Players", sc("players"))
    c4.metric("Matches", sc("matches"))

    st.divider()
    col1, col2 = st.columns(2)

    with col1:
        st.subheader("Top Scorers")
        stats = sg("match_stats", select="goals,assists,players(full_name,teams(team_name))")
        if stats:
            agg = {}
            for s in stats:
                name = s["players"]["full_name"]
                team = s["players"]["teams"]["team_name"]
                if name not in agg:
                    agg[name] = {"Player": name, "Team": team, "Goals": 0, "Assists": 0}
                agg[name]["Goals"] += s["goals"]
                agg[name]["Assists"] += s["assists"]
            df = pd.DataFrame(list(agg.values())).sort_values("Goals", ascending=False)
            st.dataframe(df, hide_index=True)

    with col2:
        st.subheader("Team Standings")
        teams = sg("teams", select="team_name,wins,losses,tournaments(name)")
        if teams:
            rows = []
            for t in teams:
                rows.append({
                    "Team": t["team_name"],
                    "Tournament": t["tournaments"]["name"],
                    "Wins": t["wins"],
                    "Losses": t["losses"],
                    "Points": t["wins"] * 3
                })
            df = pd.DataFrame(rows).sort_values("Points", ascending=False)
            st.dataframe(df, hide_index=True)

    st.subheader("Upcoming Matches")
    matches = sg("matches",
                 select="match_date,venue,team_a:teams!matches_team_a_id_fkey(team_name),team_b:teams!matches_team_b_id_fkey(team_name)",
                 filters={"status": "scheduled"})
    if matches:
        rows = []
        for m in matches:
            rows.append({
                "Home": m["team_a"]["team_name"],
                "Away": m["team_b"]["team_name"],
                "Date": m["match_date"][:10],
                "Venue": m["venue"]
            })
        st.dataframe(pd.DataFrame(rows), hide_index=True)
    else:
        st.info("No upcoming matches.")


def tournaments_page():
    st.title("🏆 Tournaments and Teams")
    tab1, tab2 = st.tabs(["Tournaments", "Teams"])

    with tab1:
        st.subheader("All Tournaments")
        data = sg("tournaments", select="*,users(full_name)")
        if data:
            rows = []
            for d in data:
                rows.append({
                    "Name": d["name"],
                    "Sport": d["sport_type"],
                    "Start": d["start_date"],
                    "End": d["end_date"],
                    "Status": d["status"],
                    "Location": d["location"],
                    "Created By": d["users"]["full_name"]
                })
            st.dataframe(pd.DataFrame(rows), hide_index=True)

        if st.session_state.group_name == "admin":
            st.subheader("Add Tournament")
            with st.form("add_tour"):
                name = st.text_input("Tournament Name")
                sport = st.selectbox("Sport", ["Football", "Basketball", "Tennis", "Volleyball"])
                c1, c2 = st.columns(2)
                start = c1.date_input("Start Date")
                end = c2.date_input("End Date")
                loc = st.text_input("Location")
                submitted = st.form_submit_button("Create")
                if submitted:
                    ok = si("tournaments", {
                        "created_by": st.session_state.user_id,
                        "name": name,
                        "sport_type": sport,
                        "start_date": str(start),
                        "end_date": str(end),
                        "location": loc,
                        "status": "upcoming"
                    })
                    if ok:
                        st.success("Tournament created!")
                    else:
                        st.error("Failed to create tournament.")
                    st.rerun()

            st.subheader("Delete Tournament")
            tours = sg("tournaments", select="tournament_id,name")
            if tours:
                t_opt = {t["name"]: t["tournament_id"] for t in tours}
                with st.form("del_tour"):
                    sel = st.selectbox("Select tournament", list(t_opt.keys()))
                    submitted2 = st.form_submit_button("Delete")
                    if submitted2:
                        sd("tournaments", "tournament_id", t_opt[sel])
                        st.success("Deleted!")
                        st.rerun()

    with tab2:
        st.subheader("All Teams")
        data = sg("teams", select="*,tournaments(name),users(full_name)")
        if data:
            rows = []
            for d in data:
                rows.append({
                    "Team": d["team_name"],
                    "Country": d["country"],
                    "Tournament": d["tournaments"]["name"],
                    "Wins": d["wins"],
                    "Losses": d["losses"],
                    "Points": d["wins"] * 3,
                    "Manager": d["users"]["full_name"]
                })
            df = pd.DataFrame(rows).sort_values("Points", ascending=False)
            st.dataframe(df, hide_index=True)

        if st.session_state.group_name in ("admin", "employee"):
            st.subheader("Add Team")
            tours = sg("tournaments", select="tournament_id,name", filters={"status": "upcoming"})
            mgrs = sg("users", select="user_id,full_name", filters={"group_id": 3})
            t_opt = {t["name"]: t["tournament_id"] for t in tours} if tours else {}
            m_opt = {m["full_name"]: m["user_id"] for m in mgrs} if mgrs else {}
            with st.form("add_team"):
                t_keys = list(t_opt.keys()) if t_opt else ["No upcoming tournaments"]
                m_keys = list(m_opt.keys()) if m_opt else ["No managers"]
                t_sel = st.selectbox("Tournament", t_keys)
                m_sel = st.selectbox("Manager", m_keys)
                tname = st.text_input("Team Name")
                cntry = st.text_input("Country")
                submitted = st.form_submit_button("Add Team")
                if submitted:
                    ok = si("teams", {
                        "tournament_id": t_opt.get(t_sel),
                        "manager_id": m_opt.get(m_sel),
                        "team_name": tname,
                        "country": cntry
                    })
                    if ok:
                        st.success("Team added!")
                    else:
                        st.error("Failed.")
                    st.rerun()


def players_page():
    st.title("👤 Players")

    data = sg("players", select="*,teams(team_name,tournaments(name))")
    if data:
        rows = []
        for d in data:
            rows.append({
                "Name": d["full_name"],
                "Position": d["position"],
                "Nationality": d["nationality"],
                "DOB": d["dob"],
                "Team": d["teams"]["team_name"],
                "Tournament": d["teams"]["tournaments"]["name"]
            })
        st.dataframe(pd.DataFrame(rows), hide_index=True)

    col1, col2 = st.columns(2)

    with col1:
        st.subheader("Add Player")
        teams = sg("teams", select="team_id,team_name")
        t_opt = {t["team_name"]: t["team_id"] for t in teams} if teams else {}
        with st.form("add_player"):
            t_sel = st.selectbox("Team", list(t_opt.keys()) if t_opt else ["None"])
            name = st.text_input("Full Name")
            pos = st.selectbox("Position", ["Forward", "Midfielder", "Defender", "Goalkeeper"])
            dob = st.date_input("Date of Birth")
            nat = st.text_input("Nationality")
            submitted = st.form_submit_button("Add Player")
            if submitted:
                ok = si("players", {
                    "team_id": t_opt.get(t_sel),
                    "full_name": name,
                    "position": pos,
                    "dob": str(dob),
                    "nationality": nat
                })
                if ok:
                    st.success("Player added!")
                else:
                    st.error("Failed.")
                st.rerun()

    with col2:
        st.subheader("Update Player")
        players = sg("players", select="player_id,full_name")
        p_opt = {p["full_name"]: p["player_id"] for p in players} if players else {}
        with st.form("upd_player"):
            p_sel = st.selectbox("Player", list(p_opt.keys()) if p_opt else ["None"])
            new_pos = st.selectbox("New Position", ["Forward", "Midfielder", "Defender", "Goalkeeper"])
            new_nat = st.text_input("New Nationality")
            submitted = st.form_submit_button("Update")
            if submitted:
                ok = su("players", {"position": new_pos, "nationality": new_nat},
                        "player_id", p_opt.get(p_sel))
                if ok:
                    st.success("Updated!")
                else:
                    st.error("Failed.")
                st.rerun()

    st.subheader("Delete Player")
    players = sg("players", select="player_id,full_name")
    p_opt = {p["full_name"]: p["player_id"] for p in players} if players else {}
    with st.form("del_player"):
        p_sel = st.selectbox("Select Player", list(p_opt.keys()) if p_opt else ["None"])
        submitted = st.form_submit_button("Delete")
        if submitted:
            sd("players", "player_id", p_opt.get(p_sel))
            st.success("Deleted!")
            st.rerun()


def matches_page():
    st.title("⚽ Matches and Statistics")
    tab1, tab2 = st.tabs(["Match Results", "Player Stats"])

    with tab1:
        data = sg("matches",
                  select="*,tournaments(name),team_a:teams!matches_team_a_id_fkey(team_name),team_b:teams!matches_team_b_id_fkey(team_name)")
        if data:
            rows = []
            for d in data:
                rows.append({
                    "Home": d["team_a"]["team_name"],
                    "Score": str(d["score_a"]) + " - " + str(d["score_b"]),
                    "Away": d["team_b"]["team_name"],
                    "Tournament": d["tournaments"]["name"],
                    "Date": d["match_date"][:10],
                    "Venue": d["venue"],
                    "Status": d["status"]
                })
            st.dataframe(pd.DataFrame(rows), hide_index=True)

        if st.session_state.group_name in ("admin", "employee"):
            col1, col2 = st.columns(2)

            with col1:
                st.subheader("Schedule Match")
                tours = sg("tournaments", select="tournament_id,name")
                teams = sg("teams", select="team_id,team_name")
                t_opt = {t["name"]: t["tournament_id"] for t in tours} if tours else {}
                tm_opt = {t["team_name"]: t["team_id"] for t in teams} if teams else {}
                with st.form("add_match"):
                    t_sel = st.selectbox("Tournament", list(t_opt.keys()) if t_opt else ["None"])
                    ha = st.selectbox("Home Team", list(tm_opt.keys()) if tm_opt else ["None"])
                    ab = st.selectbox("Away Team", list(tm_opt.keys()) if tm_opt else ["None"])
                    mdate = st.date_input("Match Date")
                    venue = st.text_input("Venue")
                    submitted = st.form_submit_button("Schedule")
                    if submitted:
                        if ha == ab:
                            st.error("Home and away must be different!")
                        else:
                            ok = si("matches", {
                                "tournament_id": t_opt.get(t_sel),
                                "team_a_id": tm_opt.get(ha),
                                "team_b_id": tm_opt.get(ab),
                                "match_date": str(mdate),
                                "venue": venue,
                                "score_a": 0,
                                "score_b": 0,
                                "status": "scheduled"
                            })
                            if ok:
                                st.success("Match scheduled!")
                            else:
                                st.error("Failed.")
                            st.rerun()

            with col2:
                st.subheader("Update Score")
                matches = sg("matches", select="match_id,match_date")
                m_opt = {}
                if matches:
                    for m in matches:
                        label = "Match " + str(m["match_id"]) + " (" + m["match_date"][:10] + ")"
                        m_opt[label] = m["match_id"]
                with st.form("upd_score"):
                    m_sel = st.selectbox("Match", list(m_opt.keys()) if m_opt else ["None"])
                    c1, c2 = st.columns(2)
                    score_a = c1.number_input("Home Score", 0, 20, 0)
                    score_b = c2.number_input("Away Score", 0, 20, 0)
                    status = st.selectbox("Status", ["scheduled", "live", "completed"])
                    submitted = st.form_submit_button("Update Score")
                    if submitted:
                        ok = su("matches",
                                {"score_a": score_a, "score_b": score_b, "status": status},
                                "match_id", m_opt.get(m_sel))
                        if ok:
                            st.success("Score updated!")
                        else:
                            st.error("Failed.")
                        st.rerun()

    with tab2:
        st.subheader("Player Statistics")
        data = sg("match_stats",
                  select="goals,assists,yellow_cards,red_cards,minutes_played,players(full_name,teams(team_name))")
        if data:
            agg = {}
            for s in data:
                name = s["players"]["full_name"]
                team = s["players"]["teams"]["team_name"]
                if name not in agg:
                    agg[name] = {"Player": name, "Team": team,
                                 "Goals": 0, "Assists": 0,
                                 "Yellows": 0, "Reds": 0,
                                 "Minutes": 0, "Matches": 0}
                agg[name]["Goals"] += s["goals"]
                agg[name]["Assists"] += s["assists"]
                agg[name]["Yellows"] += s["yellow_cards"]
                agg[name]["Reds"] += s["red_cards"]
                agg[name]["Minutes"] += s["minutes_played"]
                agg[name]["Matches"] += 1
            df = pd.DataFrame(list(agg.values())).sort_values("Goals", ascending=False)
            st.dataframe(df, hide_index=True)

        st.subheader("Add Player Stats")
        matches = sg("matches", select="match_id,match_date", filters={"status": "completed"})
        players = sg("players", select="player_id,full_name")
        m_opt = {}
        if matches:
            for m in matches:
                label = "Match " + str(m["match_id"]) + " (" + m["match_date"][:10] + ")"
                m_opt[label] = m["match_id"]
        p_opt = {p["full_name"]: p["player_id"] for p in players} if players else {}
        with st.form("add_stats"):
            m_sel = st.selectbox("Match", list(m_opt.keys()) if m_opt else ["No completed matches"])
            p_sel = st.selectbox("Player", list(p_opt.keys()) if p_opt else ["None"])
            c1, c2, c3, c4, c5 = st.columns(5)
            goals = c1.number_input("Goals", 0, 20, 0)
            assists = c2.number_input("Assists", 0, 20, 0)
            yc = c3.number_input("Yellows", 0, 2, 0)
            rc = c4.number_input("Reds", 0, 1, 0)
            mins = c5.number_input("Minutes", 0, 120, 90)
            submitted = st.form_submit_button("Save Stats")
            if submitted:
                if m_opt and p_opt:
                    ok = si("match_stats", {
                        "match_id": m_opt.get(m_sel),
                        "player_id": p_opt.get(p_sel),
                        "goals": goals,
                        "assists": assists,
                        "yellow_cards": yc,
                        "red_cards": rc,
                        "minutes_played": mins
                    })
                    if ok:
                        st.success("Stats saved!")
                    else:
                        st.error("Stat already exists for this player and match.")
                    st.rerun()


if not st.session_state.logged_in:
    login_page()
else:
    with st.sidebar:
        st.title("Tournament DB")
        st.caption("User: " + st.session_state.username)
        st.caption("Role: " + st.session_state.group_name)
        st.divider()
        page = st.radio("Navigate", [
            "Dashboard",
            "Tournaments and Teams",
            "Players",
            "Matches and Stats"
        ])
        st.divider()
        if st.button("Logout"):
            st.session_state.logged_in = False
            st.rerun()

    if page == "Dashboard":
        dashboard_page()
    elif page == "Tournaments and Teams":
        tournaments_page()
    elif page == "Players":
        players_page()
    elif page == "Matches and Stats":
        matches_page()