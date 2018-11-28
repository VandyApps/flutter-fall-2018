import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rxdart/rxdart.dart';

/// Wrapper for a list of events
class Events {
  /// Default number of events to fetch
  static const int DEFAULT_NUMBER_EVENTS = 20;

  /// List of Event objects
  List<Event> _eventsList;

  /// Time of query representing the time before the end of the first event
  /// in the entire list
  DateTime _timeOfQuery;

  /// Constructor that takes a length
  /// Will initially set the events to empty until a future returns with the
  /// data from the network
  Events(int len)
      : _eventsList = List.generate(len, (index) => Event()),
        _timeOfQuery = DateTime.now() {
    _getEvents(len).then((List<dynamic> l) => _eventsList
        .asMap()
        .forEach((int index, Event event) => event.update(l[index])));
  }

  Future<List<dynamic>> _getEvents(int len) {
    return http
        .get(_getEventsUrl())
        .then((http.Response response) => json.decode(response.body)['value'])
        .catchError((Error error) {
      print('Failed to fetch data: ${error.toString()}');
      return null;
    });
  }

  String _getEventsUrl(
      {bool add = false, int numberOfEvents = DEFAULT_NUMBER_EVENTS}) {
    final timeString =
        _timeOfQuery // always use the time of query to construct get request
            .toUtc()
            .toIso8601String()
            .replaceAll(RegExp(r':'), '%3A')
            .replaceAll(RegExp(r'\.[0-9]*'), '');

    // url for http get request
    return 'https://anchorlink.vanderbilt.edu/api/discovery/' // base api url
        'search/events?filter=EndsOn%20ge%20$timeString&top='
        '${numberOfEvents.toString()}&orderBy%5B0%5D=EndsOn%20asc&query='
        '&context=%7B%22branchIds%22%3A%5B%5D%7D' +

        // if we are adding events then we want to skip however many we have currently
        (add ? '&skip=${this.length.toString()}' : '');
  }

//  /// Factory method
//  /// creates Events object from a list of decoded json
//  Events.fromJson(String j)
//      : _eventsList = _getLocationsFromDatabase(json
//            .decode(j)['value']
//            .map<Event>((item) => Event.fromMap(item))
//            .toList());

  /// Getter for the list
  List<Event> get list => _eventsList; // returns the list

  /// Getter for length of list
  int get length => _eventsList.length; // returns length of list

  /// Adds events from decoded json list l to this
  /// adds locations to dbLocations set
  void add(String j) => _eventsList.addAll(_getLocationsFromDatabase(json
      .decode(j)['value']
      .map<Event>((item) => Event.fromMap(item))
      .toList()));

  // TODO: implement find methods for finding a certain event
  Event find([String time, String location, String org]) {
    return null;
  }

  /// Gets the locations from Firebase database using an iterator
  static List<Event> _getLocationsFromDatabase(List<Event> l) {
    //l.asMap().map<String, Event>((int key, event) => MapEntry(event.location.replaceAll(RegExp(r'[0-9]|/'), '').trim(), event));

    Map<String, List<int>> mappingKey = l.asMap().map<String, List<int>>((_,
            event) =>
        MapEntry(event.location.replaceAll(RegExp(r'[0-9]|/'), '').trim(), []));

    for (int i = 0; i < l.length; ++i)
      mappingKey[l[i].location.replaceAll(RegExp(r'[0-9]|/'), '').trim()]
          .add(i);

    Firestore.instance
        .collection('locations')
        .getDocuments()
        .then((QuerySnapshot query) {
      mappingKey.forEach((key, list) {
        DocumentSnapshot currentDoc = query.documents
            .firstWhere((doc) => doc.data.containsKey(key), orElse: () => null);

        if (currentDoc == null) {
          // No document with matching name
          // TODO create document in firebase
          int focusIndex = list.firstWhere(
              (index) =>
                  l[index].latitude != null && l[index].longitude != null,
              orElse: () => null);
          if (focusIndex == null) {
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
                    {
                      'Location': GeoPoint(
                          l[focusIndex].latitude, l[focusIndex].longitude),
                      'Confirmed': 0
                    }
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
          int focusIndex = list.firstWhere(
              (index) =>
                  l[index].latitude != null && l[index].longitude != null,
              orElse: () => null);
          if (focusIndex == null) {
            // No location with lat and lon :(
            // TODO
          } else {
            // TODO
          }
        }
      });
    }).catchError((error) => print('ERROR IN LOADING DOCS: ${error.message}'));

    return l;
  }
}

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

  // TODO remove this later
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

//  Event.fromMap(Map<String, dynamic> m)
//      :
//        // id in integer form
//        _id = int.parse(m['Id']),
//        // organization in integer form
//        _organizationId = m['OrganizationId'],
//        // multiple orgs
//        _organizationIds =
//            m['OrganizationIds'].map<int>((item) => int.parse(item)).toList(),
//        // org name
//        organizationName = m['OrganizationName'],
//        organizationNames = m['OrganizationNames']
//            .map<String>((item) => item as String)
//            .toList(),
//        // sets profile pic to null if one is not available
//        organizationProfilePicture = m['OrganizationProfilePicture'] != null
//            ? 'https://se-infra-imageserver2.azureedge.net/clink/images/${m['OrganizationProfilePicture']}?preset=small-sq'
//            : null,
//        // name of event
//        name = m['Name'],
//        // event description in HTML
//        description = m['Description'],
//        // event location (name)
//        location = m['Location'],
//        // start time in DateTime format
//        startsOn = DateTime.parse(m['StartsOn']),
//        // end time in DateTime format
//        endsOn = DateTime.parse(m['EndsOn']),
//        // null if no image
//        imagePath = m['ImagePath'] != null
//            ? 'https://se-infra-imageserver2.azureedge.net/clink/images/' +
//                m['ImagePath'] +
//                '?preset=med-w'
//            : null,
//        // theme
//        theme = m['Theme'],
//        categoryIds =
//            m['CategoryIds'].map<int>((item) => int.parse(item)).toList(),
//        categoryNames =
//            m['CategoryNames'].map<String>((item) => item as String).toList(),
//        benefitNames =
//            m['BenefitNames'].map<String>((item) => item as String).toList(),
//        // double lat
//        latitude = m['Latitude'] != null ? double.parse(m['Latitude']) : null,
//        // double long
//        longitude =
//            m['Longitude'] != null ? double.parse(m['Longitude']) : null {
//    // sets imagePath correctly if it is null i.e. need a default image
//    if (imagePath == null) {
//      String defaultImg =
//          'learning.jpg'; // if theme is null then this is the image
//      if (theme != null) {
//        // uses theme to get an image
//        switch (theme) {
//          case 'Arts':
//            defaultImg = theme.toLowerCase() + 'andmusic.jpg';
//            break;
//          case 'ThoughtfulLearning':
//          case 'CommunityService':
//            defaultImg = theme
//                    .toLowerCase()
//                    .replaceAll(RegExp(r'thoughtful|community'), '') +
//                '.jpg';
//            break;
//          default:
//            defaultImg = theme.toLowerCase() + '.jpg';
//            break;
//        }
//      }
//      imagePath =
//          'https://static.campuslabsengage.com/discovery/images/events/' +
//              defaultImg;
//    }
//
//    if (organizationNames.length > 1) {
//      _getOrganizationPictures();
//    }
//  }

  void _getOrganizationPictures() {
    http
        .get(
            'https://anchorlink.vanderbilt.edu/api/discovery/event/${id.toString()}/organizations?')
        .then((response) {
      List<dynamic> orgs = json.decode(response.body);
      organizationProfilePictures = organizationIds.map((id) {
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

  // TODO update every field with given list
  void update(Map<String, dynamic> m) {
    // id in integer form
    id = int.parse(m['Id']);
    // organization in integer form
    organizationId = m['OrganizationId'];
    // multiple orgs
    organizationIds =
        m['OrganizationIds'].map<int>((item) => int.parse(item)).toList();
    // org name
    organizationName = m['OrganizationName'];
    organizationNames =
        m['OrganizationNames'].map<String>((item) => item as String).toList();
    // sets profile pic to null if one is not available
    organizationProfilePicture = m['OrganizationProfilePicture'] != null
        ? 'https://se-infra-imageserver2.azureedge.net/clink/images/${m['OrganizationProfilePicture']}?preset=small-sq'
        : null;
    // name of event
    name = m['Name'];
    // event description in HTML
    description = m['Description'];
    // event location (name)
    location = m['Location'];
    // start time in DateTime format
    startsOn = DateTime.parse(m['StartsOn']);
    // end time in DateTime format
    endsOn = DateTime.parse(m['EndsOn']);
    // null if no image
    imagePath = m['ImagePath'] != null
        ? 'https://se-infra-imageserver2.azureedge.net/clink/images/' +
            m['ImagePath'] +
            '?preset=med-w'
        : null;
    // theme
    theme = m['Theme'];
    categoryIds = m['CategoryIds'].map<int>((item) => int.parse(item)).toList();
    categoryNames =
        m['CategoryNames'].map<String>((item) => item as String).toList();
    benefitNames =
        m['BenefitNames'].map<String>((item) => item as String).toList();
    // double lat
    latitude = m['Latitude'] != null ? double.parse(m['Latitude']) : null;
    // double long
    longitude = m['Longitude'] != null ? double.parse(m['Longitude']) : null;
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

    if (organizationNames.length > 1) {
      _getOrganizationPictures();
    }
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
      : _events = List.generate(len, (_) => EventBloc()),
        _timeOfQuery = DateTime.now() {
    _getEvents(len).then((List<dynamic> l) => _updateEvents(l));
  }

  Future<List<dynamic>> _getEvents(int len) {
    return http
        .get(_getEventsUrl(numberOfEvents: len))
        .then((http.Response response) => json.decode(response.body)['value'])
        .catchError((Error error) {
      print('Failed to fetch data: ${error.toString()}');
      return null;
    });
  }

  String _getEventsUrl(
      {bool add = false, int numberOfEvents = DEFAULT_NUMBER_EVENTS}) {
    final timeString =
        _timeOfQuery // always use the time of query to construct get request
            .toUtc()
            .toIso8601String()
            .replaceAll(RegExp(r':'), '%3A')
            .replaceAll(RegExp(r'\.[0-9]*'), '');

    // url for http get request
    return 'https://anchorlink.vanderbilt.edu/api/discovery/' // base api url
        'search/events?filter=EndsOn%20ge%20$timeString&top='
        '${numberOfEvents.toString()}&orderBy%5B0%5D=EndsOn%20asc&query='
        '&context=%7B%22branchIds%22%3A%5B%5D%7D' +

        // if we are adding events then we want to skip however many we have currently
        (add ? '&skip=${this._events.length.toString()}' : '');
  }

  void _updateEvents(List<dynamic> l) {
    _events.asMap().forEach(
        (int index, EventBloc eventBloc) => eventBloc.updateEvent(l[index]));
  }
}

class EventBloc {
  final _eventSubject = BehaviorSubject<Event>();
  final Event _event = Event();

  EventBloc() {
    _eventSubject.add(_event);
  }

  Stream<Event> get event => _eventSubject.stream;

  void updateEvent(Map<String, dynamic> m) {
    _event.update(m);
    _eventSubject.add(_event);
  }
}
