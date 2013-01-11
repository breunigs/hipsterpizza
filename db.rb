# encoding: utf-8

def table_name
  "d" + Date.today.strftime("%Y%m%d")
end

def order_submitted?
  cols, *rows = $db.execute2("SELECT name FROM sqlite_master WHERE name = 'meta' AND type='table'")
  return false if rows.size == 0
  cols, *rows = $db.execute2("SELECT * FROM meta WHERE tblname = ?", table_name)
  return rows.size > 0
end

def order_submit_date
  return nil unless order_submitted?
  cols, *rows = $db.execute2("SELECT * FROM meta WHERE tblname = ?", table_name)
  return Time.parse(rows[0]["submitted"])
end

def order_mark_submitted
  unless table_exists?("meta")
    $db.execute("CREATE TABLE meta(tblname TEXT PRIMARY KEY, submitted TEXT)")
  end

  $db.execute2("INSERT OR REPLACE INTO meta (tblname, submitted) VALUES (?, ?)", table_name, Time.now.utc.iso8601)
end

def save_order(id, name)
  cols, *rows = $db.execute2("SELECT querystring FROM #{table_name} WHERE id = ? ", id)
  return false, "Order not found" if rows.size == 0

  begin
    unless table_exists?("saved")
      $db.execute("CREATE TABLE saved(name TEXT PRIMARY KEY, querystring TEXT)")
    end

    name = name.gsub(/[^a-z0-9_-]+/i, "_")
    $db.execute2("INSERT OR REPLACE INTO saved (name, querystring) VALUES (?, ?)", name, rows[0]["querystring"])
    return true
  rescue Exception => e
    return false, error(e.message + "\n\n" +  e.backtrace.inspect)
  end
end

def delete_saved_order(name, date)
  return unless table_exists?("saved")
  return unless date_is_valid?(date)
  $db.execute2("DELETE FROM saved WHERE name = ?", name)
end

def table_exists?(tbl = nil)
  tbl = table_name if tbl.nil?
  cols, *rows = $db.execute2("SELECT name FROM sqlite_master WHERE name = '#{tbl}' AND type='table'")
  return rows.size > 0
end

# create table for today if necessary
def ensure_table_exists
  raise "strange date format: #{table_name}" unless table_name.match(/^d[0-9]{8}$/)

  return if table_exists?

  $db.execute("CREATE TABLE #{table_name}(id INTEGER PRIMARY KEY AUTOINCREMENT, paid BOOLEAN, querystring TEXT, nick TEXT)")
end

# tries to parse the order from the query string (?add=xxx)
def add_order_from_query_string(qry)
  return false, error("Error: No data in query string.") if qry.nil? || qry.empty?
  return false, error("The order has already been submitted and yours was not included. Call someone at location and ask nicely.")  if order_submitted?

  begin
    order = JSON.parse(qry)

    if order["nick"].nil? || order["nick"].empty?
      return false, error("Error: no nick specified in query string.")
    end

    if order["items"].empty?
      return false, warning("Warning: no products have been specified.")
    end

    ensure_table_exists
    sql = "INSERT INTO #{table_name} (paid, querystring, nick) VALUES (0, ?, ?)"
    $db.execute(sql, qry, order["nick"])

   cols, *rows =  $db.execute2("SELECT * FROM #{table_name} ORDER BY nick COLLATE NOCASE DESC")
    return true
  rescue Exception => e
    return false, error(e.message + "\n\n" +  e.backtrace.inspect)
  end
end


def remove_order_by_id(ord_id, date)
  return false, error("Invalid date") unless date_is_valid?(date)
  return false, error("Invalid id") unless id_is_valid?(ord_id)
  return false, error("The order has already been submitted. NOW PAY.") if order_submitted?

  begin
    $db.execute("DELETE FROM #{table_name} WHERE id = ?", ord_id)
    return true
  rescue Exception => e
    return false, error(e.message + "\n\n" +  e.backtrace.inspect)
  end
end

def toggle_paid(ord_id, date)
  return false, error("Invalid date") unless date_is_valid?(date)
  return false, error("Invalid id") unless id_is_valid?(ord_id)

  begin
    cols, *rows = $db.execute2("SELECT * FROM #{table_name} WHERE id = ?", ord_id)
    oldpaid = rows[0]["paid"] == 1 ? true : false
    $db.execute("UPDATE #{table_name} SET paid = ? WHERE id = ?", oldpaid ? 0 : 1, ord_id)
    return true
  rescue Exception => e
    return false, error(e.message + "\n\n" +  e.backtrace.inspect)
  end
end

# Setup database
`touch "#{DB_FILE}"` unless File.exist?(DB_FILE)
$db = SQLite3::Database.new(DB_FILE)
$db.results_as_hash = true
