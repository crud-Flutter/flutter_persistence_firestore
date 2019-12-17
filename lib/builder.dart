import 'package:build/build.dart';
import 'package:flutter_persistence_firestore/src/model_generator.dart';
import 'package:source_gen/source_gen.dart';

Builder entityBuilder(BuilderOptions options) => LibraryBuilder(EntityGenerator(), generatedExtension: '.entity.dart');