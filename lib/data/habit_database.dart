// reference our box
import 'package:habit_tracker_app/datetime/date_time.dart';
import 'package:hive_flutter/hive_flutter.dart';

final _myBox = Hive.box("Habit_Database");

class HabitDatabase {
  List todayHabitList = [];
  Map<DateTime, int> heatMapDataSet = {};

  // create initial default data
  void createDefaultData() {
    todayHabitList = [
      ['run', false],
      ['read book', false],
    ];

    _myBox.put("START_DATE", todaysDateFormatted());
  }

  // load data if it already exsist
  void loadData() {
    // if its a new day , get habit list from database
    if (_myBox.get(todaysDateFormatted()) == null) {
      todayHabitList = _myBox.get("CURRENT_HABIT_LIST");
      // set all habit completed to false since its a new day
      for (int i = 0; i < todayHabitList.length; i++) {
        todayHabitList[i][1] = false;
      }
    }
    // if its not a new day, load  todays list
    else {
      todayHabitList = _myBox.get(todaysDateFormatted());
    }
  }

  // update database
  void updateDatabase() {
    // update todays entry
    _myBox.put(todaysDateFormatted(), todayHabitList);

    // update universal habit list  in case it changed (new habit , edit habit , delete habit )
    _myBox.put("CURRENT_HABIT_LIST", todayHabitList);

    // calculate habit complete precentages for each days
    calculateHabitPercentages();

    //load heat map
    loadHeatMap();
  }

  void calculateHabitPercentages() {
    int countCompleted = 0;
    for (var i = 0; i < todayHabitList.length; i++) {
      if (todayHabitList[i][1] == true) {
        countCompleted++;
      }
    }

    String precent = todayHabitList.isEmpty
        ? '0,0'
        : (countCompleted / todayHabitList.length).toStringAsFixed(1);
    // key "PERCENTAGE_SUMMARY_yyyymmdd"
    // value : string if ldp number between 0-1 inclusive
    _myBox.put("PERCENTAGE_SUMMARY_${todaysDateFormatted()}", precent);
  }

  void loadHeatMap() {
    DateTime startDate = createDateTimeObject(_myBox.get("START_DATE"));

    // count the number of days to load
    int daysInBetween = DateTime.now().difference(startDate).inDays;

    // go from start date to today and add each percentage to the dataset
    // "PERCENTAGE_SUMMARY_yyyymmdd" will be the key in the database
    for (int i = 0; i < daysInBetween + 1; i++) {
      String yyyymmdd = convertDateTimeToString(
        startDate.add(Duration(days: i)),
      );

      double strengthAsPercent = double.parse(
        _myBox.get("PERCENTAGE_SUMMARY_$yyyymmdd") ?? "0.0",
      );

      // split the datetime up like below so it doesn't worry about hours/mins/secs etc.

      // year
      int year = startDate.add(Duration(days: i)).year;

      // month
      int month = startDate.add(Duration(days: i)).month;

      // day
      int day = startDate.add(Duration(days: i)).day;

      final percentForEachDay = <DateTime, int>{
        DateTime(year, month, day): (10 * strengthAsPercent).toInt(),
      };

      heatMapDataSet.addEntries(percentForEachDay.entries);
      print(heatMapDataSet);
    }
  }
}
