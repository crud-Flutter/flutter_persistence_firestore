import 'package:build/build.dart';
import 'src/entity_generator.dart';
import 'src/repository_generator.dart';
import 'package:source_gen/source_gen.dart';

Builder entityBuilder(BuilderOptions options) => LibraryBuilder(EntityGenerator(), generatedExtension: '.entity.dart');
Builder repositoryBuilder(BuilderOptions options) => LibraryBuilder(RepositoryGenerator(), generatedExtension: '.repository.dart');