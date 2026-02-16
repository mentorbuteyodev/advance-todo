// Base UseCase interface for clean architecture

import 'package:equatable/equatable.dart';

/// Base UseCase that takes [Params] and returns [T].
abstract class UseCase<T, Params> {
  Future<T> call(Params params);
}

/// Use when a UseCase takes no parameters.
class NoParams extends Equatable {
  @override
  List<Object?> get props => [];
}
