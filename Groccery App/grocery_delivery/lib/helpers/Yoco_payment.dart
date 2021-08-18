import 'package:http/http.dart' as http;

class YocoPayment {
  String requestUrl = 'https://online.yoco.com/v1/charges/';
  String secretKey = 'sk_test_b7b8f911xJoJ7Zz8a604ccf9ea3a'; // Test Secret Key

  Future getDataFromYoco() async {
    final response = await http.post(Uri.parse(requestUrl), headers: {
      'X-Auth-Secret-Key': secretKey,
    }, body: {
      'token': 'tok_test_DjaqoUgmzwYkwesr3euMxyUV4g',
      'amountInCents': "2799",
      'currency': 'ZAR',
    });
    print("Data from the API: ${response.body}");
  }

  // Future getDataViaDio() async {
  // var dio = Dio();
  // var response = await dio.get(requestUrl, queryParameters: {
//
  // },options: Options(body:));
  // }
}
