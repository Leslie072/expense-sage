import 'package:currency_picker/currency_picker.dart' as picker;
import 'package:expense_sage/bloc/cubit/app_cubit.dart';
import 'package:expense_sage/helpers/currency.helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class CurrencyText extends StatelessWidget {
  final double? amount;
  final TextStyle? style;
  final TextOverflow? overflow;
  final picker.CurrencyService currencyService = picker.CurrencyService();

  CurrencyText(this.amount, {super.key, this.style, this.overflow});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AppCubit, AppState>(builder: (context, state) {
      picker.Currency? currency = currencyService.findByCode(state.currency!);
      return Text(
        amount == null
            ? "${currency!.symbol} "
            : CurrencyHelper.format(amount!,
                name: currency?.code, symbol: currency?.symbol),
        style: style,
        overflow: overflow,
      );
    });
  }
}
