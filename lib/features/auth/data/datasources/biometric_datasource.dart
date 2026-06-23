import 'package:local_auth/local_auth.dart';
import '../../domain/entities/auth_result.dart';

abstract class BiometricDataSource {
  Future<bool> canAuthenticate();
  Future<AuthResult> authenticate();
}

class BiometricDataSourceImpl implements BiometricDataSource {
  final LocalAuthentication _auth = LocalAuthentication();

  @override
  Future<bool> canAuthenticate() async {
    try {
      final isAvailable = await _auth.isDeviceSupported();
      if (!isAvailable) return false;
      final canCheck = await _auth.canCheckBiometrics;
      return canCheck;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<AuthResult> authenticate() async {
    try {
      final result = await _auth.authenticate(
        localizedReason: 'Usa tu huella dactilar para acceder',
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
        ),
      );
      return AuthResult(
        success: result,
        message: result ? 'Autenticación exitosa' : 'Autenticación fallida',
      );
    } catch (e) {
      return AuthResult(success: false, message: 'Error: $e');
    }
  }
}
