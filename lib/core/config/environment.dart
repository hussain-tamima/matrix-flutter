/// Runtime environment selected with `--dart-define=ENV=dev`.
enum Environment { prod, dev }

Environment get currentEnvironment {
  const name = String.fromEnvironment('ENV', defaultValue: 'prod');
  return name == 'dev' ? Environment.dev : Environment.prod;
}
