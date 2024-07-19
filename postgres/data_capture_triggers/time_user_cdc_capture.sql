---------- Capturing name and time of data change, written to the cols of the same table -----------
CREATE OR REPLACE FUNCTION record_change_user()
RETURNS TRIGGER AS $$
BEGIN
NEW.modified_by := current_user;
NEW.modified_at := CURRENT_TIMESTAMP;
RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER user_update
BEFORE UPDATE ON transactions
FOR EACH ROW EXECUTE FUNCTION record_change_user();
----------------------------------------------------------------------------------------