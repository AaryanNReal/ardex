import sqlite3

db_path = r"database/data.sqlite"
con = sqlite3.connect(db_path)
cur = con.cursor()

cur.execute("SELECT id, display_name, system_name FROM roles;")
rows = cur.fetchall()
for r in rows:
    print(r)

con.close()
