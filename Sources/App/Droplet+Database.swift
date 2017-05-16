import FluentPostgreSQL
import Foundation
import Vapor

extension Droplet {
    enum PostgresError: Error {
        case invalidDatabaseURL
        case missingComponent(String)
    }

    func postgresDatabase() throws -> Database {
        guard let databaseURL = try config.extract("database", "postgres") as String?,
            let components = URLComponents(string: databaseURL)
        else {
            throw PostgresError.invalidDatabaseURL
        }

        let host = components.host ?? "localhost"
        let port = components.port ?? 5432
        let user = components.user ?? ""
        let password = components.password ?? ""

        let dbname: String
        if components.path.characters.count > 1 {
            let startPlusOne = components.path.index(after: components.path.startIndex)
            dbname = components.path.substring(from: startPlusOne)
        } else {
            dbname = "passcards"
        }

        let postgres = PostgreSQLDriver(host: host, port: port, dbname: dbname, user: user, password: password)
        return Database(postgres)
    }
}
