[
  import_deps: [:phoenix],
  inputs: [".formatter.exs", "*.{ex,exs}", "{config,lib,test}/**/*.{ex,exs}"],
  locals_without_parens: [
    assert_eventually: 1,
    assert_eventually: 2,
    assert_eventually: 3,
    refute_eventually: 1,
    refute_eventually: 2,
    refute_eventually: 3
  ]
]
