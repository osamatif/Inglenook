import 'package:flutter/material.dart';
import 'package:grocery_admin/models/state_models/add_shipping_model.dart';
import 'package:grocery_admin/models/data_models/shipping_method.dart';
import 'package:grocery_admin/models/state_models/theme_model.dart';
import 'package:grocery_admin/services/database.dart';
import 'package:grocery_admin/widgets/buttons.dart';
import 'package:grocery_admin/widgets/fade_in.dart';
import 'package:grocery_admin/widgets/text_fields.dart';
import 'package:grocery_admin/widgets/texts.dart';
import 'package:provider/provider.dart';

class AddShipping extends StatefulWidget {
  final AddShippingModel model;
  final ShippingMethod? shippingMethod;

  AddShipping({required this.model, this.shippingMethod});

  static create(BuildContext context, {ShippingMethod? shippingMethod}) async {
    final database = Provider.of<Database>(context, listen: false);

    showModalBottomSheet(
        isScrollControlled: true,
        context: context,
        builder: (context) => Padding(
          padding: MediaQuery.of(context).viewInsets,
          child: ChangeNotifierProvider<AddShippingModel>(
            create: (context) => AddShippingModel(database: database),
            child: Consumer<AddShippingModel>(
              builder: (context, model, _) {
                return AddShipping(
                  model: model,
                  shippingMethod: shippingMethod,
                );
              },
            ),
          ),
        ));
  }

  @override
  _AddShippingState createState() => _AddShippingState();
}

class _AddShippingState extends State<AddShipping>
    with TickerProviderStateMixin {
  TextEditingController titleController = TextEditingController();
  TextEditingController durationController = TextEditingController();
  TextEditingController priceController = TextEditingController();

  FocusNode titleFocus = FocusNode();
  FocusNode durationFocus = FocusNode();
  FocusNode priceFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    if (widget.shippingMethod != null) {
      titleController =
          TextEditingController(text: widget.shippingMethod!.title);
      priceController =
          TextEditingController(text: widget.shippingMethod!.price.toString());
      durationController =
          TextEditingController(text: widget.shippingMethod!.duration);
    }
  }

  @override
  void dispose() {
    super.dispose();
    titleController.dispose();
    durationController.dispose();
    priceController.dispose();
    titleFocus.dispose();
    durationFocus.dispose();
    priceFocus.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeModel = Provider.of<ThemeModel>(context);
    return Container(
      padding: EdgeInsets.only(top: 10, bottom: 20, left: 20, right: 20),
      decoration: BoxDecoration(
          color: themeModel.backgroundColor,
          borderRadius: BorderRadius.only(
              topLeft: Radius.circular(15), topRight: Radius.circular(15)),
          boxShadow: [
            BoxShadow(
                blurRadius: 30,
                offset: Offset(0, 5),
                color: themeModel.shadowColor)
          ]),
      child: Wrap(
        children: [
          TextFields.defaultTextField(
            controller: titleController,
            focusNode: titleFocus,
            textInputAction: TextInputAction.next,
            textInputType: TextInputType.text,
            labelText: 'Title',
            onSubmitted: (value) {},
            error: !widget.model.validTitle,
            isLoading: widget.model.isLoading,
            themeModel: themeModel,
            margin: EdgeInsets.only(
              top: 10,
            ),
            padding: EdgeInsets.only(left: 10, right: 10, top: 5, bottom: 5),
          ),
          AnimatedSize(
            duration: Duration(milliseconds: 300),
            vsync: this,
            child: (!widget.model.validTitle)
                ? FadeIn(
                    child: Texts.helperText(
                        'Please enter a valid title', Colors.red),
                  )
                : SizedBox(),
          ),
          TextFields.defaultTextField(
            controller: durationController,
            focusNode: durationFocus,
            textInputAction: TextInputAction.next,
            textInputType: TextInputType.text,
            labelText: 'Duration',
            onSubmitted: (value) {},
            error: !widget.model.validDuration,
            isLoading: widget.model.isLoading,
            themeModel: themeModel,
            margin: EdgeInsets.only(
              top: 10,
            ),
            padding: EdgeInsets.only(left: 10, right: 10, top: 5, bottom: 5),
          ),
          AnimatedSize(
            duration: Duration(milliseconds: 300),
            vsync: this,
            child: (!widget.model.validDuration)
                ? FadeIn(
                    child: Texts.helperText(
                        'Please enter a valid duration', Colors.red),
                  )
                : SizedBox(),
          ),
          TextFields.defaultTextField(
            controller: priceController,
            focusNode: priceFocus,
            textInputAction: TextInputAction.next,
            textInputType: TextInputType.number,
            labelText: 'Price',
            onSubmitted: (value) {},
            error: !widget.model.validPrice,
            isLoading: widget.model.isLoading,
            themeModel: themeModel,
            margin: EdgeInsets.only(
              top: 10,
            ),
            padding: EdgeInsets.only(left: 10, right: 10, top: 5, bottom: 5),
          ),
          AnimatedSize(
            duration: Duration(milliseconds: 300),
            vsync: this,
            child: (!widget.model.validPrice)
                ? FadeIn(
                    child: Texts.helperText(
                        'Please enter a valid price', Colors.red),
                  )
                : SizedBox(),
          ),
          widget.model.isLoading
              ? Center(
                  child: Padding(
                    padding: EdgeInsets.only(top: 20),
                    child: CircularProgressIndicator(),
                  ),
                )
              : Container(
                  width: double.infinity,
                  child: Buttons.button(
                      widget: Texts.headline3(
                          (widget.shippingMethod == null) ? "Add" : 'Update',
                          Colors.white),
                      onPressed: () {
                        widget.model.submit(
                            context,
                            (widget.shippingMethod == null)
                                ? null
                                : widget.shippingMethod!.path,
                            titleController.text,
                            durationController.text,
                            priceController.text);
                      },
                      color: themeModel.accentColor),
                ),
        ],
      ),
    );
  }
}
