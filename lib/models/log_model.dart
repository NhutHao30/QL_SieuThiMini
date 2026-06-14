class LogModel {
  final int id;
  final DateTime thoigian;
  final String username;
  final String hanhdong;
  final String chitiet;
  final String hoten; // joined from taikhoan -> nhanvien
  final String chucvu; // joined from taikhoan -> nhanvien

  LogModel({
    required this.id,
    required this.thoigian,
    required this.username,
    required this.hanhdong,
    required this.chitiet,
    required this.hoten,
    required this.chucvu,
  });

  factory LogModel.fromJson(Map<String, dynamic> json) {
    String hotenVal = 'Người dùng';
    String chucvuVal = 'N/A';
    
    if (json['taikhoan'] != null && 
        json['taikhoan']['nhanvien'] != null) {
        
      var nhanvienData = json['taikhoan']['nhanvien'];
      if (nhanvienData is List && nhanvienData.isNotEmpty) {
        hotenVal = nhanvienData[0]['hoten'] ?? 'Người dùng';
        chucvuVal = nhanvienData[0]['chucvu'] ?? 'N/A';
      } else if (nhanvienData is Map) {
        hotenVal = nhanvienData['hoten'] ?? 'Người dùng';
        chucvuVal = nhanvienData['chucvu'] ?? 'N/A';
      }
    }

    return LogModel(
      id: json['id'] ?? 0,
      thoigian: json['thoigian'] != null ? DateTime.parse(json['thoigian']).toLocal() : DateTime.now(),
      username: json['username'] ?? '',
      hanhdong: json['hanhdong'] ?? '',
      chitiet: json['chitiet'] ?? '',
      hoten: hotenVal,
      chucvu: chucvuVal,
    );
  }
}
