import FluentPostgreSQL
import Vapor

extension Droplet {
    func postgresDatabase() -> Database {
        let postgresConfig = config["database", "postgres"]

        let host = postgresConfig?["host"]?.string ?? "localhost"
        let port = postgresConfig?["port"]?.int ?? 5432
        let dbname = postgresConfig?["dbname"]?.string ?? "passcards"
        let user = postgresConfig?["user"]?.string ?? ""
        let password = postgresConfig?["password"]?.string ?? ""

        let postgres = PostgreSQLDriver(host: host, port: port, dbname: dbname, user: user, password: password)
        return Database(postgres)
    }
}
