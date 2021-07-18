/// A Dart template generator which helps teams
/// generate files quickly and consistently.
///
/// ```sh
/// # Activate mason
/// $ dart pub global activate mason
///
/// # See usage
/// $ mason --help
/// ```
library mason;

export 'src/exception.dart' show MasonException;
export 'src/generator.dart'
    show MasonGenerator, DirectoryGeneratorTarget, FileConflictResolution;
export 'src/logger.dart' show Logger;
export 'src/mason_bundle.dart' show MasonBundle;
export 'src/mason_yaml.dart' show GitPath;
