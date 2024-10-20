import Foundation

protocol TodoRepository: Sendable {
  func create(title: String, order: Int?, urlPrefix: String) async throws -> Todo

  func get(id: UUID) async throws -> Todo?

  func list() async throws -> [Todo]

  func update(id: UUID, title: String?, order: Int?, completed: Bool?) async throws -> Todo?

  func delete(id: UUID) async throws -> Bool

  func deleteAll() async throws
}

actor MemoryTodoRepository: TodoRepository {
  var todos: [UUID: Todo]

  init() {
    self.todos = [:]
  }

  func create(title: String, order: Int?, urlPrefix: String) async throws -> Todo {
    let id = UUID()
    let url = urlPrefix + id.uuidString

    let newTodo = Todo(id: id, title: title, url: url, order: order)
    self.todos[id] = newTodo

    return newTodo
  }

  func get(id: UUID) async throws -> Todo? {
    return self.todos[id]
  }

  func list() async throws -> [Todo] {
    return self.todos.values.map { $0 }
  }

  func update(id: UUID, title: String?, order: Int?, completed: Bool?) async throws -> Todo? {
    guard var todo = self.todos[id] else {
      return nil
    }

    if let title {
      todo.title = title
    }
    if let completed {
      todo.completed = completed
    }

    todo.order = order
    self.todos[id] = todo

    return todo
  }

  func delete(id: UUID) async throws -> Bool {
    guard self.todos.removeValue(forKey: id) != nil else {
      return false
    }
    return true
  }

  func deleteAll() async throws {
    self.todos = [:]
  }
}
