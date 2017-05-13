import FormData
import Foundation
import HTTP
import Routing
import Storage
import Vapor

private extension Field {
    var data: Bytes {
        return part.body
    }

    var string: String? {
        let body = part.body
        return body.withUnsafeBufferPointer { buffer in
            guard let uptr = buffer.baseAddress else { return nil }
            return uptr.withMemoryRebound(to: CChar.self, capacity: body.count, String.init(utf8String:))
        }
    }
}

final class VanityCollection: RouteCollection {
    typealias Wrapped = HTTP.Responder

    let updatePassword: String?
    
    init(updatePassword: String?) {
        self.updatePassword = updatePassword
    }

    func isAuthenticated(request: Request) -> Bool {
        guard let updatePassword = updatePassword else {
            // No password = always authenticated
            return true
        }

        if let authorization = request.headers[.authorization] {
            return authorization == "Bearer \(updatePassword)"
        } else {
            return false
        }
    }

    func findPass(vanityName: String) throws -> Pass? {
        return try Pass.query()
            .filter("vanity_name", vanityName)
            .first()
    }

    func parseVanityName(from fileName: String) -> String? {
        if let suffixRange = fileName.range(of: ".pkpass", options: [.anchored, .backwards, .caseInsensitive]) {
            return fileName[fileName.startIndex ..< suffixRange.lowerBound]
        } else {
            return nil
        }
    }

    func build<B: RouteBuilder>(_ builder: B) where B.Value == Wrapped {
        builder.get(String.self) { request, passName in
            guard let vanityName = self.parseVanityName(from: passName),
                let pass = try self.findPass(vanityName: vanityName),
                let passPath = pass.passPath
            else {
                return Response(status: .notFound)
            }

            let updatedAt = pass.updatedAt ?? Date()
            let headers: [HeaderKey: String] = [
                .contentType: "application/vnd.apple.pkpass",
                .lastModified: rfc2616DateFormatter.string(from: updatedAt),
            ]
            let passBytes = try Storage.get(path: passPath)
            return Response(status: .ok, headers: headers, body: .data(passBytes))
        }

        builder.post(String.self) { request, passName in
            guard self.isAuthenticated(request: request) else {
                return Response(status: .unauthorized)
            }

            guard let vanityName = self.parseVanityName(from: passName) else {
                return Response(status: .notFound)
            }

            guard try self.findPass(vanityName: vanityName) == nil else {
                return Response(status: .preconditionFailed)
            }

            guard let formData = request.formData,
                let authenticationToken = formData["authentication_token"]?.string,
                let passTypeIdentifier = formData["pass_type_identifier"]?.string,
                let serialNumber = formData["serial_number"]?.string,
                let passData = formData["pass"]?.data
            else {
                return Response(status: .badRequest)
            }

            let passPath = try Storage.upload(bytes: passData, fileName: vanityName, fileExtension: "pkpass", mime: "application/vnd.apple.pkpass")

            var pass = Pass()
            pass.vanityName = vanityName
            pass.authenticationToken = authenticationToken
            pass.serialNumber = serialNumber
            pass.passTypeIdentifier = passTypeIdentifier
            pass.passPath = passPath
            pass.updatedAt = Date()
            try pass.save()

            return Response(status: .created)
        }

        builder.put(String.self) { request, passName in
            guard self.isAuthenticated(request: request) else {
                return Response(status: .unauthorized)
            }

            guard let vanityName = self.parseVanityName(from: passName),
                var pass = try self.findPass(vanityName: vanityName)
            else {
                return Response(status: .notFound)
            }

            guard let formData = request.formData,
                let passData = formData["pass"]?.data
            else {
                return Response(status: .badRequest)
            }

            let passPath = try Storage.upload(bytes: passData, fileName: vanityName, fileExtension: "pkpass", mime: "application/vnd.apple.pkpass")
            pass.passPath = passPath
            pass.updatedAt = Date()
            try pass.save()

            return Response(status: .seeOther, headers: [.location: String(describing: request.uri)])
        }
    }
}
