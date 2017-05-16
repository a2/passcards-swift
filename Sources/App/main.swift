import HTTP
import Storage
import Vapor

let drop = Droplet()
drop.database = drop.postgresDatabase()
drop.preparations = [Pass.self, Registration.self]

try drop.addProvider(StorageProvider.self)

drop.collection(WalletCollection(droplet: drop))
drop.collection(VanityCollection(droplet: drop))

drop.get { req in
    return try drop.view.make("welcome")
}

drop.run()
