# "mix escript.new"

Because I get fed up with trying to figure out how to create an escript with Elixir.

## Installation

    mix archive.install

## Oneliner

...because it's easier to test the app this way.

    mix archive.install --force && \
      rm -rf foo/ && \
      mix escript.new foo && \
      (cd foo && mix escript.build && ./foo)
