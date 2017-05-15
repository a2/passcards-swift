# Passcards

A simple Wallet (née Passbook) server. This is a Swift re-implementation of the original [Parse-backed version](https://github.com/a2/passcards-parse).

## Usage

```sh
$ swift build -c release
$ .build/release/App
```

**Environment:**

| Key | Description |
| --- | ----------- |
| APNS_KEY_ID | APNS key ID |
| APNS_PRIVATE_KEY | APNS private key content |
| APNS_TEAM_ID | APNS team ID |
| APNS_TOPIC | APNS (certificate) topic |
| PG_DBNAME | Postgres database name |
| PG_HOST | Postgres host |
| PG_PASSWORD | Postgres password |
| PG_PORT | Postgres port |
| PG_USER | Postgres user |
| S3_ACCESS_KEY | S3 access key |
| S3_BUCKET | S3 bucket name |
| S3_REGION | S3 bucket region |
| S3_SECRET_KEY | S3 access secret key |
| UPDATE_PASSWORD | Update password *(unset == unlimited access)* |

## Author

Alexsander Akers, me@a2.io

## License

Passcards is available under the MIT license. See the LICENSE file for more info.
