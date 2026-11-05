import 'package:flutter_test/flutter_test.dart';
import 'package:food_yokfa/core/format.dart';

void main() {
  test('formate les montants en FCFA sans décimales', () {
    expect(formatFcfa(0), '0 F');
    expect(formatFcfa(500), '500 F');
    expect(formatFcfa(1000), '1 000 F');
    expect(formatFcfa(1250000), '1 250 000 F');
  });
}
