import os
# add the ability to query a mysql server using sql_alchemy
from sqlalchemy import *
from sqlalchemy_utils import database_exists

MYSQL_HOST = os.getenv("MYSQL_HOST")
MYSQL_PORT = os.getenv("MYSQL_PORT")
MYSQL_USER = os.getenv("MYSQL_USER")
MYSQL_PASSWORD = os.getenv("MYSQL_PASSWORD")
MYSQL_DATABASE = os.getenv("MYSQL_DATABASE")



def init_connect():
    # Create the connection string
    connection_string = f"mysql+pymysql://{MYSQL_USER}:{MYSQL_PASSWORD}@{MYSQL_HOST}:{MYSQL_PORT}"
    full_engine = f"{connection_string}/{MYSQL_DATABASE}"
    engine = create_engine(connection_string)
    if database_exists(full_engine):
        return engine
    else:
        with engine.connect() as conn:
            init_db(conn)
            return engine

    # Create the engine
def simple_connect():
    pass

def init():
    db_conn = init_connect()
    use_db(db_conn)
    init_chat_table(db_conn)
    return db_conn

def init_db(db_conn):
    query_create_db = text(f"CREATE DATABASE {MYSQL_DATABASE}") #create db
    with db_conn.connect() as conn:
        conn.execute(query_create_db)

def use_db(db_conn):
    use_db = text(f"USE {MYSQL_DATABASE}")
    with db_conn.connect() as conn:
        conn.execute(use_db)
        
def init_chat_table(db_conn):
    create_chat_table = text(f"CREATE TABLE IF NOT EXISTS messages (_id INT AUTO_INCREMENT,conversation_id CHAR(255),message TEXT,sender VARCHAR(50),timestamp TIMESTAMP,chat_context JSON,user_context TEXT,embedding BLOB NOT NULL, PRIMARY KEY (_id));")
    with db_conn.connect() as conn:
        conn.execute(create_chat_table)

def query_wrapper(db_conn, query):
    with db_conn.connect() as conn:
        result = conn.execute(query)
        return result
