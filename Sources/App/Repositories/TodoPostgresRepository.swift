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

  func create(title: String, order: Int?, urlPrefix: String) async throws -> Todo {
    let id = UUID()
    let url = urlPrefix + id.uuidString

    try await self.client.query(
      """
      INSERT INTO todos (id, title, url, "order")
      VALUES (\(id), \(title), \(url), \(order));
      """
    )

    return Todo(id: id, title: title, url: url, order: order)
  }

  func get(id: UUID) async throws -> Todo? {
    nil
  }

  func list() async throws -> [Todo] {
    []
  }

  func update(id: UUID, title: String?, order: Int?, completed: Bool?)
    async throws -> Todo?
  {
    nil
  }

  func delete(id: UUID) async throws -> Bool {
    false
  }

  func deleteAll() async throws {

  }
}
