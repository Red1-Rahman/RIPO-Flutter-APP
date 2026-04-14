class SessionStore {
  SessionStore._();

  static final SessionStore instance = SessionStore._();

  String? token;
  String? role;
  Map<String, dynamic>? user;

  void setSession({
    required String token,
    required String role,
    required Map<String, dynamic> user,
  }) {
    this.token = token;
    this.role = role;
    this.user = user;
  }

  void clear() {
    token = null;
    role = null;
    user = null;
  }
}
