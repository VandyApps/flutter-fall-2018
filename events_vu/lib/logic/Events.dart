import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rxdart/rxdart.dart';

// TODO
/*
The following link gets you:
1. Event website url via: items[0]['freeText'] if first word of items[0]['questionText'] is "Event"
2. Facebook event url via: items[1]['freeText'] if items[1]['questionText'] has 'Facebook' as first word
3. Additional documents if items[2]['questionText'] first words are "Additional Document"
  i. documentId via items[2]['documentId']
  ii. filename via items[2]['filename']
  iii. respondentId via items[2]['respondentId']
  iv. The file url via 'https://anchorlink.vanderbilt.edu/legacy/fileuploadquestion/
                        getdocument?documentId=${documentId}&respondentId=${respondentId}'
URL =  'https://anchorlink.vanderbilt.edu/api/discovery/event/${event._id}/additionalfields?'
*/

/// Encapsulates an event that is gotten from the anchorlink api
class Event {
  int id; // String
  int organizationId; // int
  List<int> organizationIds; // List<dynamic>
  String organizationName;
  List<String> organizationNames; // List<dynamic>
  String organizationProfilePicture;
  List<String> organizationProfilePictures;
  String name;
  String description;
  String location;
  DateTime startsOn; // String
  DateTime endsOn; // String
  // Default images associated with themes in same order:
  // 'https://static.campuslabsengage.com/discovery/images/events/' followed by
  // 'artsandmusic.jpg', 'athletics.jpg', 'service.jpg', 'cultural.jpg', 'fundraising.jpg',
  // 'groupbusiness.jpg', 'social.jpg', 'spirituality.jpg', 'learning.jpg'
  String imagePath;

  // possible themes:
  // 'Arts', 'Athletics', 'CommunityService', 'Cultural', 'Fundraising', 'GroupBusiness'
  // 'Social', 'Spirituality', 'ThoughtfulLearning'
  String theme;
  List<int> categoryIds; //? don't need
  List<String> categoryNames; // List<dynamic>
  List<String> benefitNames; // List<dynamic>
  double latitude; // String
  double longitude; // String

  // amount of time passed since event ended
  Duration timeAfterEnded;

  /// Default ctor
  Event(
      {this.id,
      this.organizationId,
      this.organizationIds,
      this.organizationName,
      this.organizationNames,
      this.organizationProfilePicture,
      this.organizationProfilePictures,
      this.name,
      this.description,
      this.location,
      this.startsOn,
      this.endsOn,
      this.imagePath,
      this.theme,
      this.categoryIds,
      this.categoryNames,
      this.benefitNames,
      this.latitude,
      this.longitude,
      this.timeAfterEnded});

  Future<List<String>> _getOrganizationPictures() {
    return http
        .get(
            'https://anchorlink.vanderbilt.edu/api/discovery/event/${id.toString()}/organizations?')
        .then((response) {
      List<dynamic> orgs = json.decode(response.body);
      return organizationIds.map((id) {
        String pic =
            orgs.singleWhere((org) => org['id'] == id)['profilePicture'];
        return pic != null
            ? 'https://se-infra-imageserver2.azureedge.net/clink/images/$pic?preset=small-sq'
            : null;
      }).toList();
    });
  }

  // returns true if updated and false if not
  void updateTime(DateTime now) {
    if (now.isAfter(endsOn)) {
      timeAfterEnded = now.difference(endsOn);
    }
  }

  Future<void> update(Map<String, dynamic> m) async {
    // id in integer form
    id = int.parse(m['id']);
    // organization in integer form
    organizationId = m['OorganizationId'];
    // multiple orgs
    organizationIds =
        m['organizationIds'].map<int>((item) => int.parse(item)).toList();
    // org name
    organizationName = m['organizationName'];
    organizationNames =
        m['organizationNames'].map<String>((item) => item as String).toList();
    // sets profile pic to null if one is not available
    organizationProfilePicture = m['organizationProfilePicture'] != null
        ? 'https://se-infra-imageserver2.azureedge.net/clink/images/${m['organizationProfilePicture']}?preset=small-sq'
        : null;
    // name of event
    name = m['name'];
    // event description in HTML
    description = m['description'];
    // event location (name)
    location = m['location'];
    // start time in DateTime format
    startsOn = DateTime.parse(m['startsOn']);
    // end time in DateTime format
    endsOn = DateTime.parse(m['endsOn']);
    // null if no image
    imagePath = m['imagePath'] != null
        ? 'https://se-infra-imageserver2.azureedge.net/clink/images/' +
            m['imagePath'] +
            '?preset=med-w'
        : null;
    // theme
    theme = m['theme'];
    categoryIds = m['categoryIds'].map<int>((item) => int.parse(item)).toList();
    categoryNames =
        m['categoryNames'].map<String>((item) => item as String).toList();
    benefitNames =
        m['benefitNames'].map<String>((item) => item as String).toList();
    // double lat
    latitude = m['latitude'] != null ? double.parse(m['latitude']) : null;
    // double long
    longitude = m['longitude'] != null ? double.parse(m['longitude']) : null;
    // sets imagePath correctly if it is null i.e. need a default image
    if (imagePath == null) {
      String defaultImg =
          'learning.jpg'; // if theme is null then this is the image
      if (theme != null) {
        // uses theme to get an image
        switch (theme) {
          case 'Arts':
            defaultImg = theme.toLowerCase() + 'andmusic.jpg';
            break;
          case 'ThoughtfulLearning':
          case 'CommunityService':
            defaultImg = theme
                    .toLowerCase()
                    .replaceAll(RegExp(r'thoughtful|community'), '') +
                '.jpg';
            break;
          default:
            defaultImg = theme.toLowerCase() + '.jpg';
            break;
        }
      }
      imagePath =
          'https://static.campuslabsengage.com/discovery/images/events/' +
              defaultImg;
    }

    updateTime(DateTime.now());

    if (organizationNames.length > 1) {
      organizationProfilePictures = await _getOrganizationPictures();
    }
    return Future<void>.value();
  }

  Future<Null> getLocationFromDatabase() {
    String key = location.replaceAll(RegExp(r'[^a-zA-Z]'), '').trim();
    return Firestore.instance
        .collection('locations')
        .getDocuments()
        .then((QuerySnapshot query) {
      DocumentSnapshot currentDoc = query.documents
          .firstWhere((doc) => doc.data.containsKey(key), orElse: () => null);

      if (currentDoc == null) {
        // No document with matching name
        // TODO create document in firebase
        if (latitude == null || longitude == null) {
          // No location with lat and lon :(
          // TODO make empty array
          Firestore.instance
              .collection('locations')
              .add({key: []})
              .then((_) => print('Created $key document'))
              .catchError(
                  (_) => print('Could not create document with key: $key'));
        } else {
          // TODO make array with lat & lon of l[focusIndex]
          Firestore.instance
              .collection('locations')
              .add({
                key: [
                  {'Location': GeoPoint(latitude, longitude), 'Confirmed': 0}
                ]
              })
              .then((_) => print('Created $key document'))
              .catchError(
                  (_) => print('Could not create document with key: $key'));
        }
      } else {
        // document has matching
        // OPTIONS:
        // preconditions: array should be sorted based on # confirmed (descending)
        // 1. no data => lat/lon = null
        // 2. data
        //    2.1. one location
        //        2.1.1. data but not confirmed => set lat/lon & flag
        //        2.1.2. data and confirmed => set lat/long & flag opposite of above
        //    2.2. multiple locations
        //        2.2.1. one confirmed, others are contesting => use confirmed??
        //        2.2.2. none confirmed => pick random
        //
        // Possibility: set expiration & increment each time not picked & reset if picked
        //              then throw away if expiration > some val
        if (latitude == null || longitude == null) {
          // No location with lat and lon :(
          // TODO
        } else {
          // TODO
        }
      }
    }).catchError((error) => print('ERROR IN LOADING DOCS: ${error.message}'));
  }
}

class Events {
  /// Default number of events to fetch
  static const int DEFAULT_NUMBER_EVENTS = 20;

  /// Time of query representing the time before the end of the first event
  /// in the entire list
  DateTime _timeOfQuery;

  List<EventBloc> _events;

  Events([int len = DEFAULT_NUMBER_EVENTS])
      : _events = <EventBloc>[],
        _timeOfQuery = DateTime.now() {
    getEvents(len);
  }

  int get length => _events.length;

  List<EventBloc> get list => _events;

  Future<void> getEvents([int len = DEFAULT_NUMBER_EVENTS]) {
    int originalLength = _events.length;
    _events.addAll(List.generate(DEFAULT_NUMBER_EVENTS, (_) => EventBloc()));
    return _getEventsRaw(len, originalLength == 0 ? null : originalLength)
        .then((dynamic l) {
      _updateEvents(l, originalLength);
    });
  }

  Future<dynamic> _getEventsRaw(int len, int skip) {
    return http
        .get(_getEventsUrl(numberOfEvents: len, skip: skip))
        .then((http.Response response) => json.decode(response.body)['value'])
        .catchError((Error error) {
      print('Failed to fetch data: ${error.toString()}');
      return null;
    });
  }

  String _getEventsUrl({int numberOfEvents = DEFAULT_NUMBER_EVENTS, int skip}) {
    final timeString =
        _timeOfQuery // always use the time of query to construct get request
            .toUtc()
            .toIso8601String()
            .replaceAll(RegExp(r':'), '%3A')
            .replaceAll(RegExp(r'\.[0-9]*'), '');

    // url for http get request
    return 'https://anchorlink.vanderbilt.edu/api/discovery/event/' // base api url
        'search?endsAfter=$timeString&orderByField=endsOn'
        '&orderByDirection=ascending&status=Approved&take=${numberOfEvents.toString()}&query=' +

        // if we are adding events then we want to skip however many we have currently
        (skip != null ? '&skip=${skip.toString()}' : '');
  }

  void _updateEvents(List<dynamic> l, int skip) {
    _events.asMap().forEach((int index, EventBloc eventBloc) =>
        index >= skip ? eventBloc.updateEvent(l[index - skip]) : null);
  }
}

class EventBloc {
  final _eventSubject = BehaviorSubject<Event>();
  final Event _event = Event();

  EventBloc() {
    _eventSubject.add(_event);
  }

  Stream<Event> get stream => _eventSubject.stream;

  void updateEvent(Map<String, dynamic> m) async {
    await _event.update(m);
    //await _event.getLocationFromDatabase();
    _eventSubject.add(_event);
  }
}
