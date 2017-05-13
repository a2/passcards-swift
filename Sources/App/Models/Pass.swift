import Foundation
import Fluent

class Pass: Entity {
    var id: Node?
    var authenticationToken: String?
    var passTypeIdentifier: String?
    var serialNumber: String?
    var passPath: String?
    var vanityName: String?
    var updatedAt: Date?

    var exists = false

    func registrations() -> Children<Registration> {
        return children()
    }

    init() {
    }
    
    static var entity: String {
        return "passes"
    }

    static func prepare(_ database: Database) throws {
        try database.create(entity) { builder in
            builder.id()
            builder.string("authentication_token")
            builder.string("pass_type_identifier")
            builder.string("serial_number")
            builder.string("pass_path")
            builder.string("vanity_name")
            builder.double("updated_at")
        }
    }

    static func revert(_ database: Database) throws {
        try database.delete(entity)
    }

    required init(node: Node, in context: Context) throws {
        id = try node.extract("id")
        authenticationToken = try node.extract("authentication_token")
        passTypeIdentifier = try node.extract("pass_type_identifier")
        serialNumber = try node.extract("serial_number")
        passPath = try node.extract("pass_path")
        vanityName = try node.extract("vanity_name")
        updatedAt = (try node.extract("updated_at")).map { ti in Date(timeIntervalSince1970: ti) }
    }

    func makeNode(context: Context) throws -> Node {
        return try Node(node: [
            "id": id,
            "authentication_token": authenticationToken,
            "pass_type_identifier": passTypeIdentifier,
            "serial_number": serialNumber,
            "pass_path": passPath,
            "vanity_name": vanityName,
            "updated_at": updatedAt?.timeIntervalSince1970,
        ])
    }
}

