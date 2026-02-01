"""
Database operations helper for SOAT Connect Lawyer Registry.
"""
import os
from supabase import create_client, Client
from typing import Optional

# Environment variables
SUPABASE_URL = os.getenv("SUPABASE_URL", "")
SUPABASE_KEY = os.getenv("SUPABASE_KEY", "")


def get_supabase_client() -> Client:
    """Get Supabase client instance."""
    if not SUPABASE_URL or not SUPABASE_KEY:
        raise ValueError("SUPABASE_URL and SUPABASE_KEY environment variables must be set")
    return create_client(SUPABASE_URL, SUPABASE_KEY)


def execute_schema(schema_file: str = "schema.sql") -> bool:
    """
    Execute the schema SQL file against Supabase.
    Note: This requires the service role key for DDL operations.
    """
    try:
        client = get_supabase_client()
        
        with open(schema_file, 'r') as f:
            schema_sql = f.read()
        
        # Split into individual statements
        statements = [s.strip() for s in schema_sql.split(';') if s.strip()]
        
        for statement in statements:
            if statement and not statement.startswith('--'):
                # Execute each statement
                client.postgrest.rpc('exec_sql', {'query': statement}).execute()
        
        print("Schema executed successfully!")
        return True
        
    except Exception as e:
        print(f"Error executing schema: {e}")
        return False


def verify_table_exists(table_name: str = "abogados") -> bool:
    """Verify that the table exists in the database."""
    try:
        client = get_supabase_client()
        # Try to select from the table
        result = client.table(table_name).select("id").limit(1).execute()
        print(f"Table '{table_name}' exists and is accessible.")
        return True
    except Exception as e:
        print(f"Table '{table_name}' does not exist or is not accessible: {e}")
        return False


if __name__ == "__main__":
    import sys
    
    if len(sys.argv) > 1:
        if sys.argv[1] == "verify":
            verify_table_exists()
        elif sys.argv[1] == "deploy":
            execute_schema()
    else:
        print("Usage: python database.py [verify|deploy]")
