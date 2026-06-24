import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../domain/entities/activity_session.dart';
import '../../data/datasources/history_local_datasource.dart';

abstract class HistoryEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class HistoryLoadRequested extends HistoryEvent {}

class HistorySessionAdded extends HistoryEvent {
  final ActivitySession session;
  HistorySessionAdded(this.session);
  @override
  List<Object?> get props => [session];
}

class HistorySessionRenamed extends HistoryEvent {
  final String id;
  final String newName;
  HistorySessionRenamed(this.id, this.newName);
  @override
  List<Object?> get props => [id, newName];
}

class HistorySessionDeleted extends HistoryEvent {
  final String id;
  HistorySessionDeleted(this.id);
  @override
  List<Object?> get props => [id];
}

abstract class HistoryState extends Equatable {
  @override
  List<Object?> get props => [];
}

class HistoryInitial extends HistoryState {}

class HistoryLoaded extends HistoryState {
  final List<ActivitySession> sessions;
  HistoryLoaded(this.sessions);
  @override
  List<Object?> get props => [sessions];
}

class HistoryBloc extends Bloc<HistoryEvent, HistoryState> {
  final HistoryLocalDatasource _datasource;

  HistoryBloc(this._datasource) : super(HistoryInitial()) {
    on<HistoryLoadRequested>(_onLoad);
    on<HistorySessionAdded>(_onAdd);
    on<HistorySessionRenamed>(_onRename);
    on<HistorySessionDeleted>(_onDelete);
  }

  Future<void> _onLoad(HistoryLoadRequested event, Emitter<HistoryState> emit) async {
    final sessions = await _datasource.getAll();
    emit(HistoryLoaded(sessions));
  }

  Future<void> _onAdd(HistorySessionAdded event, Emitter<HistoryState> emit) async {
    await _datasource.add(event.session);
    final sessions = await _datasource.getAll();
    emit(HistoryLoaded(sessions));
  }

  Future<void> _onRename(HistorySessionRenamed event, Emitter<HistoryState> emit) async {
    await _datasource.updateName(event.id, event.newName);
    final sessions = await _datasource.getAll();
    emit(HistoryLoaded(sessions));
  }

  Future<void> _onDelete(HistorySessionDeleted event, Emitter<HistoryState> emit) async {
    await _datasource.delete(event.id);
    final sessions = await _datasource.getAll();
    emit(HistoryLoaded(sessions));
  }
}
