class ProductModel {
  final String masp;
  final String maloai;
  final String tensp;
  final String dvt;
  final double giaban;
  final int soluong;
  final String mancc;
  final String? ghichu;
  final bool trangthai;

  ProductModel({
    required this.masp,
    required this.maloai,
    required this.tensp,
    required this.dvt,
    required this.giaban,
    required this.soluong,
    required this.mancc,
    this.ghichu,
    this.trangthai = true,
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      masp: json['masp'] ?? '',
      maloai: json['maloai'] ?? '',
      tensp: json['tensp'] ?? '',
      dvt: json['dvt'] ?? '',
      giaban: double.tryParse(json['giaban'].toString()) ?? 0,
      soluong: json['soluong'] ?? 0,
      mancc: json['mancc'] ?? '',
      ghichu: json['ghichu'],
      trangthai: json['trangthai'] ?? true,
    );
  }
}