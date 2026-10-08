enum RoomFilter { all, unreads, people, rooms, favourites }

extension RoomFilterLabel on RoomFilter {
  String get translationKey => switch (this) {
    RoomFilter.all => 'home_filter_all',
    RoomFilter.unreads => 'home_filter_unreads',
    RoomFilter.people => 'home_filter_people',
    RoomFilter.rooms => 'home_filter_rooms',
    RoomFilter.favourites => 'home_filter_favourites',
  };
}
