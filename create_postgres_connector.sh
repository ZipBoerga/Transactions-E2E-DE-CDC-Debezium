curl -X POST -H 'Content-Type: application/json' http://localhost:8083/connectors -d '{
  "name": "postgres-fin-connector",
  "config": {
    "connector.class": "io.debezium.connector.postgresql.PostgresConnector",
    "database.hostname": "postgres",
    "database.port": "5432",
    "database.user": "postgres",
    "database.password": "postgres",
    "database.dbname": "financial_db",
    "table.include.list": "public.transactions",
    "plugin.name": "pgoutput",
    "topic.prefix": "cdc",
    "decimal.handling.mode": "string"
  }
}'
