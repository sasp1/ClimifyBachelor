import 'package:climify/models/api_response.dart';
import 'package:climify/models/buildingModel.dart';
import 'package:climify/models/globalState.dart';
import 'package:climify/routes/dialogues/addBuilding.dart';
import 'package:climify/services/bluetooth.dart';
import 'package:climify/services/rest_service.dart';
import 'package:climify/services/snackbarError.dart';
import 'package:climify/widgets/customDialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue/flutter_blue.dart';
import 'package:provider/provider.dart';
import 'package:tuple/tuple.dart';

class BuildingList extends StatefulWidget {
  final GlobalKey<ScaffoldState> scaffoldKey;

  const BuildingList({
    Key key,
    @required this.scaffoldKey,
  }) : super(key: key);

  @override
  BuildingListState createState() => BuildingListState();
}

class BuildingListState extends State<BuildingList> {
  GlobalKey<ScaffoldState> _scaffoldKey;
  BluetoothServices _bluetooth = BluetoothServices();
  RestService _restService = RestService();
  List<BuildingModel> _buildings = [];
  List<Tuple2<String, String>> _beaconList = [];
  String buildingId = "";
  TextEditingController _buildingNameTextController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _scaffoldKey = widget.scaffoldKey;
    getBuildings();
    _getBLEDevicesList();
  }

  List<DropdownMenuItem<BuildingModel>> buildDropdownMenuItems1(
      List<BuildingModel> buildings) {
    List<DropdownMenuItem<BuildingModel>> items = List();
    for (BuildingModel building in buildings) {
      items.add(
        DropdownMenuItem(
          value: building,
          child: Text(building.name),
        ),
      );
    }
    return items;
  }

  List<DropdownMenuItem<Tuple2<String, String>>> buildDropdownMenuItems2(
      List<Tuple2<String, String>> beacons) {
    List<DropdownMenuItem<Tuple2<String, String>>> items = List();
    for (Tuple2<String, String> beacon in beacons) {
      items.add(
        DropdownMenuItem(
          value: beacon,
          child: Text(beacon.item1),
        ),
      );
    }
    return items;
  }

  Future<void> getBuildings() async {
    await Future.delayed(Duration.zero);
    String token = Provider.of<GlobalState>(context).globalState['token'];
    APIResponse<List<BuildingModel>> buildingsResponse =
        await _restService.getBuildingsWithAdminRights(token);
    if (buildingsResponse.error) return;
    setState(() {
      _buildings = buildingsResponse.data;
    });
  }

  void _focusBuilding(BuildingModel building) {
    Provider.of<GlobalState>(context).updateBuilding(building);
    Navigator.of(context)
        .pushNamed("buildingManager")
        .then((value) => getBuildings());
  }

  void _getBLEDevicesList() async {
    if (!await _bluetooth.isOn) {
      SnackBarError.showErrorSnackBar("Bluetooth is not on", _scaffoldKey);
      return;
    }
    _scan();
  }

  void _scan() async {
    if (await _bluetooth.isOn == false) return;
    List<Tuple2<String, String>> beaconList = [];
    List<ScanResult> scanResults = await _bluetooth.scanForDevices(4000);
    scanResults.forEach((result) {
      setState(() {});
      String beaconName = _bluetooth.getBeaconName(result);
      List<String> serviceUuids = result.advertisementData.serviceUuids;
      String beaconId = serviceUuids.isNotEmpty ? serviceUuids[0] : "";
      RegExp regex = RegExp(r'^[a-zA-Z0-9]{4,6}$');
      if (beaconName != "" && regex.hasMatch(beaconName)) {
        Tuple2<String, String> item =
            new Tuple2<String, String>(beaconName, beaconId);
        beaconList.add(item);
      }
    });
    setState(() {
      _beaconList = beaconList;
    });
  }

  void _deleteBuilding(){
    
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      child: RefreshIndicator(
        onRefresh: () => getBuildings(),
        child: Container(
          child: ListView.builder(
            padding: EdgeInsets.symmetric(
              horizontal: 8,
              vertical: 4,
            ),
            itemCount: _buildings.length,
            itemBuilder: (_, index) => _buildingRow(_buildings[index]),
          ),
        ),
      ),
    );
  }

  Widget _buildingRow(BuildingModel building) {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(),
        ),
      ),
      child: Material(
        child: InkWell(
          onTap: () => _focusBuilding(building),
          child: SizedBox(
            width: double.infinity,
            child: Center(
              child: Container(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  building.name,
                  style: TextStyle(
                    fontSize: 24,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
