import 'package:events_vu/API_KEY.dart';
import 'package:flutter/material.dart';
import 'package:map_view/map_view.dart';

class MapPage extends StatefulWidget {
  final String location;
  final double latitude;
  final double longitude;
  final MapView _mapView = MapView();
  final StaticMapProvider _staticMapProvider = StaticMapProvider(API_KEY);

  MapPage({Key key, this.location, this.latitude, this.longitude})
      : super(key: key);

  @override
  _MapPageState createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  String staticMapUri;
  double latitude;
  double longitude;

  @override
  void initState() {
    super.initState();
    latitude = widget.latitude ?? 36.145844;
    longitude = widget.longitude ?? -86.801838;
  }

  @override
  void dispose() {
    super.dispose();
    print('=============================\nDISPOSED\n');
  }

  void _handleExit() {
    widget._mapView.dismiss();
  }

  void _initMap(BuildContext context) {
    Marker marker;
    if (widget.latitude != null && widget.longitude != null)
      marker = Marker('1', widget.location, widget.latitude, widget.longitude);

    widget._mapView
      ..onMapReady.listen((_) {
        if (marker != null) widget._mapView.addMarker(marker);
      })
      ..onToolbarAction.listen((id) {
        if (id == 1)
          _handleExit();
        else if (id == 2) _addMarker(context);
      });

    _createStaticMap(context, marker);
  }

  void _createStaticMap(context, marker, [lat, lon]) {
    lat ??= latitude;
    lon ??= longitude;
    setState(() {
      staticMapUri = widget._staticMapProvider
          .getStaticUriWithMarkersAndZoom(marker ?? <Marker>[],
              center: Location(lat, lon),
              height: MediaQuery.of(context).size.height.toInt(),
              zoomLevel: 15)
          .toString();
    });
  }

  void _showMap() {
    List<ToolbarAction> actions = [];

    if (widget.latitude == null || widget.longitude == null)
      actions.add(ToolbarAction('Add Marker', 2));

    actions.add(ToolbarAction('Close', 1));

    widget._mapView.show(
      MapOptions(
        showMyLocationButton: true,
        showCompassButton: true,
        showUserLocation: true,
        initialCameraPosition:
            CameraPosition(Location(latitude, longitude), 15.0),
        title: widget.location,
      ),
      toolbarActions: actions,
    );
  }

  _addMarker(context) async {
    if (widget._mapView.markers.length > 0) return;

    Location currentLocation = await widget._mapView.centerLocation;

    widget._mapView.addMarker(Marker('1', widget.location,
        currentLocation.latitude, currentLocation.longitude,
        draggable: true));

    widget._mapView.onAnnotationDragEnd
        .listen((Map<Marker, Location> markerMap) {
      Marker marker = markerMap.keys.first;
      Location l = markerMap[
          marker]; // The actual position of the marker after finishing the dragging.
      _createStaticMap(
          context,
          [Marker('1', widget.location, l.latitude, l.longitude)],
          l.latitude,
          l.longitude);
      print("Annotation ${marker.id} dragging ended at ${l.toString()}");
    });
  }

  @override
  Widget build(BuildContext context) {
    _initMap(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.location),
      ),
      body: Column(
        children: <Widget>[
          staticMapUri == null
              ? Container()
              : InkWell(
                  onTap: () => _showMap(),
                  child: Image.network(staticMapUri),
                ),
          Text('Map'),
        ],
      ),
    );
  }
}
