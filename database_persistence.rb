require "pg"

class DatabasePersistence
  def initialize(logger)
    @logger = logger
    @db = if Sinatra::Base.production?
      PG.connect(ENV['DATABASE_URL'])
    else
      PG.connect(dbname: "todos")
    end
  end
  
  def query(statement, *params) #*params passes an array
    @logger.info "#{statement}: #{params}"
    @db.exec_params(statement, params)
  end 

  def find_list(id)
    sql = "SELECT * FROM lists WHERE id = $1"
    result = query(sql, id)
    tuple = result.first
    list_id = tuple["id"].to_i
    todo_result = all_todos(list_id)
    {id: tuple["id"], name: tuple["name"], todos: todo_result }
  end

  def all_lists
    sql = "SELECT * FROM lists"
    result = query(sql)
   # todos:[{name: "", completed: false}]
    result.map do |tuple|
      list_id = tuple["id"].to_i
      todo_result = all_todos(list_id)
      
      {id: list_id, name: tuple["name"], todos: todo_result }
    end 
  end

  def create_new_list(list_name)
    sql = "INSERT INTO lists (name) VALUES ($1)"
    query(sql, list_name)
  end

  def delete_list(id)
    query("DELETE FROM todos WHERE list_id = $1", id)
    query("DELETE FROM lists WHERE id = $1", id)  
  end

  def update_list_name(id, new_name)
    sql = "UPDATE lists SET name = $2 WHERE id = $1"
    query(sql, id, new_name)
  end

  def create_new_todo(list_id, todo_name)
    sql = "INSERT INTO todos (name, list_id) VALUES ($1, $2)"
    query(sql, todo_name, list_id)
  end

  def delete_todo_from_list(list_id, todo_id)
    sql = "DELETE FROM todos WHERE list_id = $1 AND id = $2"
    query(sql, list_id, todo_id)
  end

  def update_todo_status(list_id, todo_id, new_status)
    sql = "UPDATE todos SET completed = $1 WHERE list_id = $2 AND id = $3"
    query(sql, new_status, list_id, todo_id)
  end

  def mark_all_todos_as_completed(list_id)
    sql = "UPDATE todos SET completed = true WHERE list_id = $1"
    query(sql, list_id)
  end

  private

  def all_todos(list_id)
    sql = "SELECT * FROM todos WHERE list_id = $1"
    todos_result = query(sql, list_id)
    todos_result.map do |tuple|
      {id: tuple["id"], 
      name: tuple["name"],
      completed: tuple["completed"] == 't'}
    end 
  end 
 
  def disconnect
    @db.close
  end

end