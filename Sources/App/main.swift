import HTTP
import Storage
import Vapor

let drop = Droplet()
drop.database = database(for: drop)
drop.preparations = [Pass.self, Registration.self]

try drop.addProvider(StorageProvider.self)

drop.collection(WalletCollection.self)

let apns = try vaporAPNS(for: drop)
let updatePassword = try drop.config.extract("app", "updatePassword") as String?
drop.collection(VanityCollection(apns: apns, updatePassword: updatePassword))

drop.get { req in
    return try drop.view.make("welcome")
}

drop.run()
