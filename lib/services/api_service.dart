class ApiService {
  Future<String> fetchUserName() async {
    await Future.delayed(const Duration(seconds: 2));
    return "Flutter MVVM User";
  }
}
