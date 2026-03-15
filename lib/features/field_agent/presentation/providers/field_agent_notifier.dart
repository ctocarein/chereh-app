import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/field_agent_remote_datasource.dart';
import '../../domain/models/beneficiary_registration.dart';

// ---------------------------------------------------------------------------
// State
// ---------------------------------------------------------------------------

sealed class FieldAgentState {
  const FieldAgentState();
}

final class FieldAgentIdle extends FieldAgentState {
  const FieldAgentIdle();
}

final class FieldAgentSearching extends FieldAgentState {
  const FieldAgentSearching();
}

final class FieldAgentFound extends FieldAgentState {
  final BeneficiaryRegistration result;
  const FieldAgentFound(this.result);
}

final class FieldAgentError extends FieldAgentState {
  final String message;
  const FieldAgentError(this.message);
}

// ---------------------------------------------------------------------------
// Notifier
// ---------------------------------------------------------------------------

final fieldAgentNotifierProvider =
    NotifierProvider<FieldAgentNotifier, FieldAgentState>(
  FieldAgentNotifier.new,
);

class FieldAgentNotifier extends Notifier<FieldAgentState> {
  @override
  FieldAgentState build() => const FieldAgentIdle();

  /// Enregistre ou retrouve un bénéficiaire par son numéro de téléphone.
  Future<void> registerBeneficiary(String phone) async {
    if (phone.trim().isEmpty) return;
    state = const FieldAgentSearching();
    try {
      final ds = ref.read(fieldAgentRemoteDatasourceProvider);
      final result = await ds.registerBeneficiary(phone.trim());
      state = FieldAgentFound(result);
    } catch (e) {
      state = FieldAgentError(e.toString());
    }
  }

  void reset() => state = const FieldAgentIdle();
}
