import Vapor

let drop = Droplet()

drop.get { req in
    return try drop.view.make("welcome")
}

drop.run()
