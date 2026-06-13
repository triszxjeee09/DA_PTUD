import 'google_auth_service.dart';

@Deprecated('Use GoogleAuthService from google_auth_service.dart instead.')
class GoogleSignInService extends GoogleAuthService {
  GoogleSignInService({super.googleSignIn, super.timeout});
}
