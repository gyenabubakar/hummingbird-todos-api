import Foundation
import Hummingbird

struct TodoController<Repository: TodoRepository> {
  var repository: Repository

  var endpoints: RouteCollection<AppRequestContext> {
    return RouteCollection(context: AppRequestContext.self)
      .get(":id", use: get)
      .get(use: list)
      .patch(":id", use: update)
      .post(use: create)
      .delete(":id", use: delete)
      .delete(use: deleteAll)

  }

  @Sendable func get(request: Request, context: some RequestContext) async throws -> Todo? {
    let id = try context.parameters.require("id", as: UUID.self)
    return try await self.repository.get(id: id)
  }

  @Sendable func list(request: Request, context: some RequestContext) async throws -> [Todo] {
    return try await self.repository.list()
  }

  @Sendable func create(request: Request, context: some RequestContext) async throws -> EditedResponse<Todo> {
    let body = try await request.decode(as: CreateTodoDTO.self, context: context)
    let todo = try await self.repository.create(
      title: body.title,
      order: body.order,
      urlPrefix: "http://localhost:8080/todos/"
    )
    return EditedResponse(status: .created, response: todo)
  }

  @Sendable func update(request: Request, context: some RequestContext) async throws -> EditedResponse<Todo> {
    let id = try context.parameters.require("id", as: UUID.self)
    let body = try await request.decode(as: UpdateTodoDTO.self, context: context)
    let updatedTodo = try await self.repository.update(
      id: id,
      title: body.title,
      order: body.order,
      completed: body.completed
    )

    guard let updatedTodo else {
      throw HTTPError(.badRequest)
    }

    return EditedResponse(status: .created, response: updatedTodo)
  }

  @Sendable func delete(request: Request, context: some RequestContext) async throws -> HTTPResponse.Status {
    let id = try context.parameters.require("id", as: UUID.self)
    let isDeleted = try await self.repository.delete(id: id)
    if isDeleted { return .ok }
    return .badRequest
  }

  @Sendable func deleteAll(request: Request, context: some RequestContext) async throws -> HTTPResponse.Status {
    try await self.repository.deleteAll()
    return .ok
  }
}
