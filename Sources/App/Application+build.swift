import Hummingbird
import Logging
import PostgresNIO

/// Application arguments protocol. We use a protocol so we can call
/// `buildApplication` inside Tests as well as in the App executable.
/// Any variables added here also have to be added to `App` in App.swift and
/// `TestArguments` in AppTest.swift
public protocol AppArguments {
  var hostname: String { get }
  var port: Int { get }
  var logLevel: Logger.Level? { get }
  var inMemoryTesting: Bool { get }
}

// Request context used by application
typealias AppRequestContext = BasicRequestContext

///  Build application
/// - Parameter arguments: application arguments
public func buildApplication(_ arguments: some AppArguments) async throws -> some ApplicationProtocol {
  let environment = Environment()

  let logger = {
    var logger = Logger(label: "HummingbirdTodos")
    logger.logLevel = arguments.logLevel ?? environment.get("LOG_LEVEL").flatMap { Logger.Level(rawValue: $0) } ?? .info
    return logger
  }()

  var postgresRepository: TodoPostgresRepository?
  let router: Router<AppRequestContext>

  if !arguments.inMemoryTesting {
    let dbHost = environment.get("DB_HOST") ?? "localhost"
    let dbPort = Int(environment.get("DB_PORT") ?? "5432") ?? 5432
    let dbUsername = environment.get("DB_USERNAME") ?? "todos_user"
    let dbPassword = environment.get("DB_PASSWORD") ?? "todos_password"
    let dbName = environment.get("DB_NAME") ?? "hummingbird_todos"

    let client = PostgresClient(
      configuration: .init(
        host: dbHost,
        port: dbPort,
        username: dbUsername,
        password: dbPassword,
        database: dbName,
        tls: .disable
      ),
      backgroundLogger: logger
    )

    let respository = TodoPostgresRepository(client: client, logger: logger)

    postgresRepository = respository
    router = buildRouter(respository)
  } else {
    router = buildRouter(MemoryTodoRepository())
  }

  var app = Application(
    router: router,
    configuration: .init(
      address: .hostname(arguments.hostname, port: arguments.port),
      serverName: "HummingbirdTodos"
    ),
    logger: logger
  )

  if let postgresRepository {
    app.addServices(postgresRepository.client)
    app.beforeServerStarts {
      try await postgresRepository.createTable()
    }
  }

  return app
}

/// Build router
func buildRouter(_ repository: some TodoRepository) -> Router<AppRequestContext> {
  let router = Router(context: AppRequestContext.self)

  // Add middleware
  router.addMiddleware {
    // logging middleware
    LogRequestsMiddleware(.info)
  }

  // Add default endpoint
  router.get("/health") { _, _ -> HTTPResponse.Status in
    .ok
  }

  router.addRoutes(TodoController(repository: repository).endpoints, atPath: "/todos")

  return router
}
