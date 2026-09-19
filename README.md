# Library

This application is for cataloging, tagging and storing Sindhi books to preserve them. The app is built on Rails 4 and CoffeeScript.


## Development

1. To develop, fork the repository and clone your fork

```bash
git clone https://github.com/<your username>/library
```

2. [Install Ruby](https://www.digitalocean.com/community/tutorials/how-to-install-ruby-on-rails-with-rbenv-on-ubuntu-16-04)


3.   Install dependencies

`cd` to project directory and run

```bash
bundle --without production
```

Note: you will need `libsqlite-dev`

4. Run database migrations

```bash
rake db:migrate
```

5. (Optional) run tests

```bash
rspec
```

## Deployment

The app deploys as a Docker image with [Kamal](https://kamal-deploy.org/), configured in `config/deploy.yml`. Nothing environment-specific is committed: the server address comes from `KAMAL_HOST`, the backup bucket from `BACKUP_BUCKET`, and every secret named in `.kamal/secrets` is read from the environment of the shell you deploy from.

```bash
kamal setup    # first deploy
kamal deploy   # later deploys
```

To deploy your own fork, change `image` and `registry` in `config/deploy.yml`.

The production database is SQLite, kept in a Docker volume and backed up continuously to S3 by a [Litestream](https://litestream.io/) accessory. Book files are stored on S3. [Umami](https://umami.is/) analytics runs as two more accessories: Umami itself and its Postgres database.
