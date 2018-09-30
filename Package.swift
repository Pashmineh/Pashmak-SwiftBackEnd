// swift-tools-version:4.0
import PackageDescription

let package = Package(
  name: "Pashmak-SwiftBackEnd",
  dependencies: [
    
    // 💧 A server-side Swift web framework.
    .package(url: "https://github.com/vapor/vapor.git", from: "3.0.0"),
    
    // 👤 Authentication and Authorization layer for Fluent.
    .package(url: "https://github.com/vapor/auth.git", from: "2.0.0"),
    
    // 🔏 JSON Web Token signing and verification (HMAC, RSA).
    .package(url: "https://github.com/vapor/jwt.git", from: "3.0.0"),
    
    // 🖋🐘 Swift ORM (queries, models, relations, etc) built on PostgreSQL.
    .package(url: "https://github.com/vapor/fluent-postgresql.git", from: "1.0.0"),
    
    
    ],
  targets: [
    .target(name: "App", dependencies: ["Vapor", "Authentication", "JWT", "FluentPostgreSQL"]),
    .target(name: "Run", dependencies: ["App"]),
    .testTarget(name: "AppTests", dependencies: ["App"])
  ]
)

