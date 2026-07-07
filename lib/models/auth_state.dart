import 'owner_model.dart';

class AuthState {
  final Owner? currentOwner;
  final int? selectedGymId;
  final String? token;
  final bool isAuthenticated;

  const AuthState({
    this.currentOwner,
    this.selectedGymId,
    this.token,
    this.isAuthenticated = false,
  });

  AuthState copyWith({
    Owner? currentOwner,
    int? selectedGymId,
    String? token,
    bool? isAuthenticated,
  }) {
    return AuthState(
      currentOwner: currentOwner ?? this.currentOwner,
      selectedGymId: selectedGymId ?? this.selectedGymId,
      token: token ?? this.token,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
    );
  }
}