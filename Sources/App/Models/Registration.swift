import Fluent

class Registration: Entity {
    var id: Node?
    var passId: Node?
    var deviceLibraryIdentifier: String?
    var deviceToken: String?

    var exists = false
    
    func pass() throws -> Parent<Pass> {
        return try parent(passId)
    }

    init() {
    }

    static func prepare(_ database: Database) throws {
        try database.create(entity) { builder in
            builder.id()
            builder.parent(Pass.self)
            builder.string("device_library_identifier")
            builder.string("device_token")
        }
    }

    static func revert(_ database: Database) throws {
        try database.delete(entity)
    }

    required init(node: Node, in context: Context) throws {
        id = try node.extract("id")
        passId = try node.extract("pass_id")
        deviceLibraryIdentifier = try node.extract("device_library_identifier")
        deviceToken = try node.extract("device_token")
    }

    func makeNode(context: Context) throws -> Node {
        return try Node(node: [
            "id": id,
            "pass_id": passId,
            "device_library_identifier": deviceLibraryIdentifier,
            "device_token": deviceToken,
        ])
    }
}
