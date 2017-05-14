import Foundation
import HTTP
import Routing
import Storage
import Vapor

final class WalletCollection: RouteCollection, EmptyInitializable {
    typealias Wrapped = HTTP.Responder

    init() {
    }

    func findPass(passTypeIdentifier: String, serialNumber: String) throws -> Pass? {
        return try Pass.query()
            .filter("pass_type_identifier", passTypeIdentifier)
            .filter("serial_number", serialNumber)
            .first()
    }

    func findRegistration(pass: Pass, deviceLibraryIdentifier: String) throws -> Registration? {
        return try Registration.query()
            .filter("device_library_identifier", deviceLibraryIdentifier)
            .filter("pass_id", pass.id!)
            .first()
    }

    func isAuthenticated(request: Request, pass: Pass) -> Bool {
        if let authorization = request.headers[.authorization], let authenticationToken = pass.authenticationToken {
            return authorization == "ApplePass \(authenticationToken)"
        } else {
            return false
        }
    }

    func registerDevice(pass: Pass, deviceLibraryIdentifier: String, pushToken: String) throws -> Bool {
        let registration: Registration
        let created: Bool
        do {
            let existingRegistration = try Registration.query()
                .filter("device_library_identifier", deviceLibraryIdentifier)
                .filter("pass_id", pass.id!)
                .first()
            if let existingRegistration = existingRegistration {
                registration = existingRegistration
                created = false
            } else {
                registration = Registration()
                registration.deviceLibraryIdentifier = deviceLibraryIdentifier
                registration.passId = pass.id
                created = true
            }
        }

        registration.deviceToken = pushToken
        try registration.save()

        return created
    }

    func registeredSerialNumbers(deviceLibraryIdentifier: String, passTypeIdentifier: String, passesUpdatedSince: Date?) throws -> (serialNumbers: [String], lastUpdated: Date) {
        let query = try Pass.query()
            .union(Registration.self, localKey: "id", foreignKey: "pass_id")
            .filter(Registration.self, "device_library_identifier", deviceLibraryIdentifier)
            .filter("pass_type_identifier", passTypeIdentifier)

        if let passesUpdatedSince = passesUpdatedSince {
            try query.filter("updated_at", .greaterThan, passesUpdatedSince.timeIntervalSince1970)
        }

        var lastUpdated: Date?
        var serialNumbers = [String]()
        for pass in try query.all() {
            if let serialNumber = pass.serialNumber, let updatedAt = pass.updatedAt {
                if lastUpdated == nil {
                    lastUpdated = updatedAt
                } else if lastUpdated != nil && updatedAt > lastUpdated! {
                    lastUpdated = updatedAt
                }

                serialNumbers.append(serialNumber)
            }
        }

        return (serialNumbers, lastUpdated ?? Date())
    }

    func log(messages: [String]) {
        for message in messages {
            print(message)
        }
    }

    func build<B: RouteBuilder>(_ builder: B) where B.Value == Wrapped {
        builder.group("v1") { v1 in
            v1.group("devices", ":deviceLibraryIdentifier") { devices in
                devices.group("registrations") { registrations in
                    registrations.get(String.self) { request, passTypeIdentifier in
                        let passesUpdatedSince: Date?
                        if let dateString = try request.query?.extract("passesUpdatedSince") as String? {
                            passesUpdatedSince = iso8601DateFormatter.date(from: dateString)
                        } else {
                            passesUpdatedSince = nil
                        }

                        let deviceLibraryIdentifier = try request.parameters.extract("deviceLibraryIdentifier") as String
                        let (serialNumbers, lastUpdated) = try self.registeredSerialNumbers(deviceLibraryIdentifier: deviceLibraryIdentifier, passTypeIdentifier: passTypeIdentifier, passesUpdatedSince: passesUpdatedSince)
                        let serialNumbersNode = Node.array(serialNumbers.map(Node.string))

                        return try JSON(node: [
                            "lastUpdated": iso8601DateFormatter.string(from: lastUpdated),
                            "serialNumbers": serialNumbersNode,
                        ])
                    }

                    registrations.post(String.self, String.self) { request, passTypeIdentifier, serialNumber in
                        guard let pushToken = try request.json?.extract("pushToken") as String? else {
                            return Response(status: .badRequest)
                        }

                        guard let pass = try self.findPass(passTypeIdentifier: passTypeIdentifier, serialNumber: serialNumber) else {
                            return Response(status: .notFound)
                        }

                        guard self.isAuthenticated(request: request, pass: pass) else {
                            return Response(status: .unauthorized)
                        }

                        let deviceLibraryIdentifier = try request.parameters.extract("deviceLibraryIdentifier") as String
                        let created = try self.registerDevice(pass: pass, deviceLibraryIdentifier: deviceLibraryIdentifier, pushToken: pushToken)
                        return Response(status: created ? .created : .ok)
                    }

                    registrations.delete(String.self, String.self) { request, passTypeIdentifier, serialNumber in
                        guard let pass = try self.findPass(passTypeIdentifier: passTypeIdentifier, serialNumber: serialNumber) else {
                            return Response(status: .notFound)
                        }

                        guard self.isAuthenticated(request: request, pass: pass) else {
                            return Response(status: .unauthorized)
                        }

                        let deviceLibraryIdentifier = try request.parameters.extract("deviceLibraryIdentifier") as String
                        guard let registration = try self.findRegistration(pass: pass, deviceLibraryIdentifier: deviceLibraryIdentifier) else {
                            return Response(status: .notFound)
                        }

                        try registration.delete()
                        return Response(status: .ok)
                    }
                }
            }

            v1.group("passes") { passes in
                passes.get(String.self, String.self) { request, passTypeIdentifier, serialNumber in
                    guard let pass = try self.findPass(passTypeIdentifier: passTypeIdentifier, serialNumber: serialNumber) else {
                        return Response(status: .notFound)
                    }

                    guard self.isAuthenticated(request: request, pass: pass) else {
                        return Response(status: .unauthorized)
                    }

                    let updatedAt = pass.updatedAt ?? Date()
                    if let dateString = request.headers[.lastModified], let date = rfc2616DateFormatter.date(from: dateString), date > updatedAt {
                        return Response(status: .notModified)
                    }

                    guard let passPath = pass.passPath else {
                        return Response(status: .noContent)
                    }

                    let headers: [HeaderKey: String] = [
                        .contentType: "application/vnd.apple.pkpass",
                        .lastModified: rfc2616DateFormatter.string(from: updatedAt),
                    ]
                    let passBytes = try Storage.get(path: passPath)
                    return Response(status: .ok, headers: headers, body: .data(passBytes))
                }
            }

            v1.post("log") { request in
                guard let logs = try request.json?.extract("logs") as [String]? else {
                    return Response(status: .badRequest)
                }

                self.log(messages: logs)
                return Response(status: Status.ok)
            }
        }
    }
}
