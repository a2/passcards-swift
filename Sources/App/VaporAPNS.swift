import Vapor
import VaporAPNS

func vaporAPNS(for droplet: Droplet) throws -> VaporAPNS {
    let apns = try droplet.config.extract("app", "apns") as Config
    let topic = try apns.extract("topic") as String
    let teamID = try apns.extract("teamID") as String
    let keyID = try apns.extract("keyID") as String
    let rawPrivateKey = try apns.extract("privateKey") as String
    guard let (privateKey, publicKey) = ECKeys(from: rawPrivateKey) else {
        throw TokenError.invalidAuthKey
    }

    var options = try Options(topic: topic, teamId: teamID, keyId: keyID, rawPrivKey: privateKey, rawPubKey: publicKey)
    options.forceCurlInstall = droplet.environment == .production
    return try VaporAPNS(options: options)
}
