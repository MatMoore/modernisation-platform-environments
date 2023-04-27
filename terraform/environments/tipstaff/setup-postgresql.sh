#!/bin/bash

export PGPASSWORD=$TIPSTAFF_DB_PASSWORD_DEV;
# if database contains schema dbo then store schema name inside variable.
SCHEMA=$(psql -h ${DB_HOSTNAME} -p 5432 -U $TIPSTAFF_DB_USERNAME_DEV -d $DB_NAME -c "SELECT schema_name FROM information_schema.schemata WHERE schema_name = 'dbo'" | grep -o 'dbo') 
echo "Schema = $SCHEMA"

if [ "$SCHEMA" == "dbo" ]; then 
    echo "The Schema dbo is already present in the database"
else 
    psql -h ${DB_HOSTNAME} -p 5432 -U $TIPSTAFF_DB_USERNAME_DEV -d $DB_NAME -c "\i tftipstaffDB-backup-clean.sql;";
fi

