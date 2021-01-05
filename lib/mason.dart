/// A Dart template generator which helps teams
/// generate files quickly and consistently.
///
/// ```sh
/// # activate mason
/// pub global activate mason
///
/// # see usage
/// mason --help
/// ```
library mason;

export 'src/exception.dart' show MasonException;
export 'src/generator.dart' show MasonGenerator, DirectoryGeneratorTarget;
export 'src/logger.dart' show Logger;
export 'src/mason_yaml.dart' show GitPath;
