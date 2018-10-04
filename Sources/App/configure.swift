import Redis
import Vapor
import FluentPostgreSQL
import Authentication

/// Called before your application initializes.
public func configure(_ config: inout Config, _ env: inout Environment, _ services: inout Services) throws {
  
  try services.register(FluentPostgreSQLProvider())
  try services.register(AuthenticationProvider())
  try services.register(RedisProvider())
  
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
  let postgres = PostgreSQLDatabase(config: PostgreSQLDatabaseConfig(hostname: "178.62.20.28",
                                                                     port: 5432,
                                                                     username: "postgres",
                                                                     database: nil,
                                                                     password: "Ala123456",
                                                                     transport: PostgreSQLConnection.TransportConfig.cleartext))
  
  databases.add(database: postgres, as: .psql)
  
  // Redis
  let redis = try RedisDatabase(config: RedisClientConfig(url: URL(string: "178.62.20.28:6379")!))
  databases.add(database: redis, as: .redis)
  
  services.register(databases)
  
  var migrations = MigrationConfig()
  migrations.add(model: Models.User.self, database: .psql)
  migrations.add(model: Models.Device.self, database: .psql)
  migrations.add(model: Models.UserToken.self, database: .psql)
  migrations.add(model: Models.Checkin.self, database: .psql)
  migrations.add(model: Models.Event.self, database: .psql)
  migrations.add(model: Models.Transaction.self, database: .psql)
  migrations.add(model: Models.Message.self, database: .psql)
  migrations.add(model: Models.Address.self, database: .psql)
  migrations.add(model: Models.Poll.self, database: .psql)
  migrations.add(model: Models.PollItem.self, database: .psql)
  services.register(migrations)
}
