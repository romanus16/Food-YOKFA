import 'package:food_yokfa/core/identite.dart';

class IdentiteFactice implements Identite {
  IdentiteFactice([this.id = 'client-test']);
  final String id;
  @override
  Future<String> clientId() async => id;
}
