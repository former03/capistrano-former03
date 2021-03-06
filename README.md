Capistrano extensions for FORMER 03
=====================

Adds Features for Capistrano that are needed for FORMER 03's deployment

[![Gem version](https://badge.fury.io/rb/capistrano-former03.png)][gem]

[capistrano]: https://github.com/capistrano/capistrano
[gem]: https://rubygems.org/gems/capistrano-former03

Implemented features:
--------------

- Local git checkout should be deployed via rsync (to save bandwidth/time)
-- saves bandwitdh and time
-- be independent of git on remote hosts
-- execute pre deployment tasks on controlled environment (e.g. sass compilation)
- Support of git submodules
- Support of destinations server without public key authentication
- Deploy own static compiled versions of busybox and rsync if configured / needed
- Relative symlinking (often needed if ssh or webapp is chrooted)
- Current directory is no symlink (some hosting provider don't support wwwroot symlinked)
- Fix rights at local_stage

(Planned) features:
--------------

-?


Requirements
------------

- Ruby >= 2.0
- Capistrano == 3.2.1
- Rsync >= 2.6

Installation
------------

Add this line to your application's Gemfile:

```ruby
gem 'capistrano-former03'
```

And then execute:

```sh
$ bundle
```

Or install it yourself as:

```sh
$ gem install capistrano-former03
```

Usage
-----

Capfile:

```ruby
require 'capistrano/former03'
```

deploy as usual

```sh
$ cap deploy
```

Options
-------

Set capistrano variables with `set name, value`.

Name                  | Default            | Description
-------------         | --------           | ------------
local_stage           | tmp/deploy         | local stage path
remote_stage          | shared/deploy      | remote stage path
remote_bin            | shared/deploy_bin  | remote bin path
rsync_options         | --archive --delete | rsync options
deploy_busybox_bin    | false              | deploy a static version of busybox
deploy_rsync_bin      | nil (Autodetect)   | deploy a static version of rsync
relative_symlinks     | true               | create all symlinks with relative
current_path_real_dir | false              | move actual release to current_path to have a real directory instead of symlink 
ensure_file_mode      | nil                | If given all files are chmoded to that mode
ensure_dir_mode       | nil                | If given all directories are chmoded to that mode
ensure_path_mode      | {}                 | Dictionary with path => mode mapping for special files/directories

Overview
--------

### local machine

```log
~/your_project
.
|-- app
|-- config
|-- lib
|-- ...
|-- ...
`-- tmp
    `-- deploy (rsync src ==>)
```

### deployment hosts

```log
/var/www/your_project
.
|-- current -> /var/www/your_project/releases/20140219074628
|-- releases
|   |-- 20140219062041
|   |-- 20140219063022
|   `-- 20140219074628
|-- revisions.log
`-- shared
    |-- vendor
    |-- deploy (==> rsync dest)
    |-- deploy_bin (==> static binaries)
    `-- log
```

Contributing
------------

1. Fork it ( http://github.com/linyows/capistrano-withrsync/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request


Author
------

- [linyows][linyows] (Author of capistrano-withrsync)
- [simonswine][simonswine]

[linyows]: https://github.com/linyows
[simonswine]: https://github.com/simonswine

License
-------

The MIT License (MIT)
