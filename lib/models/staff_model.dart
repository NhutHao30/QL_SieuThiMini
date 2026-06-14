class StaffModel {
  final String username;
  final String hoten;
  final String chucvu;
  final String sdt;
  final String email;
  final List<String> shifts;
  final bool isActive;
  final bool isOnline;

  StaffModel({
    required this.username,
    required this.hoten,
    required this.chucvu,
    required this.sdt,
    required this.email,
    this.shifts = const [],
    this.isActive = true,
    this.isOnline = false,
  });

  factory StaffModel.fromJson(Map<String, dynamic> json) {
    List<String> shiftList = [];
    if (json['phancongca'] != null && json['phancongca'] is List) {
      for (var pc in json['phancongca']) {
        if (pc['maca'] != null) {
          shiftList.add(pc['maca'].toString());
        }
      }
    }

    final taikhoan = _getTaikhoan(json['taikhoan']);
    
    bool parsedIsActive = true;
    if (taikhoan['is_active'] != null) {
      if (taikhoan['is_active'] is bool) parsedIsActive = taikhoan['is_active'];
      else if (taikhoan['is_active'] is String) parsedIsActive = taikhoan['is_active'].toString().toLowerCase() == 'true';
    }

    bool parsedIsOnline = false;
    if (taikhoan['is_online'] != null) {
      if (taikhoan['is_online'] is bool) parsedIsOnline = taikhoan['is_online'];
      else if (taikhoan['is_online'] is String) parsedIsOnline = taikhoan['is_online'].toString().toLowerCase() == 'true';
    }

    return StaffModel(
      username: json['username'] ?? '',
      hoten: json['hoten'] ?? '',
      chucvu: json['chucvu'] ?? '',
      sdt: json['sdt'] ?? '',
      email: taikhoan['email']?.toString() ?? '',
      isActive: parsedIsActive,
      isOnline: parsedIsOnline,
      shifts: shiftList,
    );
  }

  static Map<String, dynamic> _getTaikhoan(dynamic obj) {
    if (obj == null) return {};
    if (obj is List && obj.isNotEmpty) return obj[0] as Map<String, dynamic>;
    if (obj is Map<String, dynamic>) return obj;
    return {};
  }

}