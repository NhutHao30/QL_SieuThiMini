class UserModel {
  final String username;
  final String email;
  final int marole;
  final String hoten;

  UserModel({
    required this.username,
    required this.email,
    required this.marole,
    required this.hoten,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    // If we do a join with nhanvien, hoten is in nhanvien[0]['hoten']
    String hotenVal = 'Người dùng';
    if (json['nhanvien'] != null && json['nhanvien'] is List && json['nhanvien'].isNotEmpty) {
      hotenVal = json['nhanvien'][0]['hoten'] ?? 'Người dùng';
    } else if (json['nhanvien'] != null && json['nhanvien'] is Map) {
      hotenVal = json['nhanvien']['hoten'] ?? 'Người dùng';
    }

    return UserModel(
      username: json['username']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      marole: int.tryParse(json['marole']?.toString() ?? '2') ?? 2,
      hoten: hotenVal,
    );
  }
}