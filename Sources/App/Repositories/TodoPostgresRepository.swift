import Foundation
import PostgresNIO

struct TodoPostgresRepository: TodoRepository {
  let client: PostgresClient
  let logger: Logger

  func createTable() async throws {
    try await self.client.query(
      """
      CREATE TABLE IF NOT EXISTS todos (
      	"id" UUID PRIMARY KEY,
      	"title" VARCHAR NOT NULL,
      	"url" VARCHAR NOT NULL,
      	"order" INT,
      	"completed" BOOLEAN NOT NULL DEFAULT FALSE
      )
      """,
      logger: self.logger
    )
  }

  typealias TodoRow = (UUID, String, String, Int?, Bool)

  private func runQuery(_ query: PostgresQuery) async throws -> AsyncThrowingMapSequence<PostgresRowSequence, TodoRow> {
    let stream = try await self.client.query(query, logger: logger)

    return stream.decode(TodoRow.self, context: .default)
  }

  func create(title: String, order: Int?, urlPrefix: String) async throws -> Todo {
    let id = UUID()
    let url = urlPrefix + id.uuidString

    _ = try await runQuery(
      """
      INSERT INTO todos (id, title, url, "order")
      VALUES (\(id), \(title), \(url), \(order))
      RETURNING id, title, url, "order", completed;
      """
    )

    return Todo(id: id, title: title, url: url, order: order)
  }

  func get(id: UUID) async throws -> Todo? {
    let rows = try await runQuery(
      """
      SELECT id, title, url, "order", completed FROM todos WHERE id = \(id);
      """
    )

    for try await (id, title, url, order, completed) in rows {
      return Todo(id: id, title: title, url: url, order: order, completed: completed)
    }

    return nil
  }

  func list() async throws -> [Todo] {
    var todos: [Todo] = []

    let rows = try await runQuery(#"SELECT id, title, url, "order", completed FROM todos;"#)
    for try await (id, title, url, order, completed) in rows {
      let todo = Todo(id: id, title: title, url: url, order: order, completed: completed)
      todos.append(todo)
    }

    return todos
  }

  func update(id: UUID, title: String?, order: Int?, completed: Bool?) async throws -> Todo? {
    let query: PostgresQuery

    switch (title, order, completed) {
      case (.none, .none, .none):
        return nil
      case let (title?, order?, completed?):
        query = """
          UPDATE todos
            SET title = \(title), "order" = \(order), completed = \(completed)
          WHERE id = \(id)
          RETURNING id, title, url, "order", completed;
          """
        break
      case let (title?, order?, .none):
        query = """
          UPDATE todos
            SET title = \(title), "order" = \(order)
          WHERE id = \(id)
          RETURNING id, title, url, "order", completed;
          """
        break
      case let (title?, .none, completed?):
        query = """
          UPDATE todos
            SET title = \(title), completed = \(completed)
          WHERE id = \(id)
          RETURNING id, title, url, "order", completed;
          """
        break
      case let (title?, .none, .none):
        query = """
          UPDATE todos
            SET title = \(title)
          WHERE id = \(id)
          RETURNING id, title, url, "order", completed;
          """
        break
      case let (.none, order?, completed?):
        query = """
          UPDATE todos
            SET "order" = \(order), completed = \(completed)
          WHERE id = \(id)
          RETURNING id, title, url, "order", completed;
          """
        break
      case let (.none, .none, completed?):
        query = """
          UPDATE todos
            SET completed = \(completed)
          WHERE id = \(id)
          RETURNING id, title, url, "order", completed;
          """
        break
      case let (.none, order?, .none):
        query = """
          UPDATE todos
            SET "order" = \(order)
          WHERE id = \(id)
          RETURNING id, title, url, "order", completed;
          """
        break
    }

    let rows = try await runQuery(query)
    for try await (id, title, url, order, completed) in rows {
      return Todo(id: id, title: title, url: url, order: order, completed: completed)
    }

    return nil
  }

  func delete(id: UUID) async throws -> Bool {
    let rows = try await runQuery("DELETE FROM todos WHERE id = \(id);")
    for try await _ in rows {
      return true
    }
    return false
  }

  func deleteAll() async throws {
    _ = try await runQuery("DELETE FROM todos;")
  }
}
