library date_strip_report;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:jiffy/jiffy.dart';
import 'i18n_calendar_strip.dart';


class DateStripReport extends StatefulWidget {
  final Function onDateSelected;
  final DateTime startDate;
  final DateTime endDate;
  final bool isShowMonth;
  final bool isShowQuarter;
  final bool isShowHalfYear;
  final bool isShowYear;
  final Icon rightIcon;
  final Icon leftIcon;
  final Color navigationColor;
  final Color navigationDisableColor;
  final Color selectedColor;
  final Color unSelectedColor;
  final Color textColor;
  final LocaleType locale;

  DateStripReport({
    @required this.onDateSelected,
    this.startDate,
    this.endDate,
    this.rightIcon,
    this.leftIcon,
    this.isShowMonth=true,
    this.isShowQuarter=true,
    this.isShowHalfYear=true,
    this.isShowYear=true,
    this.navigationColor = Colors.black,
    this.navigationDisableColor = Colors.black12,
    this.selectedColor = Colors.blue,
    this.unSelectedColor = Colors.white,
    this.textColor = Colors.black,
    this.locale = LocaleType.en,
  });

  State<DateStripReport> createState() =>
      DateStripReportState(startDate, endDate);
}

class DateStripReportState extends State<DateStripReport>
    with TickerProviderStateMixin {
  bool enbaleNext = true, enbalePrevious = true;
  DateType _dateType;
  DateTime _selectedDate = DateTime.now();
  int _selectedQuarter;
  int _selectedHaft;

  DateStripReportState(DateTime startDate, DateTime endDate) {
    runPresetsAndExceptions(_selectedDate, startDate, endDate);
  }

  runPresetsAndExceptions(selectedDate, startDate, endDate) {
    if ((startDate == null && endDate != null) ||
        (startDate != null && endDate == null)) {
      throw Exception(
          "Both 'startDate' and 'endDate' are mandatory to specify range");
    } else if (selectedDate != null &&
        (isDateBefore(selectedDate, startDate) ||
            isDateAfter(selectedDate, endDate))) {
      throw Exception("Selected Date is out of range from start and end dates");
    }

  }

  @override
  void initState() {

    if(!widget.isShowQuarter && !widget.isShowHalfYear&& !widget.isShowYear){
    }
    _dateType = DateType.month;
    _selectedDate = DateTime.now();
    _selectedQuarter = (_selectedDate.month/3).round();
    _selectedHaft = (_selectedDate.month/6).ceil();
    setReturnDate();
    super.initState();

  }

  isDateBefore(date1, date2) {
    DateTime _date1 = DateTime(date1.year, date1.month, date1.day);
    DateTime _date2 = DateTime(date2.year, date2.month, date2.day);
    return _date1.isBefore(_date2);
  }

  isDateAfter(date1, date2) {
    DateTime _date1 = DateTime(date1.year, date1.month, date1.day);
    DateTime _date2 = DateTime(date2.year, date2.month, date2.day).subtract(Duration(days: 1));
    return _date1.isAfter(_date2);
  }

  DateTime getDateOnly(DateTime dateTimeObj) {
    return DateTime(dateTimeObj.year, dateTimeObj.month, dateTimeObj.day);
  }

  nullOrDefault(var normalValue, var defaultValue) {
    if (normalValue == null) {
      return defaultValue;
    }
    return normalValue;
  }


  String _localeYear(int year) {
    if (widget.locale == LocaleType.zh || widget.locale == LocaleType.jp) {
      return '年 $year';
    } else if (widget.locale == LocaleType.ko) {
      return '년 $year';
    } else {
      return '$year';
    }
  }
  String _localeMonth(int month) {
    if (widget.locale == LocaleType.zh || widget.locale == LocaleType.jp) {
      return '$month月';
    } else if (widget.locale == LocaleType.ko) {
      return '$month월';
    } else {
      List monthStrings = i18nObjInLocale(widget.locale)['monthLong'];
      return monthStrings[month - 1];
    }
  }
  String _localeQuarter(int quarter) {
    print(quarter);
    if (widget.locale == LocaleType.zh || widget.locale == LocaleType.jp) {
      return '$quarter';
    } else if (widget.locale == LocaleType.ko) {
      return '$quarter';
    } else {
      List quarterStrings = i18nObjInLocale(widget.locale)['quarter'];
      return quarterStrings[quarter - 1];
    }
  }
  String _localeHalfYear(int number) {
    print(number);
    if (widget.locale == LocaleType.zh || widget.locale == LocaleType.jp) {
      return '$number';
    } else if (widget.locale == LocaleType.ko) {
      return '$number';
    } else {
      List textStrings = i18nObjInLocale(widget.locale)['halfYear'];
      return textStrings[number - 1];
    }
  }


  String _localeMonthly() {
    if (widget.locale == LocaleType.zh || widget.locale == LocaleType.jp) {
      return '日';
    } else if (widget.locale == LocaleType.ko) {
      return '일';
    } else {
      return i18nObjInLocale(widget.locale)['monthly'];
    }
  }
  String _localeQuarterly() {
    if (widget.locale == LocaleType.zh || widget.locale == LocaleType.jp) {
      return '日';
    } else if (widget.locale == LocaleType.ko) {
      return '일';
    } else {
      return i18nObjInLocale(widget.locale)['quarterly'];
    }
  }
  String _localeHalfYearly() {
    if (widget.locale == LocaleType.zh || widget.locale == LocaleType.jp) {
      return '日';
    } else if (widget.locale == LocaleType.ko) {
      return '일';
    } else {
      return i18nObjInLocale(widget.locale)['halfYearly'];
    }
  }
  String _localeYearly() {
    if (widget.locale == LocaleType.zh || widget.locale == LocaleType.jp) {
      return '日';
    } else if (widget.locale == LocaleType.ko) {
      return '일';
    } else {
      return i18nObjInLocale(widget.locale)['yearly'];
    }
  }

  _resetNavigationButton(DateType dateType){
    if (DateType.month == dateType) {
      enbalePrevious = (widget.startDate == null ||  isDateAfter(Jiffy(_selectedDate).subtract(months: 1),widget.startDate));
      enbaleNext = (widget.endDate == null || isDateBefore(Jiffy(_selectedDate).add(months: 1),widget.endDate));
    } else if (DateType.quarter == dateType) {
      _selectedQuarter = (_selectedDate.month/3).ceil();
      enbalePrevious = (widget.startDate == null ||  isDateAfter(Jiffy(_selectedDate).subtract(months: 3),widget.startDate));
      enbaleNext = (widget.endDate == null || isDateBefore(Jiffy(_selectedDate).add(months: 3),widget.endDate));
    } else if (DateType.half == dateType) {
      _selectedHaft = (_selectedDate.month/6).ceil();
      enbalePrevious = (widget.startDate == null ||  isDateAfter(Jiffy(_selectedDate).subtract(months: 6),widget.startDate));
      enbaleNext = (widget.endDate == null || isDateBefore(Jiffy(_selectedDate).add(months: 6),widget.endDate));
    }else if (DateType.year == dateType) {
      enbalePrevious = (widget.startDate == null ||  isDateAfter(Jiffy(_selectedDate).subtract(years: 1),widget.startDate));
      enbaleNext = (widget.endDate == null || isDateBefore(Jiffy(_selectedDate).add(years: 1),widget.endDate));
    }
    setReturnDate();
    }

  setReturnDate(){
    var result = new ResultDate();

    if (DateType.month == _dateType) {
      result.fromDate = new DateTime(_selectedDate.year,_selectedDate.month,1);
      result.toDate = new DateTime(_selectedDate.year,_selectedDate.month+1,1).subtract(Duration(days: 1));
      result.info = _localeMonth(_selectedDate.month);
    } else if (DateType.quarter == _dateType) {
      _selectedQuarter = (_selectedDate.month/3).ceil();
      result.fromDate = new DateTime(_selectedDate.year,((_selectedQuarter-1)*3)+1,1);
      result.toDate = new DateTime(_selectedDate.year,((_selectedQuarter)*3)+1,1).subtract(Duration(days: 1));
      result.info = _localeQuarter(_selectedQuarter);
    } else if (DateType.half == _dateType) {
      _selectedHaft = (_selectedDate.month/6).ceil();
      result.fromDate = new DateTime(_selectedDate.year,((_selectedHaft-1)*6)+1,1);
      result.toDate = new DateTime(_selectedDate.year,((_selectedHaft)*6)+1,1).subtract(Duration(days: 1));
      result.info = _localeHalfYear(_selectedHaft);
    }else if (DateType.year == _dateType) {
      result.fromDate = new DateTime(_selectedDate.year,1,1);
      result.toDate = new DateTime(_selectedDate.year+1,1,1).subtract(Duration(days: 1));
      result.info = _localeYear(_selectedDate.year);
    }
    widget.onDateSelected(result);
  }

  getNextMonth(){
    setState(() {
      _selectedDate = Jiffy(_selectedDate).add(months: 1);
      enbalePrevious = (widget.startDate == null ||  isDateAfter(Jiffy(_selectedDate).subtract(months: 1),widget.startDate));
      enbaleNext = (widget.endDate == null || isDateBefore(Jiffy(_selectedDate).add(months: 1),widget.endDate));
      setReturnDate();
    });
  }
  getPreviousMonth(){
    setState(() {
      _selectedDate = Jiffy(_selectedDate).subtract(months: 1);
      enbalePrevious = (widget.startDate == null ||  isDateAfter(Jiffy(_selectedDate).subtract(months: 1),widget.startDate));
      enbaleNext = (widget.endDate == null || isDateBefore(Jiffy(_selectedDate).add(months: 1),widget.endDate));
      setReturnDate();
    });
  }

  getNextQuarter(){
    setState(() {
      _selectedDate = Jiffy(_selectedDate).add(months: 3);
      _selectedQuarter = (_selectedDate.month/3).ceil();
      enbalePrevious = (widget.startDate == null ||  isDateAfter(Jiffy(_selectedDate).subtract(months: 3),widget.startDate));
      enbaleNext = (widget.endDate == null || isDateBefore(Jiffy(_selectedDate).add(months: 3),widget.endDate));
      setReturnDate();
    });
  }
  getPreviousQuarter(){
    setState(() {
      _selectedDate = Jiffy(_selectedDate).subtract(months: 3);
      _selectedQuarter = (_selectedDate.month/3).ceil();
      enbalePrevious = (widget.startDate == null ||  isDateAfter(Jiffy(_selectedDate).subtract(months: 3),widget.startDate));
      enbaleNext = (widget.endDate == null || isDateBefore(Jiffy(_selectedDate).add(months: 3),widget.endDate));
      setReturnDate();
    });
  }

  getNextHalf(){
    setState(() {
      _selectedDate = Jiffy(_selectedDate).add(months: 6);
      _selectedHaft = (_selectedDate.month/6).ceil();
      enbalePrevious = (widget.startDate == null ||  isDateAfter(Jiffy(_selectedDate).subtract(months: 6),widget.startDate));
      enbaleNext = (widget.endDate == null || isDateBefore(Jiffy(_selectedDate).add(months: 6),widget.endDate));
      setReturnDate();
    });
  }
  getPreviousHalf(){
    setState(() {
      _selectedDate = Jiffy(_selectedDate).subtract(months: 6);
      _selectedHaft = (_selectedDate.month/6).ceil();
      enbalePrevious = (widget.startDate == null ||  isDateAfter(Jiffy(_selectedDate).subtract(months: 6),widget.startDate));
      enbaleNext = (widget.endDate == null || isDateBefore(Jiffy(_selectedDate).add(months: 6),widget.endDate));
      setReturnDate();
    });
  }

  getNextYear(){
    setState(() {
      _selectedDate = Jiffy(_selectedDate).add(years: 1);
      enbalePrevious = (widget.startDate == null ||  isDateAfter(Jiffy(_selectedDate).subtract(years: 1),widget.startDate));
      enbaleNext = (widget.endDate == null || isDateBefore(Jiffy(_selectedDate).add(years: 1),widget.endDate));
      setReturnDate();
    });
  }
  getPreviousYear(){
    setState(() {
      _selectedDate = Jiffy(_selectedDate).subtract(years: 1);
      enbalePrevious = (widget.startDate == null ||  isDateAfter(Jiffy(_selectedDate).subtract(years: 1),widget.startDate));
      enbaleNext = (widget.endDate == null || isDateBefore(Jiffy(_selectedDate).add(years: 1),widget.endDate));
      setReturnDate();
    });
  }

  Widget getYear(){
    return
      Padding(
        padding: EdgeInsets.only(top:5, bottom: 20),
        child:
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Padding(
              padding: EdgeInsets.only(right: 20, top:25),
              child:
              InkWell(
                child: Icon(Icons.arrow_back_ios, size: 15,
                  color: enbalePrevious? widget.navigationColor:widget.navigationDisableColor,),
                onTap: (){
                  enbalePrevious? getPreviousYear():null;
                },
              ),
            ),
            Column(
              children: <Widget>[
                Text(_localeYearly(), style: TextStyle(fontSize: 15),),
                SizedBox(height: 5,),
                Text(_localeYear(_selectedDate.year), style:
                TextStyle(fontSize: 20, fontWeight: FontWeight.bold,color: widget.textColor))
              ],
            ),
            Padding(
              padding: EdgeInsets.only(left: 20, top:25),
              child:
              InkWell(
                child: Icon(Icons.arrow_forward_ios, size: 15,
                  color: enbaleNext? widget.navigationColor:widget.navigationDisableColor,),
                onTap: (){
                  enbaleNext? getNextYear():null;
                },
              ),
            )
          ],
        ),
      );
  }
  Widget getHalf(){
    return
      Padding(
        padding: EdgeInsets.only(top:5, bottom: 20),
        child:
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Padding(
              padding: EdgeInsets.only(right: 20, top:25),
              child:
              InkWell(
                child: Icon(Icons.arrow_back_ios, size: 15,
                  color: enbalePrevious? widget.navigationColor:widget.navigationDisableColor,),
                onTap: (){
                 enbalePrevious? getPreviousHalf():null;
                },
              ),
            ),
            Column(
              children: <Widget>[
                Text("${_selectedDate.year}", style: TextStyle(fontSize: 15,),),
                SizedBox(height: 5,),
                Text(_localeHalfYear(_selectedHaft), style:
                TextStyle(fontSize: 20, fontWeight: FontWeight.bold,color: widget.textColor))
              ],
            ),
            Padding(
              padding: EdgeInsets.only(left: 20, top:25),
              child:
              InkWell(
                child: Icon(Icons.arrow_forward_ios, size: 15,
                  color: enbaleNext? widget.navigationColor:widget.navigationDisableColor,),
                onTap: (){
                  enbaleNext? getNextHalf():null;
                },
              ),
            )
          ],
        ),
      );
  }
  Widget getQuarter(){
    return
      Padding(
        padding: EdgeInsets.only(top:5, bottom: 20),
        child:
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Padding(
              padding: EdgeInsets.only(right: 20, top:25),
              child:
              InkWell(
                child: Icon(Icons.arrow_back_ios, size: 15,
                  color: enbalePrevious? widget.navigationColor:widget.navigationDisableColor,),
                onTap: (){
                 enbalePrevious? getPreviousQuarter():null;
                },
              ),
            ),
            Column(
              children: <Widget>[
                Text("${_selectedDate.year}", style: TextStyle(fontSize: 15),),
                SizedBox(height: 5,),
                Text(_localeQuarter(_selectedQuarter), style:
                TextStyle(fontSize: 20, fontWeight: FontWeight.bold,color: widget.textColor))
              ],
            ),
            Padding(
              padding: EdgeInsets.only(left: 20, top:25),
              child:
              InkWell(
                child: Icon(Icons.arrow_forward_ios, size: 15,
                  color: enbaleNext? widget.navigationColor:widget.navigationDisableColor,),
                onTap: (){
                  enbaleNext? getNextQuarter():null;
                },
              ),
            )
          ],
        ),
      );
  }
  Widget getMonth(){
    return
      Padding(
        padding: EdgeInsets.only(top:5, bottom: 20),
        child:
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Padding(
              padding: EdgeInsets.only(right: 20, top:25),
              child:
              InkWell(
                child: Icon(Icons.arrow_back_ios, size: 15,
                  color: enbalePrevious? widget.navigationColor:widget.navigationDisableColor,),
                onTap: (){
                  enbalePrevious? getPreviousMonth(): null;
                },
              ),
            ),
            Column(
              children: <Widget>[
                Text("${_selectedDate.year}", style: TextStyle(fontSize: 15),),
                SizedBox(height: 5,),
                Text(_localeMonth(_selectedDate.month), style:
                TextStyle(fontSize: 20, fontWeight: FontWeight.bold,color: widget.textColor))
              ],
            ),
            Padding(
              padding: EdgeInsets.only(left: 20, top:25),
              child:
              InkWell(
                child: Icon(Icons.arrow_forward_ios, size: 15,
                  color: enbaleNext? widget.navigationColor:widget.navigationDisableColor,),
                onTap: (){
                  enbaleNext? getNextMonth():null;
                },
              ),
            )
          ],
        ),
      );
  }

  Widget getRoundButton(DateType dateType, bool isSelected){
    String txt = '';
    if (DateType.month == dateType) {
      txt = _localeMonthly();
    } else if (DateType.quarter == dateType) {
      txt = _localeQuarterly();
    } else if (DateType.half == dateType) {
      txt = _localeHalfYearly();
    }else if (DateType.year == dateType) {
      txt = _localeYearly();
    }
    return Expanded(
      child:
      Container(
        decoration: BoxDecoration(
            color: isSelected
                ? widget.selectedColor
                : widget.unSelectedColor,
            borderRadius: const BorderRadius.all(Radius.circular(24.0)),
            border: Border.all(color: widget.selectedColor)),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            splashColor: Colors.white24,
            borderRadius: const BorderRadius.all(Radius.circular(24.0)),
            onTap: () {
              setState(() {
                _dateType = dateType;
                _selectedDate = DateTime.now();
              });
              _resetNavigationButton(dateType);
            },
            child: Padding(
              padding: const EdgeInsets.only(
                  top: 10, bottom: 10, left: 10, right: 10),
              child: Center(
                child: Text(
                  txt,
                  textAlign: TextAlign.left,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                    letterSpacing: 0.27,
                    color: isSelected
                        ? widget.unSelectedColor
                        : widget.selectedColor,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  build(BuildContext context) {
    return Container(
      child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const SizedBox(
          height: 16,
        ),
        Padding(
          padding: const EdgeInsets.only(left: 0, right:0),
          child:
          Row(
            children: <Widget>[
              widget.isShowMonth?
              getRoundButton(DateType.month, _dateType == DateType.month)
                  :SizedBox(width: 0,),
              widget.isShowMonth? SizedBox(width: 16,): SizedBox(width: 0,),

              widget.isShowQuarter?
              getRoundButton(DateType.quarter, _dateType == DateType.quarter)
                  :SizedBox(width: 0,),
              widget.isShowQuarter? SizedBox(width: 16,): SizedBox(width: 0,),

              widget.isShowHalfYear?
              getRoundButton(DateType.half, _dateType == DateType.half)
                  :SizedBox(width: 0,),
              widget.isShowHalfYear? SizedBox(width: 16,): SizedBox(width: 0,),

              widget.isShowYear?
              getRoundButton(DateType.year, _dateType == DateType.year)
                  :SizedBox(width: 0,),
            ],
          ),
        ),
        const SizedBox(
          height: 16,
        ),
        _dateType == DateType.month?
        getMonth():
        (_dateType == DateType.quarter? getQuarter():
        (_dateType == DateType.half? getHalf():
        getYear())
        ),
      ],
    ),
    );
  }
}


class SlideFadeTransition extends StatefulWidget {
  final Widget child;
  final int delay;
  final String id;
  final Curve curve;

  SlideFadeTransition(
      {@required this.child, @required this.id, this.delay, this.curve});

  @override
  SlideFadeTransitionState createState() => SlideFadeTransitionState();
}

class SlideFadeTransitionState extends State<SlideFadeTransition>
    with TickerProviderStateMixin {
  AnimationController _animController;
  Animation<Offset> _animOffset;

  @override
  void initState() {
    super.initState();

    _animController =
        AnimationController(vsync: this, duration: Duration(milliseconds: 400));
    final _curve = CurvedAnimation(
        curve: widget.curve != null ? widget.curve : Curves.decelerate,
        parent: _animController);
    _animOffset =
        Tween<Offset>(begin: const Offset(0.0, 0.25), end: Offset.zero)
            .animate(_curve);

    if (widget.delay == null) {
      _animController.forward();
    } else {
      _animController.reset();
      Future.delayed(Duration(milliseconds: widget.delay), () {
        _animController.forward();
      });
    }
  }

  @override
  void didUpdateWidget(SlideFadeTransition oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.id != oldWidget.id) {
      _animController.reset();
      Future.delayed(Duration(milliseconds: widget.delay), () {
        _animController.forward();
      });
    }
  }

  @override
  void dispose() {
    super.dispose();
    _animController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      child: SlideTransition(position: _animOffset, child: widget.child),
      opacity: _animController,
    );
  }
}
enum DateType {
  month,
  quarter,
  half,
  year,
}

class ResultDate {
   DateTime fromDate;
   DateTime toDate;
   String info;
}