import 'package:collection/collection.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:monekin/core/database/services/account/account_service.dart';
import 'package:monekin/core/presentation/widgets/number_ui_formatters/currency_displayer.dart';
import 'package:monekin/core/presentation/widgets/number_ui_formatters/ui_number_formatter.dart';
import 'package:monekin/core/presentation/widgets/skeleton.dart';
import 'package:monekin/core/presentation/widgets/transaction_filter/transaction_filters.dart';
import 'package:monekin/core/presentation/widgets/trending_value.dart';
import 'package:monekin/core/utils/color_utils.dart';
import 'package:monekin/i18n/translations.g.dart';
import 'package:rxdart/rxdart.dart';

import '../../../core/services/filters/date_range_service.dart';

class LineChartDataItem {
  List<double> balance;
  List<String> labels;

  LineChartDataItem({required this.balance, required this.labels});
}

class FundEvolutionLineChart extends StatelessWidget {
  const FundEvolutionLineChart(
      {super.key,
      required this.startDate,
      required this.endDate,
      this.filters = const TransactionFilters(),
      required this.dateRange,
      this.showBalanceHeader = false});

  final DateTime? startDate;
  final DateTime? endDate;
  final DateRange dateRange;

  final bool showBalanceHeader;

  final TransactionFilters filters;

  Stream<LineChartDataItem?> getEvolutionData() {
    if (startDate == null || endDate == null) return Stream.value(null);

    List<Stream<double>> balance = [];
    List<String> labels = [];

    DateTime currentDay =
        DateTime(startDate!.year, startDate!.month, startDate!.day);

    final dayRange = (endDate!.difference(startDate!).inDays / 100).ceil();

    while (currentDay.compareTo(endDate!) < 0) {
      labels.add(DateFormat.yMMMMd().format(currentDay));

      balance.add(AccountService.instance
          .getAccountsMoney(trFilters: filters, date: currentDay));

      currentDay = currentDay.add(Duration(days: dayRange));
    }

    return Rx.combineLatest(balance,
        (values) => LineChartDataItem(balance: values, labels: labels));
  }

  @override
  Widget build(BuildContext context) {
    List<Color> gradientColors = [
      Theme.of(context).colorScheme.primary,
      Theme.of(context).colorScheme.primary.lighten(0.3),
    ];

    final accountService = AccountService.instance;

    final t = Translations.of(context);

    return Column(
      children: [
        if (showBalanceHeader) ...[
          StreamBuilder(
              stream: filters.accounts(),
              builder: (context, accountsSnapshot) {
                if (!accountsSnapshot.hasData) {
                  return Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                          'Final balance - ${DateRangeService().getTextOfRange(startDate: startDate, endDate: endDate, dateRange: dateRange)}',
                          style: const TextStyle(fontSize: 12)),
                      const Skeleton(width: 70, height: 40),
                      const Skeleton(width: 30, height: 14),
                    ],
                  );
                } else {
                  final accounts = accountsSnapshot.data!;

                  return Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                                'F. balance - ${DateRangeService().getTextOfRange(
                                  showLongMonth: false,
                                  startDate: startDate,
                                  endDate: endDate,
                                  dateRange: dateRange,
                                )}',
                                style: const TextStyle(fontSize: 12)),
                            StreamBuilder(
                                stream: accountService.getAccountsMoney(
                                  accountIds: accounts.map((e) => e.id),
                                  trFilters: filters,
                                  date: endDate,
                                ),
                                builder: (context, snapshot) {
                                  if (!snapshot.hasData) {
                                    return const Skeleton(
                                        width: 70, height: 40);
                                  }

                                  return CurrencyDisplayer(
                                      amountToConvert: snapshot.data!,
                                      textStyle: Theme.of(context)
                                          .textTheme
                                          .headlineSmall!);
                                }),
                          ],
                        ),
                        Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              t.stats.compared_to_previous_period,
                              style: const TextStyle(fontSize: 12),
                            ),
                            StreamBuilder(
                                stream:
                                    accountService.getAccountsMoneyVariation(
                                        accounts: accounts,
                                        startDate: startDate,
                                        endDate: endDate,
                                        convertToPreferredCurrency: true),
                                builder: (context, snapshot) {
                                  if (!snapshot.hasData) {
                                    return const Skeleton(
                                        width: 52, height: 22);
                                  }

                                  return TrendingValue(
                                    percentage: snapshot.data!,
                                    filled: false,
                                    fontWeight: Theme.of(context)
                                        .textTheme
                                        .headlineSmall!
                                        .fontWeight!,
                                    fontSize: Theme.of(context)
                                        .textTheme
                                        .headlineSmall!
                                        .fontSize!,
                                    outlined: false,
                                  );
                                })
                          ],
                        )
                      ],
                    ),
                  );
                }
              }),
          const SizedBox(height: 16),
        ],
        SizedBox(
          height: 300,
          child: StreamBuilder(
              stream: getEvolutionData(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(),
                        ],
                      ),
                    ],
                  );
                }

                final ultraLightBorderColor =
                    Theme.of(context).brightness == Brightness.light
                        ? Colors.black12
                        : Colors.white12;

                return Stack(
                  children: [
                    LineChart(LineChartData(
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        getDrawingHorizontalLine: (value) =>
                            defaultGridLine(value).copyWith(
                                color: ultraLightBorderColor, strokeWidth: 0.5),
                      ),
                      lineTouchData: LineTouchData(
                          enabled: snapshot.hasData,
                          touchTooltipData: LineTouchTooltipData(
                            tooltipMargin: -10,
                            tooltipBgColor:
                                Theme.of(context).colorScheme.background,
                            getTooltipItems: (touchedSpots) {
                              return touchedSpots.map((barSpot) {
                                final flSpot = barSpot;
                                if (flSpot.x == 0 || flSpot.x == 6) {
                                  return null;
                                }

                                return LineTooltipItem(
                                    '${snapshot.data!.labels[flSpot.x.toInt()]} \n',
                                    const TextStyle(),
                                    children: UINumberFormatter.decimal(
                                            amountToConvert: snapshot.data!
                                                .balance[flSpot.x.toInt()],
                                            textStyle: const TextStyle(
                                                fontWeight: FontWeight.bold))
                                        .getTextSpanList(context));
                              }).toList();
                            },
                          )),
                      minY: snapshot.hasData
                          ? snapshot.data!.balance.min -
                              snapshot.data!.balance.min * 0.1
                          : 2,
                      maxY: snapshot.hasData
                          ? snapshot.data!.balance.max +
                              snapshot.data!.balance.max * 0.1
                          : 5,
                      titlesData: FlTitlesData(
                        show: true,
                        leftTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false)),
                        topTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false)),
                        bottomTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false)),
                        rightTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: snapshot.hasData,
                            reservedSize: 42,
                            getTitlesWidget: (value, meta) {
                              if (value == meta.max || value == meta.min) {
                                return Container();
                              }

                              return SideTitleWidget(
                                axisSide: meta.axisSide,
                                space: 0,
                                child: Row(
                                  children: [
                                    Container(
                                      width: 5,
                                      height: 1,
                                      color: ultraLightBorderColor,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      meta.formattedValue,
                                      style: const TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w300,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      borderData: FlBorderData(
                        show: false,
                        border: Border(
                          bottom: BorderSide(
                              color: ultraLightBorderColor, width: 1),
                          right: BorderSide(
                              color: ultraLightBorderColor, width: 1),
                        ),
                      ),
                      lineBarsData: [
                        LineChartBarData(
                          spots: snapshot.hasData
                              ? List.generate(
                                  snapshot.data!.balance.length,
                                  (index) => FlSpot(index.toDouble(),
                                      snapshot.data!.balance[index]))
                              : [
                                  const FlSpot(0, 3),
                                  const FlSpot(2.6, 2.2),
                                  const FlSpot(4.9, 4.3),
                                  const FlSpot(6.8, 3.1),
                                  const FlSpot(8, 4),
                                  const FlSpot(9.5, 3),
                                  const FlSpot(11, 4),
                                ],
                          isCurved: true,
                          curveSmoothness: snapshot.hasData ? 0.025 : 0.2,
                          color: snapshot.hasData
                              ? gradientColors[0]
                              : Colors.grey.withOpacity(0.2),
                          barWidth: 5,
                          isStrokeCapRound: true,
                          dotData: const FlDotData(show: false),
                          belowBarData: BarAreaData(
                            show: true,
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: snapshot.hasData
                                  ? gradientColors
                                      .map((color) => color.withOpacity(0.3))
                                      .toList()
                                  : [Colors.grey, Colors.grey.lighten(0.3)]
                                      .map((color) => color.withOpacity(0.15))
                                      .toList(),
                            ),
                          ),
                        ),
                      ],
                    )),
                    if (!snapshot.hasData)
                      Positioned.fill(
                        child: Align(
                            alignment: Alignment.center,
                            child: Text(
                              t.general.insufficient_data,
                              style: Theme.of(context).textTheme.titleLarge,
                            )),
                      ),
                  ],
                );
              }),
        ),
      ],
    );
  }
}
