#!/bin/bash
# SOAT Connect Lawyer Registry - Database Deployment Script
# Deploys the schema to Supabase

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}SOAT Connect - Lawyer Registry Schema${NC}"
echo -e "${GREEN}========================================${NC}"

# Check for required environment variables
if [ -z "$SUPABASE_URL" ] || [ -z "$SUPABASE_KEY" ]; then
    echo -e "${YELLOW}Warning: SUPABASE_URL and/or SUPABASE_KEY not set${NC}"
    echo "Please set these environment variables or enter them now:"
    
    read -p "SUPABASE_URL: " SUPABASE_URL
    read -p "SUPABASE_KEY (service role): " SUPABASE_KEY
    
    export SUPABASE_URL
    export SUPABASE_KEY
fi

# Get the script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCHEMA_FILE="${SCRIPT_DIR}/schema.sql"

if [ ! -f "$SCHEMA_FILE" ]; then
    echo -e "${RED}Error: schema.sql not found at ${SCHEMA_FILE}${NC}"
    exit 1
fi

echo -e "\n${YELLOW}Deployment Options:${NC}"
echo "1) Deploy via Supabase CLI (recommended)"
echo "2) Manual deployment instructions"
echo "3) Deploy via Python script"
read -p "Select option (1-3): " option

case $option in
    1)
        # Check for Supabase CLI
        if ! command -v supabase &> /dev/null; then
            echo -e "${YELLOW}Supabase CLI not found. Installing...${NC}"
            npm install -g supabase
        fi
        
        echo -e "\n${YELLOW}Running Supabase migration...${NC}"
        
        # Create migrations directory if it doesn't exist
        mkdir -p "${SCRIPT_DIR}/supabase/migrations"
        
        # Copy schema to migrations
        TIMESTAMP=$(date +%Y%m%d%H%M%S)
        cp "$SCHEMA_FILE" "${SCRIPT_DIR}/supabase/migrations/${TIMESTAMP}_lawyer_registry_schema.sql"
        
        echo -e "${GREEN}Migration file created: ${TIMESTAMP}_lawyer_registry_schema.sql${NC}"
        echo -e "${YELLOW}Run 'supabase db push' in your Supabase project to apply${NC}"
        ;;
    2)
        echo -e "\n${YELLOW}Manual Deployment Instructions:${NC}"
        echo "1. Go to your Supabase Dashboard: https://supabase.com/dashboard"
        echo "2. Select your project"
        echo "3. Go to SQL Editor"
        echo "4. Copy the contents of schema.sql"
        echo "5. Paste and run the query"
        echo ""
        echo -e "${GREEN}Schema file location: ${SCHEMA_FILE}${NC}"
        ;;
    3)
        echo -e "\n${YELLOW}Installing Python dependencies...${NC}"
        pip install -r "${SCRIPT_DIR}/requirements.txt"
        
        echo -e "\n${YELLOW}Running deployment script...${NC}"
        python "${SCRIPT_DIR}/database.py" deploy
        ;;
    *)
        echo -e "${RED}Invalid option${NC}"
        exit 1
        ;;
esac

echo -e "\n${GREEN}========================================${NC}"
echo -e "${GREEN}Deployment complete!${NC}"
echo -e "${GREEN}========================================${NC}"
