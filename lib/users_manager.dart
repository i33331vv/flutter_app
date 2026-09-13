class UserModel {
  final String phone;
  double balance;
  bool isBanned;

  UserModel({
    required this.phone,
    this.balance = 0.0,
    this.isBanned = false,
  });
}

class UsersManager {
  static final List<UserModel> registeredUsers = [];

  static UserModel getUser(String phone) {
    try {
      return registeredUsers.firstWhere((u) => u.phone == phone);
    } catch (e) {
      final newUser = UserModel(phone: phone, balance: 0.0);
      registeredUsers.add(newUser);
      return newUser;
    }
  }
}