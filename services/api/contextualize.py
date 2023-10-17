"""
contextualize.py

Maintainer: Wes Kennedy
Description: The contextualize module allows us to write app specific queries to help build our database.
"""

import db
from sqlalchemy import *

class Contextualizer():
    def __init__():
        pass

    def customer_lookup_byid(customer_id):
        """
        Takes a customer id and returns the customer's name
        """
        pass

    def customer_lookup_byname(customer_name):
        """
        Takes a customer name and returns the customer's id
        """
        pass

    def customer_lookup_byemail(customer_email):
        """
        Takes a customer email and returns the customer's id
        """
        pass

    def customer_previous_orders(db_conn, customer_id):
        """
        Takes a customer id and returns a list of previous orders
        """
        orders = []
        query = text(f"SELECT * FROM orders WHERE customer_id = {customer_id}")
        response = db.query_wrapper(db_conn, query)

        return orders