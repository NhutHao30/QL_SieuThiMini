class InvoiceDetailModel {
  final String mahd;
  final String masp;
  final int soluong;
  final double dongia;
  final double thanhtien;

  // Joined fields for UI
  final String productName;

  InvoiceDetailModel({
    required this.mahd,
    required this.masp,
    required this.soluong,
    required this.dongia,
    required this.thanhtien,
    this.productName = 'Sản phẩm',
  });

  factory InvoiceDetailModel.fromJson(Map<String, dynamic> json) {
    return InvoiceDetailModel(
      mahd: json['mahd'] ?? json['mahdnhap'] ?? '',
      masp: json['masp'] ?? '',
      soluong: json['soluong'] ?? json['soluongtn'] ?? 0,
      dongia: double.tryParse(json['dongia']?.toString() ?? json['dongianhap']?.toString() ?? '0') ?? 0,
      thanhtien: double.tryParse(json['thanhtien']?.toString() ?? json['thanhtienn']?.toString() ?? '0') ?? 0,
      productName: json['sanpham']?['tensp'] ?? 'Sản phẩm',
    );
  }
}
