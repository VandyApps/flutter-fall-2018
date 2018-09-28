import 'package:flutter/material.dart';
import 'package:flutter_html_view/flutter_html_view.dart';
import 'package:intl/intl.dart';

class Events {
  List<Event> _eventsList; // list of Event objects

  Events() : _eventsList = <Event>[]; // set to empty list

  // creates Events object from a list (decoded json)
  Events.fromList(List<dynamic> l) : _eventsList = l.map((item) => Event.fromMap(item)).toList();

  List<Event> get list => _eventsList; // returns the list

  int get length => _eventsList.length; // returns length of list

  // adds events to list
  void add(List<dynamic> l) =>
      _eventsList.addAll(l.map<Event>((item) => Event.fromMap(item)).toList());

  // TODO: implement find methods for finding a certain event
  Event find([String time, String location, String org]) {
    return null;
  }
}

class Event {
  final int _id; // String
  final int _organizationId; // int
  final List<int> _organizationIds; // List<dynamic>
  final String _organizationName;
  final List<String> _organizationNames; // List<dynamic>
  final String _organizationProfilePicture;
  final String _name;
  final String _description;
  final String _location;
  final DateTime _startsOn; // String
  final DateTime _endsOn; // String
  // Default images associated with themes in same order:
  // 'https://static.campuslabsengage.com/discovery/images/events/' followed by
  // 'artsandmusic.jpg', 'athletics.jpg', 'service.jpg', 'cultural.jpg', 'fundraising.jpg',
  // 'groupbusiness.jpg', 'social.jpg', 'spirituality.jpg', 'learning.jpg'
  String _imagePath;

  // possible themes:
  // 'Arts', 'Athletics', 'CommunityService', 'Cultural', 'Fundraising', 'GroupBusiness'
  // 'Social', 'Spirituality', 'ThoughtfulLearning'
  final String _theme;
  final List<int> _categoryIds; //? don't need
  final List<String> _categoryNames; // List<dynamic>
  final List<String> _benefitNames; // List<dynamic>
  final double _latitude; // String
  final double _longitude; // String

  Event.fromMap(Map<String, dynamic> m)
      : _id = int.parse(m['Id']),
        // id in integer form
        _organizationId = m['OrganizationId'],
        // organization in integer form
        _organizationIds = m['OrganizationIds'].map<int>((item) => int.parse(item)).toList(),
        // multiple orgs
        _organizationName = m['OrganizationName'],
        // org name
        _organizationNames = m['OrganizationNames'].map<String>((item) => item as String).toList(),
        _organizationProfilePicture = m['OrganizationProfilePicture'] != null
            ? 'https://se-infra-imageserver2.azureedge.net/clink/images/${m['OrganizationProfilePicture']}?preset=small-sq'
            : null,
        // sets profile pic to null if one is not available
        _name = m['Name'],
        // name of event
        _description = m['Description'],
        // event description in HTML
        _location = m['Location'],
        // event location (name)
        _startsOn = DateTime.parse(m['StartsOn']),
        // start time in DateTime format
        _endsOn = DateTime.parse(m['EndsOn']),
        // end time in DateTime format
        _imagePath = m['ImagePath'] != null
            ? 'https://se-infra-imageserver2.azureedge.net/clink/images/' +
                m['ImagePath'] +
                '?preset=med-w'
            : null,
        // null if no image
        _theme = m['Theme'],
        // theme
        _categoryIds = m['CategoryIds'].map<int>((item) => int.parse(item)).toList(),
        _categoryNames = m['CategoryNames'].map<String>((item) => item as String).toList(),
        _benefitNames = m['BenefitNames'].map<String>((item) => item as String).toList(),
        _latitude = m['Latitude'] != null ? double.parse(m['Latitude']) : null,
        // double lat
        _longitude = m['Longitude'] != null ? double.parse(m['Longitude']) : null // double long
  {
    // sets _imagePath correctly if it is null i.e. need a default image
    if (_imagePath == null) {
      String defaultImg = 'learning.jpg'; // if _theme is null then this is the image
      if (_theme != null) {
        // uses theme to get an image
        switch (_theme) {
          case 'Arts':
            defaultImg = _theme.toLowerCase() + 'andmusic.jpg';
            break;
          case 'ThoughtfulLearning':
          case 'CommunityService':
            defaultImg =
                _theme.toLowerCase().replaceAll(RegExp(r'thoughtful|community'), '') + '.jpg';
            break;
          default:
            defaultImg = _theme.toLowerCase() + '.jpg';
            break;
        }
      }
      _imagePath = 'https://static.campuslabsengage.com/discovery/images/events/' + defaultImg;
    }
  }
}

class EventContainer extends StatelessWidget {
  final Event event;

  EventContainer({
    Key key,
    this.event,
  }) : super(key: key);

  String _getStartDateString(DateTime d) {
    d = d.toLocal();
    String formatStr = "EEEE, MMMM d, yyyy 'at' h:mma";
    // if it is the year we are currently in, then don't show the year, otherwise show it
    if (d.year == DateTime.now().year) formatStr = formatStr.replaceAll(RegExp(', yyyy'), '');
    return DateFormat(formatStr, 'en_US').format(d) + d.timeZoneName;
  }

  @override
  Widget build(BuildContext context) {
    BorderRadius borderRadius = BorderRadius.circular(4.0);
    double profilePicScale = 2.0;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
      shape: RoundedRectangleBorder(
        borderRadius: borderRadius,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          ClipRRect(
            borderRadius:
                BorderRadius.only(topLeft: borderRadius.topLeft, topRight: borderRadius.topRight),
            child: Image.network(
              event._imagePath,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Text(
                    event._name ?? 'No name provided',
                    style: Theme.of(context).textTheme.headline,
                    textAlign: TextAlign.left,
                  ),
                ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Icon(
                      Icons.event,
                      semanticLabel: 'Location',
                    ),
                    Expanded(
                      flex: 1,
                      child: Padding(
                        padding: const EdgeInsets.only(left: 4.0),
                        child: Text(event._startsOn != null
                            ? _getStartDateString(event._startsOn)
                            : 'No started date provided'),
                      ),
                    ),
                  ],
                ),
                Row(
                  children: <Widget>[
                    Icon(Icons.location_on),
                    Expanded(
                      flex: 1,
                      child: Padding(
                        padding: const EdgeInsets.only(left: 4.0),
                        child: Text(event._location ?? ''),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 4.0),
            child: Container(
              color: Colors.grey[100],
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    ClipOval(
                      child: event._organizationProfilePicture != null
                          ? Image.network(
                              event._organizationProfilePicture,
                              scale: profilePicScale,
                            )
                          : Container(
                              color: Colors.blueGrey,
                              constraints: BoxConstraints.expand(
                                width: 75.0 / profilePicScale,
                                height: 75.0 / profilePicScale,
                              ),
                              child: Center(
                                child: Text(
                                  event._organizationName[0],
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 40 / profilePicScale,
                                    fontWeight: FontWeight.w300,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                    ), // for event._organizationProfilePicture
                    Expanded(
                      flex: 1,
                      child: Padding(
                        padding: const EdgeInsets.only(left: 8.0),
                        child: Text(event._organizationName ?? 'Unknown Organization'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class EventPage extends StatelessWidget {
  final Event event;

  EventPage({
    Key key,
    this.event,
  }) : super(key: key);

  // Two ways of displaying time of event:
  //    if on same day: <weekday>, <month> <day>, <year> [from] <startTime> - <endTime>
  //    if not on same: <weekday>, <month> <day>, <year> at <startTime> to
  //                    <weekday>, <month> <day>, <year> at <endTime>

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Text(event._id.toString()),
        Text(event._name ?? ''),
        Text(event._description),
        HtmlView(
          data: event._description ?? '',
        ),
        Text(event._startsOn ?? ''),
        Text(event._endsOn ?? ''),
        Text(event._id.toString() ?? ''),
        Text(event._imagePath ?? ''),
        Text(event._latitude.toString() ?? ''),
        Text(event._longitude.toString() ?? ''),
        Text(event._location ?? ''),
        Image.network(event._organizationProfilePicture),
        Text(event._organizationName ?? ''),
        Text(event._organizationNames?.join(" ")),
        Text(event._theme ?? ''),
      ],
    );
  }
}
//final String _location;
//final DateTime _startsOn; // String
//final DateTime _endsOn; // String
//String _imagePath;
//final String _theme;
//final List<int> _categoryIds; //? don't need
//final List<String> _categoryNames; // List<dynamic>
//final List<String> _benefitNames; // List<dynamic>
//final double _latitude; // String
//final double _longitude; // String
