-- Create the transactions table
CREATE TABLE IF NOT EXISTS transactions (
    transaction_id VARCHAR(255) PRIMARY KEY,
    user_id VARCHAR(255),
    timestamp TIMESTAMP,
    amount DECIMAL,
    currency VARCHAR(255),
    city VARCHAR(255),
    country VARCHAR(255),
    merchant_name VARCHAR(255),
    payment_method VARCHAR(255),
    ip_address VARCHAR(255),
    voucher_code VARCHAR(255),
    affiliate_id VARCHAR(255),
    change_details JSONB
);

-- Set replica identity to FULL
ALTER TABLE transactions REPLICA IDENTITY FULL;

-- Function to capture all changes
CREATE OR REPLACE FUNCTION record_changed_columns()
RETURNS TRIGGER AS $$
DECLARE
    change_details JSONB;
    col_name TEXT;  -- Renamed to avoid ambiguity
    old_value TEXT;
    new_value TEXT;
BEGIN
    change_details := '{}'::jsonb; -- Initialize an empty JSONB object

    -- Iterate over each column in the NEW record
    FOR col_name IN
        SELECT column_name
        FROM information_schema.columns
        WHERE table_name = TG_TABLE_NAME
        AND column_name <> 'change_details'
    LOOP
        IF TG_OP = 'UPDATE' THEN
            EXECUTE format('SELECT $1.%I', col_name) INTO old_value USING OLD;
            EXECUTE format('SELECT $1.%I', col_name) INTO new_value USING NEW;
            -- Compare old and new values and record changes if any
            IF old_value IS DISTINCT FROM new_value THEN
                change_details := jsonb_insert(change_details, format('{%s}', col_name)::TEXT[], jsonb_build_object('old', old_value, 'new', new_value));
            END IF;
        ELSIF TG_OP = 'INSERT' THEN
            EXECUTE format('SELECT $1.%I', col_name) INTO new_value USING NEW;
            change_details := jsonb_insert(change_details, format('{%s}', col_name)::TEXT[], jsonb_build_object('new', new_value));
        END IF;
    END LOOP;

    -- Add user and timestamp
    change_details := change_details || jsonb_build_object('modified_by', current_user, 'modified_at', now());

    -- Update the change_details column
    NEW.change_details := change_details;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger for UPDATE
CREATE TRIGGER track_changes_before_update
BEFORE UPDATE ON transactions
FOR EACH ROW
EXECUTE FUNCTION record_changed_columns();

-- Create trigger for INSERT
CREATE TRIGGER track_changes_before_insert
BEFORE INSERT ON transactions
FOR EACH ROW
EXECUTE FUNCTION record_changed_columns();
