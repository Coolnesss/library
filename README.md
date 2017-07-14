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

The current app is deployed in [Heroku](https://www.heroku.com/). This is by far the easiest to setup. Simply follow [their instructions](https://devcenter.heroku.com/articles/getting-started-with-rails4).