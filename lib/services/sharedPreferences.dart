import 'package:climify/models/api_response.dart';
import 'package:climify/models/userModel.dart';
import 'package:climify/services/rest_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SharedPrefsHelper {
  final String tokenKey = "unauthorizedToken";
  final String startOnLogin = "alreadyUser";

  Future<String> getUnauthorizedUserToken() async {
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    String token = sharedPreferences.getString(tokenKey);
    if (token == null) {
      RestService restService = RestService();
      APIResponse<UserModel> newUserAPIResponse =
          await restService.createUnauthorizedUser();
      if (!newUserAPIResponse.error) {
        token = newUserAPIResponse.data.authToken;
        sharedPreferences.setString(tokenKey, token);
        return token;
      } else {
        return "";
      }
    } else {
      return token;
    }
  }

  Future<bool> getStartOnLogin() async {
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    bool startLogin = sharedPreferences.getBool(startOnLogin) ?? false;
    return startLogin;
  }

  Future<void> setStartOnLogin(bool b) async {
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    await sharedPreferences.setBool(startOnLogin, b);
    return;
  }
}
