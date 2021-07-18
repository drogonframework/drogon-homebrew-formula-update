# Drogon Homebrew Formula Updater

Drogon Homebrew Formula Updater updates the Drogon Homebrew formula
with just one simple call.

It fetches the Drogon source archive with the corresponding version,
computes its digest, sets the correct trantor dependency, commits the
changes, and finally pushes the updated formula.

``` common-lisp
(update "1.7.1"
  "~/Repositories/Open Source/drogon/"
  "~/Repositories/Open Source/homebrew-drogon/"
  :dry-run t)
```

After manually verifying the results in the local Homebrew formula
repository, the `:dry-run` parameter can be left out to create a
commit message, and push the updated formula to its upstream
repository.

## Requirements

* SBCL 2.1.6+
* Quicklisp
* Git

## Installation

1. Make sure you have a fairly recent SBCL environment running (other
may work, too, but they are untested).
1. Pull this repository into your Quicklisp local projects directory
   (or make a symlink).
1. Then load the system:

    ``` common-lisp
    (ql:quickload :drogon-homebrew-formula-update)
    ```

## Contribute

We welcome any contributions. Contact us if you have any questions.

## Contact

Drogon Homebrew Formula Updater is owned and maintained by [Cocobit
Software](https://www.cocobit.software/).

## License

Drogon Homebrew Formula Updater is released under the BSD 3-Clause
license. See [LICENSE](LICENSE) for details.
