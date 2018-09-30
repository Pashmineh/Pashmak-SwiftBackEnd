import Vapor
import FluentPostgreSQL
import Authentication

/// Called before your application initializes.
public func configure(_ config: inout Config, _ env: inout Environment, _ services: inout Services) throws {
  
  try services.register(FluentPostgreSQLProvider())
  try services.register(AuthenticationProvider())
  
  /// Register routes to the router
  let router = EngineRouter.default()
  try routes(router)
  services.register(router, as: Router.self)
  
  /// Register middleware
  var middlewares = MiddlewareConfig() // Create _empty_ middleware config
  /// middlewares.use(FileMiddleware.self) // Serves files from `Public/` directory
  middlewares.use(ErrorMiddleware.self) // Catches errors and converts to HTTP response
  services.register(middlewares)
  
  var databases = DatabasesConfig()
  
  // PostgreSQL
  let postgres = PostgreSQLDatabase(config: PostgreSQLDatabaseConfig(hostname: "localhost",
                                                                     port: 5432,
                                                                     username: "postgres",
                                                                     database: nil,
                                                                     password: "Ala123456",
                                                                     transport: PostgreSQLConnection.TransportConfig.cleartext))
  
  databases.add(database: postgres, as: .psql)
  services.register(databases)
  
  var migrations = MigrationConfig()
  migrations.add(model: User.self, database: .psql)
  migrations.add(model: UserToken.self, database: .psql)
  migrations.add(model: Debt.self, database: .psql)
  services.register(migrations)
}
