import Vapor
import VaporAPNS

extension Droplet {
    func vaporAPNS() throws -> VaporAPNS {
        let apns = try config.extract("app", "apns") as Config
        let topic = try apns.extract("topic") as String
        let teamID = try apns.extract("teamID") as String
        let keyID = try apns.extract("keyID") as String
        let rawPrivateKey = try apns.extract("privateKey") as String
        guard let (privateKey, publicKey) = ECKeys(from: rawPrivateKey) else {
            throw TokenError.invalidAuthKey
        }

        let options = try Options(topic: topic, teamId: teamID, keyId: keyID, rawPrivKey: privateKey, rawPubKey: publicKey)
        return try VaporAPNS(options: options)
    }
}
