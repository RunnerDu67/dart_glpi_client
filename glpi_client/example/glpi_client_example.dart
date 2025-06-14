import 'package:glpi_client/glpi_client.dart';

void main() async {
  String apiUrl = "";
  String appToken = "";
  String userToken = "";
  final glpi = GlpiService(apiUrl: apiUrl, appToken: appToken, userToken: userToken);
  await glpi.initSession();
  Map<String, dynamic> ticket = await glpi.getItem("Ticket", 5);
  print(ticket);

  String itemType = "Phone";
  List<Map<String, dynamic>>? criteria = [{}];
  List<String>? forcedisplay = ['2', '5'];
  List<dynamic> phones = await glpi.searchItems(itemType: itemType, criteria: criteria, forcedisplay: forcedisplay);
  for (var phone in phones) {
    print(phone);
  }
  glpi.killSession();
}
