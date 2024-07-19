------------------- Capturing all the details of data change in a col change_details ----------------------------
CREATE OR REPLACE FUNCTION record_changed_columns()
RETURNS TRIGGER AS $$
DECLARE
    change_details JSONB;
    column_name TEXT;
    old_value TEXT;
    new_value TEXT;
BEGIN
    change_details := '{}'::JSONB

    FOR column_name in
        SELECT column_name
        FROM information_schema.columns
        WHERE table_name = TG_TABLE_NAME
        AND column_name <> 'change_details'
    LOOP
        IF TG_OP = 'UPDATE' THEN
            EXECUTE format('SELECT $1.%I', column_name) INTO old_value USING OLD;
            EXECUTE format('SELECT $1.%I', column_name) INTO new_value USING NEW;
            IF old_value IS DISTINCT FROM new_value THEN
                change_details := jsonb_insert(change_details, format('{%s}', column_name)::TEXT[], jsonb_build_object('old', old_value, 'new', new_value));
            END IF;
        ELSIF TG_OP = 'INSERT' THEN
            EXECUTE format('SELECT $1.%I', column_name) INTO new_value USING NEW;
            change_details := jsonb_insert(change_details, format('{%s}', column_name)::TEXT[], jsonb_build_object('new', new_value));
        END IF;
    END LOOP;

    change_details := change_details || jsonb_build_object('modified_by', current_user, 'modified_at', now());

    NEW.change_details := change_details;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql

CREATE TRIGGER track_changes_before_update
BEFORE UPDATE ON transactions
FOR EACH ROW EXECUTE FUNCTION record_changed_columns();

CREATE TRIGGER track_changes_before_insert
BEFORE INSERT ON transactions
FOR EACH ROW EXECUTE FUNCTION record_changed_columns();
------------------------------------------------------------------------------------------------------------
