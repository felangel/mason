/// {@template generate_before}
/// Annotation to specify that code should be generated before the annotated element.
/// {@endtemplate}
class GenerateBefore {
  /// {@macro generate_before}
  const GenerateBefore(this.id);

  /// The unique identifier for this generation.
  final String id;
}

/// {@template generate_after}
/// Annotation to specify that code should be generated after the annotated element.
/// {@endtemplate}
class GenerateAfter {
  /// {@macro generate_after}
  const GenerateAfter(this.id);

  /// The unique identifier for this generation.
  final String id;
}

/// {@template generation_merge}
/// Annotation to specify that code should be merged with the annotated element.
/// {@endtemplate}
class GenerationMerge {
  /// {@macro generation_merge}
  const GenerationMerge(this.id);

  /// The unique identifier for this generation.
  final String id;
}
