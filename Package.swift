import PackageDescription

let package = Package(
    name: "passcards",
    dependencies: [
        .Package(url: "https://github.com/vapor/vapor.git", majorVersion: 1, minor: 5),
        .Package(url: "https://github.com/vapor/fluent.git", majorVersion: 1),
        .Package(url: "https://github.com/vapor-community/postgresql-driver.git", majorVersion: 1, minor: 1),
        .Package(url: "https://github.com/nodes-vapor/storage.git", majorVersion: 0, minor: 3),
        .Package(url: "https://github.com/matthijs2704/vapor-apns.git", majorVersion: 1, minor: 2),
    ],
    exclude: [
        "Config",
        "Database",
        "Localization",
        "Public",
        "Resources",
    ]
)
