# Passcards

A simple [Wallet](https://developer.apple.com/wallet/) server that implements the [PassKit Web Service](https://developer.apple.com/library/content/documentation/PassKit/Reference/PassKit_WebService/WebService.html) requirements. (This is a Swift re-implementation of the original [Parse-backed version](https://github.com/a2/passcards-parse).)

## Building

```sh
$ swift build -c release
$ .build/release/App
```

## Required Environment

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

## Deployment

1. Create an app on Heroku

    ```sh
    $ heroku apps:create [NAME]
    ```

2. Set the environment variables (as described above)

    ```sh
    $ heroku config:set X=abc Y=def Z=ghi ...
    ```

    If you use the [Heroku PostgreSQL](https://devcenter.heroku.com/articles/heroku-postgresql) plugin, you will need to add the plugin (which sets the `DATABASE_URL` environment variable) and then set the required `PG_*` variables.

3. Install the [Container Registry Plugin](https://devcenter.heroku.com/articles/container-registry-and-runtime)

    ```sh
    $ heroku plugins:install heroku-container-registry
    ```

4. Build and deploy Docker image to Heroku

    ```sh
    $ heroku container:push web
    ```

5. Open the website (a static single-page site)

    ```sh
    $ heroku open
    ```

## Usage

### Creating a Pass

This is beyond the scope of the project, but recommended reading includes:

- Wallet Developer Guide: [Building Your First Pass](https://developer.apple.com/library/content/documentation/UserExperience/Conceptual/PassKit_PG/YourFirst.html#//apple_ref/doc/uid/TP40012195-CH2-SW1), [Pass Design and Creation](https://developer.apple.com/library/content/documentation/UserExperience/Conceptual/PassKit_PG/Creating.html#//apple_ref/doc/uid/TP40012195-CH4-SW1)
- [PassKit Package Format Reference](https://developer.apple.com/library/content/documentation/UserExperience/Reference/PassKit_Bundle/Chapters/Introduction.html)

You will want to set _https://my-heroku-app.herokuapp.com/_ as the `webServiceURL` root key in your _pass.json_.

Example passes, as well as the source of a command-line tool for signing Pass bundles (_signpass_), can be found [here](https://developer.apple.com/services-account/download?path=/iOS/Wallet_Support_Materials/WalletCompanionFiles.zip).

### Uploading a Pass

```sh
$ curl -X POST \
    -H "Authorization: Bearer MY_UPDATE_PASSWORD" \
    -F "pass=@a_local_file.pkpass" \
    -F "authentication_token=AUTHENTICATION_TOKEN" \
    -F "pass_type_identifier=PASS_TYPE_IDENTIFIER" \
    -F "serial_number=SERIAL_NUMBER" \
    https://my-heroku-app.herokuapp.com/VANITY_URL.pkpass
```

In the above cURL command, _a_local_file.pkpass_ is a file in the current working directory. Set the `authentication_token`, `pass_type_identifier`, and `serial_number` fields to their corresponding values from the pass's _pass.json_. _MY_UPDATE_PASSWORD_ is the `UPDATE_PASSWORD` environment variable set in your app.

### Updating a Pass

```sh
$ curl -X PUT \
    -H "Authorization: Bearer MY_UPDATE_PASSWORD" \
    -F "pass=@a_local_file.pkpass" \
    https://my-heroku-app.herokuapp.com/VANITY_URL.pkpass
```

_a_local_file.pkpass_ is the new local file to replace on the server. _MY_UPDATE_PASSWORD_ is the same `UPDATE_PASSWORD` as above.

### Sharing a Pass

A Pass recipient can go to *https://my-heroku-app.herokuapp.com/VANITY_URL.pkpass* to receive your pass.

## Author

Alexsander Akers, me@a2.io

### My Personal Set-up

On my personal website (*https://pass.a2.io*), I use [CloudFlare](https://www.cloudflare.com) to secure the website subdomain that points to Heroku because then I get TLS / HTTPS (which is required for PassKit in production) for free, because I'm cheap. To that extent, I also use Heroku's free PostgreSQL plan and the [free dyno hours](https://devcenter.heroku.com/articles/free-dyno-hours).

A sleeping-when-idle Heroku app is *perfect* for Wallet services because an iOS device will call your service endpoints in the background and retry upon timeout.

Your app service service is only woken...

1. when someone adds a pass (triggering a pass registration).
2. when someone deletes a pass (triggering pass de-registration).
3. when someone triggers a manual refresh of a pass.
4. when someone toggles "Automatic Updates" on the backside of a pass (shown with the ⓘ button).

## License

Passcards is available under the MIT license. See the LICENSE file for more info.
