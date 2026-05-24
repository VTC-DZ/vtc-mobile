import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/utils/validators.dart';
import '../../../../features/auth/data/repo/profile_repository.dart';
import 'email_edit_state.dart';

class EmailEditCubit extends Cubit<EmailEditState> {
  EmailEditCubit(this._repository, {required String initialEmail})
      : super(const EmailEditState()) {
    emailController.text = initialEmail;
    final error = Validators.email(initialEmail);
    if (error.isNotEmpty) emit(state.copyWith(emailError: error));
  }

  final ProfileRepository _repository;
  final emailController = TextEditingController();

  @override
  Future<void> close() {
    emailController.dispose();
    return super.close();
  }

  void emailChanged(String value) {
    emit(state.copyWith(
      emailError: Validators.email(value.trim()),
      errorMessage: '',
    ));
  }

  Future<void> updateEmail() async {
    if (!state.canSave) return;
    emit(state.copyWith(status: EmailEditStatus.loading, errorMessage: ''));
    try {
      await _repository.updateEmail(email: emailController.text.trim());
      emit(state.copyWith(
          status: EmailEditStatus.success, email: emailController.text.trim()));
    } catch (e) {
      emit(state.copyWith(
        status: EmailEditStatus.failure,
        errorMessage: e is String ? e : 'Failed to update email.',
      ));
    }
  }
}
