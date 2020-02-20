import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:charts_flutter/flutter.dart' as charts;
import 'package:flutter_redux/flutter_redux.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:invoiceninja_flutter/constants.dart';
import 'package:invoiceninja_flutter/data/models/company_model.dart';
import 'package:invoiceninja_flutter/data/models/dashboard_model.dart';
import 'package:invoiceninja_flutter/data/models/entities.dart';
import 'package:invoiceninja_flutter/redux/app/app_actions.dart';
import 'package:invoiceninja_flutter/redux/app/app_state.dart';
import 'package:invoiceninja_flutter/redux/dashboard/dashboard_actions.dart';
import 'package:invoiceninja_flutter/redux/reports/reports_actions.dart';
import 'package:invoiceninja_flutter/redux/reports/reports_state.dart';
import 'package:invoiceninja_flutter/redux/ui/pref_state.dart';
import 'package:invoiceninja_flutter/ui/app/dialogs/multiselect_dialog.dart';
import 'package:invoiceninja_flutter/ui/app/form_card.dart';
import 'package:invoiceninja_flutter/ui/app/forms/app_dropdown_button.dart';
import 'package:invoiceninja_flutter/ui/app/forms/date_picker.dart';
import 'package:invoiceninja_flutter/ui/app/history_drawer_vm.dart';
import 'package:invoiceninja_flutter/ui/app/menu_drawer_vm.dart';
import 'package:invoiceninja_flutter/ui/reports/reports_screen_vm.dart';
import 'package:invoiceninja_flutter/utils/dates.dart';
import 'package:invoiceninja_flutter/utils/formatting.dart';
import 'package:invoiceninja_flutter/utils/localization.dart';
import 'package:invoiceninja_flutter/utils/platforms.dart';
import 'package:invoiceninja_flutter/utils/strings.dart';

class ReportsScreen extends StatelessWidget {
  const ReportsScreen({
    Key key,
    @required this.viewModel,
  }) : super(key: key);

  static const String route = '/reports';

  final ReportsScreenVM viewModel;

  @override
  Widget build(BuildContext context) {
    final localization = AppLocalization.of(context);
    final store = StoreProvider.of<AppState>(context);
    final state = viewModel.state;
    final reportsUIState = state.uiState.reportsUIState;
    final reportResult = viewModel.reportResult;

    final hasCustomDate = reportsUIState.filters.keys.where((column) {
      final filter = reportsUIState.filters[column];
      return (getReportColumnType(column, context) ==
                  ReportColumnType.dateTime ||
              getReportColumnType(column, context) == ReportColumnType.date) &&
          filter == DateRange.custom.toString();
    }).isNotEmpty;

    return WillPopScope(
      onWillPop: () async {
        store.dispatch(ViewDashboard(navigator: Navigator.of(context)));
        return false;
      },
      child: Scaffold(
        drawer: isMobile(context) || state.prefState.isMenuFloated
            ? MenuDrawerBuilder()
            : null,
        endDrawer: isMobile(context) || state.prefState.isHistoryFloated
            ? HistoryDrawerBuilder()
            : null,
        appBar: AppBar(
          leading: isMobile(context) || state.prefState.isMenuFloated
              ? null
              : IconButton(
                  icon: Icon(Icons.menu),
                  onPressed: () => store
                      .dispatch(UserSettingsChanged(sidebar: AppSidebar.menu)),
                ),
          title: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Expanded(child: Text(localization.reports)),
              if (state.isSaving)
                SizedBox(
                  width: 28,
                  height: 28,
                  child: CircularProgressIndicator(),
                ),
            ],
          ),
          actions: <Widget>[
            Builder(builder: (BuildContext context) {
              return FlatButton(
                child: Text(localization.columns),
                textColor: Colors.white,
                onPressed: () {
                  multiselectDialog(
                    context: context,
                    onSelected: (selected) {
                      viewModel.onReportColumnsChanged(context, selected);
                    },
                    options: reportResult.allColumns,
                    selected: reportResult.columns.toList(),
                    defaultSelected: reportResult.defaultColumns,
                    title: localization.editColumns,
                    addTitle: localization.addColumn,
                  );
                },
              );
            }),
            FlatButton(
              child: Text(localization.export),
              textColor: Colors.white,
              onPressed: () {
                viewModel.onExportPressed(context);
              },
            ),
            if (isMobile(context) || !state.prefState.isHistoryVisible)
              Builder(
                builder: (context) => IconButton(
                  icon: Icon(Icons.menu),
                  onPressed: () {
                    if (isMobile(context) || state.prefState.isHistoryFloated) {
                      Scaffold.of(context).openEndDrawer();
                    } else {
                      store.dispatch(
                          UserSettingsChanged(sidebar: AppSidebar.history));
                    }
                  },
                ),
              ),
          ],
        ),
        body: ListView(
          key: ValueKey(
              '${viewModel.state.isSaving}_${reportsUIState.report}_${reportsUIState.group}'),
          children: <Widget>[
            Flex(
              direction: isMobile(context) ? Axis.vertical : Axis.horizontal,
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Flexible(
                  child: FormCard(
                    children: <Widget>[
                      AppDropdownButton<String>(
                        labelText: localization.report,
                        value: reportsUIState.report,
                        onChanged: (dynamic value) =>
                            viewModel.onSettingsChanged(report: value),
                        items: [
                          //kReportActivity,
                          //kReportAging,
                          kReportClient,
                          kReportCredit,
                          kReportDocument,
                          kReportExpense,
                          kReportInvoice,
                          kReportPayment,
                          kReportProduct,
                          //kReportProfitAndLoss,
                          kReportTask,
                          //kReportTaxRate,
                          //kReportQuote,
                        ]
                            .map((report) => DropdownMenuItem(
                                  value: report,
                                  child: Text(localization.lookup(report)),
                                ))
                            .toList(),
                      ),
                      if (hasCustomDate) ...[
                        DatePicker(
                          labelText: localization.startDate,
                          selectedDate: reportsUIState.customStartDate,
                          allowClearing: true,
                          onSelected: (date) => viewModel.onSettingsChanged(
                              customStartDate: date),
                        ),
                        DatePicker(
                          labelText: localization.endDate,
                          selectedDate: reportsUIState.customEndDate,
                          allowClearing: true,
                          onSelected: (date) =>
                              viewModel.onSettingsChanged(customEndDate: date),
                        ),
                      ]
                    ],
                  ),
                ),
                Flexible(
                  child: FormCard(
                    children: <Widget>[
                      AppDropdownButton<String>(
                        labelText: localization.group,
                        value: reportsUIState.group,
                        blankValue: '',
                        showBlank: true,
                        onChanged: (dynamic value) {
                          viewModel.onSettingsChanged(
                              group: value, selectedGroup: '');
                        },
                        items: reportResult.columns
                            .where((column) =>
                                getReportColumnType(column, context) !=
                                ReportColumnType.number)
                            .map((column) {
                          final columnTitle =
                              state.company.getCustomFieldLabel(column);
                          return DropdownMenuItem(
                            child: Text(columnTitle.isEmpty
                                ? localization.lookup(column)
                                : columnTitle),
                            value: column,
                          );
                        }).toList(),
                      ),
                      if (getReportColumnType(reportsUIState.group, context) ==
                              ReportColumnType.dateTime ||
                          getReportColumnType(reportsUIState.group, context) ==
                              ReportColumnType.date)
                        AppDropdownButton<String>(
                            labelText: localization.subgroup,
                            value: reportsUIState.subgroup,
                            onChanged: (dynamic value) {
                              viewModel.onSettingsChanged(subgroup: value);
                            },
                            items: [
                              DropdownMenuItem(
                                child: Text(localization.day),
                                value: kReportGroupDay,
                              ),
                              DropdownMenuItem(
                                child: Text(localization.month),
                                value: kReportGroupMonth,
                              ),
                              DropdownMenuItem(
                                child: Text(localization.year),
                                value: kReportGroupYear,
                              ),
                            ]),
                    ],
                  ),
                ),
                if (reportsUIState.group.isNotEmpty)
                  Flexible(
                    child: FormCard(
                      children: <Widget>[
                        AppDropdownButton<String>(
                          labelText: localization.chart,
                          value: reportsUIState.chart,
                          blankValue: '',
                          showBlank: true,
                          onChanged: (dynamic value) {
                            viewModel.onSettingsChanged(chart: value);
                          },
                          items: reportResult.columns
                              .where((column) =>
                                  getReportColumnType(column, context) ==
                                  ReportColumnType.number)
                              .map((column) => DropdownMenuItem(
                                    child: Text(localization.lookup(column)),
                                    value: column,
                                  ))
                              .toList(),
                        ),
                      ],
                    ),
                  )
              ],
            ),
            ReportDataTable(
              key: ValueKey(
                  '${viewModel.state.isSaving}_${reportsUIState.group}_${reportsUIState.selectedGroup}'),
              viewModel: viewModel,
            )
          ],
        ),
      ),
    );
  }
}

class ReportDataTable extends StatefulWidget {
  const ReportDataTable({Key key, @required this.viewModel}) : super(key: key);

  final ReportsScreenVM viewModel;

  @override
  _ReportDataTableState createState() => _ReportDataTableState();
}

class _ReportDataTableState extends State<ReportDataTable> {
  final Map<String, Map<String, TextEditingController>>
      _textEditingControllers = {};

  @override
  void didChangeDependencies() {
    final state = widget.viewModel.state;
    final reportState = state.uiState.reportsUIState;
    final reportResult = widget.viewModel.reportResult;

    for (var column in reportResult.columns) {
      if (_textEditingControllers[reportState.report] == null) {
        _textEditingControllers[reportState.report] = {};
      }
      if (!_textEditingControllers[reportState.report].containsKey(column)) {
        final textEditingController = TextEditingController();
        // TODO figure out how to remove this listener in dispose
        textEditingController.addListener(() {
          _onChanged(column, textEditingController.text);
        });
        if (reportState.filters.containsKey(column)) {
          textEditingController.text = reportState.filters[column];
        }
        _textEditingControllers[reportState.report][column] =
            textEditingController;
      }
    }

    super.didChangeDependencies();
  }

  void _onChanged(String column, String value) {
    final state = widget.viewModel.state;
    widget.viewModel.onReportFiltersChanged(
        context,
        state.uiState.reportsUIState.filters
            .rebuild((b) => b..addAll({column: value})));
  }

  @override
  void dispose() {
    _textEditingControllers.keys.forEach((i) {
      _textEditingControllers[i].keys.forEach((j) {
        _textEditingControllers[i][j].dispose();
      });
    });
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.viewModel.state;
    final reportResult = widget.viewModel.reportResult;
    final reportSettings = state.userCompany.settings
            ?.reportSettings[state.uiState.reportsUIState.report] ??
        ReportSettingsEntity();

    final reportsUIState = state.uiState.reportsUIState;

    return Column(
      children: <Widget>[
        if (reportsUIState.chart.isNotEmpty)
          ClipRect(
            child: ReportCharts(
              viewModel: widget.viewModel,
            ),
          ),
        FormCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              DataTable(
                sortColumnIndex: reportSettings.sortTotalsIndex != null &&
                        reportResult.columns.length >
                            reportSettings.sortTotalsIndex
                    ? reportSettings.sortTotalsIndex
                    : null,
                sortAscending: reportSettings.sortTotalsAscending,
                columns: reportResult.totalColumns(
                    context,
                    (index, ascending) => widget.viewModel
                        .onReportTotalsSorted(index, ascending)),
                rows: reportResult.totalRows(context),
              ),
            ],
          ),
        ),
        FormCard(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              sortColumnIndex: reportSettings.sortIndex != null &&
                      reportResult.columns.length > reportSettings.sortIndex
                  ? reportSettings.sortIndex
                  : null,
              sortAscending: reportSettings.sortAscending,
              columns: reportResult.tableColumns(
                  context,
                  (index, ascending) =>
                      widget.viewModel.onReportSorted(index, ascending)),
              rows: [
                reportResult.tableFilters(
                    context,
                    _textEditingControllers[
                        state.uiState.reportsUIState.report], (column, value) {
                  widget.viewModel.onReportFiltersChanged(
                      context,
                      state.uiState.reportsUIState.filters
                          .rebuild((b) => b..addAll({column: value})));
                }),
                ...reportResult.tableRows(context, widget.viewModel),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class ReportCharts extends StatelessWidget {
  const ReportCharts({@required this.viewModel});

  final ReportsScreenVM viewModel;

  @override
  Widget build(BuildContext context) {
    final state = viewModel.state;
    final reportsUIState = state.uiState.reportsUIState;

    if (reportsUIState.chart.isEmpty || reportsUIState.group.isEmpty) {
      return SizedBox();
    }

    final color = state.prefState.enableDarkMode
        ? charts.MaterialPalette.white
        : charts.MaterialPalette.black;

    final numericAxis = charts.NumericAxisSpec(
        renderSpec: charts.GridlineRendererSpec(
            labelStyle: charts.TextStyleSpec(color: color),
            lineStyle: charts.LineStyleSpec(color: color)));

    final ordinalAxis = charts.OrdinalAxisSpec(
        renderSpec: charts.GridlineRendererSpec(
            lineStyle:
                charts.LineStyleSpec(color: charts.MaterialPalette.transparent),
            labelStyle: charts.TextStyleSpec(fontSize: 10, color: color)));

    final dateTimeAxis = charts.DateTimeAxisSpec(
        renderSpec: charts.SmallTickRendererSpec(
            labelStyle: charts.TextStyleSpec(color: color),
            lineStyle: charts.LineStyleSpec(color: color)));

    Widget child;
    switch (getReportColumnType(reportsUIState.group, context)) {
      case ReportColumnType.string:
      case ReportColumnType.bool:
        child = charts.BarChart(
          [
            charts.Series<dynamic, String>(
                id: 'chart',
                colorFn: (dynamic _, __) =>
                    charts.MaterialPalette.blue.shadeDefault,
                domainFn: (dynamic item, _) => item['name'],
                measureFn: (dynamic item, _) => item['value'],
                data: viewModel.groupTotals.keys
                    .map((key) => {
                          'name': key,
                          'value': viewModel.groupTotals[key]
                              [reportsUIState.chart]
                        })
                    .toList())
          ],
          animate: true,
          primaryMeasureAxis: numericAxis,
          domainAxis: ordinalAxis,
        );
        break;
      case ReportColumnType.date:
      case ReportColumnType.dateTime:
        final keys = viewModel.groupTotals.keys
            .where((element) => element.isNotEmpty)
            .toList();
        keys.sort((String str1, String str2) => str1.compareTo(str2));
        child = charts.TimeSeriesChart(
          [
            charts.Series<dynamic, DateTime>(
                id: 'chart',
                colorFn: (dynamic _, __) =>
                    charts.MaterialPalette.blue.shadeDefault,
                domainFn: (dynamic item, _) => DateTime.tryParse(item['name']),
                measureFn: (dynamic item, _) => item['value'],
                data: keys
                    .map((key) => {
                          'name': key,
                          'value': viewModel.groupTotals[key]
                              [reportsUIState.chart]
                        })
                    .toList())
          ],
          animate: true,
          primaryMeasureAxis: numericAxis,
          domainAxis: dateTimeAxis,
          /*
          behaviors: [
            charts.SeriesLegend(
              outsideJustification: charts.OutsideJustification.endDrawArea,
            )
          ],
           */
        );
        break;
      case ReportColumnType.number:
    }

    return child == null
        ? SizedBox()
        : FormCard(
            child: SizedBox(
              height: 200,
              child: child,
            ),
          );
  }
}

enum ReportColumnType {
  string,
  dateTime,
  date,
  number,
  bool,
}

ReportColumnType getReportColumnType(String column, BuildContext context) {
  ReportColumnType convertCustomFieldType(String type) {
    if (type == kFieldTypeDate) {
      return ReportColumnType.date;
    } else if (type == kFieldTypeSwitch) {
      return ReportColumnType.bool;
    } else {
      return ReportColumnType.string;
    }
  }

  final store = StoreProvider.of<AppState>(context);
  final company = store.state.userCompany.company;

  if (company.hasCustomField(column)) {
    return convertCustomFieldType(company.getCustomFieldType(column));
  } else if (['updated_at', 'created_at'].contains(column)) {
    return ReportColumnType.dateTime;
  } else if (['date', 'due_date'].contains(column)) {
    return ReportColumnType.date;
  } else if ([
    'balance',
    'paid_to_date',
    'amount',
    'quantity',
    'pridce',
    'cost',
    'total',
  ].contains(column)) {
    return ReportColumnType.number;
  } else if (['is_active'].contains(column)) {
    return ReportColumnType.bool;
  } else {
    return ReportColumnType.string;
  }
}

class ReportResult {
  ReportResult({
    @required this.columns,
    @required this.allColumns,
    @required this.defaultColumns,
    @required this.data,
  });

  final List<String> columns;
  final List<String> allColumns;
  final List<String> defaultColumns;
  final List<List<ReportElement>> data;

  static bool matchField({
    String column,
    dynamic value,
    UserCompanyEntity userCompany,
    ReportsUIState reportsUIState,
  }) {
    if (reportsUIState.filters.containsKey(column)) {
      final filter = reportsUIState.filters[column];
      if (filter.isNotEmpty) {
        if (value.runtimeType == int || value.runtimeType == double) {
          if (!ReportResult.matchAmount(filter: filter, amount: value)) {
            return false;
          }
        } else if (value.runtimeType == bool ||
            filter == 'true' ||
            filter == 'false') {
          // Support custom fields
          if (value.runtimeType == String) {
            if (value.toLowerCase() == 'yes') {
              value = 'true';
            } else if (value.toLowerCase() == 'no') {
              value = 'false';
            }
          }
          if (filter != '$value') {
            return false;
          }
        } else if (isValidDate(value)) {
          if (!ReportResult.matchDateTime(
              filter: filter,
              value: value,
              reportsUIState: reportsUIState,
              userCompany: userCompany)) {
            return false;
          }
        } else {
          if (!ReportResult.matchString(filter: filter, value: value)) {
            return false;
          }
        }
      }
    }

    return true;
  }

  static bool matchString({String filter, String value}) {
    if (filter == null || filter.isEmpty) {
      return true;
    }

    return value.toLowerCase().contains(filter.toLowerCase());
  }

  static bool matchAmount({String filter, double amount}) {
    final String range = filter.replaceAll(',', '-') + '-';
    final List<String> parts = range.split('-');
    final min = parseDouble(parts[0]);
    final max = parseDouble(parts[1]);
    if (amount < min || (max > 0 && amount > max)) {
      return false;
    }

    return true;
  }

  static bool matchDateTime({
    String filter,
    String value,
    UserCompanyEntity userCompany,
    ReportsUIState reportsUIState,
  }) {
    DateRange dateRange = DateRange.last30Days;
    try {
      dateRange = DateRange.valueOf(filter);
    } catch (exception) {
      //
    }

    final startDate = calculateStartDate(
      dateRange: dateRange,
      company: userCompany.company,
      customStartDate: reportsUIState.customStartDate,
      customEndDate: reportsUIState.customEndDate,
    );
    final endDate = calculateEndDate(
      dateRange: dateRange,
      company: userCompany.company,
      customStartDate: reportsUIState.customStartDate,
      customEndDate: reportsUIState.customEndDate,
    );
    final customStartDate = reportsUIState.customStartDate;
    final customEndDate = reportsUIState.customEndDate;
    if (dateRange == DateRange.custom) {
      if (customStartDate.isNotEmpty && customEndDate.isNotEmpty) {
        if (!(startDate.compareTo(value) <= 0 &&
            endDate.compareTo(value) > 0)) {
          return false;
        }
      } else if (customStartDate.isNotEmpty) {
        if (!(startDate.compareTo(value) <= 0)) {
          return false;
        }
      } else if (customEndDate.isNotEmpty) {
        if (!(endDate.compareTo(value) > 0)) {
          return false;
        }
      }
    } else {
      if (!(startDate.compareTo(value) <= 0 && endDate.compareTo(value) > 0)) {
        return false;
      }
    }

    return true;
  }

  List<String> sortedColumns(BuildContext context) {
    final data = columns.toList();
    final store = StoreProvider.of<AppState>(context);
    final group = store.state.uiState.reportsUIState.group;

    if (group.isNotEmpty) {
      data.remove(group);
      data.insert(0, group);
    }

    return data;
  }

  List<DataColumn> tableColumns(
      BuildContext context, Function(int, bool) onSortCallback) {
    final localization = AppLocalization.of(context);
    final store = StoreProvider.of<AppState>(context);
    final company = store.state.company;

    return [
      for (String column in sortedColumns(context))
        DataColumn(
          label: Container(
            constraints: BoxConstraints(minWidth: 80),
            child: Text(
              (company.getCustomFieldLabel(column).isNotEmpty
                      ? company.getCustomFieldLabel(column)
                      : localization.lookup(column)) +
                  '   ',
              overflow: TextOverflow.ellipsis,
            ),
          ),
          numeric:
              getReportColumnType(column, context) == ReportColumnType.number,
          onSort: onSortCallback,
        )
    ];
  }

  DataRow tableFilters(
      BuildContext context,
      Map<String, TextEditingController> textEditingControllers,
      Function(String, String) onFilterChanged) {
    final localization = AppLocalization.of(context);

    return DataRow(cells: [
      for (String column in sortedColumns(context))
        if (textEditingControllers == null ||
            !textEditingControllers.containsKey(column))
          DataCell(SizedBox())
        else if (getReportColumnType(column, context) == ReportColumnType.bool)
          DataCell(AppDropdownButton<bool>(
            labelText: null,
            showBlank: true,
            blankValue: null,
            value: textEditingControllers[column].text == 'true'
                ? true
                : textEditingControllers[column].text == 'false' ? false : null,
            onChanged: (dynamic value) {
              if (value == null) {
                textEditingControllers[column].text = '';
                onFilterChanged(column, '');
              } else {
                textEditingControllers[column].text = value.toString();
                onFilterChanged(column, value.toString());
              }
            },
            items: [
              DropdownMenuItem(
                child: Text(AppLocalization.of(context).yes),
                value: true,
              ),
              DropdownMenuItem(
                child: Text(AppLocalization.of(context).no),
                value: false,
              ),
            ],
          ))
        else if (getReportColumnType(column, context) ==
            ReportColumnType.number)
          DataCell(TextFormField(
            controller: textEditingControllers[column],
            keyboardType: TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
                suffixIcon: textEditingControllers == null
                    ? null
                    : (textEditingControllers[column]?.text ?? '').isEmpty
                        ? null
                        : IconButton(
                            icon: Icon(
                              Icons.clear,
                              color: Colors.grey,
                            ),
                            onPressed: () {
                              textEditingControllers[column].text = '';
                              onFilterChanged(column, '');
                            },
                          )),
          ))
        else if (getReportColumnType(column, context) ==
                ReportColumnType.dateTime ||
            getReportColumnType(column, context) == ReportColumnType.date)
          DataCell(AppDropdownButton<DateRange>(
            labelText: null,
            showBlank: true,
            blankValue: null,
            value: (textEditingControllers[column].text ?? '').isNotEmpty &&
                    textEditingControllers[column].text != 'null'
                ? DateRange.valueOf(textEditingControllers[column].text)
                : null,
            onChanged: (dynamic value) {
              if (value == null) {
                textEditingControllers[column].text = '';
                onFilterChanged(column, '');
              } else {
                textEditingControllers[column].text = value.toString();
                onFilterChanged(column, value.toString());
              }
            },
            items: DateRange.values
                .map((dateRange) => DropdownMenuItem<DateRange>(
                      child: Text(localization.lookup(dateRange.toString())),
                      value: dateRange,
                    ))
                .toList(),
          ))
        else
          DataCell(TypeAheadFormField(
            noItemsFoundBuilder: (context) => SizedBox(),
            suggestionsBoxDecoration: SuggestionsBoxDecoration(
              constraints: BoxConstraints(
                minWidth: 300,
              ),
            ),
            suggestionsCallback: (filter) {
              filter = filter.toLowerCase();
              final index = columns.indexOf(column);
              return data
                  .where((row) =>
                      row[index]
                          .renderText(context, column)
                          .toLowerCase()
                          .contains(filter) &&
                      row[index].renderText(context, column).trim().isNotEmpty)
                  .map((row) => row[index].renderText(context, column))
                  .toSet()
                  .toList();
            },
            itemBuilder: (context, String entityId) {
              return Padding(
                padding: const EdgeInsets.all(12),
                child: Text('$entityId'),
              );
            },
            onSuggestionSelected: (String value) {
              textEditingControllers[column].text = value;
              onFilterChanged(column, value);
            },
            textFieldConfiguration: TextFieldConfiguration<String>(
              controller: textEditingControllers != null
                  ? textEditingControllers[column]
                  : null,
              decoration: InputDecoration(
                  suffixIcon: textEditingControllers == null
                      ? null
                      : (textEditingControllers[column]?.text ?? '').isEmpty
                          ? null
                          : IconButton(
                              icon: Icon(
                                Icons.clear,
                                color: Colors.grey,
                              ),
                              onPressed: () {
                                textEditingControllers[column].text = '';
                                onFilterChanged(column, '');
                              },
                            )),
            ),
            autoFlipDirection: true,
            animationStart: 1,
            debounceDuration: Duration(seconds: 0),
          ))
    ]);
  }

  List<DataRow> tableRows(BuildContext context, ReportsScreenVM viewModel) {
    final rows = <DataRow>[];
    final store = StoreProvider.of<AppState>(context);
    final state = store.state;
    final reportState = state.uiState.reportsUIState;
    final reportSettings = state.userCompany.settings
            ?.reportSettings[state.uiState.reportsUIState.report] ??
        ReportSettingsEntity();
    final groupBy = reportState.group;

    final isGroupByFIltered = reportState.filters.containsKey(groupBy) &&
        reportState.filters[groupBy].isNotEmpty;

    if (groupBy.isEmpty || isGroupByFIltered) {
      for (var i = 0; i < data.length; i++) {
        final row = data[i];
        final cells = <DataCell>[];
        for (var j = 0; j < row.length; j++) {
          final cell = row[j];
          final column = columns[j];
          cells.add(DataCell(cell.renderWidget(context, column)));
        }
        rows.add(DataRow(cells: cells));
      }
    } else {
      final groupTotals = viewModel.groupTotals;
      final keys = groupTotals.keys.toList();
      keys.sort((rowA, rowB) {
        final valuesA = groupTotals[rowA];
        final valuesB = groupTotals[rowB];
        if (reportSettings.sortIndex != null &&
            reportSettings.sortIndex < columns.length) {
          final sort = columns[reportSettings.sortIndex];
          if (valuesA.containsKey(sort) && valuesB.containsKey(sort)) {
            return reportSettings.sortAscending
                ? valuesA[sort].compareTo(valuesB[sort])
                : valuesB[sort].compareTo(valuesA[sort]);
          }
        }
        return 0;
      });
      keys.forEach((group) {
        final values = viewModel.groupTotals[group];
        final cells = <DataCell>[];
        for (var column in sortedColumns(context)) {
          String value = '';
          if (column == groupBy) {
            if (group.isEmpty) {
              value = AppLocalization.of(context).blank;
            } else if (getReportColumnType(column, context) ==
                    ReportColumnType.dateTime ||
                getReportColumnType(column, context) == ReportColumnType.date) {
              value = formatDate(group, context);
            } else {
              value = group;
            }
            value = value + ' (' + values['count'].floor().toString() + ')';
          } else if (getReportColumnType(column, context) ==
              ReportColumnType.number) {
            value = formatNumber(values[column], context);
          }
          cells.add(DataCell(Text(value), onTap: () {
            if (group.isEmpty) {
              return;
            }
            if (column == groupBy) {
              String filter = group;
              String customStartDate = '';
              String customEndDate = '';
              if (getReportColumnType(column, context) ==
                      ReportColumnType.dateTime ||
                  getReportColumnType(column, context) ==
                      ReportColumnType.date) {
                filter = DateRange.custom.toString();
                final date = DateTime.tryParse(group);
                customStartDate = group;
                if (reportState.subgroup == kReportGroupDay) {
                  customEndDate = convertDateTimeToSqlDate(addDays(date, 1));
                } else if (reportState.subgroup == kReportGroupMonth) {
                  customEndDate = convertDateTimeToSqlDate(addMonths(date, 1));
                } else {
                  customEndDate = convertDateTimeToSqlDate(addYears(date, 1));
                }
              } else if (getReportColumnType(column, context) ==
                  ReportColumnType.bool) {
                filter = filter == AppLocalization.of(context).yes
                    ? 'true'
                    : filter == AppLocalization.of(context).no ? 'false' : '';
              }
              store.dispatch(
                UpdateReportSettings(
                  report: reportState.report,
                  selectedGroup: filter,
                  customStartDate: customStartDate,
                  customEndDate: customEndDate,
                  filters: reportState.filters
                      .rebuild((b) => b..addAll({column: filter})),
                ),
              );
            }
          }));
        }
        rows.add(DataRow(cells: cells));
      });
    }

    return rows;
  }

  List<DataColumn> totalColumns(
      BuildContext context, Function(int, bool) onSortCallback) {
    final localization = AppLocalization.of(context);
    columns.toList().sort((String str1, String str2) => str1.compareTo(str2));

    return [
      DataColumn(
        label: Text(localization.currency),
        onSort: onSortCallback,
      ),
      DataColumn(
        label: Text(localization.count),
        onSort: onSortCallback,
      ),
      for (String column in columns)
        if (getReportColumnType(column, context) == ReportColumnType.number)
          DataColumn(
            label: Text(
              localization.lookup(column),
              overflow: TextOverflow.ellipsis,
            ),
            numeric: true,
            onSort: onSortCallback,
          )
    ];
  }

  List<DataRow> totalRows(BuildContext context) {
    final rows = <DataRow>[];
    final store = StoreProvider.of<AppState>(context);
    final state = store.state;
    final reportSettings = state.userCompany.settings
            ?.reportSettings[state.uiState.reportsUIState.report] ??
        ReportSettingsEntity();
    final Map<String, Map<String, double>> totals = {};

    for (var i = 0; i < data.length; i++) {
      final row = data[i];
      bool countedRow = false;
      for (var j = 0; j < row.length; j++) {
        final cell = row[j];
        final column = columns[j];
        if (cell is ReportNumberValue) {
          final String currencyId = cell.currencyId;

          if (!totals.containsKey(currencyId)) {
            totals[currencyId] = {'count': 0};
          }
          if (!countedRow) {
            totals[currencyId]['count']++;
            countedRow = true;
          }
          if (!totals[currencyId].containsKey(column)) {
            totals[currencyId][column] = 0;
          }
          totals[currencyId][column] += cell.value;
        }
      }
    }

    final keys = totals.keys.toList();
    if (reportSettings.sortTotalsIndex != null) {
      keys.sort((rowA, rowB) {
        dynamic valueA;
        dynamic valueB;

        if (reportSettings.sortTotalsIndex == 0) {
          final currencyMap = state.staticState.currencyMap;
          valueA = currencyMap[rowA].listDisplayName;
          valueB = currencyMap[rowB].listDisplayName;
        } else if (reportSettings.sortTotalsIndex == 1) {
          valueA = totals[rowA]['count'];
          valueB = totals[rowB]['count'];
        } else {
          final List<String> fields = totals[rowA].keys.toList()
            ..remove('count')
            ..sort((String str1, String str2) => str1.compareTo(str2));
          final sortColumn = fields[reportSettings.sortTotalsIndex - 2];
          valueA = totals[rowA][sortColumn];
          valueB = totals[rowB][sortColumn];
        }

        if (valueA == null || valueB == null) {
          return 0;
        }

        return reportSettings.sortTotalsAscending
            ? valueA.compareTo(valueB)
            : valueB.compareTo(valueA);
      });
    }

    keys.forEach((currencyId) {
      final values = totals[currencyId];
      final cells = <DataCell>[
        DataCell(Text(
            store.state.staticState.currencyMap[currencyId]?.listDisplayName ??
                '')),
        DataCell(Text(values['count'].toInt().toString())),
      ];

      final List<String> fields = values.keys.toList()
        ..sort((String str1, String str2) => str1.compareTo(str2));
      fields.forEach((field) {
        final amount = values[field];
        final value = formatNumber(amount, context, currencyId: currencyId);
        if (field != 'count') {
          cells.add(DataCell(Text(value)));
        }
      });

      rows.add(DataRow(cells: cells));
    });

    return rows;
  }
}

abstract class ReportElement {
  ReportElement({this.value, this.entityType, this.entityId});

  final dynamic value;
  final EntityType entityType;
  final String entityId;

  Widget renderWidget(BuildContext context, String column) {
    throw 'Error: need to override renderWidget()';
  }

  String renderText(BuildContext context, String column) {
    throw 'Error: need to override sortString()';
  }
}

class ReportStringValue extends ReportElement {
  ReportStringValue({
    dynamic value,
    EntityType entityType,
    String entityId,
  }) : super(value: value, entityType: entityType, entityId: entityId);

  @override
  Widget renderWidget(BuildContext context, String column) {
    return Text(renderText(context, column));
  }

  @override
  String renderText(BuildContext context, String column) {
    if (getReportColumnType(column, context) == ReportColumnType.dateTime ||
        getReportColumnType(column, context) == ReportColumnType.date) {
      return formatDate(value, context,
          showTime: getReportColumnType(column, context) ==
              ReportColumnType.dateTime);
    } else {
      return value ?? '';
    }
  }
}

class ReportNumberValue extends ReportElement {
  ReportNumberValue({
    dynamic value,
    EntityType entityType,
    String entityId,
    this.currencyId,
    this.formatNumberType = FormatNumberType.money,
  }) : super(value: value, entityType: entityType, entityId: entityId);

  final FormatNumberType formatNumberType;
  final String currencyId;

  @override
  Widget renderWidget(BuildContext context, String column) {
    return Text(renderText(context, column));
  }

  @override
  String renderText(BuildContext context, String column) {
    return formatNumber(value, context,
        currencyId: currencyId, formatNumberType: formatNumberType);
  }
}

class ReportBoolValue extends ReportElement {
  ReportBoolValue({
    dynamic value,
    EntityType entityType,
    String entityId,
  }) : super(value: value, entityType: entityType, entityId: entityId);

  @override
  Widget renderWidget(BuildContext context, String column) {
    final localization = AppLocalization.of(context);
    return SizedBox(
      width: 80,
      child: Text(
        value == true ? localization.yes : localization.no,
        textAlign: TextAlign.center,
      ),
    );
  }

  @override
  String renderText(BuildContext context, String column) {
    final localization = AppLocalization.of(context);
    return value == true ? localization.yes : localization.no;
  }
}

int sortReportTableRows(
    dynamic rowA, dynamic rowB, ReportSettingsEntity reportSettings) {
  if (reportSettings.sortIndex == null) {
    return 0;
  } else if (rowA.length <= reportSettings.sortIndex ||
      rowB.length <= reportSettings.sortIndex) {
    return 0;
  }

  final dynamic valueA = rowA[reportSettings.sortIndex].value;
  final dynamic valueB = rowB[reportSettings.sortIndex].value;

  if (reportSettings.sortAscending) {
    return valueA.compareTo(valueB);
  } else {
    return valueB.compareTo(valueA);
  }
}
