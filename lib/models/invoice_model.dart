class InvoiceModel {
  final String mahd;
  final String ngaylap;
  final String? username;
  final String? ghichu;
  final String? makh;
  final double tongtien;

  // Additional fields for UI display
  final String customerName;
  final int totalItems;
  final bool isImport;
  final String? mancc;

  InvoiceModel({
    required this.mahd,
    required this.ngaylap,
    this.username,
    this.ghichu,
    this.makh,
    required this.tongtien,
    this.customerName = 'Khách vãng lai',
    this.totalItems = 0,
    this.isImport = false,
    this.mancc,
  });

  factory InvoiceModel.fromJson(Map<String, dynamic> json) {
    int itemsCount = 0;
    if (json['chitiethdban'] != null) {
      if (json['chitiethdban'] is List) {
        itemsCount = (json['chitiethdban'] as List).length;
      } else if (json['chitiethdban'] is Map && json['chitiethdban']['count'] != null) {
        itemsCount = json['chitiethdban']['count'] as int;
      }
    }
    if (json['chitiethdnhap'] != null) {
      if (json['chitiethdnhap'] is List) {
        itemsCount = (json['chitiethdnhap'] as List).length;
      }
    }

    bool isImp = json['mahdnhap'] != null;
    
    double total = 0;
    if (isImp) {
      if (json['congno'] != null && json['congno'] is List && (json['congno'] as List).isNotEmpty) {
        total = double.tryParse((json['congno'] as List)[0]['sotienphaitra']?.toString() ?? '0') ?? 0;
      }
    } else {
      total = double.tryParse(json['tongtien']?.toString() ?? '0') ?? 0;
    }

    String custName = 'Khách vãng lai';
    if (isImp) {
      custName = json['nhacungcap']?['tenncc'] ?? json['mancc'] ?? 'Nhà cung cấp';
    } else {
      custName = json['khachhang']?['hoten'] ?? 'Khách vãng lai';
    }

    return InvoiceModel(
      mahd: isImp ? (json['mahdnhap'] ?? '') : (json['mahd'] ?? ''),
      ngaylap: json['ngaylap'] ?? '',
      username: json['username'],
      ghichu: json['ghichu'],
      makh: json['makh'],
      mancc: json['mancc'],
      tongtien: total,
      customerName: custName,
      totalItems: itemsCount,
      isImport: isImp,
    );
  }
}
