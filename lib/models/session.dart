class UserSession {
  const UserSession({required this.idToken, required this.refreshToken, required this.uid, required this.expiresAt, required this.pseudo, required this.anonymous});
  final String idToken;
  final String refreshToken;
  final String uid;
  final int expiresAt;
  final String pseudo;
  final bool anonymous;

  factory UserSession.fromJson(Map<String, dynamic> json) => UserSession(
    idToken: '${json['idToken'] ?? ''}', refreshToken: '${json['refreshToken'] ?? ''}', uid: '${json['uid'] ?? ''}',
    expiresAt: (json['expiresAt'] as num?)?.toInt() ?? 0, pseudo: '${json['pseudo'] ?? ''}', anonymous: json['anonymous'] != false,
  );
  Map<String, dynamic> toJson() => {'idToken': idToken, 'refreshToken': refreshToken, 'uid': uid, 'expiresAt': expiresAt, 'pseudo': pseudo, 'anonymous': anonymous};
}
