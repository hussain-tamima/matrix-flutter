import 'package:element_x/features/poll/cubit/poll_state.dart';
export 'package:element_x/features/poll/cubit/poll_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:element_x/features/poll/models/poll_draft.dart';
import 'package:element_x/features/poll/repo/poll_repo.dart';

class PollCubit extends Cubit<PollState> {
  PollCubit(this._repo, this.roomId) : super(const PollState());

  final PollRepo _repo;
  final String roomId;

  void create({
    required String question,
    required String first,
    required String second,
  }) {
    final options = [
      first.trim(),
      second.trim(),
    ].where((option) => option.isNotEmpty).toList();
    if (question.trim().isEmpty || options.length < 2) {
      emit(const PollState(error: 'Add a question and two options'));
      return;
    }
    _repo.create(
      roomId,
      PollDraft(question: question.trim(), options: options),
    );
    emit(const PollState(created: true));
  }
}
