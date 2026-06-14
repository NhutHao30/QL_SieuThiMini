class CustomerModel {
  final String makh;
  final String hoten;
  final String sdt;
  final String gioitinh;
  final String diachi;
  final String ngaysinh;
  final String loaikh;
  final int diemtichluy;

  CustomerModel({
    required this.makh,
    required this.hoten,
    required this.sdt,
    required this.gioitinh,
    required this.diachi,
    required this.ngaysinh,
    required this.loaikh,
    required this.diemtichluy,
  });

  factory CustomerModel.fromJson(Map<String, dynamic> json) {
    return CustomerModel(
      makh: json['makh'] ?? '',
      hoten: json['hoten'] ?? '',
      sdt: json['sdt'] ?? '',
      gioitinh: json['gioitinh'] ?? '',
      diachi: json['diachi'] ?? '',
      ngaysinh: json['ngaysinh'] ?? '',
      loaikh: json['loaikh'] ?? '',
      diemtichluy: json['diemtichluy'] ?? 0,
    );
  }
}